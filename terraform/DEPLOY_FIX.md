# Fix TCP Server Connection Issue

The TCP server was binding to `localhost` instead of `0.0.0.0`, which prevented external connections. This has been fixed in `tcp-server.js`.

## Steps to Deploy the Fix

### Option 1: If using GitHub auto-deployment

1. **Commit and push the fix:**
   ```bash
   git add tcp-server.js
   git commit -m "Fix TCP server to bind to 0.0.0.0 for external connections"
   git push origin main
   ```

2. **SSH into your server:**
   ```bash
   ssh root@67.207.90.123
   ```

3. **Pull the latest code and restart:**
   ```bash
   cd /opt/bus-ticketing
   git pull
   npm install --production
   pm2 restart bus-ticketing
   ```

4. **Verify the fix:**
   ```bash
   pm2 logs bus-ticketing --lines 20
   ```
   You should see: `[TCP] Server listening on 0.0.0.0:8080`

5. **Check if port is listening correctly:**
   ```bash
   netstat -tlnp | grep 8080
   ```
   Should show: `0.0.0.0:8080` (not `127.0.0.1:8080`)

### Option 2: Manual deployment

1. **SSH into your server:**
   ```bash
   ssh root@67.207.90.123
   ```

2. **Edit the file directly:**
   ```bash
   cd /opt/bus-ticketing
   nano tcp-server.js
   ```
   
   Find line 68 and change:
   ```javascript
   this.server.listen(this.port, () => {
   ```
   to:
   ```javascript
   this.server.listen(this.port, '0.0.0.0', () => {
   ```
   
   Also update line 69:
   ```javascript
   console.log(`[TCP] Server listening on 0.0.0.0:${this.port}`);
   ```

3. **Restart the application:**
   ```bash
   pm2 restart bus-ticketing
   ```

4. **Verify:**
   ```bash
   pm2 logs bus-ticketing --lines 20
   netstat -tlnp | grep 8080
   ```

## Verify the Fix

After deploying, test from your local machine:

```bash
node tests/test-tcp-client-deployed.js
```

You should now be able to connect successfully!

## Troubleshooting

If it still doesn't work:

1. **Check if the application is running:**
   ```bash
   ssh root@67.207.90.123
   pm2 status
   ```

2. **Check logs for errors:**
   ```bash
   pm2 logs bus-ticketing --lines 50
   ```

3. **Verify firewall rules:**
   - Go to DigitalOcean dashboard → Networking → Firewalls
   - Check that port 8080 is open for inbound traffic from `0.0.0.0/0`

4. **Check UFW firewall on server:**
   ```bash
   ssh root@67.207.90.123
   ufw status
   ufw allow 8080/tcp  # If not already allowed
   ```

5. **Test port connectivity:**
   ```bash
   # From your local machine
   telnet 67.207.90.123 8080
   # or
   nc -zv 67.207.90.123 8080
   ```

