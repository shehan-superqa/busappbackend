#!/bin/bash

# Enable comprehensive logging - DO NOT EXIT ON ERRORS
exec > >(tee -a /var/log/user-data.log) 2>&1
set -x  # Debug mode

# Set PATH early and comprehensively
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "Starting server setup - $(date)"
echo "=========================================="
echo ""

# Update system
echo "[1/12] Updating system packages..."
apt-get update || true
apt-get upgrade -y || true

# Install essential packages
echo "[2/12] Installing essential packages..."
apt-get install -y curl wget git build-essential || true

# Install Node.js 18.x
echo "[3/12] Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || {
    echo "NodeSource setup failed, trying alternative..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
}
apt-get install -y nodejs || {
    echo "Node.js install failed, retrying..."
    apt-get install -y nodejs
}

# Verify and wait for Node.js
sleep 2
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found, but continuing..."
else
    echo "✓ Node.js: $(node --version)"
    echo "✓ npm: $(npm --version)"
fi

# Install PM2 - MULTIPLE METHODS
echo "[4/12] Installing PM2 (Method 1: npm install)..."
npm install -g pm2 2>&1 || {
    echo "PM2 install failed, retrying..."
    sleep 3
    npm install -g pm2 2>&1
}

# Wait for npm to finish
sleep 5

# Update PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Check if PM2 is available
if ! command -v pm2 &> /dev/null; then
    echo "[5/12] PM2 not in PATH, searching and creating symlink..."
    
    # Find PM2
    PM2_FOUND=$(find /usr -name pm2 -type f 2>/dev/null | grep -E "(bin|node_modules)" | head -1)
    
    if [ -z "$PM2_FOUND" ]; then
        # Try npm root
        NPM_ROOT=$(npm root -g 2>/dev/null || echo "/usr/lib/node_modules")
        PM2_FOUND="$NPM_ROOT/pm2/bin/pm2"
    fi
    
    if [ -f "$PM2_FOUND" ]; then
        echo "Found PM2 at: $PM2_FOUND"
        ln -sf "$PM2_FOUND" /usr/local/bin/pm2 2>/dev/null || true
        ln -sf "$PM2_FOUND" /usr/bin/pm2 2>/dev/null || true
    else
        echo "PM2 not found, trying to reinstall..."
        npm cache clean --force 2>/dev/null || true
        npm install -g pm2 --force 2>&1
        sleep 5
        
        # Try again
        PM2_FOUND=$(find /usr -name pm2 -type f 2>/dev/null | head -1)
        if [ -f "$PM2_FOUND" ]; then
            ln -sf "$PM2_FOUND" /usr/local/bin/pm2 2>/dev/null || true
            ln -sf "$PM2_FOUND" /usr/bin/pm2 2>/dev/null || true
        fi
    fi
fi

# Create PM2 wrapper script as last resort
if ! command -v pm2 &> /dev/null; then
    echo "[6/12] Creating PM2 wrapper script..."
    cat > /usr/local/bin/pm2 <<'PM2EOF'
#!/bin/bash
NPM_ROOT=$(npm root -g 2>/dev/null || echo "/usr/lib/node_modules")
PM2_BIN="$NPM_ROOT/pm2/bin/pm2"
if [ -f "$PM2_BIN" ]; then
    exec "$PM2_BIN" "$@"
else
    echo "PM2 not found at $PM2_BIN"
    exit 1
fi
PM2EOF
    chmod +x /usr/local/bin/pm2
    export PATH=$PATH:/usr/local/bin
fi

# Final PM2 verification
echo "[7/12] Verifying PM2 installation..."
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
sleep 2

if command -v pm2 &> /dev/null; then
    echo "✓ PM2 is available: $(which pm2)"
    pm2 --version || echo "PM2 found but version check failed"
else
    echo "✗ PM2 still not available, but continuing setup..."
    echo "You may need to install PM2 manually: npm install -g pm2"
fi

# Create application directory
echo "[8/12] Setting up application directory..."
mkdir -p /opt/${project_name}
cd /opt/${project_name} || exit 1

# Clone repository
if [ -n "${github_repo}" ]; then
  echo "[9/12] Cloning repository..."
  
  MAX_RETRIES=5
  RETRY=0
  while [ $RETRY -lt $MAX_RETRIES ]; do
    if git clone -b ${github_branch} ${github_repo} . 2>&1; then
      break
    fi
    RETRY=$((RETRY + 1))
    echo "Clone attempt $RETRY failed, retrying..."
    sleep 5
    rm -rf * .[^.]* 2>/dev/null || true
  done
  
  # Move server code if in subdirectory
  if [ -d "server" ] && [ -f "server/package.json" ]; then
    echo "Moving server code to root..."
    mv server/* . 2>/dev/null || true
    mv server/.* . 2>/dev/null || true
    rmdir server 2>/dev/null || true
  fi
  
  if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found!"
    exit 1
  fi
  echo "✓ Repository cloned"
else
  echo "ERROR: GitHub repo not provided!"
  exit 1
fi

# Create .env file
echo "[10/12] Creating .env file..."
cat > /opt/${project_name}/.env <<EOF
PORT=${port}
TCP_PORT=${tcp_port}
NODE_ENV=${node_env}
DB_URL=${db_url}
EOF
echo "✓ .env created"

# Install dependencies
echo "[11/12] Installing npm dependencies..."
cd /opt/${project_name}
npm install --production --no-audit --no-fund 2>&1 || {
    echo "npm install failed, retrying..."
    sleep 3
    npm install --production --no-audit --no-fund 2>&1
}

if [ ! -d "node_modules" ]; then
    echo "WARNING: node_modules not found!"
fi

# Create PM2 ecosystem file
cat > /opt/${project_name}/ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: '${project_name}',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '300M',
    node_args: '--max-old-space-size=256',
    env: {
      NODE_ENV: '${node_env}',
      PORT: ${port},
      TCP_PORT: ${tcp_port}
    },
    error_file: '/var/log/${project_name}-error.log',
    out_file: '/var/log/${project_name}-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF

# Start application with PM2
echo "[12/12] Starting application..."
cd /opt/${project_name}
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ -f "server.js" ]; then
    # Try to start with PM2
    if command -v pm2 &> /dev/null; then
        pm2 kill 2>/dev/null || true
        sleep 2
        pm2 start ecosystem.config.js 2>&1
        sleep 3
        pm2 save 2>&1 || true
        
        # Setup startup
        STARTUP_CMD=$(pm2 startup systemd -u root --hp /root 2>&1 | tail -1)
        if [ -n "$STARTUP_CMD" ] && [ "$STARTUP_CMD" != "PM2" ]; then
            eval "$STARTUP_CMD" 2>&1 || true
        fi
        
        pm2 list
    else
        echo "PM2 not available, starting with node directly..."
        nohup node server.js > /var/log/${project_name}-direct.log 2>&1 &
    fi
else
    echo "ERROR: server.js not found!"
    ls -la
fi

# Configure firewall
echo "Configuring firewall..."
ufw --force allow 22/tcp 2>/dev/null || true
ufw --force allow ${port}/tcp 2>/dev/null || true
ufw --force allow ${tcp_port}/tcp 2>/dev/null || true
ufw --force enable 2>/dev/null || true

# Final status
echo ""
echo "=========================================="
echo "Setup Complete - $(date)"
echo "=========================================="
echo "Node.js: $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "PM2: $(pm2 --version 2>/dev/null || echo 'NOT FOUND - Run: npm install -g pm2')"
echo "PM2 Path: $(which pm2 2>/dev/null || echo 'NOT FOUND')"
echo ""
if command -v pm2 &> /dev/null; then
    echo "PM2 Status:"
    pm2 list 2>&1 || echo "PM2 list failed"
else
    echo "PM2 is NOT installed. To install manually:"
    echo "  npm install -g pm2"
    echo "  pm2 start /opt/${project_name}/ecosystem.config.js"
fi
echo ""
echo "Check logs: /var/log/user-data.log"
echo "=========================================="
