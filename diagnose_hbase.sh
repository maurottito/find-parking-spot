#!/bin/bash
# HBase Thrift Diagnostic and Fix Script
# Run this on EC2 to diagnose and fix HBase connection issues

echo "=========================================="
echo "HBase Thrift Connection Diagnostic"
echo "=========================================="
echo ""

# Step 1: Check if HBase Thrift is running
echo "1. Checking if HBase Thrift is running on port 9090..."
THRIFT_RUNNING=$(netstat -tlnp 2>/dev/null | grep :9090 || ss -tlnp 2>/dev/null | grep :9090)
if [ -n "$THRIFT_RUNNING" ]; then
    echo "✓ Port 9090 is listening"
    echo "$THRIFT_RUNNING"
else
    echo "✗ Port 9090 is NOT listening - HBase Thrift is not running!"
    echo ""
    echo "Starting HBase Thrift server..."
    hbase thrift start -p 9090 > /tmp/hbase-thrift.log 2>&1 &
    THRIFT_PID=$!
    echo $THRIFT_PID > /tmp/hbase-thrift.pid
    echo "Started HBase Thrift with PID: $THRIFT_PID"
    sleep 5
fi

echo ""

# Step 2: Check Thrift logs for errors
echo "2. Checking HBase Thrift logs..."
if [ -f /tmp/hbase-thrift.log ]; then
    echo "Last 20 lines of Thrift log:"
    tail -n 20 /tmp/hbase-thrift.log
else
    echo "No Thrift log found at /tmp/hbase-thrift.log"
fi

echo ""

# Step 3: Test Thrift connection with telnet/nc
echo "3. Testing connection to localhost:9090..."
if command -v nc &> /dev/null; then
    timeout 2 nc -zv localhost 9090 2>&1 && echo "✓ Connection successful" || echo "✗ Connection failed"
elif command -v telnet &> /dev/null; then
    timeout 2 telnet localhost 9090 2>&1 | head -5
else
    echo "Neither nc nor telnet available for testing"
fi

echo ""

# Step 4: Check if tables exist
echo "4. Verifying HBase tables exist..."
echo "list" | hbase shell -n 2>/dev/null | grep -E "maurottito_parking" && echo "✓ Tables found" || echo "✗ Tables not found"

echo ""

# Step 5: Try alternative Thrift REST API
echo "5. Testing HBase REST API (alternative to Thrift)..."
if curl -s http://localhost:8080/version 2>/dev/null | grep -q "version"; then
    echo "✓ HBase REST API is available on port 8080"
else
    echo "✗ HBase REST API not available"
fi

echo ""

# Step 6: Check what's actually listening on 9090
echo "6. Detailed check of port 9090..."
lsof -i :9090 2>/dev/null || ss -tlnp | grep 9090

echo ""
echo "=========================================="
echo "Recommended Actions:"
echo "=========================================="
echo ""

if [ -n "$THRIFT_RUNNING" ]; then
    echo "1. HBase Thrift appears to be running"
    echo "2. The issue might be with the Node.js HBase client library"
    echo "3. Try restarting the web app with updated code"
    echo ""
    echo "Run these commands:"
    echo "  cd ~/maurottito/parking_spot_app_deploy"
    echo "  # Copy updated app.js from repository"
    echo "  # Then restart:"
    echo "  PID=\$(cat logs/parking_app_deploy.pid) && kill \$PID"
    echo "  ./start_app.sh"
    echo "  sleep 2"
    echo "  curl http://localhost:3027/hbase-test"
else
    echo "1. HBase Thrift was not running - we started it"
    echo "2. Wait 10 seconds for it to fully start"
    echo "3. Then restart the web app"
    echo ""
    echo "Run these commands:"
    echo "  sleep 10"
    echo "  cd ~/maurottito/parking_spot_app_deploy"
    echo "  PID=\$(cat logs/parking_app_deploy.pid) && kill \$PID"
    echo "  ./start_app.sh"
fi

echo ""
echo "=========================================="
echo "Alternative: Use HBase REST instead of Thrift"
echo "=========================================="
echo ""
echo "If Thrift continues to fail, we can modify the app to use REST API"
echo "This would require changing the Node.js code to use HTTP requests"
echo ""

