require('dotenv').config();
const mysql = require('mysql2');

// const db = mysql.createConnection({
//     host: 'localhost',        // e.g., 'localhost'
//     user: 'root',    // e.g., 'root'
//     password: 'Sharkk12#',// e.g., 'password'
//     database: 'opengive' // e.g., 'certificatesvault'
// });


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



 function dbConnect() {
    if (!db || db === null) {
        db.connect((err) => {
            if (err) {
                console.error('Database connection failed: ', err);
            } else {
                console.log('Connected to database');
                AlertError("☠️ DB : ", "dbConnect", err.ErrorCode, "system", 'Database connectivity could not be established !!');

            }
        });
    };
};

dbConnect()
module.exports = { db, dbConnect };