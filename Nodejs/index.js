const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello, World! - VJ-new');
});

// app.listen(port, () => {
//   console.log(`Server running at http://localhost:${port}`);
// });


app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});