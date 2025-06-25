const { logToCloudWatch, testCloudWatchConnection } = require('./cloudwatch-logger');

async function runDebugTests() {
  console.log("🚀 Starting CloudWatch Debug Tests\n");
  
  // Test 1: Check AWS credentials and connection
  console.log("=== TEST 1: AWS Connection ===");
  const connectionOk = await testCloudWatchConnection();
  if (!connectionOk) {
    console.log("❌ Connection failed - check AWS credentials and permissions");
    return;
  }
  console.log("");
  
  // Test 2: Check environment variables
  console.log("=== TEST 2: Environment Variables ===");
  console.log(`AWS_REGION: ${process.env.AWS_REGION || 'undefined (using default: us-east-2)'}`);
  console.log(`NODE_ENV: ${process.env.NODE_ENV || 'undefined'}`);
  console.log(`HOSTNAME: ${require('os').hostname()}`);
  console.log("");
  
  // Test 3: Send test log messages
  console.log("=== TEST 3: Sending Test Logs ===");
  
  const testMessages = [
    "🧪 Debug Test Message #1 - Application Start",
    "🧪 Debug Test Message #2 - Connection Established", 
    "🧪 Debug Test Message #3 - Processing Request",
    "🧪 Debug Test Message #4 - Operation Complete"
  ];
  
  for (let i = 0; i < testMessages.length; i++) {
    console.log(`\n--- Sending Test Message ${i + 1} ---`);
    await logToCloudWatch(testMessages[i]);
    
    // Wait a bit between messages to avoid throttling
    if (i < testMessages.length - 1) {
      console.log("⏳ Waiting 2 seconds before next message...");
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }
  
  console.log("\n=== TEST COMPLETE ===");
  console.log("✅ All test messages sent!");
  console.log("🔍 Check your CloudWatch console to verify the log streams were created:");
  console.log(`   - ${new Date().toISOString().split('T')[0]}/${require('os').hostname()}/node-app.log`);
  console.log(`   - ${new Date().toISOString().split('T')[0]}/all_instance_logs/node-app.log`);
  console.log("\n🌐 AWS Console Link:");
  console.log(`   https://console.aws.amazon.com/cloudwatch/home?region=${process.env.AWS_REGION || 'us-east-2'}#logsV2:log-groups/log-group/node-app-logs`);
}

// Run the debug tests
runDebugTests().catch(err => {
  console.error("❌ Debug test failed:", err);
  process.exit(1);
});