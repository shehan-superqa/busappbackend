# Redeploy Server with TCP Fix

Follow these steps to redeploy your server with the TCP server fix (binding to 0.0.0.0).

## Step 1: Push Changes to GitHub

Since your Terraform is configured to auto-deploy from GitHub, you need to push the fix first:

```bash
# From your server directory
git add tcp-server.js
git commit -m "Fix TCP server to bind to 0.0.0.0 for external connections"
git push origin main
```

## Step 2: Deploy with Terraform

1. **Navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform (if needed):**
   ```bash
   terraform init
   ```

3. **Review the deployment plan:**
   ```bash
   terraform plan
   ```

4. **Deploy the new droplet:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

5. **Wait 2-3 minutes** for the server to:
   - Create the droplet
   - Install Node.js and dependencies
   - Clone your GitHub repository
   - Install npm packages
   - Start the application with PM2

## Step 3: Get Your New Server IP

After deployment completes:

```bash
terraform output
```

This will show:
- New droplet IP address
- HTTP API URL
- TCP endpoint
- SSH command

## Step 4: Update Test File

Update your test file with the new IP address:

```bash
# Edit tests/test-tcp-client-deployed.js
# Change HOST to the new IP from terraform output
```

Or run:
```bash
terraform output droplet_ip
```

## Step 5: Test the Connection

1. **Test HTTP endpoint:**
   ```bash
   curl http://<new-ip>:3000/health
   ```

2. **Test TCP connection:**
   ```bash
   node tests/test-tcp-client-deployed.js
   ```
   (Make sure to update the IP in the test file first)

## Step 6: Verify Server Status

SSH into the new server:

```bash
ssh root@<new-ip>
```

Check application status:
```bash
pm2 status
pm2 logs bus-ticketing --lines 30
```

You should see:
- `[HTTP] Express server running on port 3000`
- `[TCP] Server listening on 0.0.0.0:8080` ← This confirms the fix!

Verify port binding:
```bash
netstat -tlnp | grep 8080
```

Should show: `0.0.0.0:8080` (not `127.0.0.1:8080`)

## Troubleshooting

If the TCP connection still doesn't work:

1. **Check if application started:**
   ```bash
   ssh root@<new-ip>
   pm2 logs bus-ticketing
   ```

2. **Check firewall:**
   - DigitalOcean dashboard → Networking → Firewalls
   - Verify port 8080 is open

3. **Check UFW on server:**
   ```bash
   ssh root@<new-ip>
   ufw status
   ```

4. **Verify code was pulled:**
   ```bash
   ssh root@<new-ip>
   cd /opt/bus-ticketing
   grep -A 2 "server.listen" tcp-server.js
   ```
   Should show: `this.server.listen(this.port, '0.0.0.0', () => {`

## Cost

- Droplet: $4/month (s-1vcpu-512mb-10gb)
- MongoDB Atlas: $0/month (free tier)
- **Total: $4/month**

