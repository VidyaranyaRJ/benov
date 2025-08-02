#!/bin/bash

# PM2 Reset and Restart Script
# This script handles both initial deployment and restarts

set -e  # Exit on any error

# Configuration
APP_NAME="nodejs-app"
APP_FILE="app.js"  # or your main application file
PORT=3000
DEPLOY_PATH="/mnt/efs/code/nodejs-app"

echo "🚀 Starting PM2 application management..."

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $port is in use"
        return 0
    else
        echo "✅ Port $port is available"
        return 1
    fi
}



# Function to kill processes on port
kill_port_processes() {
    local port=$1
    echo "🔍 Checking for processes on port $port..."
    
    if check_port $port; then
        echo "🔧 Killing processes on port $port..."
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 2
        
        if check_port $port; then
            echo "❌ Failed to free port $port"
            return 1
        else
            echo "✅ Port $port is now free"
        fi
    fi
    
    return 0
}

# Change to application directory
cd "$DEPLOY_PATH" || { echo "❌ Failed to change to $DEPLOY_PATH"; exit 1; }

# ✅ Install any new dependencies
echo "📦 Installing dependencies..."
npm install


echo "📁 Current directory: $(pwd)"
echo "📋 Files in directory:"
ls -la

# Kill any orphan processes on the port
kill_port_processes $PORT

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 is not installed"
    exit 1
fi

# Get current PM2 processes
echo "🔍 Checking current PM2 processes..."
pm2 list

# Check if our app is already running
if pm2 describe "$APP_NAME" &> /dev/null; then
    echo "🔄 Application '$APP_NAME' exists, restarting with updated log path..."

    HOSTNAME=$(hostname)
    DATE=$(date +%F)
    LOG_PATH="/mnt/efs/logs/${DATE}-${HOSTNAME}-app.log"
    echo "📁 Using updated log path: $LOG_PATH"

    pm2 delete "$APP_NAME"
    pm2 start "$APP_FILE" --name "$APP_NAME" --log "$LOG_PATH"

else
    echo "🆕 Application '$APP_NAME' not found, starting new instance..."
    
    # Check if ecosystem.config.js exists
    if [ -f "ecosystem.config.js" ]; then
        echo "📋 Using ecosystem.config.js"
        pm2 start ecosystem.config.js
    elif [ -f "$APP_FILE" ]; then
        echo "📋 Starting $APP_FILE directly"
        HOSTNAME=$(hostname)
        DATE=$(date +%F)
        LOG_PATH="/mnt/efs/logs/${DATE}-${HOSTNAME}-app.log"
        echo "📁 Using dynamic log path: $LOG_PATH"

        pm2 start "$APP_FILE" --name "$APP_NAME" --log "$LOG_PATH"
    else
        echo "❌ No application file found ($APP_FILE or ecosystem.config.js)"
        exit 1
    fi
fi

# Wait a moment for the application to start
echo "⏳ Waiting for application to start..."
sleep 5

# Verify the application is running
echo "🔍 Verifying application status..."
pm2 list

# Check if the application is online
if pm2 describe "$APP_NAME" | grep -q "online"; then
    echo "✅ Application '$APP_NAME' is online"
else
    echo "❌ Application '$APP_NAME' is not online"
    pm2 logs "$APP_NAME" --lines 20
    exit 1
fi

# Check if port is listening
if check_port $PORT; then
    echo "✅ Application is listening on port $PORT"
else
    echo "❌ Application is not listening on port $PORT"
    pm2 logs "$APP_NAME" --lines 20
    exit 1
fi

# Save PM2 configuration
echo "💾 Saving PM2 configuration..."
pm2 save

echo "✅ PM2 restart completed successfully!"
echo "📊 Final PM2 status:"
pm2 list
pm2 info "$APP_NAME"