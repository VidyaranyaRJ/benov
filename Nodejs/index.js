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
  
  // Send response with current timestamp
  res.send(`Hello, World! - VJ ${dayOfWeek} ${timeString}`);
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});