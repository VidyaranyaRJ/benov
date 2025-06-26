// cloudwatch-logger.js
const { CloudWatchLogsClient, PutLogEventsCommand, CreateLogGroupCommand, CreateLogStreamCommand, DescribeLogStreamsCommand } = require('@aws-sdk/client-cloudwatch-logs');
const os = require('os');

class CloudWatchLogger {
  constructor() {
    this.client = new CloudWatchLogsClient({ 
      region: process.env.AWS_REGION || 'us-east-1' 
    });
    this.logGroupName = process.env.LOG_GROUP_NAME || 'node-app-logs';
    this.hostname = process.env.CUSTOM_HOSTNAME || os.hostname();
    
    // Separate buffers for different log streams
    this.instanceBuffer = [];
    this.consolidatedBuffer = [];
    
    this.isInitialized = false;
    this.bufferFlushInterval = 3000; // 3 seconds
    this.maxBufferSize = 50;
    this.sequenceTokens = new Map(); // Track sequence tokens per stream
    
    // Initialize logging and start buffer flushing
    this.initializeLogging().then(() => {
      this.startBufferFlush();
      console.log(`✅ CloudWatch logging initialized for ${this.hostname}`);
    }).catch(error => {
      console.error('❌ Failed to initialize CloudWatch logging:', error.message);
    });
  }

  async initializeLogging() {
    try {
      // Create log group if it doesn't exist
      await this.createLogGroupIfNotExists();
      
      // Create both consolidated and per-instance streams
      const today = new Date().toISOString().split('T')[0];
      await this.createLogStreamIfNotExists(`${today}/all-instances/consolidated.log`);
      await this.createLogStreamIfNotExists(`${today}/${this.hostname}/instance.log`);
      
      this.isInitialized = true;
      
      // Send initialization message
      this.info(`🚀 CloudWatch Logger initialized for ${this.hostname}`);
      
    } catch (error) {
      console.error('Failed to initialize CloudWatch logging:', error.message);
      throw error;
    }
  }

  async createLogGroupIfNotExists() {
    try {
      await this.client.send(new CreateLogGroupCommand({
        logGroupName: this.logGroupName
      }));
    } catch (error) {
      if (error.name !== 'ResourceAlreadyExistsException') {
        throw error;
      }
    }
  }

  async createLogStreamIfNotExists(logStreamName) {
    try {
      await this.client.send(new CreateLogStreamCommand({
        logGroupName: this.logGroupName,
        logStreamName: logStreamName
      }));
    } catch (error) {
      if (error.name !== 'ResourceAlreadyExistsException') {
        throw error;
      }
    }
  }

  getLogStreamName(type = 'consolidated') {
    const today = new Date().toISOString().split('T')[0];
    
    if (type === 'consolidated') {
      return `${today}/all-instances/consolidated.log`;
    } else {
      return `${today}/${this.hostname}/instance.log`;
    }
  }

  // Get the latest sequence token for a stream
  async getSequenceToken(logStreamName) {
    try {
      const command = new DescribeLogStreamsCommand({
        logGroupName: this.logGroupName,
        logStreamNamePrefix: logStreamName,
        limit: 1
      });
      
      const response = await this.client.send(command);
      const stream = response.logStreams?.[0];
      return stream?.uploadSequenceToken || null;
    } catch (error) {
      console.error(`Failed to get sequence token for ${logStreamName}:`, error.message);
      return null;
    }
  }

  formatLogMessage(level, message, metadata = {}) {
    return {
      timestamp: new Date().toISOString(),
      level,
      message,
      hostname: this.hostname,
      pid: process.pid,
      ...metadata
    };
  }

  addToBuffer(level, message, metadata = {}) {
    if (!this.isInitialized) {
      // Queue logs until initialized
      setTimeout(() => this.addToBuffer(level, message, metadata), 100);
      return;
    }

    const logData = this.formatLogMessage(level, message, metadata);
    const logEntry = {
      timestamp: Date.now(),
      message: JSON.stringify(logData)
    };

    // Add to both buffers
    this.instanceBuffer.push(logEntry);
    this.consolidatedBuffer.push(logEntry);

    // Flush if buffer is getting full
    if (this.instanceBuffer.length >= this.maxBufferSize || 
        this.consolidatedBuffer.length >= this.maxBufferSize) {
      this.flushBuffer();
    }
  }

  async flushBuffer() {
    if (this.instanceBuffer.length === 0 && this.consolidatedBuffer.length === 0) {
      return;
    }

    // Create copies and clear buffers
    const instanceLogsToFlush = [...this.instanceBuffer];
    const consolidatedLogsToFlush = [...this.consolidatedBuffer];
    
    this.instanceBuffer = [];
    this.consolidatedBuffer = [];

    // Send logs to both streams concurrently
    const promises = [];
    
    if (instanceLogsToFlush.length > 0) {
      promises.push(this.sendToCloudWatch(instanceLogsToFlush, 'instance'));
    }
    
    if (consolidatedLogsToFlush.length > 0) {
      promises.push(this.sendToCloudWatch(consolidatedLogsToFlush, 'consolidated'));
    }

    // Wait for all sends to complete
    const results = await Promise.allSettled(promises);
    
    // Log any failures
    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        const streamType = index === 0 ? 'instance' : 'consolidated';
        console.error(`Failed to send logs to ${streamType} stream:`, result.reason);
      }
    });
  }

  async sendToCloudWatch(logEvents, streamType, maxRetries = 3) {
    const logStreamName = this.getLogStreamName(streamType);
    let retries = 0;
    
    while (retries <= maxRetries) {
      try {
        const command = new PutLogEventsCommand({
          logGroupName: this.logGroupName,
          logStreamName: logStreamName,
          logEvents: logEvents.sort((a, b) => a.timestamp - b.timestamp), // Ensure chronological order
          sequenceToken: this.sequenceTokens.get(logStreamName)
        });

        const response = await this.client.send(command);
        
        // Update sequence token on success
        if (response.nextSequenceToken) {
          this.sequenceTokens.set(logStreamName, response.nextSequenceToken);
        }
        
        return; // Success, exit retry loop
        
      } catch (error) {
        retries++;
        
        if (error.name === 'InvalidSequenceTokenException') {
          // Get fresh sequence token and retry
          const freshToken = await this.getSequenceToken(logStreamName);
          this.sequenceTokens.set(logStreamName, freshToken);
          
          if (retries <= maxRetries) {
            const backoffTime = Math.min(1000 * Math.pow(2, retries), 5000) + Math.random() * 500;
            await this.sleep(backoffTime);
            continue;
          }
        }
        
        if (error.name === 'DataAlreadyAcceptedException') {
          // Data was already accepted, consider it success
          return;
        }
        
        if (error.name === 'ResourceNotFoundException') {
          // Stream doesn't exist, recreate it
          await this.createLogStreamIfNotExists(logStreamName);
          this.sequenceTokens.delete(logStreamName);
          
          if (retries <= maxRetries) {
            continue;
          }
        }
        
        if (retries <= maxRetries) {
          // General retry with jittered exponential backoff
          const backoffTime = Math.min(1000 * Math.pow(2, retries), 5000) + Math.random() * 500;
          await this.sleep(backoffTime);
        } else {
          console.error(`❌ Failed to send ${streamType} logs after ${maxRetries} retries:`, error.message);
          throw error;
        }
      }
    }
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  startBufferFlush() {
    // Regular buffer flush
    this.flushInterval = setInterval(() => {
      this.flushBuffer().catch(console.error);
    }, this.bufferFlushInterval);

    // Flush on process exit
    const cleanup = () => {
      if (this.flushInterval) {
        clearInterval(this.flushInterval);
      }
      this.flushBuffer().catch(console.error);
    };

    process.on('SIGTERM', cleanup);
    process.on('SIGINT', cleanup);
    process.on('exit', cleanup);
    process.on('beforeExit', cleanup);
  }

  // Public logging methods
  info(message, metadata = {}) {
    this.addToBuffer('INFO', message, metadata);
    console.log(`[INFO] ${message}`); // Also log to console
  }

  error(message, metadata = {}) {
    this.addToBuffer('ERROR', message, metadata);
    console.error(`[ERROR] ${message}`); // Also log to console
  }

  warn(message, metadata = {}) {
    this.addToBuffer('WARN', message, metadata);
    console.warn(`[WARN] ${message}`); // Also log to console
  }

  debug(message, metadata = {}) {
    this.addToBuffer('DEBUG', message, metadata);
    console.log(`[DEBUG] ${message}`); // Also log to console
  }

  // Express middleware
  expressMiddleware() {
    return (req, res, next) => {
      const start = Date.now();
      
      res.on('finish', () => {
        const duration = Date.now() - start;
        const logMessage = `${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`;
        
        this.info(logMessage, {
          method: req.method,
          url: req.originalUrl,
          statusCode: res.statusCode,
          responseTime: duration,
          ip: req.ip || req.connection?.remoteAddress || 'unknown',
          userAgent: req.get('User-Agent'),
          referer: req.get('Referer')
        });
      });
      
      next();
    };
  }

  // Force flush method for critical logs
  async forceFlush() {
    return this.flushBuffer();
  }
}

// Create singleton instance
const logger = new CloudWatchLogger();

module.exports = logger;