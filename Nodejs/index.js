const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  // Get current date and time
  const now = new Date();
  
  // Format the time as HH:MM:SS
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  const timeString = `${hours}:${minutes}:${seconds}`;
  
  // Get day of the week
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = days[now.getDay()];
  
  // Get server hostname to identify different instances
  const os = require('os');
  const hostname = os.hostname();
  
  // Send response with current timestamp and hostname
  res.send(`Hello, World! - VJ all 5 instances ${dayOfWeek} ${timeString} - Server: ${hostname}`);
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});