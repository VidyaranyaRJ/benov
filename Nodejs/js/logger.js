// js/logger.js
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

    if (req?.session?.isAuthenticated) {
        console.log(`${timestamp} | ${req.session.user?.org_id} | ${req.session.user_id} | ${messages.join(' ')}`);
    } else {
        console.log(`${timestamp} | NA | NA | ${messages.join(' ')}`);
    }
};

module.exports = logger;