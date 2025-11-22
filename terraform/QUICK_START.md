# Quick Start: Deploy to DigitalOcean (Minimum Cost - $4/month)

This guide will help you deploy your contactless bus ticketing server to DigitalOcean using the **lowest cost configuration** ($4/month).

## Prerequisites

1. **DigitalOcean Account**: Sign up at https://www.digitalocean.com (get $200 free credit with referral)
2. **DigitalOcean API Token**: 
   - Go to https://cloud.digitalocean.com/account/api/tokens
   - Click "Generate New Token"
   - Give it a name (e.g., "terraform-deploy")
   - Select "Write" scope
   - Copy the token (you won't see it again!)
3. **SSH Key**: You need an SSH key to access the server
   - If you don't have one: `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`
   - Get fingerprint: `ssh-keygen -lf ~/.ssh/id_rsa.pub`
4. **Terraform**: Install from https://www.terraform.io/downloads
   - Windows: `choco install terraform`
   - macOS: `brew install terraform`
   - Linux: Download from terraform.io

## Step 1: Configure Terraform

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   ```hcl
   # Required: Your DigitalOcean API token
   do_token = "your-digitalocean-api-token-here"
   
   # Required: Your SSH key fingerprint
   ssh_key_fingerprints = [
     "your-ssh-key-fingerprint-here"
   ]
   
   # Required: MongoDB connection string
   # Use MongoDB Atlas (free tier) for best results
   db_url = "mongodb+srv://username:password@cluster.mongodb.net/busticketing?retryWrites=true&w=majority"
   
   # Optional: GitHub repository for auto-deployment
   github_repo = "https://github.com/yourusername/yourrepo.git"
   github_branch = "main"
   
   # Optional: Domain name (leave empty if not using)
   domain_name = ""
   
   # Droplet configuration (already set to minimum cost)
   droplet_size = "s-1vcpu-512mb-10gb"  # $4/month
   droplet_region = "nyc1"  # Choose closest to you
   ```

## Step 2: Set Up MongoDB (Free)

1. Go to https://www.mongodb.com/cloud/atlas
2. Sign up for free tier (M0 - Free Forever)
3. Create a cluster (choose closest region)
4. Create database user
5. Whitelist IP: `0.0.0.0/0` (or your droplet IP after creation)
6. Get connection string and add to `terraform.tfvars`

## Step 3: Deploy

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the deployment plan:
   ```bash
   terraform plan
   ```

3. Deploy (this will create the droplet):
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

4. Wait 2-3 minutes for the server to set up automatically.

## Step 4: Get Your Server Details

After deployment, get your server information:
```bash
terraform output
```

You'll see:
- **Droplet IP**: Your server's public IP address
- **HTTP API**: `http://<ip>:3000`
- **TCP Socket**: `<ip>:8080`
- **SSH Command**: `ssh root@<ip>`

## Step 5: Verify Deployment

1. Test the HTTP API:
   ```bash
   curl http://<droplet-ip>:3000/health
   ```

2. SSH into the server:
   ```bash
   ssh root@<droplet-ip>
   ```

3. Check application status:
   ```bash
   pm2 status
   pm2 logs bus-ticketing
   ```

## Cost Breakdown

- **Droplet**: $4/month (s-1vcpu-512mb-10gb)
- **MongoDB Atlas**: $0/month (free tier)
- **Total**: **$4/month** 💰

## Managing Your Server

### View Logs
```bash
ssh root@<droplet-ip>
pm2 logs bus-ticketing
```

### Restart Application
```bash
ssh root@<droplet-ip>
pm2 restart bus-ticketing
```

### Update Application (if using GitHub)
```bash
ssh root@<droplet-ip>
cd /opt/bus-ticketing
git pull
npm install --production
pm2 restart bus-ticketing
```

### Check System Resources
```bash
ssh root@<droplet-ip>
free -h  # Check memory
df -h    # Check disk space
top      # Check CPU usage
```

## Troubleshooting

### Application not starting
```bash
ssh root@<droplet-ip>
pm2 logs bus-ticketing --lines 50
# Check for errors in the logs
```

### Out of memory
If you see memory issues, upgrade to `s-1vcpu-1gb` ($6/month):
1. Edit `terraform.tfvars`: `droplet_size = "s-1vcpu-1gb"`
2. Run: `terraform apply`

### Can't connect to server
- Check firewall: DigitalOcean dashboard → Networking → Firewalls
- Verify SSH key is correct
- Check if droplet is running in DigitalOcean dashboard

## Security Recommendations

1. **Restrict SSH access** (edit `terraform.tfvars`):
   ```hcl
   allowed_ssh_ips = ["your.ip.address.here/32"]
   ```

2. **Use MongoDB Atlas** instead of self-hosting (already recommended)

3. **Set up domain and SSL** (optional, requires domain):
   - Add domain to `terraform.tfvars`
   - Install Certbot for Let's Encrypt SSL

## Destroying Resources

To stop all charges and delete everything:
```bash
terraform destroy
```

## Next Steps

1. Set up a domain name (optional)
2. Configure SSL/HTTPS with Let's Encrypt
3. Set up monitoring and alerts
4. Configure automated backups
5. Set up CI/CD pipeline

## Support

- DigitalOcean Docs: https://docs.digitalocean.com
- Terraform Docs: https://www.terraform.io/docs
- MongoDB Atlas Docs: https://docs.atlas.mongodb.com

