// cloudwatch-logger.js
const { CloudWatchLogsClient, PutLogEventsCommand, CreateLogGroupCommand, CreateLogStreamCommand } = require('@aws-sdk/client-cloudwatch-logs');
const os = require('os');

class CloudWatchLogger {
  constructor() {
    this.client = new CloudWatchLogsClient({ 
      region: process.env.AWS_REGION || 'us-east-1' 
    });
    this.logGroupName = process.env.LOG_GROUP_NAME || 'node-app-logs';
    this.hostname = process.env.CUSTOM_HOSTNAME || os.hostname();
    this.logBuffer = [];
    this.isBuffering = true;
    this.bufferFlushInterval = 5000; // 5 seconds
    this.maxBufferSize = 100;
    
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

    this.logBuffer.push(logEntry);

    // Flush if buffer is getting full
    if (this.logBuffer.length >= this.maxBufferSize) {
      this.flushBuffer();
    }
  }

  async flushBuffer() {
    if (this.logBuffer.length === 0) return;

    const logsToFlush = [...this.logBuffer];
    this.logBuffer = [];

    // Send to both consolidated and per-instance streams
    await Promise.all([
      this.sendToCloudWatch(logsToFlush, 'consolidated'),
      this.sendToCloudWatch(logsToFlush, 'instance')
    ]);
  }

  async sendToCloudWatch(logEvents, streamType, retries = 3) {
    try {
      const command = new PutLogEventsCommand({
        logGroupName: this.logGroupName,
        logStreamName: this.getLogStreamName(streamType),
        logEvents: logEvents
        // Note: No sequenceToken needed since January 2023 AWS update
      });

      await this.client.send(command);
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