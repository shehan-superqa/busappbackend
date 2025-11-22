#!/bin/bash

# Enable logging (but don't exit on errors - we want to complete setup)
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Set PATH early to ensure commands are found
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin

echo "=========================================="
echo "Starting server setup..."
echo "=========================================="

# Update system
echo "[1/10] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Install Node.js 18.x
echo "[2/10] Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y nodejs -qq

# Verify Node.js installation
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js installation failed!"
    exit 1
fi
echo "Node.js version: $(node --version)"

# Install PM2 globally
echo "[3/10] Installing PM2..."
npm install -g pm2 > /dev/null 2>&1 || {
    echo "WARNING: npm install pm2 had issues, trying again..."
    sleep 2
    npm install -g pm2
}

# Verify PM2 installation and ensure it's in PATH
export PATH=$PATH:/usr/local/bin:/usr/bin
sleep 1  # Give npm time to finish

# Verify PM2 is available
if ! command -v pm2 &> /dev/null; then
    echo "ERROR: PM2 installation failed! Trying to locate..."
    # Try to find where npm installed it
    PM2_PATH=$(find /usr -name pm2 2>/dev/null | head -1)
    if [ -n "$PM2_PATH" ]; then
        ln -s "$PM2_PATH" /usr/local/bin/pm2 2>/dev/null || true
        export PATH=$PATH:$(dirname "$PM2_PATH")
    fi
    
    if ! command -v pm2 &> /dev/null; then
        echo "ERROR: PM2 still not found after retry!"
        # Don't exit - continue and try to fix later
    else
        echo "PM2 found and linked"
    fi
fi

if command -v pm2 &> /dev/null; then
    echo "PM2 version: $(pm2 --version)"
else
    echo "WARNING: PM2 command not available, but continuing..."
fi

# Install Git
echo "[4/10] Installing Git..."
apt-get install -y git -qq

# Install Nginx (optional, for reverse proxy) - Only if domain is configured
# Nginx will be installed later if domain_name is provided to save memory

# Create application directory
echo "[5/10] Setting up application directory..."
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Clone repository if GitHub repo is provided
if [ -n "${github_repo}" ]; then
  echo "Cloning repository from ${github_repo} (branch: ${github_branch})..."
  
  # Retry cloning up to 3 times
  MAX_RETRIES=3
  RETRY_COUNT=0
  CLONE_SUCCESS=false
  
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if git clone -b ${github_branch} ${github_repo} . 2>&1; then
      CLONE_SUCCESS=true
      break
    else
      RETRY_COUNT=$((RETRY_COUNT + 1))
      echo "Clone attempt $RETRY_COUNT failed, retrying in 5 seconds..."
      sleep 5
      rm -rf * .[^.]* 2>/dev/null || true  # Clean up failed clone
    fi
  done
  
  if [ "$CLONE_SUCCESS" = true ]; then
    # If server code is in a 'server' subdirectory, move it to root
    if [ -d "server" ] && [ -f "server/package.json" ]; then
      echo "Server code found in 'server' subdirectory, moving to root..."
      mv server/* .
      mv server/.* . 2>/dev/null || true
      rmdir server 2>/dev/null || true
    fi
    
    if [ -f "package.json" ]; then
      echo "Repository cloned successfully"
    else
      echo "WARNING: package.json not found after cloning, but continuing..."
    fi
  else
    echo "ERROR: Failed to clone repository after $MAX_RETRIES attempts!"
    echo "You may need to clone manually or check repository access."
  fi
else
  # Create a placeholder - you'll need to upload your code manually
  echo "WARNING: GitHub repo not provided. Please upload your code manually to /opt/${project_name}"
fi

# Create .env file
echo "[6/10] Creating .env file..."
cat > /opt/${project_name}/.env <<EOF
PORT=${port}
TCP_PORT=${tcp_port}
NODE_ENV=${node_env}
DB_URL=${db_url}
EOF
echo ".env file created"

# Install dependencies
if [ -f /opt/${project_name}/package.json ]; then
  echo "[7/10] Installing npm dependencies..."
  cd /opt/${project_name}
  
  # Retry npm install if it fails
  if ! npm install --production --no-audit --no-fund 2>&1; then
    echo "WARNING: npm install had issues, retrying..."
    sleep 3
    npm install --production --no-audit --no-fund || {
      echo "ERROR: npm install failed after retry, but continuing..."
    }
  fi
  
  if [ -d "node_modules" ]; then
    echo "Dependencies installed successfully"
  else
    echo "WARNING: node_modules directory not found after install"
  fi
else
  echo "WARNING: package.json not found, skipping npm install"
fi

# Create PM2 ecosystem file (optimized for minimal resources)
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
if [ -f /opt/${project_name}/server.js ]; then
  echo "[8/10] Starting application with PM2..."
  cd /opt/${project_name}
  
  # Ensure PM2 is in PATH
  export PATH=$PATH:/usr/local/bin:/usr/bin
  
  # Wait a moment to ensure PM2 is ready
  sleep 2
  
  # Start the application (retry if needed)
  if command -v pm2 &> /dev/null; then
    # Stop any existing instance first
    pm2 delete ${project_name} 2>/dev/null || true
    pm2 kill 2>/dev/null || true
    sleep 1
    
    # Start PM2 daemon if not running
    pm2 ping || pm2 kill && sleep 1
    
    # Start the application
    if pm2 start ecosystem.config.js 2>&1; then
      echo "PM2 start command executed"
      
      # Save PM2 process list
      sleep 2
      pm2 save 2>&1 || {
        echo "WARNING: Failed to save PM2 process list, but continuing..."
      }
      
      # Setup PM2 startup script (non-blocking)
      pm2 startup systemd -u root --hp /root 2>&1 | tail -1 | bash 2>/dev/null || {
        echo "WARNING: Failed to setup PM2 startup script, but continuing..."
      }
      
      # Wait for the app to start
      sleep 5
      
      # Verify PM2 status
      if pm2 list 2>/dev/null | grep -q "${project_name}.*online"; then
        echo "✓ Application started successfully with PM2"
      else
        echo "WARNING: Application may not be online yet. Checking status..."
        pm2 list
        echo "Check logs with: pm2 logs ${project_name}"
      fi
    else
      echo "ERROR: Failed to start application with PM2!"
      echo "Attempting to start directly with node to see errors..."
      node server.js &
      sleep 2
    fi
  else
    echo "ERROR: PM2 command not available! Starting with node directly..."
    nohup node server.js > /var/log/${project_name}-direct.log 2>&1 &
    echo "Application started with node (not PM2)"
  fi
else
  echo "WARNING: server.js not found, skipping PM2 start"
  echo "Files in directory:"
  ls -la /opt/${project_name}/ 2>/dev/null || true
fi

# Configure Nginx as reverse proxy (optional)
if [ -n "${domain_name}" ]; then
  # Install Nginx if domain is configured
  apt-get install -y nginx
  
  cat > /etc/nginx/sites-available/${project_name} <<EOF
server {
    listen 80;
    server_name ${domain_name};

    location / {
        proxy_pass http://localhost:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  ln -s /etc/nginx/sites-available/${project_name} /etc/nginx/sites-enabled/
  rm /etc/nginx/sites-enabled/default
  nginx -t && systemctl restart nginx
fi

# Setup firewall (UFW)
echo "[9/10] Configuring firewall..."
ufw --force allow 22/tcp > /dev/null 2>&1
ufw --force allow ${port}/tcp > /dev/null 2>&1
ufw --force allow ${tcp_port}/tcp > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo "Firewall configured"

# Final verification
echo "[10/10] Verifying setup..."
echo ""
echo "=========================================="
echo "Setup Summary"
echo "=========================================="
echo "Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "PM2: $(pm2 --version 2>/dev/null || echo 'Not found')"
echo "Application directory: /opt/${project_name}"
if [ -f /opt/${project_name}/server.js ]; then
  echo "Server file: ✓ Found"
else
  echo "Server file: ✗ Not found"
fi

# Check if PM2 is running the app
export PATH=$PATH:/usr/local/bin:/usr/bin
if command -v pm2 &> /dev/null; then
  echo ""
  echo "PM2 Status:"
  pm2 list 2>/dev/null || echo "PM2 not running any processes"
  
  # Final check - try to ensure app is running
  if ! pm2 list 2>/dev/null | grep -q "${project_name}.*online"; then
    echo ""
    echo "Application not showing as online, attempting final start..."
    cd /opt/${project_name} 2>/dev/null
    if [ -f "ecosystem.config.js" ]; then
      pm2 delete ${project_name} 2>/dev/null || true
      pm2 start ecosystem.config.js 2>/dev/null
      pm2 save 2>/dev/null
      sleep 3
      pm2 list
    fi
  fi
fi

echo ""
echo "=========================================="
echo "Setup completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. SSH into the server: ssh root@<droplet-ip>"
echo "2. Check application status: pm2 status"
echo "3. View logs: pm2 logs ${project_name}"
echo "4. Test HTTP endpoint: curl http://localhost:${port}/health"
echo ""
echo "Logs are saved to: /var/log/user-data.log"

