
const logger = (req, ...messages) => {
    if (req.session.isAuthenticated ) {
        console.log(`${new Date().toLocaleString('en-US', { hour12: true, month: '2-digit', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })} | ${req.session.user.org_id} | ${req.session.user_id} | ${messages.join(' ')}`);
    }
    else {
        console.log(`${new Date().toLocaleString('en-US', { hour12: true, month: '2-digit', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })} | NA | NA | ${messages.join(' ')}`);
    }
};


exports = logger;