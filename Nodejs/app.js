// require('dotenv').config();
// const express = require('express');
// const bodyParser = require('body-parser');
// const path = require('path');
// const os = require('os');

// const { faker } = require('@faker-js/faker');
// const { promiseDB } = require('./js/db');
// const logger = require('./js/logger');

// const app = express();
// const XLSX = require('xlsx');



// app.set('view engine', 'ejs');
// app.set('views', path.join(__dirname, 'views'));
// app.use(express.static(path.join(__dirname, 'public')));
// app.use(express.urlencoded({ extended: true }));
// app.use(bodyParser.json());
// app.use(express.text({ type: 'text/plain' }));

// function getServerIpAddress() {
//   const nets = os.networkInterfaces();
//   for (const name of Object.keys(nets)) {
//     for (const net of nets[name]) {
//       if (net.family === 'IPv4' && !net.internal) {
//         return net.address;
//       }
//     }
//   }
//   return '127.0.0.1';
// }

// app.get('/test-xlsx', (req, res) => {
//   try {
//     // 1. Create sample data
//     const data = [
//       { Name: 'Alice', Email: 'alice@example.com', Age: 30 },
//       { Name: 'Bob', Email: 'bob@example.com', Age: 25 },
//       { Name: 'Charlie', Email: 'charlie@example.com', Age: 35 },
//     ];

//     // 2. Convert JSON to worksheet
//     const worksheet = XLSX.utils.json_to_sheet(data);

//     // 3. Create a new workbook and append the worksheet
//     const workbook = XLSX.utils.book_new();
//     XLSX.utils.book_append_sheet(workbook, worksheet, 'Users');

//     // 4. Write workbook to buffer
//     const buffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' });

//     // 5. Send as downloadable file
//     res.setHeader('Content-Disposition', 'attachment; filename=test-users.xlsx');
//     res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
//     res.send(buffer);
//   } catch (err) {
//     console.error('❌ XLSX test error:', err);
//     res.status(500).send('Failed to generate Excel file');
//   }
// });


// app.get('/insertRandomUser', async (req, res) => {
//   try {
//     const ec2instances = req.query.ec2instances;
//     const testcaseid = req.query.testcaseid;
//     const misc = req.query.misc;
//     const acu = req.query.acu;
    
//     console.log(testcaseid);
//     const name = faker.person.fullName();
//     const email = faker.internet.email();
//     const userType = faker.helpers.arrayElement(['Admin', 'User', 'Guest']);
//     const phone = faker.phone.number();

//     const ip_address = getServerIpAddress();
//     const host_name = os.hostname();

//     const [result] = await promiseDB.execute(
//       'INSERT INTO stress_test_users (name, email, user_type, phone, ip_address, host_name, testcaseid, misc, ec2instances, acu) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
//       [name, email, userType, phone, ip_address, host_name, testcaseid, misc, ec2instances, acu]
//     );

//     // Pipe-separated console log
//     console.log(host_name, ` | Inserted stress_test_users: ${result.insertId}|${name}`);

//     res.json({
//       message: 'Random user inserted successfully!',
//       user: { name,
//         email,
//         userType,
//         phone,
//         ip_address,
//         host_name,
//         testcaseid,
//         misc,
//         ec2instances,
//         acu },
//       insertId: result.insertId
//     });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'Error inserting user', error: err.message });
//   }
// });

// app.get('/listUsers', async (req, res) => {
//   try {
//     const [rows] = await promiseDB.execute(
//       'SELECT * FROM stress_test_users ORDER BY user_id DESC LIMIT 1000'
//     );
//     res.json({ users: rows });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'Error fetching users', error: err.message });
//   }
// });

// app.get('/users', async (req, res) => {
//   try {
//     const [rows] = await promiseDB.query('SELECT * FROM stress_test_users LIMIT 10');
//     res.json(rows);
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'DB error', error: err.message });
//   }
// });

// app.get('/health', (req, res) => {
//   res.status(200).send('OK');
// });



// // app.get('/', (req, res) => {
// //   res.send('Benevolate');
// // });

// // app.get('/', (req, res) => {
// //   const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
// //   const ip_address = getServerIpAddress();
// //   const host_name = os.hostname();

// //   res.send(`
// //     <h1>Benevolate - 7/18</h1>
// //     <p><strong>Environment:</strong> ${environment}</p>
// //     <p><strong>Host:</strong> ${host_name}</p>
// //     <p><strong>IP:</strong> ${ip_address}</p>
// //   `);
// // });


// app.get('/', (req, res) => {
//   const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
//   const ip_address = getServerIpAddress();
//   const host_name = os.hostname();


//   const current_time = new Date().toLocaleString();
//   const memory_used = ((os.totalmem() - os.freemem()) / 1024 / 1024).toFixed(2); // in MB

//   res.send(`
//     <h1>Benevolate - 7/24 - ${environment}</h1>
//     <p><strong>Host:</strong> ${host_name}</p>
//     <p><strong>IP:</strong> ${ip_address}</p>
//     <p><strong>Time:</strong> ${current_time}</p>
//     <p><strong>Memory Used:</strong> ${memory_used} MB</p>
//   `);
//   });


// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//   console.log(`Server is running on port ${PORT}`);
// });





// require('dotenv').config();
// const express = require('express');
// const bodyParser = require('body-parser');
// const path = require('path');
// const os = require('os');
// const multer = require('multer');
// const fs = require('fs-extra');
// const AWS = require('aws-sdk');
// const { faker } = require('@faker-js/faker');
// const { promiseDB } = require('./js/db');
// const logger = require('./js/logger');

// const app = express();
// const XLSX = require('xlsx');

// // Ensure required directories exist before setting up multer
// const setupDirectories = async () => {
//   const requiredDirs = [
//     '/mnt/efs/code/benevolate/public/uploads/',
//     '/mnt/efs/code/benevolate/public/data',
//     '/mnt/efs/code/benevolate/public/org/invite/images'
//   ];

//   for (const dir of requiredDirs) {
//     try {
//       await fs.ensureDir(dir);
//       console.log(`✅ Directory ensured: ${dir}`);
//     } catch (err) {
//       console.error(`❌ Failed to create directory ${dir}:`, err.message);
//       // Don't exit, just log the error and continue
//     }
//   }
// };

// // Initialize directories
// setupDirectories().catch(err => {
//   console.error('Failed to setup directories:', err);
// });

// // Setup multer to store files temporarily in the EFS directory
// const upload = multer({
//   dest: '/mnt/efs/code/benevolate/public/uploads/', // EFS mount point for uploads
//   fileFilter: (req, file, cb) => {
//     // Add basic file validation
//     const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|xlsx|xls/;
//     const mimetype = allowedTypes.test(file.mimetype);
//     const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

//     if (mimetype && extname) {
//       return cb(null, true);
//     } else {
//       cb(new Error('Only image, PDF, and document files are allowed'));
//     }
//   },
//   limits: {
//     fileSize: 10 * 1024 * 1024 // 10MB limit
//   }
// });

// // Set AWS S3 configuration
// const s3 = new AWS.S3();
// const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME || "vj-test-benvolate";

// app.set('view engine', 'ejs');
// app.set('views', path.join(__dirname, 'views'));
// app.use(express.static(path.join(__dirname, 'public')));
// app.use(express.urlencoded({ extended: true }));
// app.use(bodyParser.json());
// app.use(express.text({ type: 'text/plain' }));

// function getServerIpAddress() {
//   const nets = os.networkInterfaces();
//   for (const name of Object.keys(nets)) {
//     for (const net of nets[name]) {
//       if (net.family === 'IPv4' && !net.internal) {
//         return net.address;
//       }
//     }
//   }
//   return '127.0.0.1';
// }

// // File upload route (improved with better error handling)
// app.post('/add_org_invite', upload.fields([
//   { name: 'orglogo', maxCount: 1 },
//   { name: 'background', maxCount: 1 }
// ]), async (req, res) => {
//   try {
//     const { orgname, invite_id } = req.body;
//     const files = req.files;

//     if (!invite_id) {
//       return res.status(400).json({ message: 'invite_id is required' });
//     }

//     // Get uploaded files
//     const orgLogo = files['orglogo'] ? files['orglogo'][0] : null;
//     const background = files['background'] ? files['background'][0] : null;

//     if (!orgLogo || !background) {
//       return res.status(400).json({ message: 'Both orglogo and background files are required' });
//     }

//     // Define subfolder based on invite_id
//     const subfolder = `org/invite/images/${invite_id}`;
//     const uploadDir = path.join(__dirname, 'public', subfolder);
//     const dataDir = '/mnt/efs/code/benevolate/public/data'; // The directory synced with S3

//     // Ensure the folders exist
//     await fs.ensureDir(uploadDir);
//     await fs.ensureDir(dataDir);

//     // Construct file paths in the uploads folder
//     const logoFileName = `logo-${invite_id}.png`;
//     const bgFileName = `background-${invite_id}.png`;

//     const logoPath = path.join(uploadDir, logoFileName);
//     const backgroundPath = path.join(uploadDir, bgFileName);

//     // Copy the files to the upload directory
//     await fs.copy(orgLogo.path, logoPath);
//     await fs.copy(background.path, backgroundPath);

//     // Copy the files to the S3-sync'd data directory
//     await fs.copy(logoPath, path.join(dataDir, logoFileName));
//     await fs.copy(backgroundPath, path.join(dataDir, bgFileName));

//     // Clean up temporary files
//     await fs.remove(orgLogo.path);
//     await fs.remove(background.path);

//     // Sync to S3
//     await syncFilesToS3(dataDir, S3_BUCKET_NAME);

//     // Generate public URLs
//     const logoPublicURL = `${process.env.WEBSITE_PREFIX}/${subfolder}/${logoFileName}`;
//     const bgPublicURL = `${process.env.WEBSITE_PREFIX}/${subfolder}/${bgFileName}`;

//     res.json({
//       message: 'Files uploaded successfully!',
//       logoURL: logoPublicURL,
//       backgroundURL: bgPublicURL,
//     });
//   } catch (err) {
//     console.error('Error uploading files:', err);
//     res.status(500).json({ 
//       message: 'Error uploading files', 
//       error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
//     });
//   }
// });

// // Function to sync files from EFS to S3
// async function syncFilesToS3(efsDir, bucketName) {
//   try {
//     const files = await fs.readdir(efsDir);

//     for (const file of files) {
//       const filePath = path.join(efsDir, file);
//       const stats = await fs.stat(filePath);
      
//       // Skip directories
//       if (stats.isDirectory()) continue;

//       const fileStream = fs.createReadStream(filePath);

//       // Define the S3 key (which includes the folder structure)
//       const s3Key = `benevolate/application/data-${process.env.ENVIRONMENT || 'dev'}/${file}`;

//       // Upload the file to S3
//       await s3.upload({
//         Bucket: bucketName,
//         Key: s3Key,
//         Body: fileStream,
//       }).promise();

//       console.log(`File uploaded to S3: ${s3Key}`);
//     }
//   } catch (err) {
//     console.error('Error syncing files to S3:', err);
//     throw err;
//   }
// }

// // Your existing routes

// app.get('/test-xlsx', (req, res) => {
//   try {
//     // 1. Create sample data
//     const data = [
//       { Name: 'Alice', Email: 'alice@example.com', Age: 30 },
//       { Name: 'Bob', Email: 'bob@example.com', Age: 25 },
//       { Name: 'Charlie', Email: 'charlie@example.com', Age: 35 },
//     ];

//     // 2. Convert JSON to worksheet
//     const worksheet = XLSX.utils.json_to_sheet(data);

//     // 3. Create a new workbook and append the worksheet
//     const workbook = XLSX.utils.book_new();
//     XLSX.utils.book_append_sheet(workbook, worksheet, 'Users');

//     // 4. Write workbook to buffer
//     const buffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' });

//     // 5. Send as downloadable file
//     res.setHeader('Content-Disposition', 'attachment; filename=test-users.xlsx');
//     res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
//     res.send(buffer);
//   } catch (err) {
//     console.error('❌ XLSX test error:', err);
//     res.status(500).send('Failed to generate Excel file');
//   }
// });

// app.get('/insertRandomUser', async (req, res) => {
//   try {
//     const name = faker.person.fullName();
//     const email = faker.internet.email();
//     const userType = faker.helpers.arrayElement(['Admin', 'User', 'Guest']);
//     const phone = faker.phone.number();
//     const ip_address = getServerIpAddress();
//     const host_name = os.hostname();

//     const [result] = await promiseDB.execute(
//       'INSERT INTO stress_test_users (name, email, user_type, phone, ip_address, host_name) VALUES (?, ?, ?, ?, ?, ?)',
//       [name, email, userType, phone, ip_address, host_name]
//     );

//     res.json({
//       message: 'Random user inserted successfully!',
//       user: { name, email, userType, phone, ip_address, host_name },
//       insertId: result.insertId
//     });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'Error inserting user', error: err.message });
//   }
// });

// app.get('/listUsers', async (req, res) => {
//   try {
//     const [rows] = await promiseDB.execute(
//       'SELECT * FROM stress_test_users ORDER BY user_id DESC LIMIT 1000'
//     );
//     res.json({ users: rows });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: 'Error fetching users', error: err.message });
//   }
// });

// app.get('/health', (req, res) => {
//   res.status(200).json({ 
//     status: 'OK', 
//     timestamp: new Date().toISOString(),
//     environment: process.env.ENVIRONMENT || 'unknown',
//     hostname: os.hostname()
//   });
// });

// app.get('/', (req, res) => {
//   const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
//   const ip_address = getServerIpAddress();
//   const host_name = os.hostname();

//   const current_time = new Date().toLocaleString();
//   const memory_used = ((os.totalmem() - os.freemem()) / 1024 / 1024).toFixed(2); // in MB

//   res.send(`
//     <h1>Benevolate - 7/29</h1>
//     <p><strong>Environment:</strong> ${environment}</p>
//     <p><strong>Host:</strong> ${host_name}</p>
//     <p><strong>IP:</strong> ${ip_address}</p>
//     <p><strong>Time:</strong> ${current_time}</p>
//     <p><strong>Memory Used:</strong> ${memory_used} MB</p>
//   `);
// });

// // Global error handler
// app.use((err, req, res, next) => {
//   console.error('Unhandled error:', err);
//   res.status(500).json({
//     message: 'Something went wrong!',
//     error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
//   });
// });

// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//   console.log(`Server is running on port ${PORT}`);
//   console.log(`Environment: ${process.env.ENVIRONMENT || 'development'}`);
//   console.log(`Host: ${os.hostname()}`);
// });


require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const os = require('os');
const multer = require('multer');
const fs = require('fs-extra');
const AWS = require('aws-sdk');
const { faker } = require('@faker-js/faker');
const { promiseDB } = require('./js/db');
// const logger = require('./js/logger');
const XLSX = require('xlsx');

const app = express();

logger: (req, ...messages) => {
    if (req.session?.isAuthenticated) {
      console.log(`${new Date().toLocaleString()} | ${req.session.user.org_id} | ${req.session.user_id} | ${messages.join(' ')}`);
    } else {
      console.log(`${new Date().toLocaleString()} | ${messages.join(' ')}`);
    }
  }




// Ensure required directories exist before setting up multer
const setupDirectories = async () => {
  const requiredDirs = [
    '/mnt/efs/code/benevolate/public/uploads/',
    '/mnt/efs/code/benevolate/public/data',
    '/mnt/efs/code/benevolate/public/org/invite/images'
  ];

  for (const dir of requiredDirs) {
    try {
      await fs.ensureDir(dir);
      console.log(`✅ Directory ensured: ${dir}`);
    } catch (err) {
      console.error(`❌ Failed to create directory ${dir}:`, err.message);
      // Don't exit, just log the error and continue
    }
  }
};

// Initialize directories
setupDirectories().catch(err => {
  console.error('Failed to setup directories:', err);
});

// Setup multer to store files temporarily in the EFS directory
const upload = multer({
  dest: '/mnt/efs/code/benevolate/public/uploads/', // EFS mount point for uploads
  fileFilter: (req, file, cb) => {
    // Add basic file validation
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|xlsx|xls/;
    const mimetype = allowedTypes.test(file.mimetype);
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image, PDF, and document files are allowed'));
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Set AWS S3 configuration
const s3 = new AWS.S3();
const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME || "vj-test-benvolate";

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

// Function to sync files from EFS to S3
async function syncFilesToS3(efsDir, bucketName) {
  try {
    const files = await fs.readdir(efsDir);

    for (const file of files) {
      const filePath = path.join(efsDir, file);
      const stats = await fs.stat(filePath);
      
      // Skip directories
      if (stats.isDirectory()) continue;

      const fileStream = fs.createReadStream(filePath);

      // Define the S3 key (which includes the folder structure)
      const s3Key = `benevolate/application/data-${process.env.ENVIRONMENT || 'dev'}/${file}`;

      // Upload the file to S3
      await s3.upload({
        Bucket: bucketName,
        Key: s3Key,
        Body: fileStream,
      }).promise();

      console.log(`File uploaded to S3: ${s3Key}`);
    }
  } catch (err) {
    console.error('Error syncing files to S3:', err);
    throw err;
  }
}

// GET route for /add_org_invite - Shows upload form
app.get('/add_org_invite', (req, res) => {
  const environment = process.env.ENVIRONMENT || 'development';
  const hostname = os.hostname();
  
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Organization Invite - File Upload</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                max-width: 800px; 
                margin: 0 auto; 
                padding: 20px; 
                background-color: #f5f5f5;
            }
            .container { 
                background: white; 
                padding: 30px; 
                border-radius: 10px; 
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            h1 { 
                color: #333; 
                text-align: center;
                margin-bottom: 30px;
            }
            .form-group { 
                margin-bottom: 20px; 
            }
            label { 
                display: block; 
                font-weight: bold; 
                margin-bottom: 5px; 
                color: #555;
            }
            input[type="text"], input[type="file"] { 
                width: 100%; 
                padding: 10px; 
                border: 2px solid #ddd; 
                border-radius: 5px; 
                font-size: 16px;
                box-sizing: border-box;
            }
            input[type="file"] {
                padding: 8px;
            }
            .submit-btn { 
                background-color: #007bff; 
                color: white; 
                padding: 12px 30px; 
                border: none; 
                border-radius: 5px; 
                font-size: 16px; 
                cursor: pointer; 
                width: 100%;
                margin-top: 20px;
            }
            .submit-btn:hover { 
                background-color: #0056b3; 
            }
            .info-box {
                background-color: #e7f3ff;
                border: 1px solid #b3d9ff;
                border-radius: 5px;
                padding: 15px;
                margin-bottom: 20px;
            }
            .server-info {
                background-color: #f8f9fa;
                border: 1px solid #dee2e6;
                border-radius: 5px;
                padding: 10px;
                margin-bottom: 20px;
                font-size: 12px;
                color: #6c757d;
            }
            .file-requirements {
                font-size: 14px;
                color: #666;
                margin-top: 5px;
            }
            #uploadStatus {
                margin-top: 20px;
                padding: 10px;
                border-radius: 5px;
                display: none;
            }
            .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
            .error { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
            .loading { background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🏢 Organization Invite Setup</h1>
            
            <div class="server-info">
                <strong>Server Info:</strong> ${hostname} | Environment: ${environment} | ${new Date().toLocaleString()}
            </div>
            
            <div class="info-box">
                <strong>📋 Instructions:</strong><br>
                Upload your organization logo and background image to create invitation materials. 
                Both files are required and will be processed automatically.
            </div>
            
            <form id="uploadForm" action="/add_org_invite" method="POST" enctype="multipart/form-data">
                <div class="form-group">
                    <label for="orgname">🏢 Organization Name:</label>
                    <input type="text" id="orgname" name="orgname" required placeholder="Enter your organization name">
                </div>
                
                <div class="form-group">
                    <label for="invite_id">🔖 Invite ID:</label>
                    <input type="text" id="invite_id" name="invite_id" required placeholder="Enter unique invite ID (e.g., invite_2025_001)">
                </div>
                
                <div class="form-group">
                    <label for="orglogo">🖼️ Organization Logo:</label>
                    <input type="file" id="orglogo" name="orglogo" accept="image/*" required>
                    <div class="file-requirements">Accepted: PNG, JPG, JPEG, GIF (Max: 10MB)</div>
                </div>
                
                <div class="form-group">
                    <label for="background">🎨 Background Image:</label>
                    <input type="file" id="background" name="background" accept="image/*" required>
                    <div class="file-requirements">Accepted: PNG, JPG, JPEG, GIF (Max: 10MB)</div>
                </div>
                
                <button type="submit" class="submit-btn">📤 Upload Files</button>
            </form>
            
            <div id="uploadStatus"></div>
        </div>

        <script>
            document.getElementById('uploadForm').addEventListener('submit', function(e) {
                const statusDiv = document.getElementById('uploadStatus');
                statusDiv.style.display = 'block';
                statusDiv.className = 'loading';
                statusDiv.innerHTML = '⏳ Uploading files and syncing to S3... Please wait.';
                
                // Disable submit button to prevent double submission
                const submitBtn = document.querySelector('.submit-btn');
                submitBtn.disabled = true;
                submitBtn.textContent = '⏳ Uploading...';
            });
        </script>
    </body>
    </html>
  `);
});

// POST route for file upload
app.post('/add_org_invite', upload.fields([
  { name: 'orglogo', maxCount: 1 },
  { name: 'background', maxCount: 1 }
]), async (req, res) => {
  try {
    const { orgname, invite_id } = req.body;
    const files = req.files;

    if (!invite_id) {
      return res.status(400).json({ message: 'invite_id is required' });
    }

    // Get uploaded files
    const orgLogo = files['orglogo'] ? files['orglogo'][0] : null;
    const background = files['background'] ? files['background'][0] : null;

    if (!orgLogo || !background) {
      return res.status(400).json({ message: 'Both orglogo and background files are required' });
    }

    // Define subfolder based on invite_id
    const subfolder = `org/invite/images/${invite_id}`;
    const uploadDir = path.join(__dirname, 'public', subfolder);
    const dataDir = '/mnt/efs/code/benevolate/public/data'; // The directory synced with S3

    // Ensure the folders exist
    await fs.ensureDir(uploadDir);
    await fs.ensureDir(dataDir);

    // Construct file paths in the uploads folder
    const logoFileName = `logo-${invite_id}.png`;
    const bgFileName = `background-${invite_id}.png`;

    const logoPath = path.join(uploadDir, logoFileName);
    const backgroundPath = path.join(uploadDir, bgFileName);

    // Copy the files to the upload directory
    await fs.copy(orgLogo.path, logoPath);
    await fs.copy(background.path, backgroundPath);

    // Copy the files to the S3-sync'd data directory
    await fs.copy(logoPath, path.join(dataDir, logoFileName));
    await fs.copy(backgroundPath, path.join(dataDir, bgFileName));

    // Clean up temporary files
    await fs.remove(orgLogo.path);
    await fs.remove(background.path);

    // Sync to S3
    await syncFilesToS3(dataDir, S3_BUCKET_NAME);

    // Generate public URLs
    const logoPublicURL = `${process.env.WEBSITE_PREFIX}/${subfolder}/${logoFileName}`;
    const bgPublicURL = `${process.env.WEBSITE_PREFIX}/${subfolder}/${bgFileName}`;

    // Return success response with HTML for better user experience
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>Upload Successful</title>
          <style>
              body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background-color: #f5f5f5; }
              .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
              .file-info { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
              .btn { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
              .btn:hover { background-color: #0056b3; }
              img { max-width: 200px; max-height: 150px; border: 1px solid #ddd; border-radius: 5px; margin: 10px 0; }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="success">
                  <h2>✅ Files Uploaded Successfully!</h2>
                  <p>Organization: <strong>${orgname}</strong></p>
                  <p>Invite ID: <strong>${invite_id}</strong></p>
              </div>
              
              <div class="file-info">
                  <h3>📁 Uploaded Files:</h3>
                  <p><strong>Logo:</strong> ${logoFileName}</p>
                  <p><strong>Background:</strong> ${bgFileName}</p>
                  <p><strong>Location:</strong> ${uploadDir}</p>
                  <p><strong>S3 Sync:</strong> ✅ Completed</p>
              </div>
              
              <div class="file-info">
                  <h3>🔗 Public URLs:</h3>
                  <p><strong>Logo URL:</strong> <a href="${logoPublicURL}" target="_blank">${logoPublicURL}</a></p>
                  <p><strong>Background URL:</strong> <a href="${bgPublicURL}" target="_blank">${bgPublicURL}</a></p>
              </div>
              
              <div style="text-align: center; margin-top: 30px;">
                  <a href="/add_org_invite" class="btn">📤 Upload Another</a>
                  <a href="/" class="btn">🏠 Home</a>
              </div>
          </div>
      </body>
      </html>
    `);
  } catch (err) {
    console.error('Error uploading files:', err);
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>Upload Error</title>
          <style>
              body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background-color: #f5f5f5; }
              .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              .error { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; }
              .btn { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="error">
                  <h2>❌ Upload Failed</h2>
                  <p>Error: ${process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'}</p>
              </div>
              <div style="text-align: center; margin-top: 20px;">
                  <a href="/add_org_invite" class="btn">🔄 Try Again</a>
                  <a href="/" class="btn">🏠 Home</a>
              </div>
          </div>
      </body>
      </html>
    `);
  }
});

// API endpoint to get upload status
app.get('/api/upload-status/:invite_id', async (req, res) => {
  const { invite_id } = req.params;
  
  try {
    const subfolder = `org/invite/images/${invite_id}`;
    const uploadDir = path.join(__dirname, 'public', subfolder);
    
    const logoPath = path.join(uploadDir, `logo-${invite_id}.png`);
    const backgroundPath = path.join(uploadDir, `background-${invite_id}.png`);
    
    const logoExists = await fs.pathExists(logoPath);
    const backgroundExists = await fs.pathExists(backgroundPath);
    
    res.json({
      invite_id,
      status: (logoExists && backgroundExists) ? 'complete' : 'incomplete',
      files: {
        logo: logoExists,
        background: backgroundExists
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Error checking upload status' });
  }
});

// Test XLSX route
app.get('/test-xlsx', (req, res) => {
  try {
    // 1. Create sample data
    const data = [
      { Name: 'Alice', Email: 'alice@example.com', Age: 30 },
      { Name: 'Bob', Email: 'bob@example.com', Age: 25 },
      { Name: 'Charlie', Email: 'charlie@example.com', Age: 35 },
    ];

    // 2. Convert JSON to worksheet
    const worksheet = XLSX.utils.json_to_sheet(data);

    // 3. Create a new workbook and append the worksheet
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Users');

    // 4. Write workbook to buffer
    const buffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'buffer' });

    // 5. Send as downloadable file
    res.setHeader('Content-Disposition', 'attachment; filename=test-users.xlsx');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(buffer);
  } catch (err) {
    console.error('❌ XLSX test error:', err);
    res.status(500).send('Failed to generate Excel file');
  }
});

// Insert random user route
app.get('/insertRandomUser', async (req, res) => {
  try {
    const name = faker.person.fullName();
    const email = faker.internet.email();
    const userType = faker.helpers.arrayElement(['Admin', 'User', 'Guest']);
    const phone = faker.phone.number();
    const ip_address = getServerIpAddress();
    const host_name = os.hostname();

    const [result] = await promiseDB.execute(
      'INSERT INTO stress_test_users (name, email, user_type, phone, ip_address, host_name) VALUES (?, ?, ?, ?, ?, ?)',
      [name, email, userType, phone, ip_address, host_name]
    );

    res.json({
      message: 'Random user inserted successfully!',
      user: { name, email, userType, phone, ip_address, host_name },
      insertId: result.insertId
    });
    logger(req, `Inserted stress_test_users: ${result.insertId} | ${name}`);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error inserting user', error: err.message });
  }
});

// List users route
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

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.ENVIRONMENT || 'unknown',
    hostname: os.hostname()
  });
});

// Home route
app.get('/', (req, res) => {
  const environment = process.env.ENVIRONMENT || 'EC2 (Default)';
  const ip_address = getServerIpAddress();
  const host_name = os.hostname();

  const current_time = new Date().toLocaleString();
  const memory_used = ((os.totalmem() - os.freemem()) / 1024 / 1024).toFixed(2); // in MB

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Benevolate - Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background-color: #f5f5f5; }
            .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .nav-links { margin: 20px 0; }
            .nav-links a { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
            .nav-links a:hover { background-color: #0056b3; }
            .info-box { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🏢 Benevolate - 7/29</h1>
            
            <div class="info-box">
                <p><strong>Environment:</strong> ${environment}</p>
                <p><strong>Host:</strong> ${host_name}</p>
                <p><strong>IP:</strong> ${ip_address}</p>
                <p><strong>Time:</strong> ${current_time}</p>
                <p><strong>Memory Used:</strong> ${memory_used} MB</p>
            </div>

            <div class="nav-links">
                <h3>📋 Available Services:</h3>
                <a href="/add_org_invite">📤 Upload Organization Files</a>
                <a href="/insertRandomUser">👤 Add Random User</a>
                <a href="/listUsers">📜 List Users</a>
                <a href="/test-xlsx">📊 Download Test Excel</a>
                <a href="/health">❤️ Health Check</a>
            </div>
        </div>
    </body>
    </html>
  `);
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  
  // Handle multer errors specifically
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html>
        <head><title>File Too Large</title></head>
        <body style="font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px;">
            <div style="background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px;">
                <h2>❌ File Too Large</h2>
                <p>The uploaded file exceeds the maximum size limit of 10MB.</p>
                <a href="/add_org_invite" style="display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; margin-top: 10px;">🔄 Try Again</a>
            </div>
        </body>
        </html>
      `);
    }
  }
  
  res.status(500).json({
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Environment: ${process.env.ENVIRONMENT || 'development'}`);
  console.log(`Host: ${os.hostname()}`);
});