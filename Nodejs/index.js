const express = require('express');
const os = require('os');
const fs = require('fs');
const path = require('path');
// Load environment variables from .env
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const LOG_PATH = process.env.LOG_PATH || '/var/log'; // Changed to match CloudWatch config
const LOG_FILE = path.join(LOG_PATH, 'node-app.log');

// Get hostname once at startup
const HOSTNAME = os.hostname();

// Ensure log directory exists
if (!fs.existsSync(LOG_PATH)) {
  fs.mkdirSync(LOG_PATH, { recursive: true });
}

// Enhanced log function with different log levels and hostname
function logToFileAndConsole(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const logLine = `${timestamp} [${level}] [${HOSTNAME}] ${message}`;
  
  // Log to file
  fs.appendFile(LOG_FILE, logLine + '\n', (err) => {
    if (err) console.error('Failed to write to log file:', err);
  });
  
  // Log to console (for CloudWatch) - this will appear in node-app-logs
  console.log(logLine);
}

// Track page visits
let visitCount = 0;
let uniqueVisitors = new Set();

// Middleware to log all requests
app.use((req, res, next) => {
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  const userAgent = req.headers['user-agent'] || 'Unknown';
  const method = req.method;
  const url = req.url;
  const timestamp = new Date().toLocaleString();
  
  logToFileAndConsole(`${method} ${url} - IP: ${clientIp} - User-Agent: ${userAgent}`, 'ACCESS');
  next();
});

// Serve the static HTML page
app.get('/', (req, res) => {
  visitCount++;
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  uniqueVisitors.add(clientIp);
  
  logToFileAndConsole(`HOME_PAGE_LOADED - Visit #${visitCount} - Unique visitors: ${uniqueVisitors.size} - IP: ${clientIp}`, 'PAGE_VIEW');
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Live Time - CloudWatch Monitoring</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          text-align: center; 
          margin-top: 50px; 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          min-height: 100vh;
        }
        .container {
          background: rgba(255,255,255,0.1);
          padding: 40px;
          border-radius: 20px;
          display: inline-block;
          margin-top: 50px;
          backdrop-filter: blur(10px);
        }
        #time { 
          font-size: 3em; 
          margin: 20px 0; 
          font-weight: bold;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        .stats {
          margin-top: 30px;
          font-size: 1.2em;
        }
        .refresh-btn {
          background: #4CAF50;
          color: white;
          border: none;
          padding: 15px 30px;
          font-size: 1.1em;
          border-radius: 25px;
          cursor: pointer;
          margin: 20px;
          transition: background 0.3s;
        }
        .refresh-btn:hover {
          background: #45a049;
        }
        .log-indicator {
          position: fixed;
          top: 20px;
          right: 20px;
          background: #ff4444;
          color: white;
          padding: 10px 20px;
          border-radius: 20px;
          font-size: 0.9em;
          opacity: 0;
          transition: opacity 0.3s;
        }
        .log-indicator.show {
          opacity: 1;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>⏰ Live Time Monitor</h1>
        <div id="time">Loading...</div>
        <div class="stats">
          <div>Visit Count: <span id="visitCount">${visitCount}</span></div>
          <div>Server: <span id="hostname">${HOSTNAME}</span></div>
        </div>
        <button class="refresh-btn" onclick="manualRefresh()">🔄 Manual Refresh</button>
        <button class="refresh-btn" onclick="viewLogs()">📊 View Logs</button>
      </div>
      
      <div id="logIndicator" class="log-indicator">
        Log sent to CloudWatch! 📊
      </div>

      <script>
        let refreshCount = 0;
        
        async function updateTime() {
          try {
            const res = await fetch('/time');
            const data = await res.json();
            document.getElementById('time').innerText = data.time;
            document.getElementById('visitCount').innerText = data.visitCount;
            showLogIndicator();
          } catch (error) {
            console.error('Error fetching time:', error);
            document.getElementById('time').innerText = 'Error loading time';
          }
        }
        
        async function manualRefresh() {
          refreshCount++;
          await fetch('/manual-refresh', { method: 'POST' });
          await updateTime();
        }
        
        function viewLogs() {
          window.open('/logs', '_blank');
        }
        
        function showLogIndicator() {
          const indicator = document.getElementById('logIndicator');
          indicator.classList.add('show');
          setTimeout(() => {
            indicator.classList.remove('show');
          }, 2000);
        }
        
        // Initial call
        updateTime();
        
        // Update every second
        setInterval(updateTime, 1000);
        
        // Log page visibility changes
        document.addEventListener('visibilitychange', () => {
          if (!document.hidden) {
            fetch('/page-focus', { method: 'POST' });
          }
        });
      </script>
    </body>
    </html>
  `);
});

// API endpoint to return time data
app.get('/time', (req, res) => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = days[now.getDay()];
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  const userAgent = req.headers['user-agent'] || 'Unknown';
  
  const timeString = `${dayOfWeek} ${hours}:${minutes}:${seconds}`;
  
  // Log the time request
  logToFileAndConsole(`TIME_REQUEST - Time: ${timeString} - IP: ${clientIp} - User-Agent: ${userAgent}`, 'TIME_API');
  
  res.json({
    time: `🟢 ${timeString} - Server: ${HOSTNAME}`,
    visitCount: visitCount,
    hostname: HOSTNAME,
    timestamp: now.toISOString()
  });
});

// Manual refresh endpoint
app.post('/manual-refresh', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  const userAgent = req.headers['user-agent'] || 'Unknown';
  
  logToFileAndConsole(`MANUAL_REFRESH - User clicked refresh button - IP: ${clientIp} - User-Agent: ${userAgent}`, 'USER_ACTION');
  
  res.json({ status: 'refresh logged' });
});

// Page focus endpoint
app.post('/page-focus', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  
  logToFileAndConsole(`PAGE_FOCUS - User returned to page - IP: ${clientIp}`, 'USER_ACTION');
  
  res.json({ status: 'focus logged' });
});

// Logs viewer endpoint
app.get('/logs', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  
  logToFileAndConsole(`LOGS_VIEWED - User accessed logs page - IP: ${clientIp}`, 'ADMIN');
  
  // Read recent log entries
  fs.readFile(LOG_FILE, 'utf8', (err, data) => {
    if (err) {
      logToFileAndConsole(`LOG_READ_ERROR - ${err.message}`, 'ERROR');
      return res.status(500).send('Error reading logs');
    }
    
    const lines = data.split('\n').filter(line => line.trim()).slice(-50); // Last 50 lines
    
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Application Logs - ${HOSTNAME}</title>
        <style>
          body { font-family: monospace; margin: 20px; background: #1e1e1e; color: #fff; }
          .log-entry { margin: 5px 0; padding: 5px; border-left: 3px solid #4CAF50; }
          .log-entry.ERROR { border-left-color: #f44336; }
          .log-entry.WARN { border-left-color: #ff9800; }
          .log-entry.ACCESS { border-left-color: #2196F3; }
          .log-entry.USER_ACTION { border-left-color: #9c27b0; }
          .log-entry.STARTUP { border-left-color: #00bcd4; }
          .log-entry.SYSTEM { border-left-color: #ff5722; }
          .log-entry.HEALTH { border-left-color: #8bc34a; }
          .header { background: #333; padding: 20px; margin: -20px -20px 20px -20px; }
          .refresh-btn { background: #4CAF50; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin-right: 10px; }
          .hostname-badge { background: #2196F3; padding: 5px 15px; border-radius: 15px; font-size: 0.9em; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Application Logs <span class="hostname-badge">${HOSTNAME}</span></h1>
          <p>Last 50 entries</p>
          <button class="refresh-btn" onclick="location.reload()">🔄 Refresh Logs</button>
          <button class="refresh-btn" onclick="window.close()">❌ Close</button>
        </div>
        <div>
          ${lines.map(line => {
            const level = line.match(/\[(.*?)\]/)?.[1] || 'INFO';
            return `<div class="log-entry ${level}">${line}</div>`;
          }).join('')}
        </div>
        <script>
          // Auto-refresh logs every 5 seconds
          setTimeout(() => location.reload(), 5000);
        </script>
      </body>
      </html>
    `);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress;
  logToFileAndConsole(`ERROR - ${err.message} - IP: ${clientIp} - Stack: ${err.stack}`, 'ERROR');
  res.status(500).send('Something went wrong!');
});

// Optional health check
app.get('/health', (req, res) => {
  const uptime = process.uptime();
  const memUsage = process.memoryUsage();
  
  logToFileAndConsole(`HEALTH_CHECK - Uptime: ${uptime}s - Memory: ${Math.round(memUsage.rss / 1024 / 1024)}MB`, 'HEALTH');
  
  res.status(200).json({
    status: 'OK',
    uptime: uptime,
    memory: memUsage,
    hostname: HOSTNAME,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logToFileAndConsole('SIGTERM received, shutting down gracefully', 'SYSTEM');
  process.exit(0);
});

process.on('SIGINT', () => {
  logToFileAndConsole('SIGINT received, shutting down gracefully', 'SYSTEM');
  process.exit(0);
});

// Start the server
app.listen(port, () => {
  logToFileAndConsole(`Server started on port ${port} - PID: ${process.pid} - Node: ${process.version}`, 'STARTUP');
});

// Log system information on startup
logToFileAndConsole(`System Info - OS: ${os.type()} ${os.release()} - Arch: ${os.arch()} - CPUs: ${os.cpus().length} - Memory: ${Math.round(os.totalmem() / 1024 / 1024 / 1024)}GB`, 'STARTUP');