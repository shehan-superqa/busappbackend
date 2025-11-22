# Terraform Deployment for DigitalOcean

This directory contains Terraform configuration files to deploy the contactless bus ticketing server to DigitalOcean.

## Prerequisites

1. **DigitalOcean Account**: Sign up at https://www.digitalocean.com
2. **DigitalOcean API Token**: 
   - Go to https://cloud.digitalocean.com/account/api/tokens
   - Generate a new token with read/write permissions
3. **Terraform**: Install from https://www.terraform.io/downloads
4. **SSH Key**: You need an SSH key to access the server

## Setup

1. **Install Terraform** (if not already installed):
   ```bash
   # Windows (using Chocolatey)
   choco install terraform
   
   # macOS (using Homebrew)
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Get your SSH key fingerprint**:
   ```bash
   ssh-keygen -lf ~/.ssh/id_rsa.pub
   ```
   Or add your SSH key in DigitalOcean dashboard and copy the fingerprint.

3. **Configure variables**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` and fill in your values:
   - `do_token`: Your DigitalOcean API token
   - `ssh_key_fingerprints`: Your SSH key fingerprint(s)
   - `db_url`: MongoDB connection string (use MongoDB Atlas for managed DB)

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the deployment plan**:
   ```bash
   terraform plan
   ```

6. **Deploy**:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

7. **Get connection details**:
   ```bash
   terraform output
   ```

## Configuration Options

### Droplet Sizes
- `s-1vcpu-1gb` - $6/month (recommended for testing)
- `s-1vcpu-2gb` - $12/month
- `s-2vcpu-2gb` - $18/month

### Regions
Popular options:
- `nyc1`, `nyc3` - New York
- `sfo3` - San Francisco
- `sgp1` - Singapore
- `lon1` - London
- `fra1` - Frankfurt

## Deployment Methods

### Method 1: GitHub Auto-Deployment (Recommended)
1. Push your code to GitHub
2. Set `github_repo` and `github_branch` in `terraform.tfvars`
3. The server will automatically clone and deploy your code

### Method 2: Manual Deployment
1. Deploy the infrastructure with Terraform
2. SSH into the server:
   ```bash
   ssh root@<droplet-ip>
   ```
3. Upload your code to `/opt/bus-ticketing/`
4. Run:
   ```bash
   cd /opt/bus-ticketing
   npm install --production
   pm2 restart bus-ticketing
   ```

## Accessing Your Server

After deployment, you'll get:
- **HTTP API**: `http://<droplet-ip>:3000`
- **TCP Socket**: `<droplet-ip>:8080`
- **SSH**: `ssh root@<droplet-ip>`

## Managing the Application

SSH into the server and use PM2:

```bash
# Check status
pm2 status

# View logs
pm2 logs bus-ticketing

# Restart
pm2 restart bus-ticketing

# Stop
pm2 stop bus-ticketing

# Monitor
pm2 monit
```

## Updating the Application

### If using GitHub:
1. Push changes to your repository
2. SSH into server:
   ```bash
   ssh root@<droplet-ip>
   cd /opt/bus-ticketing
   git pull
   npm install --production
   pm2 restart bus-ticketing
   ```

### Manual update:
1. Upload new files to `/opt/bus-ticketing/`
2. SSH and run:
   ```bash
   cd /opt/bus-ticketing
   npm install --production
   pm2 restart bus-ticketing
   ```

## Destroying Resources

To tear down everything:
```bash
terraform destroy
```

## Troubleshooting

### Can't SSH into server
- Check firewall rules in DigitalOcean dashboard
- Verify SSH key is added correctly
- Check `allowed_ssh_ips` in terraform.tfvars

### Application not starting
- SSH into server and check logs: `pm2 logs bus-ticketing`
- Verify `.env` file exists and has correct values
- Check MongoDB connection: `mongosh <your-connection-string>`

### Ports not accessible
- Verify firewall rules in DigitalOcean dashboard
- Check UFW on server: `ufw status`
- Verify application is running: `pm2 status`

## Cost Estimation

- Droplet (s-1vcpu-1gb): $6/month
- MongoDB Atlas (free tier): $0/month
- **Total: ~$6/month**

## Security Recommendations

1. **Change SSH access**: Update `allowed_ssh_ips` to your IP only
2. **Use MongoDB Atlas**: Don't expose MongoDB to the internet
3. **Enable HTTPS**: Use Nginx with Let's Encrypt (add to user-data.sh)
4. **Regular updates**: Keep system and dependencies updated
5. **Firewall**: DigitalOcean firewall is already configured

## Next Steps

1. Set up domain name and SSL certificate
2. Configure monitoring (DigitalOcean monitoring is free)
3. Set up automated backups
4. Configure log rotation
5. Set up CI/CD pipeline

