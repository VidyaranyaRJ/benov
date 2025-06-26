const express = require('express');
const os = require('os');
require('dotenv').config();

const db = require('./db');
const { faker } = require('@faker-js/faker');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const HOSTNAME = os.hostname();

// Track page visits
let visitCount = 0;
let uniqueVisitors = new Set();

function getClientIp(req) {
  return req.headers['x-forwarded-for'] || 
         req.headers['x-real-ip'] || 
         req.connection.remoteAddress || 
         req.socket.remoteAddress || 
         'unknown';
}

// Start server
app.listen(PORT, () => {
  console.log(`🚀 App listening on port ${PORT}`);
  console.log(`🖥️ Server hostname: ${HOSTNAME}`);
});

// Home page
app.get('/', (req, res) => {
  const clientIp = getClientIp(req);
  visitCount++;
  uniqueVisitors.add(clientIp);

  console.log(`🏠 Home page visit #${visitCount} from IP: ${clientIp}`);

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Live Time - Simple App</title>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { 
          font-family: Arial, sans-serif; 
          text-align: center; 
          margin: 0;
          padding: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          min-height: 100vh;
        }
        .container {
          background: rgba(255,255,255,0.1);
          padding: 40px;
          border-radius: 20px;
          display: inline-block;
          margin-top: 50px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        #time { 
          font-size: 3em; 
          margin: 20px 0; 
          font-weight: bold;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        .stats {
          margin-top: 30px;
          font-size: 1.2em;
        }
        .btn {
          background: #4CAF50;
          color: white;
          border: none;
          padding: 15px 30px;
          font-size: 1.1em;
          border-radius: 25px;
          cursor: pointer;
          margin: 10px;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px 0 rgba(76, 175, 80, 0.3);
        }
        .btn:hover {
          background: #45a049;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px 0 rgba(76, 175, 80, 0.4);
        }
        .btn.secondary {
          background: #2196F3;
          box-shadow: 0 4px 15px 0 rgba(33, 150, 243, 0.3);
        }
        .btn.secondary:hover {
          background: #1976D2;
          box-shadow: 0 6px 20px 0 rgba(33, 150, 243, 0.4);
        }
        .message {
          margin-top: 20px;
          padding: 10px;
          border-radius: 10px;
          background: rgba(255,255,255,0.1);
          display: none;
        }
        .message.success {
          background: rgba(76, 175, 80, 0.3);
          border: 1px solid #4CAF50;
        }
        .message.error {
          background: rgba(244, 67, 54, 0.3);
          border: 1px solid #f44336;
        }
        @media (max-width: 768px) {
          .container {
            margin: 20px;
            padding: 20px;
          }
          #time {
            font-size: 2em;
          }
          .btn {
            display: block;
            width: 100%;
            margin: 10px 0;
          }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>⏰ Live Time Monitor</h1>
        <div id="time">Loading...</div>
        <div class="stats">
          <div>Visit Count: <span id="visitCount">${visitCount}</span></div>
          <div>Unique Visitors: <span id="uniqueVisitors">${uniqueVisitors.size}</span></div>
          <div>Server: <span id="hostname">${HOSTNAME}</span></div>
        </div>
        
        <div style="margin-top: 30px;">
          <button class="btn" onclick="insertRandomUser()">➕ Insert User</button>
          <button class="btn secondary" onclick="viewUsers()">👥 View Users</button>
          <button class="btn secondary" onclick="refreshTime()">🔄 Refresh</button>
        </div>
        
        <div id="message" class="message"></div>
      </div>

      <script>
        function updateTime() {
          fetch('/time')
            .then(res => res.json())
            .then(data => {
              document.getElementById('time').innerText = data.time;
              document.getElementById('visitCount').innerText = data.visitCount;
              document.getElementById('uniqueVisitors').innerText = data.uniqueVisitors;
            })
            .catch(err => {
              console.error('Error fetching time:', err);
              document.getElementById('time').innerText = 'Error loading time';
            });
        }
        
        async function insertRandomUser() {
          try {
            const response = await fetch('/insert-random-user', { method: 'POST' });
            const data = await response.json();
            
            if (data.success) {
              showMessage(\`✅ User inserted: \${data.name}\`, 'success');
              console.log('Inserted user:', data);
            } else {
              showMessage('❌ Failed to insert user', 'error');
            }
          } catch (error) {
            console.error('Insert user error:', error);
            showMessage('❌ Network error', 'error');
          }
        }
        
        async function viewUsers() {
          try {
            const response = await fetch('/users');
            const users = await response.json();
            
            console.log('All users:', users);
            showMessage(\`📊 \${users.length} users found (check console)\`, 'success');
          } catch (error) {
            console.error('Error fetching users:', error);
            showMessage('❌ Failed to fetch users', 'error');
          }
        }
        
        function refreshTime() {
          updateTime();
          showMessage('🔄 Time refreshed', 'success');
        }
        
        function showMessage(text, type) {
          const messageEl = document.getElementById('message');
          messageEl.textContent = text;
          messageEl.className = \`message \${type}\`;
          messageEl.style.display = 'block';
          
          setTimeout(() => {
            messageEl.style.display = 'none';
          }, 3000);
        }
        
        // Initial load and auto-refresh
        updateTime();
        setInterval(updateTime, 1000);
      </script>
    </body>
    </html>
  `);
});

// Time API endpoint
app.get('/time', (req, res) => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayOfWeek = days[now.getDay()];
  const timeString = `${dayOfWeek} ${hours}:${minutes}:${seconds}`;

  res.json({
    time: `🟢 ${timeString} - Server: ${HOSTNAME}`,
    visitCount: visitCount,
    uniqueVisitors: uniqueVisitors.size,
    hostname: HOSTNAME,
    timestamp: now.toISOString()
  });
});

// Insert random user endpoint
app.post('/insert-random-user', async (req, res) => {
  const clientIp = getClientIp(req);
  
  try {
    const nameParts = faker.person.fullName().split(' ');
    const firstName = nameParts[0];
    const lastName = nameParts[1] || '';
    const name = `${firstName} ${lastName}`;
    const email = faker.internet.email({ firstName, lastName });
    const user_type = 'User';

    const insertQuery = `
      INSERT INTO users (name, email, user_type)
      VALUES (?, ?, ?)
    `;
    
    await db.query(insertQuery, [name, email, user_type]);
    
    console.log(`✅ User inserted: ${name} (${email}) from IP: ${clientIp}`);
    
    res.status(200).json({ 
      success: true, 
      name, 
      email,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('❌ Error inserting user:', err.message);
    
    res.status(500).json({ 
      success: false, 
      error: 'Failed to insert user',
      timestamp: new Date().toISOString()
    });
  }
});

// Get all users endpoint
app.get('/users', async (req, res) => {
  const clientIp = getClientIp(req);
  
  try {
    const [rows] = await db.query('SELECT * FROM users ORDER BY created_at DESC');
    
    console.log(`📊 Users queried by IP: ${clientIp}, Count: ${rows.length}`);
    
    res.json(rows);
  } catch (err) {
    console.error('❌ Error fetching users:', err.message);
    
    res.status(500).json({ 
      error: 'Failed to fetch users',
      timestamp: new Date().toISOString()
    });
  }
});

// 404 handler
app.use((req, res) => {
  const clientIp = getClientIp(req);
  console.log(`❓ 404 - ${req.method} ${req.originalUrl} from IP: ${clientIp}`);
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  const clientIp = getClientIp(req);
  console.error(`💥 Server error from IP: ${clientIp}:`, err.message);
  
  res.status(500).json({ 
    error: 'Something went wrong!', 
    timestamp: new Date().toISOString() 
  });
});