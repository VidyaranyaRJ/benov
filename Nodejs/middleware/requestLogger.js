module.exports = function requestLogger(req, res, next) {
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  const userAgent = req.headers['user-agent'] || 'Unknown';
  const method = req.method;
  const url = req.url;

  const logEntry = `[ACCESS] ${method} ${url} - IP: ${clientIp} - User-Agent: ${userAgent}`;
  writeLog(logEntry);
  logToCloudWatch(logEntry);
  next();
};