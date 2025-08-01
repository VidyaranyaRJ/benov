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







// js/logger.js
const fs = require('fs');
const os = require('os');
const path = require('path');

const logger = (req, ...messages) => {
  // Get ISO timestamp with timezone offset
  const date = new Date();
  const tzOffsetMin = date.getTimezoneOffset(); // minutes
  const absOffset = Math.abs(tzOffsetMin);
  const offsetHours = String(Math.floor(absOffset / 60)).padStart(2, '0');
  const offsetMinutes = String(absOffset % 60).padStart(2, '0');
  const offsetSign = tzOffsetMin > 0 ? '-' : '+';
  const isoWithOffset = date.toISOString().replace('Z', `${offsetSign}${offsetHours}:${offsetMinutes}`);

  const host = os.hostname();
  const userId = req?.session?.user_id || 'NA';

  const line = `${isoWithOffset} ${userId} ${host} | ${messages.join(' ')}`;

  console.log(line);

  // Optional: also write to EFS log file
  try {
    const logDir = '/mnt/efs/logs';
    const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD
    const logFile = `${dateStr}-${host}-app.log`;
    const fullPath = path.join(logDir, logFile);

    fs.appendFileSync(fullPath, line + '\n', 'utf8');
  } catch (err) {
    console.error(`❌ Failed to write to log file: ${err.message}`);
  }
};

module.exports = logger;
