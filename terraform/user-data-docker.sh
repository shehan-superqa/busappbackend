#!/bin/bash

# Docker-based deployment script
exec > >(tee -a /var/log/user-data.log) 2>&1
set -x

export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "=========================================="
echo "Starting Docker-based deployment - $(date)"
echo "=========================================="

# Update system
echo "[1/6] Updating system..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "[2/6] Installing Docker..."
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
systemctl start docker
systemctl enable docker

# Install Git
echo "[3/6] Installing Git..."
apt-get install -y git

# Clone repository
echo "[4/6] Cloning repository..."
mkdir -p /opt/${project_name}
cd /opt/${project_name}

if [ -n "${github_repo}" ]; then
  git clone -b ${github_branch} ${github_repo} . || {
    echo "Clone failed, retrying..."
    sleep 5
    git clone -b ${github_branch} ${github_repo} .
  }
  
  # Move server code if in subdirectory
  if [ -d "server" ] && [ -f "server/package.json" ]; then
    mv server/* .
    mv server/.* . 2>/dev/null || true
    rmdir server 2>/dev/null || true
  fi
else
  echo "ERROR: GitHub repo not provided!"
  exit 1
fi

# Create .env file
echo "[5/6] Creating .env file..."
cat > .env <<EOF
PORT=${port}
TCP_PORT=${tcp_port}
NODE_ENV=${node_env}
DB_URL=${db_url}
EOF

# Build and run Docker container
echo "[6/6] Building and starting Docker container..."
docker build -t ${project_name}:latest .

# Stop and remove existing container if any
docker stop ${project_name} 2>/dev/null || true
docker rm ${project_name} 2>/dev/null || true

# Run container
docker run -d \
  --name ${project_name} \
  --restart unless-stopped \
  -p ${port}:3000 \
  -p ${tcp_port}:8080 \
  --env-file .env \
  ${project_name}:latest

# Configure firewall
echo "Configuring firewall..."
ufw --force allow 22/tcp
ufw --force allow ${port}/tcp
ufw --force allow ${tcp_port}/tcp
ufw --force enable

# Wait for container to start
sleep 10

# Final status
echo ""
echo "=========================================="
echo "Deployment Complete - $(date)"
echo "=========================================="
echo "Docker version: $(docker --version)"
echo ""
echo "Container status:"
docker ps | grep ${project_name} || echo "Container not running!"
echo ""
echo "Container logs:"
docker logs ${project_name} --tail 20 || echo "No logs available"
echo ""
echo "To view logs: docker logs -f ${project_name}"
echo "To restart: docker restart ${project_name}"
echo "=========================================="

