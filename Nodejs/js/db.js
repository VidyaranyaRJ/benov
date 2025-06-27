require('dotenv').config();
const mysql = require('mysql2');
const logger = require('./logger');

// ------------------- SINGLE CONNECTION (Legacy) -------------------

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  dateStrings: ['DATE', 'DATETIME'],
  timezone: '+00:00'
});

db.connect(err => {
  if (err) {
    console.error('Database connection failed: ' + err.stack);
    return;
  }
  console.log('Connected to database.');
});

// ------------------- CONNECTION POOL -------------------

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: ['DATE', 'DATETIME'],
  timezone: '+00:00'
});

const promiseDB = pool.promise();

// ------------------- EXPORT ALL -------------------

module.exports = {
  db,
  promiseDB,
  pool,
  logger
};
