#!/bin/bash

# node-deploy.sh - Local deployment script for Node.js app
# This script runs on the EC2 instance after code extraction

set -euo pipefail

echo "🚀 Starting Node.js application deployment..."

# Get current directory
APP_DIR=$(pwd)
echo "📂 Application directory: $APP_DIR"

# Check if we're in the right place
if [ ! -f "app.js" ]; then
  echo "❌ Error: app.js not found in current directory"
  exit 1
fi

# Stop existing PM2 processes
echo "🛑 Stopping existing PM2 processes..."
pm2 stop nodejs-app || true
pm2 delete nodejs-app || true

# Set up environment
echo "🔧 Setting up environment..."
echo "PORT=3000" > .env
echo "NODE_ENV=${NODE_ENV:-production}" >> .env

# Install dependencies (if package.json exists)
if [ -f "package.json" ]; then
  echo "📦 Installing dependencies..."
  npm install --production || echo "⚠️ npm install failed, continuing..."
else
  echo "ℹ️ No package.json found, skipping npm install"
fi

# Start application with PM2
echo "🚀 Starting application with PM2..."
pm2 start app.js --name nodejs-app --cwd "$APP_DIR" --env production

# Save PM2 configuration
pm2 save

# Show PM2 status
echo "✅ PM2 Status:"
pm2 list

# Check if application is running on port 3000
echo "🔍 Checking application status..."
sleep 3
if netstat -tlnp | grep -q ":3000"; then
  echo "✅ Application is running on port 3000"
else
  echo "⚠️ Application might not be running on port 3000"
fi

# Try a basic health check
echo "🏥 Performing health check..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
  echo "✅ Health check passed"
else
  echo "⚠️ Health check failed - application might still be starting"
fi

echo "✅ Node.js deployment completed!"