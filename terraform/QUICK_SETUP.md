# Quick Server Setup Guide

If PM2 is not installed, the initial setup didn't complete. Follow these steps:

## Option 1: Run Setup Script (Recommended)

1. **Copy the setup script to your server:**
   ```bash
   # On your local machine, copy the script
   scp terraform/setup-server.sh root@157.230.92.146:/root/
   ```

2. **SSH into server and run it:**
   ```bash
   ssh root@157.230.92.146
   chmod +x /root/setup-server.sh
   /root/setup-server.sh
   ```

   The script will:
   - Install Node.js 18.x
   - Install PM2
   - Clone your GitHub repository
   - Install dependencies
   - Create .env file (will ask for MongoDB URL)
   - Start the application

## Option 2: Manual Setup

SSH into your server and run these commands:

### 1. Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
```

### 2. Install PM2
```bash
npm install -g pm2
```

### 3. Install Git
```bash
apt-get update
apt-get install -y git
```

### 4. Clone Your Repository
```bash
mkdir -p /opt/bus-ticketing
cd /opt/bus-ticketing
git clone -b main https://github.com/shehan-superqa/busappbackend.git .

# If server code is in 'server' subdirectory
if [ -d "server" ]; then
    mv server/* .
    mv server/.* . 2>/dev/null || true
    rmdir server 2>/dev/null || true
fi
```

### 5. Create .env File
```bash
cd /opt/bus-ticketing
cat > .env <<EOF
PORT=3000
TCP_PORT=8080
NODE_ENV=production
DB_URL=mongodb+srv://shehan_db_user:gMLmZua0getxorb5@cluster0.q13ia75.mongodb.net/vehiclerun?retryWrites=true&w=majority
EOF
```

### 6. Install Dependencies
```bash
npm install --production
```

### 7. Create PM2 Config
```bash
cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'bus-ticketing',
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
    error_file: '/var/log/bus-ticketing-error.log',
    out_file: '/var/log/bus-ticketing-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOF
```

### 8. Start Application
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /root
```

### 9. Configure Firewall
```bash
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8080/tcp
ufw --force enable
```

## Verify Setup

After setup, verify everything is working:

```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs bus-ticketing --lines 20

# Check ports
netstat -tlnp | grep -E ':(3000|8080)'

# Test HTTP endpoint
curl http://localhost:3000/health
```

You should see:
- `[HTTP] Express server running on port 3000`
- `[TCP] Server listening on 0.0.0.0:8080`
- `MongoDB Connected: ...`

## Troubleshooting

### If PM2 still not found after installation:
```bash
# Check npm global path
npm config get prefix

# Add to PATH (if needed)
export PATH=$PATH:/usr/local/bin
```

### If application fails to start:
```bash
# Check logs
pm2 logs bus-ticketing --err

# Check if .env file exists
cat /opt/bus-ticketing/.env

# Try running manually to see errors
cd /opt/bus-ticketing
node server.js
```

### If ports not listening:
```bash
# Check if app is running
pm2 status

# Check firewall
ufw status

# Check if ports are in use
netstat -tlnp | grep -E ':(3000|8080)'
```

