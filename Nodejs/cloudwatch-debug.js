// cloudwatch-debug.js
const logger = require('./cloudwatch-logger');
const os = require('os');

async function runDebugTests() {
  console.log("🚀 Starting CloudWatch Debug Tests\n");

  console.log("=== TEST 1: AWS Connection ===");
  const connectionOk = await logger.testCloudWatchConnection();
  if (!connectionOk) {
    console.log("❌ Connection failed - check AWS credentials and permissions");
    return;
  }
  console.log("✅ AWS connection test passed\n");

  console.log("=== TEST 2: Environment Variables ===");
  console.log(`AWS_REGION: ${process.env.AWS_REGION || 'undefined (default: us-east-2)'}`);
  console.log(`NODE_ENV: ${process.env.NODE_ENV || 'undefined'}`);
  console.log(`HOSTNAME: ${os.hostname()}\n`);

  console.log("=== TEST 3: Sending Test Logs ===");

  const testMessages = [
    "🧪 Debug Test Message #1 - Application Start",
    "🧪 Debug Test Message #2 - Connection Established", 
    "🧪 Debug Test Message #3 - Processing Request",
    "🧪 Debug Test Message #4 - Operation Complete"
  ];

  for (let i = 0; i < testMessages.length; i++) {
    console.log(`\n--- Sending Test Message ${i + 1} ---`);
    logger.info(testMessages[i]);
    if (i < testMessages.length - 1) {
      console.log("⏳ Waiting 2 seconds before next message...");
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }

  await logger.forceFlush();

  console.log("\n=== TEST COMPLETE ===");
  console.log("✅ All test messages sent!");
  console.log("🔍 Check your CloudWatch console to verify the log streams:");
  console.log(`   - ${new Date().toISOString().split('T')[0]}/${os.hostname()}/instance.log`);
  console.log(`   - ${new Date().toISOString().split('T')[0]}/all-instances/consolidated.log`);
  console.log(`🌐 AWS Console: https://console.aws.amazon.com/cloudwatch/home?region=${process.env.AWS_REGION || 'us-east-2'}#logsV2:log-groups/log-group/node-app-logs`);
}

runDebugTests().catch(err => {
  console.error("❌ Debug test failed:", err);
  process.exit(1);
});
