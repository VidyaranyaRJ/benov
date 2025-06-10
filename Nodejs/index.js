const express = require('express');
const os = require('os');
const app = express();
const port = 3000;

// Serve the static HTML page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Live Time</title>
      <style>
        body { font-family: Arial; text-align: center; margin-top: 50px; }
        #time { font-size: 2em; margin-top: 20px; }
      </style>
    </head>
    <body>
      <h1>⏰ VJ Instance Time</h1>
      <div id="time">Loading...</div>

      <script>
        async function updateTime() {
          const res = await fetch('/time');
          const text = await res.text();
          document.getElementById('time').innerText = text;
        }

        updateTime(); // initial call
        setInterval(updateTime, 1000); // every second
      </script>
    </body>
    </html>
  `);
});

// API endpoint to return time data
app.get('/time', (req, res) => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = days[now.getDay()];
  const hostname = os.hostname();

  // Log instance hostname and the current time to CloudWatch
  console.log(`Instance: ${hostname} - Time: ${dayOfWeek} ${hours}:${minutes}:${seconds}`);

  res.send(`🟢Hi  ${dayOfWeek} ${hours}:${minutes}:${seconds} - Server: ${hostname}`);
});

// Optional health check
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
