// // js/logger.js
// const logger = (req, ...messages) => {
//     const timestamp = new Date().toLocaleString('en-US', {
//         hour12: true,
//         month: '2-digit',
//         day: '2-digit',
//         year: 'numeric',
//         hour: '2-digit',
//         minute: '2-digit',
//         second: '2-digit'
//     });

//     if (req?.session?.isAuthenticated) {
//         console.log(`${timestamp} | ${req.session.user?.org_id} | ${req.session.user_id} | ${messages.join(' ')}`);
//     } else {
//         console.log(`${timestamp} | NA | NA | ${messages.join(' ')}`);
//     }
// };

// module.exports = logger;







// // js/logger.js
// const fs = require('fs');
// const os = require('os');
// const path = require('path');

// const logger = (req, ...messages) => {
//   // Get ISO timestamp with timezone offset
//   const date = new Date();
//   const tzOffsetMin = date.getTimezoneOffset(); // minutes
//   const absOffset = Math.abs(tzOffsetMin);
//   const offsetHours = String(Math.floor(absOffset / 60)).padStart(2, '0');
//   const offsetMinutes = String(absOffset % 60).padStart(2, '0');
//   const offsetSign = tzOffsetMin > 0 ? '-' : '+';
//   const isoWithOffset = date.toISOString().replace('Z', `${offsetSign}${offsetHours}:${offsetMinutes}`);

//   const host = os.hostname();
//   const userId = req?.session?.user_id || 'NA';

//   const line = `${isoWithOffset} ${userId} ${host} | ${messages.join(' ')}`;

//   console.log(line);

//   // Optional: also write to EFS log file
//   try {
//     const logDir = '/mnt/efs/logs';
//     const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
//     const logFile = `${dateStr}-${host}-app.log`;
//     const fullPath = path.join(logDir, logFile);

//     fs.appendFileSync(fullPath, line + '\n', 'utf8');
//   } catch (err) {
//     console.error(`❌ Failed to write to log file: ${err.message}`);
//   }
// };

// module.exports = logger;







// // js/logger.js
// const fs = require('fs');
// const os = require('os');
// const path = require('path');

// // Cache the log file path based on app start time, not current time
// let cachedLogFile = null;

// const getLogFile = () => {
//   if (!cachedLogFile) {
//     const date = new Date();
//     const host = os.hostname();
//     const logDir = '/mnt/efs/logs';
//     const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
//     const logFile = `${dateStr}-${host}-app.log`;
//     cachedLogFile = path.join(logDir, logFile);
    
//     // Log the initial setup
//     console.log(`📝 Logger initialized with log file: ${cachedLogFile}`);
//   }
//   return cachedLogFile;
// };

// // Function to rotate log file (called by external process or cron)
// const rotateLogFile = () => {
//   const date = new Date();
//   const host = os.hostname();
//   const logDir = '/mnt/efs/logs';
//   const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
//   const logFile = `${dateStr}-${host}-app.log`;
//   cachedLogFile = path.join(logDir, logFile);
  
//   console.log(`🔄 Log file rotated to: ${cachedLogFile}`);
//   return cachedLogFile;
// };

// const logger = (req, ...messages) => {
//   // Get ISO timestamp with timezone offset
//   const date = new Date();
//   const tzOffsetMin = date.getTimezoneOffset(); // minutes
//   const absOffset = Math.abs(tzOffsetMin);
//   const offsetHours = String(Math.floor(absOffset / 60)).padStart(2, '0');
//   const offsetMinutes = String(absOffset % 60).padStart(2, '0');
//   const offsetSign = tzOffsetMin > 0 ? '-' : '+';
//   const isoWithOffset = date.toISOString().replace('Z', `${offsetSign}${offsetHours}:${offsetMinutes}`);

//   const host = os.hostname();
//   const userId = req?.session?.user_id || 'NA';

//   const line = `${isoWithOffset} ${userId} ${host} | ${messages.join(' ')}`;

//   console.log(line);

//   // Write to consistent log file (rotated externally)
//   try {
//     const fullPath = getLogFile();
//     fs.appendFileSync(fullPath, line + '\n', 'utf8');
//   } catch (err) {
//     console.error(`❌ Failed to write to log file: ${err.message}`);
//   }
// };

// // Export both logger and rotate function
// module.exports = {
//   logger,
//   rotateLogFile
// };

// // For backward compatibility
// module.exports.default = logger;




const fs = require('fs');
const os = require('os');
const path = require('path');

// Cache the log file path based on app start time
let cachedLogFile = null;

const getLogFile = () => {
  if (!cachedLogFile) {
    const date = new Date();
    const host = os.hostname();
    const logDir = '/mnt/efs/logs';
    const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
    const logFile = `${dateStr}-${host}-app.log`;
    cachedLogFile = path.join(logDir, logFile);
    // 🔇 Removed console.log to keep stdout clean
  }
  return cachedLogFile;
};

// Optional rotation logic
const rotateLogFile = () => {
  const date = new Date();
  const host = os.hostname();
  const logDir = '/mnt/efs/logs';
  const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
  const logFile = `${dateStr}-${host}-app.log`;
  cachedLogFile = path.join(logDir, logFile);
  return cachedLogFile;
};

const logger = (req, ...messages) => {
  // Format timestamp: ISO string with offset
  const date = new Date();
  const tzOffsetMin = date.getTimezoneOffset(); // minutes
  const absOffset = Math.abs(tzOffsetMin);
  const offsetHours = String(Math.floor(absOffset / 60)).padStart(2, '0');
  const offsetMinutes = String(absOffset % 60).padStart(2, '0');
  const offsetSign = tzOffsetMin > 0 ? '-' : '+';
  const isoWithOffset = date.toISOString().replace('Z', `${offsetSign}${offsetHours}:${offsetMinutes}`);

  const host = os.hostname();
  const orgId = req?.session?.user?.org_id || 'NA';
  const userId = req?.session?.user_id || 'NA';

  const line = `${isoWithOffset} | ${orgId} | ${userId} | ${host} | ${messages.join(' ')}`;

  // Log to stdout
  console.log(line);

  // Append to file
  try {
    const fullPath = getLogFile();
    fs.appendFileSync(fullPath, line + '\n', 'utf8');
  } catch (err) {
    console.error(`❌ Failed to write to log file: ${err.message}`);
  }
};

// Export both
module.exports = {
  logger,
  rotateLogFile
};
module.exports.default = logger;
