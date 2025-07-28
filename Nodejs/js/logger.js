// js/logger.js

// This wraps console.log to inject org/user info for API access logs
const logger = (req, ...messages) => {
    const timestamp = new Date().toLocaleString('en-US', {
        hour12: true,
        month: '2-digit',
        day: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });

    const org = req?.session?.user?.org_id || 'NA';
    const user = req?.session?.user_id || 'NA';
    
    console.log(`[REQ] ${timestamp} | ${org} | ${user} | ${messages.join(' ')}`);
};

module.exports = logger;
