# Deployment Guide

This project supports multiple deployment methods. Choose the one that best fits your needs.

## 🐳 Option 1: Docker Deployment (RECOMMENDED)

**Why Docker?**
- ✅ Consistent environment
- ✅ No dependency issues
- ✅ Easy updates
- ✅ Better resource management
- ✅ Automatic restarts
- ✅ Health checks

### Quick Start with Docker

1. **Build the image:**
   ```bash
   docker build -t bus-ticketing .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name bus-ticketing \
     --restart unless-stopped \
     -p 3000:3000 \
     -p 8080:8080 \
     -e PORT=3000 \
     -e TCP_PORT=8080 \
     -e NODE_ENV=production \
     -e DB_URL=your_mongodb_url \
     bus-ticketing
   ```

3. **Or use docker-compose:**
   ```bash
   # Create .env file with your variables
   DB_URL=your_mongodb_url docker-compose up -d
   ```

### Deploy to DigitalOcean with Docker

1. **Update Terraform to use Docker:**
   ```bash
   cd terraform
   # Edit main.tf to use user-data-docker.sh instead of user-data.sh
   ```

2. **Deploy:**
   ```bash
   terraform apply
   ```

## 🚀 Option 2: DigitalOcean App Platform (Easiest)

**Why App Platform?**
- ✅ Fully managed
- ✅ Automatic scaling
- ✅ Built-in CI/CD
- ✅ SSL certificates
- ✅ Zero server management

### Steps:

1. Go to DigitalOcean App Platform
2. Connect your GitHub repository
3. Configure:
   - Build command: `npm install`
   - Run command: `npm start`
   - Environment variables: PORT, TCP_PORT, DB_URL, NODE_ENV
4. Deploy!

**Note:** App Platform doesn't support raw TCP sockets (port 8080) well. Use Docker deployment for TCP support.

## 📦 Option 3: Improved Terraform (Current Method)

The current Terraform setup with improved user-data script.

### Deploy:

```bash
cd terraform
terraform apply
```

Wait 4-5 minutes for setup to complete.

## 🔄 Option 4: CI/CD with GitHub Actions

Automated deployment on every push to main branch.

### Setup:

1. Create `.github/workflows/deploy.yml`
2. Configure secrets in GitHub:
   - `DIGITALOCEAN_ACCESS_TOKEN`
   - `SSH_PRIVATE_KEY`
   - `DB_URL`
3. Push to main branch - automatic deployment!

## 📊 Comparison

| Method | Ease | Cost | Reliability | Best For |
|--------|------|------|-------------|----------|
| Docker | ⭐⭐⭐⭐ | $18/mo | ⭐⭐⭐⭐⭐ | Production |
| App Platform | ⭐⭐⭐⭐⭐ | $12-25/mo | ⭐⭐⭐⭐⭐ | Quick setup |
| Terraform | ⭐⭐⭐ | $18/mo | ⭐⭐⭐ | Full control |
| CI/CD | ⭐⭐⭐⭐ | $18/mo | ⭐⭐⭐⭐⭐ | Auto-deploy |

## 🎯 Recommended: Docker Deployment

For your use case, **Docker deployment is recommended** because:
- Handles TCP sockets properly
- More reliable than manual setup
- Easy to update
- Better resource management
- Consistent across environments

## Quick Commands

### Docker Commands:
```bash
# Build
docker build -t bus-ticketing .

# Run
docker run -d --name bus-ticketing -p 3000:3000 -p 8080:8080 --env-file .env bus-ticketing

# View logs
docker logs -f bus-ticketing

# Restart
docker restart bus-ticketing

# Stop
docker stop bus-ticketing

# Update
docker stop bus-ticketing
docker rm bus-ticketing
docker build -t bus-ticketing .
docker run -d --name bus-ticketing -p 3000:3000 -p 8080:8080 --env-file .env bus-ticketing
```

## Troubleshooting

### Docker container not starting:
```bash
docker logs bus-ticketing
docker ps -a
```

### Check container status:
```bash
docker ps
docker stats bus-ticketing
```

### Restart container:
```bash
docker restart bus-ticketing
```

