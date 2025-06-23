// const express = require('express');
// const os = require('os');
// const fs = require('fs');
// const path = require('path');
// // Load environment variables from .env
// require('dotenv').config();

// const compression = require('compression');

// const { logToCloudWatch } = require('./cloudwatch-logger');

// const writeLog = require('./logger'); 
// const app = express();
// app.use(compression());
// const port = process.env.PORT || 3000;



// // Get hostname once at startup
// const HOSTNAME = os.hostname();


// logToCloudWatch(`🚀 Node.js app started on host ${HOSTNAME}`);


// // Track page visits
// let visitCount = 0;
// let uniqueVisitors = new Set();

// // Middleware to log all requests
// app.use((req, res, next) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
//   const userAgent = req.headers['user-agent'] || 'Unknown';
//   const method = req.method;
//   const url = req.url;
  
//   writeLog(`[ACCESS] ${method} ${url} - IP: ${clientIp} - User-Agent: ${userAgent}`);
//   next();
// });

// // Serve the static HTML page
// app.get('/', (req, res) => {
//   logToCloudWatch(`🏠 [HOME] Visit from ${req.ip}`);


//   visitCount++;
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
//   uniqueVisitors.add(clientIp);
  
//   writeLog(`[PAGE_VIEW] HOME_PAGE_LOADED - Visit #${visitCount} - Unique visitors: ${uniqueVisitors.size} - IP: ${clientIp}`);
  
//   res.send(`
//     <!DOCTYPE html>
//     <html>
//     <head>
//       <title>Live Time - CloudWatch Monitoring</title>
//       <meta charset="UTF-8">
//       <meta name="viewport" content="width=device-width, initial-scale=1.0">
//       <style>
//         body { 
//           font-family: Arial, sans-serif; 
//           text-align: center; 
//           margin: 0;
//           padding: 0;
//           background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
//           color: white;
//           min-height: 100vh;
//         }
//         .container {
//           background: rgba(255,255,255,0.1);
//           padding: 40px;
//           border-radius: 20px;
//           display: inline-block;
//           margin-top: 50px;
//           backdrop-filter: blur(10px);
//           box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
//         }
//         #time { 
//           font-size: 3em; 
//           margin: 20px 0; 
//           font-weight: bold;
//           text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
//         }
//         .stats {
//           margin-top: 30px;
//           font-size: 1.2em;
//         }
//         .refresh-btn {
//           background: #4CAF50;
//           color: white;
//           border: none;
//           padding: 15px 30px;
//           font-size: 1.1em;
//           border-radius: 25px;
//           cursor: pointer;
//           margin: 10px;
//           transition: all 0.3s ease;
//           box-shadow: 0 4px 15px 0 rgba(76, 175, 80, 0.3);
//         }
//         .refresh-btn:hover {
//           background: #45a049;
//           transform: translateY(-2px);
//           box-shadow: 0 6px 20px 0 rgba(76, 175, 80, 0.4);
//         }
//         .log-indicator {
//           position: fixed;
//           top: 20px;
//           right: 20px;
//           background: rgba(76, 175, 80, 0.9);
//           color: white;
//           padding: 10px 20px;
//           border-radius: 20px;
//           font-size: 0.9em;
//           opacity: 0;
//           transition: opacity 0.3s ease;
//           backdrop-filter: blur(5px);
//           z-index: 1000;
//         }
//         .log-indicator.show {
//           opacity: 1;
//         }
//         .status-indicator {
//           position: fixed;
//           top: 20px;
//           left: 20px;
//           background: rgba(76, 175, 80, 0.9);
//           color: white;
//           padding: 8px 16px;
//           border-radius: 15px;
//           font-size: 0.8em;
//           backdrop-filter: blur(5px);
//         }
//         @media (max-width: 768px) {
//           .container {
//             margin: 20px;
//             padding: 20px;
//           }
//           #time {
//             font-size: 2em;
//           }
//           .refresh-btn {
//             display: block;
//             width: 100%;
//             margin: 10px 0;
//           }
//         }
//       </style>
//     </head>
//     <body>
//       <div class="status-indicator" id="statusIndicator">
//         🟢 LIVE
//       </div>
      
//       <div class="container">
//         <h1>⏰ Live - GMT Time Monitor</h1>
//         <div id="time">Loading...</div>
//         <div class="stats">
//           <div>Visit Count: <span id="visitCount">${visitCount}</span></div>
//           <div>Unique Visitors: <span id="uniqueVisitors">${uniqueVisitors.size}</span></div>
//           <div>Server: <span id="hostname">${HOSTNAME}</span></div>
//         </div>
//         <button class="refresh-btn" onclick="manualRefresh()">🔄 Manual Refresh</button>
//         <button class="refresh-btn" onclick="viewLogs()">📊 View Logs</button>
//         <button class="refresh-btn" onclick="viewHealth()">❤️ Health Check</button>
//       </div>
      
//       <div id="logIndicator" class="log-indicator">
//         Log sent to CloudWatch! 📊
//       </div>

//       <script>
//         let refreshCount = 0;
//         let isOnline = true;
        
//         async function updateTime() {
//           try {
//             const res = await fetch('/time');
//             if (!res.ok) throw new Error('HTTP ' + res.status);
            
//             const data = await res.json();
//             document.getElementById('time').innerText = data.time;
//             document.getElementById('visitCount').innerText = data.visitCount;
//             document.getElementById('uniqueVisitors').innerText = data.uniqueVisitors || 0;
            
//             // Update status indicator
//             const statusEl = document.getElementById('statusIndicator');
//             statusEl.innerHTML = '🟢 LIVE ';
//             statusEl.style.background = 'rgba(76, 175, 80, 0.9)';
            
//             if (!isOnline) {
//               isOnline = true;
//               showLogIndicator('🟢 Connection restored!');
//             }
            
//             showLogIndicator();
//           } catch (error) {
//             console.error('Error fetching time:', error);
//             document.getElementById('time').innerText = 'Error loading time';
            
//             // Update status indicator
//             const statusEl = document.getElementById('statusIndicator');
//             statusEl.innerHTML = '🔴 OFFLINE';
//             statusEl.style.background = 'rgba(244, 67, 54, 0.9)';
            
//             if (isOnline) {
//               isOnline = false;
//               showLogIndicator('🔴 Connection lost!', 5000);
//             }
//           }
//         }
        
//         async function manualRefresh() {
//           refreshCount++;
//           try {
//             await fetch('/manual-refresh', { method: 'POST' });
//             showLogIndicator('🔄 Manual refresh logged!');
//           } catch (error) {
//             console.error('Manual refresh error:', error);
//             showLogIndicator('❌ Refresh failed!', 3000);
//           }
//           await updateTime();
//         }
        
//         function viewLogs() {
//           window.open('/logs', '_blank');
//         }
        
//         function viewHealth() {
//           window.open('/health', '_blank');
//         }
        
//         function showLogIndicator(message = 'Log sent to CloudWatch! 📊', duration = 2000) {
//           const indicator = document.getElementById('logIndicator');
//           indicator.innerText = message;
//           indicator.classList.add('show');
//           setTimeout(() => {
//             indicator.classList.remove('show');
//           }, duration);
//         }
        
//         // Initial call
//         // updateTime();
//         window.addEventListener('load', () => {
//           updateTime();
//           setInterval(updateTime, 1000);
//         });
        
//         // Update every second
//         setInterval(updateTime, 1000);
        
//         // Log page visibility changes
//         document.addEventListener('visibilitychange', () => {
//           if (!document.hidden) {
//             fetch('/page-focus', { method: 'POST' }).catch(console.error);
//           }
//         });
        
//         // Handle connection errors gracefully
//         window.addEventListener('online', () => {
//           showLogIndicator('🟢 Back online!', 3000);
//         });
        
//         window.addEventListener('offline', () => {
//           showLogIndicator('🔴 Gone offline!', 3000);
//         });
//       </script>
//     </body>
//     </html>
//   `);
// });

// // API endpoint to return time data
// app.get('/time', (req, res) => {
//   logToCloudWatch(`⏱️ [TIME] Requested by ${req.ip}`);

//   const now = new Date();
//   const hours = now.getHours().toString().padStart(2, '0');
//   const minutes = now.getMinutes().toString().padStart(2, '0');
//   const seconds = now.getSeconds().toString().padStart(2, '0');
//   const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
//   const dayOfWeek = days[now.getDay()];
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   const timeString = `${dayOfWeek} ${hours}:${minutes}:${seconds}`;
  
//   // Log the time request (reduced frequency to avoid log spam)
//   if (seconds % 10 === 0) { // Log only every 10 seconds
//     writeLog(`[TIME_API] TIME_REQUEST - Time: ${timeString} - IP: ${clientIp}`);
//   }
  
//   res.json({
//     time: `🟢 ${timeString} - Server: ${HOSTNAME}`,
//     visitCount: visitCount,
//     uniqueVisitors: uniqueVisitors.size,
//     hostname: HOSTNAME,
//     timestamp: now.toISOString()
//   });
// });

// // Manual refresh endpoint
// app.post('/manual-refresh', (req, res) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   writeLog(`[USER_ACTION] MANUAL_REFRESH - User clicked refresh button - IP: ${clientIp}`);
  
//   res.json({ status: 'refresh logged', timestamp: new Date().toISOString() });
// });

// // Page focus endpoint
// app.post('/page-focus', (req, res) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   writeLog(`[USER_ACTION] PAGE_FOCUS - User returned to page - IP: ${clientIp}`);
  
//   res.json({ status: 'focus logged', timestamp: new Date().toISOString() });
// });

// // Logs viewer endpoint
// app.get('/logs', (req, res) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   writeLog(`[ADMIN] LOGS_VIEWED - User accessed logs page - IP: ${clientIp}`);
  
//   // Get current log file path (same as logger.js)
//   const now = new Date();
//   const month = String(now.getMonth() + 1).padStart(2, '0');
//   const day = String(now.getDate()).padStart(2, '0');
//   const year = now.getFullYear();
//   const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${HOSTNAME}`;
//   const logFile = path.join(logDir, 'node-app.log');
  
//   // Read recent log entries
//   fs.readFile(logFile, 'utf8', (err, data) => {
//     if (err) {
//       writeLog(`[ERROR] LOG_READ_ERROR - ${err.message}`);
//       return res.status(500).send('Error reading logs');
//     }
    
//     const lines = data.split('\n').filter(line => line.trim()).slice(-100); // Last 100 lines
    
//     res.send(`
//       <!DOCTYPE html>
//       <html>
//       <head>
//         <title>Application Logs - ${HOSTNAME}</title>
//         <meta charset="UTF-8">
//         <meta name="viewport" content="width=device-width, initial-scale=1.0">
//         <style>
//           body { 
//             font-family: 'Courier New', monospace; 
//             margin: 0; 
//             padding: 0;
//             background: #1e1e1e; 
//             color: #fff; 
//             font-size: 14px;
//           }
//           .log-entry { 
//             margin: 2px 0; 
//             padding: 8px 12px; 
//             border-left: 3px solid #4CAF50; 
//             background: rgba(255,255,255,0.02);
//             word-wrap: break-word;
//             font-family: 'Courier New', monospace;
//             font-size: 13px;
//             line-height: 1.4;
//           }
//           .log-entry.ERROR { border-left-color: #f44336; background: rgba(244, 67, 54, 0.1); }
//           .log-entry.WARN { border-left-color: #ff9800; background: rgba(255, 152, 0, 0.1); }
//           .log-entry.ACCESS { border-left-color: #2196F3; background: rgba(33, 150, 243, 0.05); }
//           .log-entry.USER_ACTION { border-left-color: #9c27b0; background: rgba(156, 39, 176, 0.1); }
//           .log-entry.STARTUP { border-left-color: #00bcd4; background: rgba(0, 188, 212, 0.1); }
//           .log-entry.SYSTEM { border-left-color: #ff5722; background: rgba(255, 87, 34, 0.1); }
//           .log-entry.HEALTH { border-left-color: #8bc34a; background: rgba(139, 195, 74, 0.1); }
//           .log-entry.TIME_API { border-left-color: #607d8b; background: rgba(96, 125, 139, 0.05); }
//           .log-entry.PAGE_VIEW { border-left-color: #e91e63; background: rgba(233, 30, 99, 0.1); }
//           .log-entry.ADMIN { border-left-color: #795548; background: rgba(121, 85, 72, 0.1); }
//           .header { 
//             background: #333; 
//             padding: 20px; 
//             margin: 0;
//             position: sticky;
//             top: 0;
//             z-index: 100;
//             box-shadow: 0 2px 10px rgba(0,0,0,0.5);
//           }
//           .refresh-btn { 
//             background: #4CAF50; 
//             color: white; 
//             border: none; 
//             padding: 10px 20px; 
//             border-radius: 5px; 
//             cursor: pointer; 
//             margin-right: 10px; 
//             margin-bottom: 10px;
//             transition: background 0.3s;
//           }
//           .refresh-btn:hover { background: #45a049; }
//           .refresh-btn.danger { background: #f44336; }
//           .refresh-btn.danger:hover { background: #da190b; }
//           .hostname-badge { 
//             background: #2196F3; 
//             padding: 5px 15px; 
//             border-radius: 15px; 
//             font-size: 0.9em; 
//             margin-left: 10px;
//           }
//           .log-container {
//             padding: 20px;
//             max-height: calc(100vh - 160px);
//             overflow-y: auto;
//           }
//           .stats {
//             background: #444;
//             padding: 10px 20px;
//             margin: 0;
//             font-size: 14px;
//             color: #ccc;
//           }
//           @media (max-width: 768px) {
//             .header { padding: 15px; }
//             .log-entry { font-size: 12px; padding: 6px 8px; }
//             .refresh-btn { padding: 8px 15px; font-size: 14px; }
//           }
//         </style>
//       </head>
//       <body>
//         <div class="header">
//           <h1>📊 Application Logs <span class="hostname-badge">${HOSTNAME}</span></h1>
//           <div class="stats">
//             Last ${lines.length} entries • Auto-refresh: 10s • Total size: ${(data.length / 1024).toFixed(1)}KB
//           </div>
//           <div style="margin-top: 15px;">
//             <button class="refresh-btn" onclick="location.reload()">🔄 Refresh Now</button>
//             <button class="refresh-btn" onclick="window.close()">❌ Close</button>
//             <button class="refresh-btn danger" onclick="clearLogs()">🗑️ Clear Logs</button>
//           </div>
//         </div>
//         <div class="log-container">
//           ${lines.map(line => {
//             const levelMatch = line.match(/\\[(.*?)\\]/);
//             const level = levelMatch ? levelMatch[1] : 'INFO';
//             const timestamp = line.match(/^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z)/)?.[1] || '';
//             return '<div class="log-entry ' + level + '" title="' + timestamp + '">' + line + '</div>';
//           }).join('')}
//         </div>
//         <script>
//           let autoRefresh = true;
          
//           function clearLogs() {
//             if (confirm('Are you sure you want to clear all logs? This action cannot be undone.')) {
//               fetch('/clear-logs', { method: 'POST' })
//                 .then(() => location.reload())
//                 .catch(err => alert('Failed to clear logs: ' + err.message));
//             }
//           }
          
//           // Auto-refresh logs every 10 seconds
//           function scheduleRefresh() {
//             if (autoRefresh && !document.hidden) {
//               setTimeout(() => {
//                 location.reload();
//               }, 10000);
//             }
//           }
          
//           // Pause auto-refresh when tab is hidden
//           document.addEventListener('visibilitychange', () => {
//             if (!document.hidden) {
//               scheduleRefresh();
//             }
//           });
          
//           // Auto-scroll to bottom
//           window.addEventListener('load', () => {
//             window.scrollTo(0, document.body.scrollHeight);
//             scheduleRefresh();
//           });
//         </script>
//       </body>
//       </html>
//     `);
//   });
// });

// // Clear logs endpoint
// app.post('/clear-logs', (req, res) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   writeLog(`[ADMIN] LOGS_CLEARED - User cleared logs - IP: ${clientIp}`);
  
//   // Get current log file path (same as logger.js)
//   const now = new Date();
//   const month = String(now.getMonth() + 1).padStart(2, '0');
//   const day = String(now.getDate()).padStart(2, '0');
//   const year = now.getFullYear();
//   const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${HOSTNAME}`;
//   const logFile = path.join(logDir, 'node-app.log');
  
//   // Clear the log file
//   fs.writeFile(logFile, '', (err) => {
//     if (err) {
//       writeLog(`[ERROR] LOG_CLEAR_ERROR - ${err.message}`);
//       return res.status(500).json({ error: 'Failed to clear logs' });
//     }
    
//     writeLog(`[SYSTEM] LOG_FILE_CLEARED - Log file cleared by user - IP: ${clientIp}`);
//     res.json({ status: 'logs cleared', timestamp: new Date().toISOString() });
//   });
// });

// // Error handling middleware
// app.use((err, req, res, next) => {
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   writeLog(`[ERROR] ${err.message} - IP: ${clientIp} - Stack: ${err.stack}`);
//   res.status(500).json({ 
//     error: 'Something went wrong!', 
//     timestamp: new Date().toISOString() 
//   });
// });

// // Enhanced health check
// app.get('/health', (req, res) => {
//   logToCloudWatch(`💓 [HEALTH] Check from ${req.ip}`);

//   const uptime = process.uptime();
//   const memUsage = process.memoryUsage();
//   const loadAvg = os.loadavg();
//   const clientIp = req.headers['x-forwarded-for'] || 
//                    req.headers['x-real-ip'] || 
//                    req.connection.remoteAddress || 
//                    req.socket.remoteAddress || 
//                    'unknown';
  
//   // Only log health checks every 5 minutes to avoid spam
//   const now = Date.now();
//   if (!app.lastHealthLog || now - app.lastHealthLog > 300000) {
//     writeLog(`[HEALTH] HEALTH_CHECK - Uptime: ${Math.floor(uptime)}s - Memory: ${Math.round(memUsage.rss / 1024 / 1024)}MB - Load: ${loadAvg[0].toFixed(2)} - IP: ${clientIp}`);
//     app.lastHealthLog = now;
//   }
  
//   const healthData = {
//     status: 'OK',
//     uptime: Math.floor(uptime),
//     memory: {
//       rss: Math.round(memUsage.rss / 1024 / 1024),
//       heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
//       heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
//       external: Math.round(memUsage.external / 1024 / 1024)
//     },
//     system: {
//       loadAverage: loadAvg,
//       totalMemory: Math.round(os.totalmem() / 1024 / 1024 / 1024),
//       freeMemory: Math.round(os.freemem() / 1024 / 1024 / 1024),
//       cpuCount: os.cpus().length
//     },
//     application: {
//       visitCount: visitCount,
//       uniqueVisitors: uniqueVisitors.size,
//       nodeVersion: process.version,
//       platform: os.platform(),
//       arch: os.arch()
//     },
//     hostname: HOSTNAME,
//     timestamp: new Date().toISOString()
//   };
  
//   // Return JSON for API calls, HTML for browser
//   if (req.headers.accept && req.headers.accept.includes('application/json')) {
//     res.status(200).json(healthData);
//   } else {
//     res.send(`
//       <!DOCTYPE html>
//       <html>
//       <head>
//         <title>Health Check - ${HOSTNAME}</title>
//         <meta charset="UTF-8">
//         <meta name="viewport" content="width=device-width, initial-scale=1.0">
//         <style>
//           body { 
//             font-family: Arial, sans-serif; 
//             background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
//             color: white;
//             margin: 0;
//             padding: 20px;
//             min-height: 100vh;
//           }
//           .health-container {
//             max-width: 800px;
//             margin: 0 auto;
//             background: rgba(255,255,255,0.1);
//             padding: 30px;
//             border-radius: 20px;
//             backdrop-filter: blur(10px);
//             box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
//           }
//           .health-grid {
//             display: grid;
//             grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
//             gap: 20px;
//             margin-top: 20px;
//           }
//           .health-card {
//             background: rgba(255,255,255,0.05);
//             padding: 20px;
//             border-radius: 15px;
//             border: 1px solid rgba(255,255,255,0.1);
//           }
//           .health-card h3 {
//             margin-top: 0;
//             color: #4CAF50;
//           }
//           .metric {
//             display: flex;
//             justify-content: space-between;
//             margin: 10px 0;
//             padding: 8px 0;
//             border-bottom: 1px solid rgba(255,255,255,0.1);
//           }
//           .metric:last-child {
//             border-bottom: none;
//           }
//           .status-ok {
//             color: #4CAF50;
//             font-weight: bold;
//             font-size: 1.2em;
//           }
//           .back-btn {
//             background: #4CAF50;
//             color: white;
//             border: none;
//             padding: 15px 30px;
//             font-size: 1.1em;
//             border-radius: 25px;
//             cursor: pointer;
//             margin: 20px 10px 0 0;
//             transition: all 0.3s ease;
//             text-decoration: none;
//             display: inline-block;
//           }
//           .back-btn:hover {
//             background: #45a049;
//             transform: translateY(-2px);
//           }
//         </style>
//       </head>
//       <body>
//         <div class="health-container">
//           <h1>🏥 System Health Check</h1>
//           <div class="status-ok">✅ System Status: ${healthData.status}</div>
//           <div class="health-grid">
//             <div class="health-card">
//               <h3>🖥️ System Info</h3>
//               <div class="metric">
//                 <span>Hostname:</span>
//                 <span>${healthData.hostname}</span>
//               </div>
//               <div class="metric">
//                 <span>Platform:</span>
//                 <span>${healthData.application.platform}</span>
//               </div>
//               <div class="metric">
//                 <span>Architecture:</span>
//                 <span>${healthData.application.arch}</span>
//               </div>
//               <div class="metric">
//                 <span>Node Version:</span>
//                 <span>${healthData.application.nodeVersion}</span>
//               </div>
//               <div class="metric">
//                 <span>CPU Cores:</span>
//                 <span>${healthData.system.cpuCount}</span>
//               </div>
//             </div>
            
//             <div class="health-card">
//               <h3>⏱️ Runtime</h3>
//               <div class="metric">
//                 <span>Uptime:</span>
//                 <span>${Math.floor(healthData.uptime / 3600)}h ${Math.floor((healthData.uptime % 3600) / 60)}m ${healthData.uptime % 60}s</span>
//               </div>
//               <div class="metric">
//                 <span>Total Visits:</span>
//                 <span>${healthData.application.visitCount}</span>
//               </div>
//               <div class="metric">
//                 <span>Unique Visitors:</span>
//                 <span>${healthData.application.uniqueVisitors}</span>
//               </div>
//             </div>
            
//             <div class="health-card">
//               <h3>💾 Memory Usage</h3>
//               <div class="metric">
//                 <span>RSS:</span>
//                 <span>${healthData.memory.rss} MB</span>
//               </div>
//               <div class="metric">
//                 <span>Heap Used:</span>
//                 <span>${healthData.memory.heapUsed} MB</span>
//               </div>
//               <div class="metric">
//                 <span>Heap Total:</span>
//                 <span>${healthData.memory.heapTotal} MB</span>
//               </div>
//               <div class="metric">
//                 <span>External:</span>
//                 <span>${healthData.memory.external} MB</span>
//               </div>
//             </div>
            
//             <div class="health-card">
//               <h3>🖲️ System Resources</h3>
//               <div class="metric">
//                 <span>Load Average:</span>
//                 <span>${healthData.system.loadAverage[0].toFixed(2)}</span>
//               </div>
//               <div class="metric">
//                 <span>Total Memory:</span>
//                 <span>${healthData.system.totalMemory} GB</span>
//               </div>
//               <div class="metric">
//                 <span>Free Memory:</span>
//                 <span>${healthData.system.freeMemory} GB</span>
//               </div>
//               <div class="metric">
//                 <span>Memory Usage:</span>
//                  <span>${Math.round(((healthData.system.totalMemory - healthData.system.freeMemory) / healthData.system.totalMemory) * 100)}%</span>
//               </div>
//             </div>
//           </div>
//           <div style="margin-top: 30px;">
//             <a href="/" class="back-btn">🏠 Back to Home</a>
//             <button class="back-btn" onclick="location.reload()">🔄 Refresh</button>
//           </div>
          
//           <div style="margin-top: 20px; font-size: 0.9em; opacity: 0.8;">
//             Last updated: ${healthData.timestamp}
//           </div>
//         </div>
//         <script>
//           // Auto-refresh every 30 seconds
//           setTimeout(() => {
//             location.reload();
//           }, 30000);
//         </script>
//       </body>
//       </html>
//     `);
//   }
// });


// // Start the server
// app.listen(port, () => {
//   logToCloudWatch(`✅ Server listening on port ${port}`);
//   writeLog(`SERVER_STARTED - Node.js app listening on port ${port} - Hostname: ${HOSTNAME}`, 'STARTUP');
//     console.log(`Server running at http://localhost:${port}`);
// });





const express = require('express');
const os = require('os');
const fs = require('fs');
const path = require('path');
// Load environment variables from .env
require('dotenv').config();

const compression = require('compression');

const { logToCloudWatch } = require('./cloudwatch-logger');

const writeLog = require('./logger'); 
const app = express();

// Enhanced compression configuration
app.use(compression({
  level: 6, // Compression level (0-9)
  threshold: 1024, // Only compress responses larger than 1KB
  filter: (req, res) => {
    // Don't compress if the request includes a cache-busting param
    if (req.headers['x-no-compression']) {
      return false;
    }
    // Use compression for all other responses
    return compression.filter(req, res);
  }
}));

const port = process.env.PORT || 3000;

// Get hostname once at startup
const HOSTNAME = os.hostname();

logToCloudWatch(`🚀 Node.js app started on host ${HOSTNAME}`);

// Track page visits with better memory management
let visitCount = 0;
let uniqueVisitors = new Set();

// Clean up old visitors periodically (prevent memory leaks)
setInterval(() => {
  if (uniqueVisitors.size > 10000) {
    uniqueVisitors.clear();
    writeLog(`[SYSTEM] VISITOR_CACHE_CLEARED - Cleared visitor cache to prevent memory issues`);
  }
}, 3600000); // Every hour

// Enhanced request logging middleware
app.use((req, res, next) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  const userAgent = req.headers['user-agent'] || 'Unknown';
  const method = req.method;
  const url = req.url;
  
  // Add compression info to logs
  const acceptsGzip = req.headers['accept-encoding'] && req.headers['accept-encoding'].includes('gzip');
  
  writeLog(`[ACCESS] ${method} ${url} - IP: ${clientIp} - Gzip: ${acceptsGzip} - User-Agent: ${userAgent.substring(0, 100)}`);
  next();
});

// Enhanced static HTML page with compression indicators
app.get('/', (req, res) => {
  logToCloudWatch(`🏠 [HOME] Visit from ${req.ip}`);

  visitCount++;
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  uniqueVisitors.add(clientIp);
  
  const acceptsGzip = req.headers['accept-encoding'] && req.headers['accept-encoding'].includes('gzip');
  
  writeLog(`[PAGE_VIEW] HOME_PAGE_LOADED - Visit #${visitCount} - Unique visitors: ${uniqueVisitors.size} - IP: ${clientIp} - Gzip: ${acceptsGzip}`);
  
  // Set proper cache headers for better performance
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Live Time - CloudWatch Monitoring</title>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { 
          font-family: Arial, sans-serif; 
          text-align: center; 
          margin: 0;
          padding: 0;
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
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
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
          margin: 10px;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px 0 rgba(76, 175, 80, 0.3);
        }
        .refresh-btn:hover {
          background: #45a049;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px 0 rgba(76, 175, 80, 0.4);
        }
        .log-indicator {
          position: fixed;
          top: 20px;
          right: 20px;
          background: rgba(76, 175, 80, 0.9);
          color: white;
          padding: 10px 20px;
          border-radius: 20px;
          font-size: 0.9em;
          opacity: 0;
          transition: opacity 0.3s ease;
          backdrop-filter: blur(5px);
          z-index: 1000;
        }
        .log-indicator.show {
          opacity: 1;
        }
        .status-indicator {
          position: fixed;
          top: 20px;
          left: 20px;
          background: rgba(76, 175, 80, 0.9);
          color: white;
          padding: 8px 16px;
          border-radius: 15px;
          font-size: 0.8em;
          backdrop-filter: blur(5px);
        }
        .compression-indicator {
          position: fixed;
          bottom: 20px;
          right: 20px;
          background: rgba(33, 150, 243, 0.9);
          color: white;
          padding: 5px 12px;
          border-radius: 12px;
          font-size: 0.7em;
          backdrop-filter: blur(5px);
        }
        .performance-stats {
          margin-top: 20px;
          font-size: 1em;
          opacity: 0.8;
        }
        @media (max-width: 768px) {
          .container {
            margin: 20px;
            padding: 20px;
          }
          #time {
            font-size: 2em;
          }
          .refresh-btn {
            display: block;
            width: 100%;
            margin: 10px 0;
          }
        }
      </style>
    </head>
    <body>
      <div class="status-indicator" id="statusIndicator">
        🟢 LIVE
      </div>
      
      <div class="compression-indicator" id="compressionIndicator">
        📦 Checking compression...
      </div>
      
      <div class="container">
        <h1>⏰ Live GMT Time Monitor</h1>
        <div id="time">Loading...</div>
        <div class="stats">
          <div>Visit Count: <span id="visitCount">${visitCount}</span></div>
          <div>Unique Visitors: <span id="uniqueVisitors">${uniqueVisitors.size}</span></div>
          <div>Server: <span id="hostname">${HOSTNAME}</span></div>
        </div>
        <div class="performance-stats">
          <div>Response Time: <span id="responseTime">--</span>ms</div>
          <div>Last Update: <span id="lastUpdate">--</span></div>
        </div>
        <button class="refresh-btn" onclick="manualRefresh()">🔄 Manual Refresh</button>
        <button class="refresh-btn" onclick="viewLogs()">📊 View Logs</button>
        <button class="refresh-btn" onclick="viewHealth()">❤️ Health Check</button>
        <button class="refresh-btn" onclick="testCompression()">🗜️ Test Compression</button>
      </div>
      
      <div id="logIndicator" class="log-indicator">
        Log sent to CloudWatch! 📊
      </div>

      <script>
        let refreshCount = 0;
        let isOnline = true;
        
        // Check if response was compressed
        function checkCompression() {
          fetch('/compression-test')
            .then(response => {
              const compressionHeader = response.headers.get('content-encoding');
              const isCompressed = compressionHeader && compressionHeader.includes('gzip');
              const indicator = document.getElementById('compressionIndicator');
              
              if (isCompressed) {
                indicator.innerHTML = '🗜️ GZIP ON';
                indicator.style.background = 'rgba(76, 175, 80, 0.9)';
              } else {
                indicator.innerHTML = '📦 NO GZIP';
                indicator.style.background = 'rgba(255, 152, 0, 0.9)';
              }
            })
            .catch(() => {
              document.getElementById('compressionIndicator').innerHTML = '❌ ERROR';
            });
        }
        
        // async function updateTime() {
        //   const startTime = performance.now();
          
        //   try {
        //     const res = await fetch('/time');
        //     if (!res.ok) throw new Error('HTTP ' + res.status);
            
        //     const endTime = performance.now();
        //     const responseTime = Math.round(endTime - startTime);
            
        //     const data = await res.json();
        //     document.getElementById('time').innerText = data.time;
        //     document.getElementById('visitCount').innerText = data.visitCount;
        //     document.getElementById('uniqueVisitors').innerText = data.uniqueVisitors || 0;
        //     document.getElementById('responseTime').innerText = responseTime;
        //     document.getElementById('lastUpdate').innerText = new Date().toLocaleTimeString();
            
        //     // Update status indicator
        //     const statusEl = document.getElementById('statusIndicator');
        //     statusEl.innerHTML = '🟢 LIVE';
        //     statusEl.style.background = 'rgba(76, 175, 80, 0.9)';
            
        //     if (!isOnline) {
        //       isOnline = true;
        //       showLogIndicator('🟢 Connection restored!');
        //     }
            
        //     showLogIndicator();
        //   } catch (error) {
        //     console.error('Error fetching time:', error);
        //     document.getElementById('time').innerText = 'Error loading time';
        //     document.getElementById('responseTime').innerText = '--';
            
        //     // Update status indicator
        //     const statusEl = document.getElementById('statusIndicator');
        //     statusEl.innerHTML = '🔴 OFFLINE';
        //     statusEl.style.background = 'rgba(244, 67, 54, 0.9)';
            
        //     if (isOnline) {
        //       isOnline = false;
        //       showLogIndicator('🔴 Connection lost!', 5000);
        //     }
        //   }
        // }

        
        const ws = new WebSocket("ws://" + location.host);

        ws.onmessage = function (event) {
          try {
            const data = JSON.parse(event.data);
            document.getElementById('time').innerText =  \`\${data.time}\`;
            document.getElementById('visitCount').innerText = data.visitCount;
            document.getElementById('uniqueVisitors').innerText = data.uniqueVisitors;
            document.getElementById('lastUpdate').innerText = new Date().toLocaleTimeString();
          } catch (err) {
            console.error('Failed to parse WebSocket message:', err);
          }
        };

ws.onopen = function () {
  console.log('WebSocket connected');
};

ws.onclose = function () {
  console.warn('WebSocket disconnected');
  const statusEl = document.getElementById('statusIndicator');
  if (statusEl) {
    statusEl.innerText = '🔴 DISCONNECTED';
    statusEl.style.background = 'rgba(244, 67, 54, 0.9)';
  }
};

        

                
        async function manualRefresh() {
          refreshCount++;
          try {
            await fetch('/manual-refresh', { method: 'POST' });
            showLogIndicator('🔄 Manual refresh logged!');
          } catch (error) {
            console.error('Manual refresh error:', error);
            showLogIndicator('❌ Refresh failed!', 3000);
          }
          await updateTime();
        }
        
        function viewLogs() {
          window.open('/logs', '_blank');
        }
        
        function viewHealth() {
          window.open('/health', '_blank');
        }
        
        function testCompression() {
          window.open('/compression-test', '_blank');
        }
        
        function showLogIndicator(message = 'Log sent to CloudWatch! 📊', duration = 2000) {
          const indicator = document.getElementById('logIndicator');
          indicator.innerText = message;
          indicator.classList.add('show');
          setTimeout(() => {
            indicator.classList.remove('show');
          }, duration);
        }
        
        // Initial calls
        window.addEventListener('load', () => {
          updateTime();
          checkCompression();
          setInterval(updateTime, 1000);
        });
        
        // Log page visibility changes
        document.addEventListener('visibilitychange', () => {
          if (!document.hidden) {
            fetch('/page-focus', { method: 'POST' }).catch(console.error);
          }
        });
        
        // Handle connection errors gracefully
        window.addEventListener('online', () => {
          showLogIndicator('🟢 Back online!', 3000);
        });
        
        window.addEventListener('offline', () => {
          showLogIndicator('🔴 Gone offline!', 3000);
        });
      </script>
    </body>
    </html>
  `);
});

// API endpoint to return time data with compression headers
app.get('/time', (req, res) => {
  logToCloudWatch(`⏱️ [TIME] Requested by ${req.ip}`);

  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = days[now.getDay()];
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  const timeString = `${dayOfWeek} ${hours}:${minutes}:${seconds}`;
  
  // Log the time request (reduced frequency to avoid log spam)
  if (seconds % 10 === 0) { // Log only every 10 seconds
    const acceptsGzip = req.headers['accept-encoding'] && req.headers['accept-encoding'].includes('gzip');
    writeLog(`[TIME_API] TIME_REQUEST - Time: ${timeString} - IP: ${clientIp} - Gzip: ${acceptsGzip}`);
  }
  
  // Set JSON response headers for better compression
  res.set({
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache'
  });
  
  res.json({
    time: `🟢 ${timeString} - Server: ${HOSTNAME}`,
    visitCount: visitCount,
    uniqueVisitors: uniqueVisitors.size,
    hostname: HOSTNAME,
    timestamp: now.toISOString(),
    compressed: req.headers['accept-encoding'] && req.headers['accept-encoding'].includes('gzip')
  });
});

// New endpoint to test compression
app.get('/compression-test', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  const acceptsGzip = req.headers['accept-encoding'] && req.headers['accept-encoding'].includes('gzip');
  
  writeLog(`[COMPRESSION] TEST_REQUEST - IP: ${clientIp} - Accepts Gzip: ${acceptsGzip}`);
  
  // Create a large JSON response to trigger compression
  const testData = {
    message: 'This is a compression test endpoint',
    timestamp: new Date().toISOString(),
    clientSupportsGzip: acceptsGzip,
    largeData: Array(1000).fill().map((_, i) => ({
      id: i,
      data: `This is test data item ${i} with some repeated content to make it compressible. `.repeat(5)
    })),
    compressionInfo: {
      threshold: '1024 bytes',
      level: 6,
      algorithm: 'gzip'
    }
  };
  
  // Set headers for JSON response
  res.set({
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache'
  });
  
  if (req.headers.accept && req.headers.accept.includes('text/html')) {
    // Return HTML view for browser
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Compression Test</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
          .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .status { padding: 15px; border-radius: 5px; margin: 10px 0; }
          .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
          .warning { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
          .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
          pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🗜️ Compression Test Results</h1>
          
          <div class="status ${acceptsGzip ? 'success' : 'warning'}">
            <strong>Client Gzip Support:</strong> ${acceptsGzip ? '✅ Yes' : '❌ No'}
          </div>
          
          <div class="status info">
            <strong>Response Size:</strong> ~${JSON.stringify(testData).length} bytes<br>
            <strong>Compression Threshold:</strong> 1024 bytes<br>
            <strong>Should be compressed:</strong> ${JSON.stringify(testData).length > 1024 ? '✅ Yes' : '❌ No'}
          </div>
          
          <h3>Test Data Sample:</h3>
          <pre>${JSON.stringify(testData, null, 2).substring(0, 500)}...</pre>
          
          <p><a href="/">← Back to Home</a></p>
        </div>
        
        <script>
          // Check if this response was actually compressed
          console.log('Response headers:', Object.fromEntries([...document.querySelectorAll('meta[name]')].map(m => [m.name, m.content])));
        </script>
      </body>
      </html>
    `);
  } else {
    // Return JSON for API calls
    res.json(testData);
  }
});

// Manual refresh endpoint
app.post('/manual-refresh', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  writeLog(`[USER_ACTION] MANUAL_REFRESH - User clicked refresh button - IP: ${clientIp}`);
  
  res.json({ status: 'refresh logged', timestamp: new Date().toISOString() });
});

// Page focus endpoint
app.post('/page-focus', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  writeLog(`[USER_ACTION] PAGE_FOCUS - User returned to page - IP: ${clientIp}`);
  
  res.json({ status: 'focus logged', timestamp: new Date().toISOString() });
});

// Enhanced logs viewer endpoint
app.get('/logs', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  writeLog(`[ADMIN] LOGS_VIEWED - User accessed logs page - IP: ${clientIp}`);
  
  // Get current log file path (same as logger.js)
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const year = now.getFullYear();
  const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${HOSTNAME}`;
  const logFile = path.join(logDir, 'node-app.log');
  
  // Read recent log entries
  fs.readFile(logFile, 'utf8', (err, data) => {
    if (err) {
      writeLog(`[ERROR] LOG_READ_ERROR - ${err.message}`);
      return res.status(500).send('Error reading logs');
    }
    
    const lines = data.split('\n').filter(line => line.trim()).slice(-100); // Last 100 lines
    
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Application Logs - ${HOSTNAME}</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            font-family: 'Courier New', monospace; 
            margin: 0; 
            padding: 0;
            background: #1e1e1e; 
            color: #fff; 
            font-size: 14px;
          }
          .log-entry { 
            margin: 2px 0; 
            padding: 8px 12px; 
            border-left: 3px solid #4CAF50; 
            background: rgba(255,255,255,0.02);
            word-wrap: break-word;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.4;
          }
          .log-entry.ERROR { border-left-color: #f44336; background: rgba(244, 67, 54, 0.1); }
          .log-entry.WARN { border-left-color: #ff9800; background: rgba(255, 152, 0, 0.1); }
          .log-entry.ACCESS { border-left-color: #2196F3; background: rgba(33, 150, 243, 0.05); }
          .log-entry.USER_ACTION { border-left-color: #9c27b0; background: rgba(156, 39, 176, 0.1); }
          .log-entry.STARTUP { border-left-color: #00bcd4; background: rgba(0, 188, 212, 0.1); }
          .log-entry.SYSTEM { border-left-color: #ff5722; background: rgba(255, 87, 34, 0.1); }
          .log-entry.HEALTH { border-left-color: #8bc34a; background: rgba(139, 195, 74, 0.1); }
          .log-entry.TIME_API { border-left-color: #607d8b; background: rgba(96, 125, 139, 0.05); }
          .log-entry.PAGE_VIEW { border-left-color: #e91e63; background: rgba(233, 30, 99, 0.1); }
          .log-entry.ADMIN { border-left-color: #795548; background: rgba(121, 85, 72, 0.1); }
          .log-entry.COMPRESSION { border-left-color: #3f51b5; background: rgba(63, 81, 181, 0.1); }
          .header { 
            background: #333; 
            padding: 20px; 
            margin: 0;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 10px rgba(0,0,0,0.5);
          }
          .refresh-btn { 
            background: #4CAF50; 
            color: white; 
            border: none; 
            padding: 10px 20px; 
            border-radius: 5px; 
            cursor: pointer; 
            margin-right: 10px; 
            margin-bottom: 10px;
            transition: background 0.3s;
          }
          .refresh-btn:hover { background: #45a049; }
          .refresh-btn.danger { background: #f44336; }
          .refresh-btn.danger:hover { background: #da190b; }
          .hostname-badge { 
            background: #2196F3; 
            padding: 5px 15px; 
            border-radius: 15px; 
            font-size: 0.9em; 
            margin-left: 10px;
          }
          .log-container {
            padding: 20px;
            max-height: calc(100vh - 160px);
            overflow-y: auto;
          }
          .stats {
            background: #444;
            padding: 10px 20px;
            margin: 0;
            font-size: 14px;
            color: #ccc;
          }
          @media (max-width: 768px) {
            .header { padding: 15px; }
            .log-entry { font-size: 12px; padding: 6px 8px; }
            .refresh-btn { padding: 8px 15px; font-size: 14px; }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>📊 Application Logs <span class="hostname-badge">${HOSTNAME}</span></h1>
          <div class="stats">
            Last ${lines.length} entries • Auto-refresh: 10s • Total size: ${(data.length / 1024).toFixed(1)}KB
          </div>
          <div style="margin-top: 15px;">
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh Now</button>
            <button class="refresh-btn" onclick="window.close()">❌ Close</button>
            <button class="refresh-btn danger" onclick="clearLogs()">🗑️ Clear Logs</button>
          </div>
        </div>
        <div class="log-container">
          ${lines.map(line => {
            const levelMatch = line.match(/\\[(.*?)\\]/);
            const level = levelMatch ? levelMatch[1] : 'INFO';
            const timestamp = line.match(/^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z)/)?.[1] || '';
            return '<div class="log-entry ' + level + '" title="' + timestamp + '">' + line + '</div>';
          }).join('')}
        </div>
        <script>
          let autoRefresh = true;
          
          function clearLogs() {
            if (confirm('Are you sure you want to clear all logs? This action cannot be undone.')) {
              fetch('/clear-logs', { method: 'POST' })
                .then(() => location.reload())
                .catch(err => alert('Failed to clear logs: ' + err.message));
            }
          }
          
          // Auto-refresh logs every 10 seconds
          function scheduleRefresh() {
            if (autoRefresh && !document.hidden) {
              setTimeout(() => {
                location.reload();
              }, 10000);
            }
          }
          
          // Pause auto-refresh when tab is hidden
          document.addEventListener('visibilitychange', () => {
            if (!document.hidden) {
              scheduleRefresh();
            }
          });
          
          // Auto-scroll to bottom
          window.addEventListener('load', () => {
            window.scrollTo(0, document.body.scrollHeight);
            scheduleRefresh();
          });
        </script>
      </body>
      </html>
    `);
  });
});

// Clear logs endpoint
app.post('/clear-logs', (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  writeLog(`[ADMIN] LOGS_CLEARED - User cleared logs - IP: ${clientIp}`);
  
  // Get current log file path (same as logger.js)
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const year = now.getFullYear();
  const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${HOSTNAME}`;
  const logFile = path.join(logDir, 'node-app.log');
  
  // Clear the log file
  fs.writeFile(logFile, '', (err) => {
    if (err) {
      writeLog(`[ERROR] LOG_CLEAR_ERROR - ${err.message}`);
      return res.status(500).json({ error: 'Failed to clear logs' });
    }
    
    writeLog(`[SYSTEM] LOG_FILE_CLEARED - Log file cleared by user - IP: ${clientIp}`);
    res.json({ status: 'logs cleared', timestamp: new Date().toISOString() });
  });
});

// Health check endpoint

// Enhanced health check
app.get('/health', (req, res) => {
  logToCloudWatch(`💓 [HEALTH] Check from ${req.ip}`);

  const uptime = process.uptime();
  const memUsage = process.memoryUsage();
  const loadAvg = os.loadavg();
  const clientIp = req.headers['x-forwarded-for'] || 
                   req.headers['x-real-ip'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress || 
                   'unknown';
  
  // Only log health checks every 5 minutes to avoid spam
  const now = Date.now();
  if (!app.lastHealthLog || now - app.lastHealthLog > 300000) {
    writeLog(`[HEALTH] HEALTH_CHECK - Uptime: ${Math.floor(uptime)}s - Memory: ${Math.round(memUsage.rss / 1024 / 1024)}MB - Load: ${loadAvg[0].toFixed(2)} - IP: ${clientIp}`);
    app.lastHealthLog = now;
  }
  
  const healthData = {
    status: 'OK',
    uptime: Math.floor(uptime),
    memory: {
      rss: Math.round(memUsage.rss / 1024 / 1024),
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
      external: Math.round(memUsage.external / 1024 / 1024)
    },
    system: {
      loadAverage: loadAvg,
      totalMemory: Math.round(os.totalmem() / 1024 / 1024 / 1024),
      freeMemory: Math.round(os.freemem() / 1024 / 1024 / 1024),
      cpuCount: os.cpus().length
    },
    application: {
      visitCount: visitCount,
      uniqueVisitors: uniqueVisitors.size,
      nodeVersion: process.version,
      platform: os.platform(),
      arch: os.arch()
    },
    hostname: HOSTNAME,
    timestamp: new Date().toISOString()
  };
  
  // Return JSON for API calls, HTML for browser
  if (req.headers.accept && req.headers.accept.includes('application/json')) {
    res.status(200).json(healthData);
  } else {
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Health Check - ${HOSTNAME}</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 20px;
            min-height: 100vh;
          }
          .health-container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
          }
          .health-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 20px;
          }
          .health-card {
            background: rgba(255,255,255,0.05);
            padding: 20px;
            border-radius: 15px;
            border: 1px solid rgba(255,255,255,0.1);
          }
          .health-card h3 {
            margin-top: 0;
            color: #4CAF50;
          }
          .metric {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
          }
          .metric:last-child {
            border-bottom: none;
          }
          .status-ok {
            color: #4CAF50;
            font-weight: bold;
            font-size: 1.2em;
          }
          .back-btn {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 1.1em;
            border-radius: 25px;
            cursor: pointer;
            margin: 20px 10px 0 0;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
          }
          .back-btn:hover {
            background: #45a049;
            transform: translateY(-2px);
          }
        </style>
      </head>
      <body>
        <div class="health-container">
          <h1>🏥 System Health Check</h1>
          <div class="status-ok">✅ System Status: ${healthData.status}</div>
          <div class="health-grid">
            <div class="health-card">
              <h3>🖥️ System Info</h3>
              <div class="metric">
                <span>Hostname:</span>
                <span>${healthData.hostname}</span>
              </div>
              <div class="metric">
                <span>Platform:</span>
                <span>${healthData.application.platform}</span>
              </div>
              <div class="metric">
                <span>Architecture:</span>
                <span>${healthData.application.arch}</span>
              </div>
              <div class="metric">
                <span>Node Version:</span>
                <span>${healthData.application.nodeVersion}</span>
              </div>
              <div class="metric">
                <span>CPU Cores:</span>
                <span>${healthData.system.cpuCount}</span>
              </div>
            </div>
            
            <div class="health-card">
              <h3>⏱️ Runtime</h3>
              <div class="metric">
                <span>Uptime:</span>
                <span>${Math.floor(healthData.uptime / 3600)}h ${Math.floor((healthData.uptime % 3600) / 60)}m ${healthData.uptime % 60}s</span>
              </div>
              <div class="metric">
                <span>Total Visits:</span>
                <span>${healthData.application.visitCount}</span>
              </div>
              <div class="metric">
                <span>Unique Visitors:</span>
                <span>${healthData.application.uniqueVisitors}</span>
              </div>
            </div>
            
            <div class="health-card">
              <h3>💾 Memory Usage</h3>
              <div class="metric">
                <span>RSS:</span>
                <span>${healthData.memory.rss} MB</span>
              </div>
              <div class="metric">
                <span>Heap Used:</span>
                <span>${healthData.memory.heapUsed} MB</span>
              </div>
              <div class="metric">
                <span>Heap Total:</span>
                <span>${healthData.memory.heapTotal} MB</span>
              </div>
              <div class="metric">
                <span>External:</span>
                <span>${healthData.memory.external} MB</span>
              </div>
            </div>
            
            <div class="health-card">
              <h3>🖲️ System Resources</h3>
              <div class="metric">
                <span>Load Average:</span>
                <span>${healthData.system.loadAverage[0].toFixed(2)}</span>
              </div>
              <div class="metric">
                <span>Total Memory:</span>
                <span>${healthData.system.totalMemory} GB</span>
              </div>
              <div class="metric">
                <span>Free Memory:</span>
                <span>${healthData.system.freeMemory} GB</span>
              </div>
              <div class="metric">
                <span>Memory Usage:</span>
                 <span>${Math.round(((healthData.system.totalMemory - healthData.system.freeMemory) / healthData.system.totalMemory) * 100)}%</span>
              </div>
            </div>
          </div>
          <div style="margin-top: 30px;">
            <a href="/" class="back-btn">🏠 Back to Home</a>
            <button class="back-btn" onclick="location.reload()">🔄 Refresh</button>
          </div>
          
          <div style="margin-top: 20px; font-size: 0.9em; opacity: 0.8;">
            Last updated: ${healthData.timestamp}
          </div>
        </div>
        <script>
          // Auto-refresh every 30 seconds
          setTimeout(() => {
            location.reload();
          }, 30000);
        </script>
      </body>
      </html>
    `);
  }
});


// // Start the server
// app.listen(port, () => {
//   logToCloudWatch(`✅ Server listening on port ${port}`);
//   writeLog(`SERVER_STARTED - Node.js app listening on port ${port} - Hostname: ${HOSTNAME}`, 'STARTUP');
//     console.log(`Server running at http://localhost:${port}`);
// });



const http = require('http');
const WebSocket = require('ws');

// Create HTTP server from Express app
const server = http.createServer(app);

// Attach WebSocket server to HTTP server
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
  const ip = req.socket.remoteAddress;

  const sendTime = () => {
    const now = new Date();
    const timeString = now.toISOString();
    ws.send(JSON.stringify({
      time: timeString,
      visitCount,
      uniqueVisitors: uniqueVisitors.size,
      hostname: HOSTNAME
    }));
  };

  const interval = setInterval(sendTime, 1000);

  ws.on('close', () => {
    clearInterval(interval);
  });

  writeLog(`[WEBSOCKET] Client connected - IP: ${ip}`);
});

server.listen(port, () => {
  logToCloudWatch(`✅ Server (WS-enabled) listening on port ${port}`);
  writeLog(`SERVER_STARTED - WS-enabled server listening on port ${port} - Hostname: ${HOSTNAME}`, 'STARTUP');
  console.log(`Server running at http://localhost:${port}`);
});
