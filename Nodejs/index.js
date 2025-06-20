const express = require('express');
const os = require('os');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

// Load environment variables from .env
require('dotenv').config();

const { logToCloudWatch } = require('./cloudwatch-logger');
const writeLog = require('./logger'); 

const app = express();
const port = process.env.PORT || 3000;

// Pre-compute static values
const HOSTNAME = os.hostname();
const writeFileAsync = promisify(fs.writeFile);

// Optimized in-memory storage
const stats = {
  visitCount: 0,
  uniqueVisitors: new Set(),
  startTime: Date.now()
};

// Pre-built HTML template for faster response
const HTML_TEMPLATE = `<!DOCTYPE html>
<html>
<head>
  <title>Live Time - CloudWatch Monitoring</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body{font-family:Arial,sans-serif;text-align:center;margin:0;padding:0;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;min-height:100vh}
    .container{background:rgba(255,255,255,0.1);padding:40px;border-radius:20px;display:inline-block;margin-top:50px;backdrop-filter:blur(10px);box-shadow:0 8px 32px 0 rgba(31,38,135,0.37)}
    #time{font-size:3em;margin:20px 0;font-weight:bold;text-shadow:2px 2px 4px rgba(0,0,0,0.5)}
    .stats{margin-top:30px;font-size:1.2em}
    .refresh-btn{background:#4CAF50;color:white;border:none;padding:15px 30px;font-size:1.1em;border-radius:25px;cursor:pointer;margin:10px;transition:all 0.3s ease;box-shadow:0 4px 15px 0 rgba(76,175,80,0.3)}
    .refresh-btn:hover{background:#45a049;transform:translateY(-2px);box-shadow:0 6px 20px 0 rgba(76,175,80,0.4)}
    .log-indicator{position:fixed;top:20px;right:20px;background:rgba(76,175,80,0.9);color:white;padding:10px 20px;border-radius:20px;font-size:0.9em;opacity:0;transition:opacity 0.3s ease;backdrop-filter:blur(5px);z-index:1000}
    .log-indicator.show{opacity:1}
    .status-indicator{position:fixed;top:20px;left:20px;background:rgba(76,175,80,0.9);color:white;padding:8px 16px;border-radius:15px;font-size:0.8em;backdrop-filter:blur(5px)}
    @media (max-width:768px){.container{margin:20px;padding:20px}#time{font-size:2em}.refresh-btn{display:block;width:100%;margin:10px 0}}
  </style>
</head>
<body>
  <div class="status-indicator">🟢 LIVE</div>
  <div class="container">
    <h1>⏰ Live - GMT Time Monitor</h1>
    <div id="time">Loading...</div>
    <div class="stats">
      <div>Visit Count: <span id="visitCount">{{VISIT_COUNT}}</span></div>
      <div>Unique Visitors: <span id="uniqueVisitors">{{UNIQUE_VISITORS}}</span></div>
      <div>Server: <span id="hostname">${HOSTNAME}</span></div>
    </div>
    <button class="refresh-btn" onclick="manualRefresh()">🔄 Manual Refresh</button>
    <button class="refresh-btn" onclick="viewLogs()">📊 View Logs</button>
    <button class="refresh-btn" onclick="viewHealth()">❤️ Health Check</button>
  </div>
  <div id="logIndicator" class="log-indicator">Log sent to CloudWatch! 📊</div>
  <script>
    let refreshCount=0,isOnline=!0;
    async function updateTime(){
      try{
        const e=await fetch('/time');
        if(!e.ok)throw new Error('HTTP '+e.status);
        const t=await e.json();
        document.getElementById('time').innerText=t.time,
        document.getElementById('visitCount').innerText=t.visitCount,
        document.getElementById('uniqueVisitors').innerText=t.uniqueVisitors||0;
        const n=document.getElementById('statusIndicator');
        n.innerHTML='🟢 LIVE ',n.style.background='rgba(76, 175, 80, 0.9)',
        isOnline||(isOnline=!0,showLogIndicator('🟢 Connection restored!')),
        showLogIndicator()
      }catch(e){
        console.error('Error fetching time:',e),
        document.getElementById('time').innerText='Error loading time';
        const t=document.getElementById('statusIndicator');
        t.innerHTML='🔴 OFFLINE',t.style.background='rgba(244, 67, 54, 0.9)',
        isOnline&&(isOnline=!1,showLogIndicator('🔴 Connection lost!',5e3))
      }
    }
    async function manualRefresh(){
      refreshCount++;
      try{
        await fetch('/manual-refresh',{method:'POST'}),
        showLogIndicator('🔄 Manual refresh logged!')
      }catch(e){
        console.error('Manual refresh error:',e),
        showLogIndicator('❌ Refresh failed!',3e3)
      }
      await updateTime()
    }
    function viewLogs(){window.open('/logs','_blank')}
    function viewHealth(){window.open('/health','_blank')}
    function showLogIndicator(e='Log sent to CloudWatch! 📊',t=2e3){
      const n=document.getElementById('logIndicator');
      n.innerText=e,n.classList.add('show'),
      setTimeout(()=>{n.classList.remove('show')},t)
    }
    window.addEventListener('load',()=>{updateTime(),setInterval(updateTime,1e4)}),
    setInterval(updateTime,1e4),
    document.addEventListener('visibilitychange',()=>{
      document.hidden||fetch('/page-focus',{method:'POST'}).catch(console.error)
    }),
    window.addEventListener('online',()=>{showLogIndicator('🟢 Back online!',3e3)}),
    window.addEventListener('offline',()=>{showLogIndicator('🔴 Gone offline!',3e3)})
  </script>
</body>
</html>`;

// Async logging to prevent blocking
const asyncLog = (message, type = 'INFO') => {
  // Non-blocking logging
  setImmediate(() => {
    try {
      writeLog(message, type);
    } catch (error) {
      console.error('Logging error:', error);
    }
  });
};

const asyncCloudWatchLog = (message) => {
  setImmediate(() => {
    try {
      logToCloudWatch(message);
    } catch (error) {
      console.error('CloudWatch logging error:', error);
    }
  });
};

// Fast IP extraction function
const getClientIp = (req) => {
  return req.headers['x-forwarded-for']?.split(',')[0] || 
         req.headers['x-real-ip'] || 
         req.connection?.remoteAddress || 
         req.socket?.remoteAddress || 
         'unknown';
};

// Optimized middleware with reduced overhead
app.use((req, res, next) => {
  if (req.url !== '/time') { // Skip logging for frequent time requests
    const clientIp = getClientIp(req);
    const userAgent = req.headers['user-agent'] || 'Unknown';
    asyncLog(`[ACCESS] ${req.method} ${req.url} - IP: ${clientIp} - UA: ${userAgent}`);
  }
  next();
});

// Optimized home route with pre-built template
app.get('/', (req, res) => {
  // Fast response with cached template
  stats.visitCount++;
  const clientIp = getClientIp(req);
  stats.uniqueVisitors.add(clientIp);
  
  // Non-blocking logging
  asyncCloudWatchLog(`🏠 [HOME] Visit from ${clientIp}`);
  asyncLog(`[PAGE_VIEW] HOME_PAGE_LOADED - Visit #${stats.visitCount} - Unique: ${stats.uniqueVisitors.size} - IP: ${clientIp}`);
  
  // Fast string replacement instead of template engine
  const html = HTML_TEMPLATE
    .replace('{{VISIT_COUNT}}', stats.visitCount)
    .replace('{{UNIQUE_VISITORS}}', stats.uniqueVisitors.size);
  
  res.setHeader('Content-Type', 'text/html');
  res.setHeader('Cache-Control', 'no-cache'); // Prevent caching for dynamic content
  res.send(html);
});

// Optimized time endpoint with minimal processing
app.get('/time', (req, res) => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  
  // Pre-computed day names array
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = dayNames[now.getDay()];
  
  const timeString = `${dayOfWeek} ${hours}:${minutes}:${seconds}`;
  
  // Reduced logging frequency (every 30 seconds instead of 10)
  if (seconds % 30 === 0) {
    const clientIp = getClientIp(req);
    asyncLog(`[TIME_API] TIME_REQUEST - Time: ${timeString} - IP: ${clientIp}`);
    asyncCloudWatchLog(`⏱️ [TIME] Requested by ${clientIp}`);
  }
  
  // Fast JSON response
  res.json({
    time: `🟢 ${timeString} - Server: ${HOSTNAME}`,
    visitCount: stats.visitCount,
    uniqueVisitors: stats.uniqueVisitors.size,
    hostname: HOSTNAME,
    timestamp: now.toISOString()
  });
});

// Optimized manual refresh endpoint
app.post('/manual-refresh', (req, res) => {
  const clientIp = getClientIp(req);
  asyncLog(`[USER_ACTION] MANUAL_REFRESH - User clicked refresh - IP: ${clientIp}`);
  
  res.json({ 
    status: 'refresh logged', 
    timestamp: new Date().toISOString() 
  });
});

// Optimized page focus endpoint
app.post('/page-focus', (req, res) => {
  const clientIp = getClientIp(req);
  asyncLog(`[USER_ACTION] PAGE_FOCUS - User returned to page - IP: ${clientIp}`);
  
  res.json({ 
    status: 'focus logged', 
    timestamp: new Date().toISOString() 
  });
});

// Optimized clear logs endpoint with async file operations
app.post('/clear-logs', async (req, res) => {
  const clientIp = getClientIp(req);
  asyncLog(`[ADMIN] LOGS_CLEARED - User cleared logs - IP: ${clientIp}`);
  
  try {
    // Get current log file path
    const now = new Date();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const year = now.getFullYear();
    const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${HOSTNAME}`;
    const logFile = path.join(logDir, 'node-app.log');
    
    // Async file clear
    await writeFileAsync(logFile, '');
    asyncLog(`[SYSTEM] LOG_FILE_CLEARED - Log file cleared by user - IP: ${clientIp}`);
    
    res.json({ 
      status: 'logs cleared', 
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    asyncLog(`[ERROR] LOG_CLEAR_ERROR - ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to clear logs',
      timestamp: new Date().toISOString()
    });
  }
});

// Fast health check with cached uptime calculation
let lastUptimeCheck = 0;
let cachedUptime = 0;

app.get('/health', (req, res) => {
  const now = Date.now();
  
  // Cache uptime calculation for 5 seconds
  if (now - lastUptimeCheck > 5000) {
    cachedUptime = Math.floor(process.uptime());
    lastUptimeCheck = now;
  }
  
  res.json({
    status: 'ok',
    uptime: cachedUptime,
    timestamp: new Date().toISOString(),
    memory: process.memoryUsage().rss // Add memory info for monitoring
  });
});

// Optimized error handling
app.use((err, req, res, next) => {
  const clientIp = getClientIp(req);
  asyncLog(`[ERROR] ${err.message} - IP: ${clientIp}`);
  
  res.status(500).json({ 
    error: 'Something went wrong!', 
    timestamp: new Date().toISOString() 
  });
});

// Performance monitoring
const logPerformanceMetrics = () => {
  const memUsage = process.memoryUsage();
  const uptime = process.uptime();
  
  asyncLog(`[PERF] Memory: ${Math.round(memUsage.rss / 1024 / 1024)}MB, Uptime: ${Math.round(uptime)}s, Visits: ${stats.visitCount}`);
};

// Start the server with performance logging
app.listen(port, () => {
  asyncCloudWatchLog(`✅ Server listening on port ${port}`);
  asyncLog(`SERVER_STARTED - Node.js app listening on port ${port} - Hostname: ${HOSTNAME}`, 'STARTUP');
  console.log(`🚀 Optimized server running at http://localhost:${port}`);
  
  // Log performance metrics every 5 minutes
  setInterval(logPerformanceMetrics, 5 * 60 * 1000);
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  asyncCloudWatchLog('🛑 Server shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  asyncCloudWatchLog('🛑 Server shutting down gracefully');
  process.exit(0);
});