const bcrypt = require('bcryptjs');
const csvParser = require('csv-parser');
const axios = require('axios');
const express = require('express');
const multer = require('multer');
const path = require('path');
// const getColors = require('get-image-colors');
const fs = require('fs');
const bodyParser = require('body-parser');
const mysql = require('mysql2');
const session = require('express-session');
const passport = require('passport');
const saltRounds = 8; // You can increase the salt rounds for better security
require('dotenv').config();
//const { Location } = require("./js/utils");

const os = require('os');
const { exec } = require('child_process');
var SuperAdminLeftnavcode = ""
var UserLeftnavcode = ""
var AdminLeftnavcode = ""

const { db, dbConnect } = require('./js/db');
const promiseDB = db.promise();
//const hdate = await import('@hebcal/hdate');

const logger = (req, ...messages) => {
    if (req.session.isAuthenticated) {
        console.log(`${new Date().toLocaleString('en-US', { hour12: true, month: '2-digit', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })} | ${req.session.user.org_id} | ${req.session.user_id} | ${messages.join(' ')}`);
    }
    else {
        console.log(`${new Date().toLocaleString('en-US', { hour12: true, month: '2-digit', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' })} | ${messages.join(' ')}`);
    }
};



// --------------------------------------------------------------------------------------------------------
// App Setup


const app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
//app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json()); // Add this line to parse JSON bodies
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

// Get server hostname
const host_name = os.hostname();


 const { faker } = require('@faker-js/faker');

 

app.get('/insertRandomUser', async (req, res) => {
  try {
    const name = faker.person.fullName();
    const email = faker.internet.email();
    const userType = faker.helpers.arrayElement(['Admin', 'User', 'Guest']);
    const phone = faker.phone.number();

    const ip_address = getServerIpAddress();
    const host_name = os.hostname();

    const [result] = await promiseDB.execute(
      'INSERT INTO users (name, email, user_type, phone, ip_address, host_name) VALUES (?, ?, ?, ?, ?, ?)',
      [name, email, userType, phone, ip_address, host_name]
    );

    // Pipe-separated console log
    console.log(`Inserted user: ${result.insertId}|${name}`);

    res.json({
      message: 'Random user inserted successfully!',
      user: { name, email, userType, phone, ip_address, host_name },
      insertId: result.insertId
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error inserting user', error: err.message });
  }
});



const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});


app.get('/listUsers', async (req, res) => {
  try {
    // Fetch 100 users from the database
    const [rows] = await promiseDB.execute(
      'SELECT * FROM users ORDER BY user_id DESC LIMIT 100'
    );
    res.json({
      users: rows
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error fetching users', error: err.message });
  }
});

dbConnect();