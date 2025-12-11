#!/bin/bash
# Manual setup after test success
# Run this on EMR cluster

echo "=========================================="
echo "Creating Service Management Scripts"
echo "=========================================="
echo ""

# Make sure we're in the right directory
cd ~/maurottito/speed_layer || exit 1

# Download the management scripts
cat > start_live_camera.sh << 'EOF'
#!/bin/bash
# Start live camera auto-update service

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE=~/maurottito/logs/parking_live_camera.log
PID_FILE=~/maurottito/logs/parking_live_camera.pid

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "⚠ Live camera service already running (PID: $PID)"
        exit 1
    fi
fi

echo "Starting live camera parking updates..."
echo "Camera: https://2-fss-2.streamhoster.com/pl_126/200612-1195858-1/playlist.m3u8"
echo "Log: $LOG_FILE"
echo ""

nohup python3 $SCRIPT_DIR/auto_update_live_camera.py > $LOG_FILE 2>&1 &
PID=$!
echo $PID > $PID_FILE

sleep 3

if ps -p $PID > /dev/null 2>&1; then
    echo "✓ Live camera service started (PID: $PID)"
    echo ""
    echo "Monitor with:"
    echo "  tail -f $LOG_FILE"
    echo ""
    echo "Stop with:"
    echo "  bash ~/maurottito/speed_layer/stop_live_camera.sh"
else
    echo "✗ Failed to start. Check log:"
    tail -20 $LOG_FILE
    rm -f $PID_FILE
    exit 1
fi
EOF

cat > stop_live_camera.sh << 'EOF'
#!/bin/bash
# Stop live camera service

PID_FILE=~/maurottito/logs/parking_live_camera.pid

if [ ! -f "$PID_FILE" ]; then
    echo "⚠ Live camera service not running"
    exit 1
fi

PID=$(cat "$PID_FILE")

if ! ps -p $PID > /dev/null 2>&1; then
    echo "⚠ Process not found (PID: $PID)"
    rm -f $PID_FILE
    exit 1
fi

echo "Stopping live camera service (PID: $PID)..."
kill $PID

for i in {1..5}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        echo "✓ Service stopped"
        rm -f $PID_FILE
        exit 0
    fi
    sleep 1
done

echo "Force stopping..."
kill -9 $PID 2>/dev/null
rm -f $PID_FILE
echo "✓ Service stopped (forced)"
EOF

cat > status_live_camera.sh << 'EOF'
#!/bin/bash
# Check live camera service status

PID_FILE=~/maurottito/logs/parking_live_camera.pid
LOG_FILE=~/maurottito/logs/parking_live_camera.log

echo "=========================================="
echo "Live Camera Service Status"
echo "=========================================="
echo ""

if [ ! -f "$PID_FILE" ]; then
    echo "Status: ⚠ NOT RUNNING"
    echo ""
    echo "Start with:"
    echo "  bash ~/maurottito/speed_layer/start_live_camera.sh"
    exit 1
fi

PID=$(cat "$PID_FILE")

if ps -p $PID > /dev/null 2>&1; then
    echo "Status: ✓ RUNNING"
    echo "PID: $PID"
    echo "Uptime: $(ps -p $PID -o etime= | tr -d ' ')"
    echo ""
    echo "Recent camera detections:"
    grep "Camera Analysis" $LOG_FILE 2>/dev/null | tail -5
    echo ""
    echo "Monitor live:"
    echo "  tail -f $LOG_FILE"
else
    echo "Status: ✗ STOPPED"
    rm -f $PID_FILE
    echo ""
    echo "Start with:"
    echo "  bash ~/maurottito/speed_layer/start_live_camera.sh"
fi
EOF

chmod +x start_live_camera.sh
chmod +x stop_live_camera.sh
chmod +x status_live_camera.sh

echo "✓ Created start_live_camera.sh"
echo "✓ Created stop_live_camera.sh"
echo "✓ Created status_live_camera.sh"
echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Start the service:"
echo "  bash ~/maurottito/speed_layer/start_live_camera.sh"
echo ""

