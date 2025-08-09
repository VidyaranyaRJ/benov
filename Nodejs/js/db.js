require('dotenv').config();
const mysql = require('mysql2');

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
  timezone: '+00:00',
  // No timeout options - handled automatically by MySQL2 v3+
});

// ------------------- SINGLE CONNECTION -------------------  
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  dateStrings: ['DATE', 'DATETIME'],
  timezone: '+00:00',
});

const promiseDB = pool.promise();

const dbConnect = () => {
  db.connect(err => {
    if (err) {
      console.error('Database connection failed: ' + err.stack);
      return;
    }
    console.log('Connected to database.');
  });
};

pool.on('connection', function (connection) {
  console.log('New connection established as id ' + connection.threadId);
});

pool.on('error', function(err) {
  console.error('Database pool error:', err);
  if(err.code === 'PROTOCOL_CONNECTION_LOST') {
    console.log('Connection was closed, will reconnect...');
  }
});

module.exports = {
  db,
  promiseDB,
  pool,
  dbConnect
};