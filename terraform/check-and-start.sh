#!/bin/bash

# Quick script to check status and start the application if needed

PROJECT_NAME="bus-ticketing"
APP_DIR="/opt/${PROJECT_NAME}"

echo "=========================================="
echo "Checking Application Status"
echo "=========================================="
echo ""

# Check if application directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "✗ Application directory not found: $APP_DIR"
    echo ""
    echo "The user-data script may not have completed."
    echo "Please check: cat /var/log/user-data.log"
    exit 1
fi

echo "✓ Application directory exists: $APP_DIR"
cd $APP_DIR

# Check if code exists
if [ ! -f "package.json" ]; then
    echo "✗ package.json not found!"
    echo ""
    echo "Code may not have been cloned. Checking..."
    
    # Check if GitHub repo is configured
    if [ -z "$GITHUB_REPO" ]; then
        echo "Please provide GitHub repository URL:"
        read -p "GitHub repo URL: " GITHUB_REPO
    fi
    
    if [ -n "$GITHUB_REPO" ]; then
        echo "Cloning repository..."
        git clone -b main $GITHUB_REPO .
        
        # If server code is in 'server' subdirectory
        if [ -d "server" ] && [ -f "server/package.json" ]; then
            echo "Moving server code to root..."
            mv server/* .
            mv server/.* . 2>/dev/null || true
            rmdir server 2>/dev/null || true
        fi
    else
        echo "Cannot proceed without repository URL"
        exit 1
    fi
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "✗ .env file not found!"
    echo "Creating .env file..."
    
    read -p "MongoDB URL (DB_URL): " DB_URL
    read -p "HTTP Port [3000]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-3000}
    read -p "TCP Port [8080]: " TCP_PORT
    TCP_PORT=${TCP_PORT:-8080}
    
    cat > .env <<EOF
PORT=${HTTP_PORT}
TCP_PORT=${TCP_PORT}
NODE_ENV=production
DB_URL=${DB_URL}
EOF
    echo "✓ .env file created"
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "✗ node_modules not found!"
    echo "Installing dependencies..."
    npm install --production
    echo "✓ Dependencies installed"
fi

# Check if ecosystem.config.js exists
if [ ! -f "ecosystem.config.js" ]; then
    echo "✗ ecosystem.config.js not found!"
    echo "Creating PM2 ecosystem file..."
    
    cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: '${PROJECT_NAME}',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '300M',
    node_args: '--max-old-space-size=256',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      TCP_PORT: 8080
    },
    error_file: '/var/log/${PROJECT_NAME}-error.log',
    out_file: '/var/log/${PROJECT_NAME}-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF
    echo "✓ ecosystem.config.js created"
fi

# Check PM2 status
echo ""
echo "Current PM2 status:"
pm2 list

# Check if app is already running
if pm2 list | grep -q "${PROJECT_NAME}.*online"; then
    echo ""
    echo "✓ Application is already running!"
    echo ""
    echo "To view logs: pm2 logs ${PROJECT_NAME}"
    echo "To restart: pm2 restart ${PROJECT_NAME}"
else
    echo ""
    echo "Application is not running. Starting now..."
    
    # Ensure PM2 is in PATH
    export PATH=$PATH:/usr/local/bin:/usr/bin
    
    # Start the application
    pm2 start ecosystem.config.js
    
    # Save PM2 process list
    pm2 save
    
    # Wait a moment
    sleep 2
    
    # Check status again
    echo ""
    echo "Updated PM2 status:"
    pm2 list
    
    # Show logs
    echo ""
    echo "Recent logs:"
    pm2 logs ${PROJECT_NAME} --lines 10 --nostream
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="

