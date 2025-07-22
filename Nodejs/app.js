require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const os = require('os');

const { faker } = require('@faker-js/faker');
const { promiseDB } = require('./js/db');
const logger = require('./js/logger');

const app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.text({ type: 'text/plain' }));

function getServerIpAddress() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '127.0.0.1';
}

app.get('/insertRandomUser', async (req, res) => {
  try {
    const ec2instances = req.query.ec2instances;
    const testcaseid = req.query.testcaseid;
    const misc = req.query.misc;
    const acu = req.query.acu;
    
    console.log(testcaseid);
    const name = faker.person.fullName();
    const email = faker.internet.email();
    const userType = faker.helpers.arrayElement(['Admin', 'User', 'Guest']);
    const phone = faker.phone.number();

    const ip_address = getServerIpAddress();
    const host_name = os.hostname();

    const [result] = await promiseDB.execute(
      'INSERT INTO stress_test_users (name, email, user_type, phone, ip_address, host_name, testcaseid, misc, ec2instances, acu) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name, email, userType, phone, ip_address, host_name, testcaseid, misc, ec2instances, acu]
    );

    // Pipe-separated console log
    console.log(host_name, ` | Inserted stress_test_users: ${result.insertId}|${name}`);

    res.json({
      message: 'Random user inserted successfully!',
      user: { name,
        email,
        userType,
        phone,
        ip_address,
        host_name,
        testcaseid,
        misc,
        ec2instances,
        acu },
      insertId: result.insertId
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error inserting user', error: err.message });
  }
});

app.get('/listUsers', async (req, res) => {
  try {
    const [rows] = await promiseDB.execute(
      'SELECT * FROM stress_test_users ORDER BY user_id DESC LIMIT 1000'
    );
    res.json({ users: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error fetching users', error: err.message });
  }
});

app.get('/users', async (req, res) => {
  try {
    const [rows] = await promiseDB.query('SELECT * FROM stress_test_users LIMIT 10');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'DB error', error: err.message });
  }
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});


// app.get('/', (req, res) => {
//   res.send('Benevolate');
// });

// app.get('/', (req, res) => {
//   const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
//   const ip_address = getServerIpAddress();
//   const host_name = os.hostname();

//   res.send(`
//     <h1>Benevolate - 7/18</h1>
//     <p><strong>Environment:</strong> ${environment}</p>
//     <p><strong>Host:</strong> ${host_name}</p>
//     <p><strong>IP:</strong> ${ip_address}</p>
//   `);
// });



app.get('/', (req, res) => {
  const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
  const ip_address = getServerIpAddress();
  const host_name = os.hostname();


  const current_time = new Date().toLocaleString();
  const memory_used = ((os.totalmem() - os.freemem()) / 1024 / 1024).toFixed(2); // in MB

  res.send(`
    <h1>Benevolate - 7/22 - test</h1>
    <p><strong>Environment:</strong> ${environment}</p>
    <p><strong>Host:</strong> ${host_name}</p>
    <p><strong>IP:</strong> ${ip_address}</p>
    <p><strong>Time:</strong> ${current_time}</p>
    <p><strong>Memory Used:</strong> ${memory_used} MB</p>
  `);
});


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});