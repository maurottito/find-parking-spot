#!/bin/bash
# Browser access troubleshooting script

echo "=========================================="
echo "Web Server Browser Access Diagnostics"
echo "=========================================="
echo ""

echo "1. Checking if web server is running..."
PID=$(cat ~/maurottito/parking_spot_app_deploy/logs/parking_app_deploy.pid 2>/dev/null)
if [ -n "$PID" ] && ps -p $PID > /dev/null 2>&1; then
    echo "✓ Web server is running (PID: $PID)"
else
    echo "✗ Web server is NOT running"
    exit 1
fi

echo ""
echo "2. Checking if port 3027 is listening..."
if netstat -tlnp 2>/dev/null | grep :3027 || ss -tlnp 2>/dev/null | grep :3027; then
    echo "✓ Port 3027 is listening"
else
    echo "✗ Port 3027 is NOT listening"
    exit 1
fi

echo ""
echo "3. Testing localhost access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3027/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Localhost access works (HTTP $HTTP_CODE)"
else
    echo "✗ Localhost access failed (HTTP $HTTP_CODE)"
fi

echo ""
echo "4. Getting server's public IP..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
if [ -n "$PUBLIC_IP" ]; then
    echo "✓ Public IP: $PUBLIC_IP"
else
    echo "⚠ No public IP found - instance may not have public IP assigned"
fi

echo ""
echo "5. Checking firewall/iptables..."
if command -v iptables &> /dev/null; then
    IPTABLES_RULES=$(sudo iptables -L -n 2>/dev/null | grep 3027 || echo "No rules for 3027")
    echo "Iptables rules for port 3027:"
    echo "$IPTABLES_RULES"
else
    echo "⚠ iptables not available"
fi

echo ""
echo "6. Testing if server responds on all interfaces..."
curl -s -o /dev/null -w "0.0.0.0:3027 - HTTP %{http_code}\n" http://0.0.0.0:3027/health 2>/dev/null || echo "Cannot connect to 0.0.0.0:3027"

echo ""
echo "7. Checking what interface the server is bound to..."
netstat -tlnp 2>/dev/null | grep :3027 || ss -tlnp 2>/dev/null | grep :3027

echo ""
echo "=========================================="
echo "BROWSER ACCESS URLs TO TRY:"
echo "=========================================="
echo ""
if [ -n "$PUBLIC_IP" ]; then
    echo "Using Public IP:"
    echo "  http://$PUBLIC_IP:3027/home.html"
    echo ""
fi
echo "Using DNS hostname:"
echo "  http://ec2-52-20-203-80.compute-1.amazonaws.com:3027/home.html"
echo ""
echo "=========================================="
echo "NEXT STEPS:"
echo "=========================================="
echo ""
echo "If you get connection timeout/refused in browser:"
echo "1. Check AWS Security Group allows inbound TCP port 3027"
echo "2. Verify the source IP/CIDR in the security group rule"
echo "3. Try from different network if your IP changed"
echo ""
echo "To check from external host, run:"
echo "  telnet ec2-52-20-203-80.compute-1.amazonaws.com 3027"
echo "  (or) nc -zv ec2-52-20-203-80.compute-1.amazonaws.com 3027"
echo ""

