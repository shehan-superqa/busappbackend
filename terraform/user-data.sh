#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

# Install Git
apt-get install -y git

# Install Nginx (optional, for reverse proxy)
apt-get install -y nginx

# Create application directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Clone repository if GitHub repo is provided
if [ -n "${github_repo}" ]; then
  git clone -b ${github_branch} ${github_repo} .
else
  # Create a placeholder - you'll need to upload your code manually
  echo "GitHub repo not provided. Please upload your code manually to /opt/${project_name}"
fi

# Create .env file
cat > /opt/${project_name}/.env <<EOF
PORT=${port}
TCP_PORT=${tcp_port}
NODE_ENV=${node_env}
DB_URL=${db_url}
EOF

# Install dependencies
if [ -f /opt/${project_name}/package.json ]; then
  cd /opt/${project_name}
  npm install --production
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
    max_memory_restart: '500M',
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
  cd /opt/${project_name}
  pm2 start ecosystem.config.js
  pm2 save
  pm2 startup systemd -u root --hp /root
fi

# Configure Nginx as reverse proxy (optional)
if [ -n "${domain_name}" ]; then
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
ufw allow 22/tcp
ufw allow ${port}/tcp
ufw allow ${tcp_port}/tcp
ufw --force enable

echo "Setup completed!"

