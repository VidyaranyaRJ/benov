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

    this.instanceBuffer = [];
    this.consolidatedBuffer = [];
    this.isInitialized = false;
    this.bufferFlushInterval = 3000;
    this.maxBufferSize = 50;
    this.sequenceTokens = new Map();

    this.initializeLogging().then(() => {
      this.startBufferFlush();
      console.log(`✅ CloudWatch logging initialized for ${this.hostname}`);
    }).catch(error => {
      console.error('❌ Failed to initialize CloudWatch logging:', error.message);
    });
  }

  async initializeLogging() {
    await this.createLogGroupIfNotExists();

    const today = new Date().toISOString().split('T')[0];
    await this.createLogStreamIfNotExists(`${today}/all-instances/consolidated.log`);
    await this.createLogStreamIfNotExists(`${today}/${this.hostname}/instance.log`);

    this.isInitialized = true;
    this.info(`🚀 CloudWatch Logger initialized for ${this.hostname}`);
  }

  async createLogGroupIfNotExists() {
    try {
      await this.client.send(new CreateLogGroupCommand({
        logGroupName: this.logGroupName
      }));
    } catch (error) {
      if (error.name !== 'ResourceAlreadyExistsException') throw error;
    }
  }

  async createLogStreamIfNotExists(logStreamName) {
    try {
      await this.client.send(new CreateLogStreamCommand({
        logGroupName: this.logGroupName,
        logStreamName: logStreamName
      }));
    } catch (error) {
      if (error.name !== 'ResourceAlreadyExistsException') throw error;
    }
  }

  getLogStreamName(type = 'consolidated') {
    const today = new Date().toISOString().split('T')[0];
    return type === 'consolidated'
      ? `${today}/all-instances/consolidated.log`
      : `${today}/${this.hostname}/instance.log`;
  }

  async getSequenceToken(logStreamName) {
    const command = new DescribeLogStreamsCommand({
      logGroupName: this.logGroupName,
      logStreamNamePrefix: logStreamName,
      limit: 1
    });

    const response = await this.client.send(command);
    const stream = response.logStreams?.[0];
    return stream?.uploadSequenceToken || null;
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
      setTimeout(() => this.addToBuffer(level, message, metadata), 100);
      return;
    }

    const logEntry = {
      timestamp: Date.now(),
      message: JSON.stringify(this.formatLogMessage(level, message, metadata))
    };

    this.instanceBuffer.push(logEntry);
    this.consolidatedBuffer.push(logEntry);

    if (this.instanceBuffer.length >= this.maxBufferSize || 
        this.consolidatedBuffer.length >= this.maxBufferSize) {
      this.flushBuffer();
    }
  }

  async flushBuffer() {
    if (this.instanceBuffer.length === 0 && this.consolidatedBuffer.length === 0) return;

    const instanceLogs = [...this.instanceBuffer];
    const consolidatedLogs = [...this.consolidatedBuffer];
    this.instanceBuffer = [];
    this.consolidatedBuffer = [];

    await Promise.allSettled([
      this.sendToCloudWatch(instanceLogs, 'instance'),
      this.sendToCloudWatch(consolidatedLogs, 'consolidated')
    ]);
  }

  async sendToCloudWatch(logEvents, streamType, maxRetries = 3) {
    const logStreamName = this.getLogStreamName(streamType);
    let retries = 0;

    while (retries <= maxRetries) {
      try {
        const command = new PutLogEventsCommand({
          logGroupName: this.logGroupName,
          logStreamName,
          logEvents: logEvents.sort((a, b) => a.timestamp - b.timestamp),
          sequenceToken: this.sequenceTokens.get(logStreamName)
        });

        const response = await this.client.send(command);
        this.sequenceTokens.set(logStreamName, response.nextSequenceToken);
        return;

      } catch (error) {
        retries++;

        if (error.name === 'InvalidSequenceTokenException') {
          const freshToken = await this.getSequenceToken(logStreamName);
          this.sequenceTokens.set(logStreamName, freshToken);
        } else if (error.name === 'ResourceNotFoundException') {
          await this.createLogStreamIfNotExists(logStreamName);
          this.sequenceTokens.delete(logStreamName);
        } else if (error.name === 'DataAlreadyAcceptedException') {
          return;
        } else if (retries > maxRetries) {
          console.error(`❌ Failed to send ${streamType} logs:`, error.message);
          throw error;
        }

        await this.sleep(1000 * Math.pow(2, retries));
      }
    }
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  startBufferFlush() {
    this.flushInterval = setInterval(() => {
      this.flushBuffer().catch(console.error);
    }, this.bufferFlushInterval);

    const cleanup = () => {
      clearInterval(this.flushInterval);
      this.flushBuffer().catch(console.error);
    };

    process.on('exit', cleanup);
    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
  }

  // Public Logging Methods
  info(message, metadata = {}) {
    this.addToBuffer('INFO', message, metadata);
    console.log(`[INFO] ${message}`);
  }

  error(message, metadata = {}) {
    this.addToBuffer('ERROR', message, metadata);
    console.error(`[ERROR] ${message}`);
  }

  warn(message, metadata = {}) {
    this.addToBuffer('WARN', message, metadata);
    console.warn(`[WARN] ${message}`);
  }

  debug(message, metadata = {}) {
    this.addToBuffer('DEBUG', message, metadata);
    console.log(`[DEBUG] ${message}`);
  }

  async forceFlush() {
    await this.flushBuffer();
  }

  // ✅ NEW method for cloudwatch-debug.js
  async testCloudWatchConnection() {
    try {
      this.info("🔌 Testing CloudWatch connection...");
      await this.forceFlush();
      return true;
    } catch (err) {
      console.error("❌ testCloudWatchConnection failed:", err.message);
      return false;
    }
  }
}

const logger = new CloudWatchLogger();
module.exports = logger;
