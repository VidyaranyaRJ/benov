const fs = require('fs');
const path = require('path');
const os = require('os');

const hostname = os.hostname(); // e.g., ip-10-0-1-23

function writeLog(message) {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const year = now.getFullYear();

  const logDir = `/mnt/efs/logs/${month}-${day}-${year}/${hostname}`;
  const logFile = path.join(logDir, 'node-app.log');

  // Ensure log directory exists
  fs.mkdirSync(logDir, { recursive: true });

  const timestamp = now.toISOString();
  const fullMessage = `${timestamp} - ${message}\n`;

  fs.appendFileSync(logFile, fullMessage);
}

module.exports = writeLog;
