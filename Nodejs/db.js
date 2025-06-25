require('dotenv').config();      // if you’re using a .env file
const mysql = require('mysql2/promise');

const { logToCloudWatch } = require('./cloudwatch-logger'); 

const promiseDB = mysql.createPool({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

async function queryWithLogging(sql, params = []) {
  const formattedQuery = mysql.format(sql, params);
  const timestamp = new Date().toISOString();

  try {
    const [rows] = await pool.query(sql, params);
    await logToCloudWatch(`[DB QUERY SUCCESS] ${timestamp}\n${formattedQuery}`);
    return rows;
  } catch (err) {
    await logToCloudWatch(`[DB QUERY ERROR] ${timestamp}\n${formattedQuery}\nError: ${err.message}`);
    throw err;
  }
}

module.exports = {
  query: queryWithLogging,
  pool, // Export pool in case you need raw connection access
};