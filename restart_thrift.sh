#!/bin/bash
# Complete HBase Thrift troubleshooting and fix script

echo "=========================================="
echo "HBase Thrift Diagnostic & Fix"
echo "=========================================="
echo ""

# Step 1: Check what's on port 9090
echo "1. Checking port 9090..."
netstat -tlnp 2>/dev/null | grep :9090 || ss -tlnp 2>/dev/null | grep :9090
echo ""

# Step 2: Check Thrift processes
echo "2. Checking for Thrift processes..."
ps aux | grep -i thrift | grep -v grep
echo ""

# Step 3: Kill all existing Thrift processes
echo "3. Stopping all HBase Thrift processes..."
pkill -f "thrift" || echo "No processes to kill"
sleep 2
echo ""

# Step 4: Check Thrift logs
echo "4. Checking recent Thrift logs..."
if [ -f /tmp/hbase-thrift.log ]; then
    echo "Last 20 lines of /tmp/hbase-thrift.log:"
    tail -n 20 /tmp/hbase-thrift.log
else
    echo "No Thrift log found"
fi
echo ""

# Step 5: Start HBase Thrift with verbose logging
echo "5. Starting HBase Thrift server (verbose mode)..."
nohup hbase thrift start -p 9090 -v > /tmp/hbase-thrift-verbose.log 2>&1 &
THRIFT_PID=$!
echo "Started Thrift with PID: $THRIFT_PID"
echo $THRIFT_PID > /tmp/hbase-thrift.pid
echo "Waiting 10 seconds for Thrift to fully start..."
sleep 10
echo ""

# Step 6: Verify Thrift started
echo "6. Verifying Thrift is running..."
if ps -p $THRIFT_PID > /dev/null 2>&1; then
    echo "✓ Thrift process is running (PID: $THRIFT_PID)"
else
    echo "✗ Thrift process died! Check logs:"
    tail -n 50 /tmp/hbase-thrift-verbose.log
    exit 1
fi
echo ""

# Step 7: Check port is listening
echo "7. Checking if port 9090 is listening..."
netstat -tlnp 2>/dev/null | grep :9090 || ss -tlnp 2>/dev/null | grep :9090
if netstat -tlnp 2>/dev/null | grep -q :9090 || ss -tlnp 2>/dev/null | grep -q :9090; then
    echo "✓ Port 9090 is listening"
else
    echo "✗ Port 9090 is NOT listening"
    echo "Thrift log:"
    tail -n 50 /tmp/hbase-thrift-verbose.log
    exit 1
fi
echo ""

# Step 8: Test connection with telnet
echo "8. Testing connection to localhost:9090..."
timeout 3 bash -c 'exec 3<>/dev/tcp/localhost/9090 && echo "✓ Connection successful"' 2>/dev/null || echo "✗ Cannot connect"
echo ""

# Step 9: Show recent Thrift logs
echo "9. Recent Thrift startup logs:"
tail -n 30 /tmp/hbase-thrift-verbose.log
echo ""

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Restart the web application:"
echo "   cd ~/maurottito/parking_spot_app_deploy"
echo "   PID=\$(cat logs/parking_app_deploy.pid) && kill \$PID"
echo "   ./start_app.sh"
echo ""
echo "2. Wait 3 seconds then test:"
echo "   sleep 3"
echo "   curl http://localhost:3027/hbase-test"
echo "   curl -s http://localhost:3027/parking.html | head -100"
echo ""

