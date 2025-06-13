const express = require('express');
const os = require('os');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const LOG_PATH = process.env.LOG_PATH || '/mnt/efs/logs';
const LOG_FILE = path.join(LOG_PATH, 'node-app.log');

// Ensure log directory exists
if (!fs.existsSync(LOG_PATH)) {
  fs.mkdirSync(LOG_PATH, { recursive: true });
}

// Log function
function logToFileAndConsole(message) {
  const timestamp = new Date().toISOString();
  const logLine = `[${timestamp}] ${message}\n`;
  // Log to file
  fs.appendFile(LOG_FILE, logLine, (err) => {
    if (err) console.error('Failed to write to log file:', err);
  });
  // Log to console (for CloudWatch)
  console.log(logLine.trim());
}

// Serve the static HTML page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Live Time</title>
      <style>
        body { font-family: Arial; text-align: center; margin-top: 50px; }
        #time { font-size: 2em; margin-top: 20px; }
      </style>
    </head>
    <body>
      <h1>⏰ Time</h1>
      <div id="time">Loading...</div>

      <script>
        async function updateTime() {
          const res = await fetch('/time');
          const text = await res.text();
          document.getElementById('time').innerText = text;
        }

        updateTime(); // initial call
        setInterval(updateTime, 1000); // every second
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
  const hostname = os.hostname();

  const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
  const userAgent = req.headers['user-agent'];

  const logMessage = `Page Refresh: Instance: ${hostname} - Time: ${dayOfWeek} ${hours}:${minutes}:${seconds} - IP: ${clientIp} - User-Agent: ${userAgent}`;
  logToFileAndConsole(logMessage);

  res.send(`🟢Hi  ${dayOfWeek} ${hours}:${minutes}:${seconds} - Server: ${hostname}`);
});

// Optional health check
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Start the server
app.listen(port, () => {
  logToFileAndConsole(`Server running at http://localhost:${port}`);
});
