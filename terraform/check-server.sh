#!/bin/bash

# Script to check server status and troubleshoot connection issues
# Usage: Run this on your local machine or SSH into the server

SERVER_IP="67.207.90.123"

echo "=========================================="
echo "Server Status Check"
echo "=========================================="
echo ""

# Check if server is reachable
echo "1. Checking if server is reachable..."
if ping -c 1 $SERVER_IP &> /dev/null; then
    echo "   ✓ Server is reachable"
else
    echo "   ✗ Server is not reachable"
    exit 1
fi
echo ""

# Check if port 3000 (HTTP) is open
echo "2. Checking HTTP port (3000)..."
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$SERVER_IP/3000" 2>/dev/null; then
    echo "   ✓ Port 3000 is open"
    echo "   Testing HTTP endpoint..."
    HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$SERVER_IP:3000/health" 2>/dev/null)
    if [ "$HTTP_RESPONSE" = "200" ]; then
        echo "   ✓ HTTP server is responding"
    else
        echo "   ⚠ Port 3000 is open but server returned: $HTTP_RESPONSE"
    fi
else
    echo "   ✗ Port 3000 is closed or filtered"
fi
echo ""

# Check if port 8080 (TCP) is open
echo "3. Checking TCP port (8080)..."
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$SERVER_IP/8080" 2>/dev/null; then
    echo "   ✓ Port 8080 is open"
else
    echo "   ✗ Port 8080 is closed or filtered"
    echo "   This is likely the issue!"
fi
echo ""

# Instructions for SSH
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "SSH into the server:"
echo "  ssh root@$SERVER_IP"
echo ""
echo "Then run these commands to check:"
echo ""
echo "1. Check if application is running:"
echo "   pm2 status"
echo ""
echo "2. Check application logs:"
echo "   pm2 logs bus-ticketing"
echo ""
echo "3. Check if ports are listening:"
echo "   netstat -tlnp | grep -E ':(3000|8080)'"
echo "   or"
echo "   ss -tlnp | grep -E ':(3000|8080)'"
echo ""
echo "4. Check firewall status:"
echo "   ufw status"
echo ""
echo "5. Check if TCP server is bound to 0.0.0.0:"
echo "   netstat -tlnp | grep 8080"
echo "   (Should show 0.0.0.0:8080, not 127.0.0.1:8080)"
echo ""

