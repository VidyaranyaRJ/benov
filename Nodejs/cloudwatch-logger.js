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
    this.logBuffer = [];
    this.consolidatedBuffer = []; // Separate buffer for consolidated logs
    this.isBuffering = true;
    this.bufferFlushInterval = 5000; // 5 seconds
    this.maxBufferSize = 100;
    this.sequenceTokens = {}; // Track sequence tokens per stream
    
    // Start buffer flushing
    this.startBufferFlush();
    
    // Ensure log group and streams exist
    this.initializeLogging();
  }

  async initializeLogging() {
    try {
      // Create log group if it doesn't exist
      await this.createLogGroupIfNotExists();
      
      // Create both consolidated and per-instance streams
      const today = new Date().toISOString().split('T')[0];
      await this.createLogStreamIfNotExists(`${today}/all_instance_logs/node-app.log`);
      await this.createLogStreamIfNotExists(`${today}/${this.hostname}/node-app.log`);
      
      console.log(`✅ CloudWatch logging initialized for ${this.hostname}`);
    } catch (error) {
      console.error('❌ Failed to initialize CloudWatch logging:', error.message);
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
      return `${today}/all_instance_logs/node-app.log`;
    } else {
      return `${today}/${this.hostname}/node-app.log`;
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

  addToBuffer(level, message, metadata = {}) {
    const logEntry = {
      timestamp: Date.now(),
      message: JSON.stringify({
        level,
        message,
        hostname: this.hostname,
        timestamp: new Date().toISOString(),
        ...metadata
      })
    };

    // Add to both buffers
    this.logBuffer.push(logEntry);
    this.consolidatedBuffer.push(logEntry);

    // Flush if buffer is getting full
    if (this.logBuffer.length >= this.maxBufferSize) {
      this.flushBuffer();
    }
  }

  async flushBuffer() {
    if (this.logBuffer.length === 0 && this.consolidatedBuffer.length === 0) return;

    const instanceLogsToFlush = [...this.logBuffer];
    const consolidatedLogsToFlush = [...this.consolidatedBuffer];
    
    this.logBuffer = [];
    this.consolidatedBuffer = [];

    // Send to both streams with proper error handling
    const promises = [];
    
    if (instanceLogsToFlush.length > 0) {
      promises.push(this.sendToCloudWatch(instanceLogsToFlush, 'instance'));
    }
    
    if (consolidatedLogsToFlush.length > 0) {
      promises.push(this.sendToCloudWatchWithRetry(consolidatedLogsToFlush, 'consolidated'));
    }

    await Promise.allSettled(promises);
  }

  async sendToCloudWatch(logEvents, streamType, retries = 3) {
    try {
      const logStreamName = this.getLogStreamName(streamType);
      
      const command = new PutLogEventsCommand({
        logGroupName: this.logGroupName,
        logStreamName: logStreamName,
        logEvents: logEvents
      });

      const response = await this.client.send(command);
      
      // Store the next sequence token if provided
      if (response.nextSequenceToken) {
        this.sequenceTokens[logStreamName] = response.nextSequenceToken;
      }
      
    } catch (error) {
      console.error(`❌ Failed to send logs to ${streamType} stream:`, error.message);
      
      // Retry with exponential backoff
      if (retries > 0) {
        const delay = Math.pow(2, 3 - retries) * 1000;
        setTimeout(() => {
          this.sendToCloudWatch(logEvents, streamType, retries - 1);
        }, delay);
      }
    }
  }

  // Special method for consolidated logs with better conflict handling
  async sendToCloudWatchWithRetry(logEvents, streamType, maxRetries = 5) {
    let retries = 0;
    
    while (retries <= maxRetries) {
      try {
        const logStreamName = this.getLogStreamName(streamType);
        
        const command = new PutLogEventsCommand({
          logGroupName: this.logGroupName,
          logStreamName: logStreamName,
          logEvents: logEvents,
          sequenceToken: this.sequenceTokens[logStreamName]
        });

        const response = await this.client.send(command);
        
        // Update sequence token on success
        if (response.nextSequenceToken) {
          this.sequenceTokens[logStreamName] = response.nextSequenceToken;
        }
        
        return; // Success, exit retry loop
        
      } catch (error) {
        retries++;
        
        // Handle specific errors
        if (error.name === 'InvalidSequenceTokenException' && retries <= maxRetries) {
          // Get fresh sequence token and retry
          this.sequenceTokens[this.getLogStreamName(streamType)] = await this.getSequenceToken(this.getLogStreamName(streamType));
          const backoffTime = Math.min(1000 * Math.pow(2, retries), 10000) + Math.random() * 1000;
          await this.sleep(backoffTime);
          continue;
        }
        
        if (error.name === 'DataAlreadyAcceptedException') {
          // Data was already accepted, consider it success
          console.log(`Data already accepted for ${streamType} stream`);
          return;
        }
        
        if (retries <= maxRetries) {
          // General retry with jittered exponential backoff
          const backoffTime = Math.min(1000 * Math.pow(2, retries), 10000) + Math.random() * 1000;
          console.log(`Retrying consolidated log send in ${backoffTime}ms (attempt ${retries}/${maxRetries})`);
          await this.sleep(backoffTime);
        } else {
          console.error(`❌ Failed to send consolidated logs after ${maxRetries} retries:`, error.message);
          break;
        }
      }
    }
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  startBufferFlush() {
    setInterval(() => {
      this.flushBuffer();
    }, this.bufferFlushInterval);

    // Flush on process exit
    process.on('SIGTERM', () => this.flushBuffer());
    process.on('SIGINT', () => this.flushBuffer());
    process.on('exit', () => this.flushBuffer());
  }

  // Public logging methods
  info(message, metadata = {}) {
    this.addToBuffer('INFO', message, metadata);
  }

  error(message, metadata = {}) {
    this.addToBuffer('ERROR', message, metadata);
  }

  warn(message, metadata = {}) {
    this.addToBuffer('WARN', message, metadata);
  }

  debug(message, metadata = {}) {
    this.addToBuffer('DEBUG', message, metadata);
  }

  // Express middleware
  expressMiddleware() {
    return (req, res, next) => {
      res.on('finish', () => {
        this.info(`${req.method} ${req.path}`, {
          method: req.method,
          path: req.path,
          statusCode: res.statusCode,
          ip: req.ip || req.connection.remoteAddress,
          userAgent: req.get('User-Agent'),
          responseTime: res.get('X-Response-Time')
        });
      });
      next();
    };
  }
}

// Create singleton instance
const logger = new CloudWatchLogger();

module.exports = logger;