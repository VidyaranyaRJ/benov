// Add this to your app.js file - Log Rotation System
const fs = require('fs');
const path = require('path');
const os = require('os');

// Log rotation configuration
const LOG_DIR = process.env.LOG_DIR || '/mnt/efs/logs';
const HOSTNAME = process.env.HOSTNAME || os.hostname();

// Global log file path - will be updated daily
let currentLogFile = null;
let currentLogStream = null;

// Function to get today's log file path
function getTodayLogFile() {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    return path.join(LOG_DIR, `${today}-${HOSTNAME}-app.log`);
}

// Function to ensure log directory exists
function ensureLogDirectory() {
    if (!fs.existsSync(LOG_DIR)) {
        fs.mkdirSync(LOG_DIR, { recursive: true, mode: 0o755 });
        console.log(`✅ Created log directory: ${LOG_DIR}`);
    }
}

// Function to rotate log file if date has changed
function rotateLogFileIfNeeded() {
    const todayLogFile = getTodayLogFile();
    
    if (currentLogFile !== todayLogFile) {
        // Close current log stream if it exists
        if (currentLogStream && currentLogStream !== process.stdout) {
            currentLogStream.end();
            console.log(`📝 Closed previous log file: ${currentLogFile}`);
        }
        
        // Update to new log file
        currentLogFile = todayLogFile;
        
        // Create new log stream
        currentLogStream = fs.createWriteStream(currentLogFile, { 
            flags: 'a',  // append mode
            encoding: 'utf8'
        });
        
        console.log(`📝 Rotated to new log file: ${currentLogFile}`);
        
        // Write rotation marker
        writeLog(`=== Log rotation at ${new Date().toISOString()} ===`);
    }
}

// Enhanced logging function
function writeLog(message, level = 'INFO') {
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const logEntry = `${timestamp} [${level}] ${message}\n`;
    
    // Ensure log rotation
    rotateLogFileIfNeeded();
    
    // Write to current log file
    if (currentLogStream) {
        currentLogStream.write(logEntry);
    }
    
    // Also write to console for PM2 logs
    console.log(`${timestamp} [${level}] ${message}`);
}

// Initialize logging system
function initializeLogging() {
    ensureLogDirectory();
    rotateLogFileIfNeeded();
    
    // Set up daily rotation check (every hour)
    setInterval(() => {
        rotateLogFileIfNeeded();
    }, 60 * 60 * 1000); // Check every hour
    
    console.log(`✅ Logging system initialized`);
    console.log(`📁 Log directory: ${LOG_DIR}`);
    console.log(`🏷️  Hostname: ${HOSTNAME}`);
    console.log(`📝 Current log file: ${currentLogFile}`);
}

// Override console methods to use our logging system
const originalConsoleLog = console.log;
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

console.log = (...args) => {
    const message = args.join(' ');
    writeLog(message, 'INFO');
};

console.error = (...args) => {
    const message = args.join(' ');
    writeLog(message, 'ERROR');
    originalConsoleError(...args); // Still output to stderr for PM2
};

console.warn = (...args) => {
    const message = args.join(' ');
    writeLog(message, 'WARN');
    originalConsoleWarn(...args); // Still output to stderr for PM2
};

// Initialize the logging system when this module is loaded
initializeLogging();

// Export the logging functions for use in other modules
module.exports = {
    writeLog,
    rotateLogFileIfNeeded,
    getCurrentLogFile: () => currentLogFile,
    getLogDirectory: () => LOG_DIR
};

// Graceful shutdown - close log stream
process.on('SIGTERM', () => {
    writeLog('Application received SIGTERM, shutting down gracefully');
    if (currentLogStream && currentLogStream !== process.stdout) {
        currentLogStream.end();
    }
    process.exit(0);
});

process.on('SIGINT', () => {
    writeLog('Application received SIGINT, shutting down gracefully');
    if (currentLogStream && currentLogStream !== process.stdout) {
        currentLogStream.end();
    }
    process.exit(0);
});