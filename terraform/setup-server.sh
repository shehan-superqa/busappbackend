#!/bin/bash

# Server Setup Script
# Run this on the DigitalOcean droplet if the initial setup didn't complete

set -e

PROJECT_NAME="bus-ticketing"
APP_DIR="/opt/${PROJECT_NAME}"

echo "=========================================="
echo "Server Setup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "1. Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "2. Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    echo "2. Node.js already installed: $(node --version)"
fi

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    echo "3. Installing PM2..."
    npm install -g pm2
else
    echo "3. PM2 already installed: $(pm2 --version)"
fi

# Install Git if not installed
if ! command -v git &> /dev/null; then
    echo "4. Installing Git..."
    apt-get install -y git
else
    echo "4. Git already installed: $(git --version)"
fi

# Create application directory
echo "5. Setting up application directory..."
mkdir -p ${APP_DIR}
cd ${APP_DIR}

# Check if code exists
if [ ! -f "package.json" ]; then
    echo "   Code not found. Checking for GitHub repo..."
    
    # Try to get GitHub repo from environment or ask
    if [ -z "$GITHUB_REPO" ]; then
        echo "   Please provide GitHub repository URL:"
        echo "   Example: https://github.com/shehan-superqa/busappbackend.git"
        read -p "GitHub repo URL: " GITHUB_REPO
    fi
    
    if [ -n "$GITHUB_REPO" ]; then
        echo "   Cloning repository..."
        git clone -b main ${GITHUB_REPO} .
        
        # If server code is in a 'server' subdirectory, move it to root
        if [ -d "server" ] && [ -f "server/package.json" ]; then
            echo "   Server code found in 'server' subdirectory, moving to root..."
            mv server/* .
            mv server/.* . 2>/dev/null || true
            rmdir server 2>/dev/null || true
        fi
    else
        echo "   ⚠ No GitHub repo provided. Please clone your code manually to ${APP_DIR}"
        exit 1
    fi
else
    echo "   Application code found"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "6. Creating .env file..."
    echo "   Please provide your configuration:"
    
    read -p "MongoDB URL (DB_URL): " DB_URL
    read -p "HTTP Port [3000]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-3000}
    read -p "TCP Port [8080]: " TCP_PORT
    TCP_PORT=${TCP_PORT:-8080}
    read -p "Node Environment [production]: " NODE_ENV
    NODE_ENV=${NODE_ENV:-production}
    
    cat > .env <<EOF
PORT=${HTTP_PORT}
TCP_PORT=${TCP_PORT}
NODE_ENV=${NODE_ENV}
DB_URL=${DB_URL}
EOF
    echo "   .env file created"
else
    echo "6. .env file already exists"
fi

# Install dependencies
echo "7. Installing npm dependencies..."
if [ -f "package.json" ]; then
    npm install --production
else
    echo "   ⚠ package.json not found!"
    exit 1
fi

# Create PM2 ecosystem file
echo "8. Creating PM2 ecosystem file..."
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
      PORT: ${HTTP_PORT:-3000},
      TCP_PORT: ${TCP_PORT:-8080}
    },
    error_file: '/var/log/${PROJECT_NAME}-error.log',
    out_file: '/var/log/${PROJECT_NAME}-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF

# Start application with PM2
echo "9. Starting application with PM2..."
if [ -f "server.js" ]; then
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup systemd -u root --hp /root
    echo "   Application started!"
else
    echo "   ⚠ server.js not found!"
    exit 1
fi

# Setup firewall
echo "10. Configuring firewall..."
ufw allow 22/tcp
ufw allow ${HTTP_PORT:-3000}/tcp
ufw allow ${TCP_PORT:-8080}/tcp
ufw --force enable

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Check status with:"
echo "  pm2 status"
echo ""
echo "View logs with:"
echo "  pm2 logs ${PROJECT_NAME}"
echo ""
echo "Check ports:"
echo "  netstat -tlnp | grep -E ':(3000|8080)'"
echo ""

