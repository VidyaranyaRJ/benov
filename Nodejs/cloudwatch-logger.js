const {
  CloudWatchLogsClient,
  CreateLogGroupCommand,
  CreateLogStreamCommand,
  PutLogEventsCommand,
  DescribeLogStreamsCommand,
} = require("@aws-sdk/client-cloudwatch-logs");
const os = require("os");

const REGION = process.env.AWS_REGION || "us-east-2";
const LOG_GROUP = "node-app-logs";
const client = new CloudWatchLogsClient({ region: REGION });

let sequenceTokenCache = {};
let initializedDate = "";

function getTodayDateStr() {
  return new Date().toISOString().split("T")[0];
}

async function ensureLogStream(logStreamName) {
  try {
    console.log(`🔍 Checking if log stream exists: ${logStreamName}`);
    
    const describeRes = await client.send(
      new DescribeLogStreamsCommand({
        logGroupName: LOG_GROUP,
        logStreamNamePrefix: logStreamName,
      })
    );

    if (describeRes.logStreams && describeRes.logStreams.length > 0) {
      const existingStream = describeRes.logStreams.find(s => s.logStreamName === logStreamName);
      if (existingStream) {
        console.log(`✅ Log stream exists: ${logStreamName}`);
        return existingStream.uploadSequenceToken;
      }
    }

    console.log(`🆕 Creating new log stream: ${logStreamName}`);
    await client.send(
      new CreateLogStreamCommand({
        logGroupName: LOG_GROUP,
        logStreamName,
      })
    );
    
    console.log(`✅ Log stream created successfully: ${logStreamName}`);
    return null;
  } catch (err) {
    console.error(`❌ ensureLogStream error for ${logStreamName}:`, err.message);
    throw err;
  }
}

async function sendToStream(logStreamName, message) {
  try {
    if (!sequenceTokenCache[logStreamName]) {
      console.log(`🔧 Initializing sequence token for: ${logStreamName}`);
      sequenceTokenCache[logStreamName] = await ensureLogStream(logStreamName);
    }

    const logEvent = {
      message: `[${new Date().toISOString()}] ${message}`,
      timestamp: Date.now(),
    };

    console.log(`📤 Sending log to stream: ${logStreamName}`);
    console.log(`📝 Message: ${logEvent.message.substring(0, 100)}...`);

    const command = new PutLogEventsCommand({
      logGroupName: LOG_GROUP,
      logStreamName,
      logEvents: [logEvent],
      sequenceToken: sequenceTokenCache[logStreamName],
    });

    const res = await client.send(command);
    sequenceTokenCache[logStreamName] = res.nextSequenceToken;
    
    console.log(`✅ Log sent successfully to: ${logStreamName}`);
  } catch (err) {
    console.error(`❌ Failed to send log to ${logStreamName}:`, err.message);
    
    // If sequence token is invalid, reset and retry once
    if (err.name === 'InvalidSequenceTokenException') {
      console.log(`🔄 Resetting sequence token for ${logStreamName} and retrying...`);
      delete sequenceTokenCache[logStreamName];
      
      try {
        sequenceTokenCache[logStreamName] = await ensureLogStream(logStreamName);
        const retryCommand = new PutLogEventsCommand({
          logGroupName: LOG_GROUP,
          logStreamName,
          logEvents: [logEvent],
          sequenceToken: sequenceTokenCache[logStreamName],
        });
        
        const retryRes = await client.send(retryCommand);
        sequenceTokenCache[logStreamName] = retryRes.nextSequenceToken;
        console.log(`✅ Retry successful for: ${logStreamName}`);
      } catch (retryErr) {
        console.error(`❌ Retry failed for ${logStreamName}:`, retryErr.message);
      }
    }
  }
}

async function logToCloudWatch(message) {
  try {
    const today = getTodayDateStr();
    const hostname = os.hostname();

    console.log(`🚀 Starting CloudWatch logging process...`);
    console.log(`📅 Date: ${today}`);
    console.log(`🖥️ Hostname: ${hostname}`);
    console.log(`🌍 Region: ${REGION}`);
    console.log(`📦 Log Group: ${LOG_GROUP}`);

    const streamNames = [
      `${today}/${hostname}/node-app.log`,
      `${today}/all_instance_logs/node-app.log`,
    ];

    console.log(`📋 Target streams:`, streamNames);

    // Create log group if new day or first run
    if (initializedDate !== today) {
      console.log(`🆕 Ensuring log group exists: ${LOG_GROUP}`);
      try {
        await client.send(new CreateLogGroupCommand({ logGroupName: LOG_GROUP }));
        console.log(`✅ Log group created: ${LOG_GROUP}`);
      } catch (err) {
        if (err.name === "ResourceAlreadyExistsException") {
          console.log(`ℹ️ Log group already exists: ${LOG_GROUP}`);
        } else {
          console.error(`❌ Failed to create log group:`, err.message);
          throw err;
        }
      }
      initializedDate = today;
    }

    // Send to each stream
    for (const streamName of streamNames) {
      await sendToStream(streamName, message);
    }
    
    console.log(`🎉 CloudWatch logging completed successfully!`);
  } catch (err) {
    console.error("❌ CloudWatch logging failed:", err);
    console.error("Stack trace:", err.stack);
  }
}

// Test function to verify CloudWatch connectivity
async function testCloudWatchConnection() {
  console.log("🧪 Testing CloudWatch connection...");
  
  try {
    // Test if we can describe log groups
    const { CloudWatchLogsClient, DescribeLogGroupsCommand } = require("@aws-sdk/client-cloudwatch-logs");
    const testClient = new CloudWatchLogsClient({ region: REGION });
    
    const result = await testClient.send(new DescribeLogGroupsCommand({
      logGroupNamePrefix: LOG_GROUP,
      limit: 1
    }));
    
    console.log("✅ CloudWatch connection successful");
    console.log(`📊 Found ${result.logGroups ? result.logGroups.length : 0} matching log groups`);
    
    return true;
  } catch (err) {
    console.error("❌ CloudWatch connection failed:", err.message);
    return false;
  }
}

module.exports = { 
  logToCloudWatch, 
  testCloudWatchConnection 
};