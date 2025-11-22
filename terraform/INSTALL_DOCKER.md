# Manual Docker Installation and Setup

If the automated setup didn't work, follow these steps manually:

## Step 1: Install Docker

```bash
# Update system
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
apt-get update

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify installation
docker --version
docker ps
```

## Step 2: Install Git

```bash
apt-get install -y git
```

## Step 3: Clone Repository

```bash
mkdir -p /opt/bus-ticketing
cd /opt/bus-ticketing
git clone -b main https://github.com/shehan-superqa/busappbackend.git .

# If server code is in 'server' subdirectory
if [ -d "server" ] && [ -f "server/package.json" ]; then
    mv server/* .
    mv server/.* . 2>/dev/null || true
    rmdir server 2>/dev/null || true
fi
```

## Step 4: Create .env File

```bash
cat > /opt/bus-ticketing/.env <<EOF
PORT=3000
TCP_PORT=8080
NODE_ENV=production
DB_URL=mongodb+srv://shehan_db_user:gMLmZua0getxorb5@cluster0.q13ia75.mongodb.net/vehiclerun?retryWrites=true&w=majority
EOF
```

## Step 5: Build Docker Image

```bash
cd /opt/bus-ticketing
docker build -t bus-ticketing:latest .
```

## Step 6: Run Docker Container

```bash
# Stop and remove existing container if any
docker stop bus-ticketing 2>/dev/null || true
docker rm bus-ticketing 2>/dev/null || true

# Run the container
docker run -d \
  --name bus-ticketing \
  --restart unless-stopped \
  -p 3000:3000 \
  -p 8080:8080 \
  --env-file .env \
  bus-ticketing:latest
```

## Step 7: Verify

```bash
# Check container status
docker ps

# View logs
docker logs bus-ticketing

# Test HTTP endpoint
curl http://localhost:3000/health
```

## Step 8: Configure Firewall

```bash
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8080/tcp
ufw --force enable
```

## Useful Docker Commands

```bash
# View logs
docker logs -f bus-ticketing

# Restart container
docker restart bus-ticketing

# Stop container
docker stop bus-ticketing

# Start container
docker start bus-ticketing

# View container stats
docker stats bus-ticketing

# Update application (rebuild and restart)
cd /opt/bus-ticketing
git pull
docker stop bus-ticketing
docker rm bus-ticketing
docker build -t bus-ticketing:latest .
docker run -d --name bus-ticketing --restart unless-stopped -p 3000:3000 -p 8080:8080 --env-file .env bus-ticketing:latest
```

