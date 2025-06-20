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
let currentDate = "";

function getTodayDateStr() {
  return new Date().toISOString().split("T")[0]; // e.g. "2025-06-20"
}

async function getOrCreateLogStream(logStreamName) {
  try {
    const describeRes = await client.send(
      new DescribeLogStreamsCommand({
        logGroupName: LOG_GROUP,
        logStreamNamePrefix: logStreamName,
      })
    );

    if (describeRes.logStreams.length > 0) {
      return describeRes.logStreams[0].uploadSequenceToken;
    }

    await client.send(
      new CreateLogStreamCommand({
        logGroupName: LOG_GROUP,
        logStreamName,
      })
    );

    return null;
  } catch (err) {
    console.error("getOrCreateLogStream error:", err);
    throw err;
  }
}

async function logToCloudWatch(message) {
  try {
    const today = getTodayDateStr();
    const hostname = os.hostname();
    const logStreamName = `${today}/${hostname}/node-app.log`;

    if (currentDate !== today || !sequenceTokenCache[today]) {
      try {
        await client.send(new CreateLogGroupCommand({ logGroupName: LOG_GROUP }));
      } catch (err) {
        if (err.name !== "ResourceAlreadyExistsException") throw err;
      }

      const token = await getOrCreateLogStream(logStreamName);
      sequenceTokenCache[today] = token;
      currentDate = today;
    }

    const command = new PutLogEventsCommand({
      logGroupName: LOG_GROUP,
      logStreamName,
      logEvents: [
        {
          message: `[${new Date().toISOString()}] ${message}`,
          timestamp: Date.now(),
        },
      ],
      sequenceToken: sequenceTokenCache[today],
    });

    const response = await client.send(command);
    sequenceTokenCache[today] = response.nextSequenceToken;
  } catch (err) {
    console.error("CloudWatch logging failed:", err);
  }
}

module.exports = { logToCloudWatch };
