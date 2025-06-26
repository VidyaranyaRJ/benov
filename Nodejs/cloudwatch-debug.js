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

// test-logging.js - Add this to your project root and run it to test logging
const cloudwatchLogger = require('./cloudwatch-logger');

async function testLogging() {
  console.log('🧪 Starting CloudWatch logging test...');
  
  // Wait for initialization
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Test different log levels
  cloudwatchLogger.info('Test log from multiple instances - INFO level', {
    testType: 'multi-instance',
    logLevel: 'info',
    instanceId: process.env.HOSTNAME || 'test-instance'
  });
  
  cloudwatchLogger.warn('Test log from multiple instances - WARN level', {
    testType: 'multi-instance',
    logLevel: 'warn',
    instanceId: process.env.HOSTNAME || 'test-instance'
  });
  
  cloudwatchLogger.error('Test log from multiple instances - ERROR level', {
    testType: 'multi-instance',
    logLevel: 'error',
    instanceId: process.env.HOSTNAME || 'test-instance'
  });
  
  // Simulate application events
  cloudwatchLogger.info('Simulated user login', {
    event: 'user_login',
    userId: 'test-user-123',
    ip: '192.168.1.100'
  });
  
  cloudwatchLogger.info('Simulated database query', {
    event: 'db_query',
    query: 'SELECT * FROM users',
    duration: 45
  });
  
  // Force flush to ensure logs are sent
  await cloudwatchLogger.forceFlush();
  
  console.log('✅ Test logs sent to CloudWatch');
  console.log('Check your CloudWatch console - you should see logs in:');
  console.log(`- Instance stream: ${new Date().toISOString().split('T')[0]}/${process.env.HOSTNAME || 'test-instance'}/instance.log`);
  console.log(`- Consolidated stream: ${new Date().toISOString().split('T')[0]}/all-instances/consolidated.log`);
  
  process.exit(0);
}

testLogging().catch(console.error);