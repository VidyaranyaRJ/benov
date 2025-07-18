#!/bin/bash

set -euo pipefail
echo "🔁 Resetting PM2 completely and restarting nodejs-app..."

pm2 delete all || true
pm2 kill || true
pm2 flush || true
pm2 save --force || true
rm -rf ~/.pm2

PID=$(sudo lsof -t -i:3000 || true)
if [[ ! -z "$PID" ]]; then
  echo "🧨 Killing orphan Node.js process on port 3000 (PID: $PID)..."
  sudo kill -9 $PID
else
  echo "✅ No orphan process found on port 3000."
fi

cd /mnt/efs/code/nodejs-app
echo "📁 Now in $(pwd)"

npm ci --silent

pm2 start app.js --name nodejs-app --cwd $(pwd) --env production
pm2 save

sleep 3
curl --fail --silent http://localhost:3000 || echo "⚠️ Health check failed"

echo "✅ PM2 reset & app restart complete!"
