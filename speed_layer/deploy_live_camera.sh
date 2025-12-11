#!/bin/bash
# Deploy Live Camera Auto-Update Service

echo "=========================================="
echo "Live Camera Auto-Update - Deployment"
echo "=========================================="
echo ""
echo "This will use REAL camera feed from:"
echo "https://2-fss-2.streamhoster.com/pl_126/200612-1195858-1/playlist.m3u8"
echo ""

# Check location
if [[ ! -f /usr/bin/hbase ]]; then
    echo "⚠ Warning: Should be run on EMR cluster"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Installing Python dependencies..."
echo ""

# Install happybase
if ! python3 -c "import happybase" 2>/dev/null; then
    echo "Installing happybase..."
    pip3 install --user happybase
    echo "✓ happybase installed"
else
    echo "✓ happybase already installed"
fi

# Install opencv-python-headless (no GUI dependencies)
if ! python3 -c "import cv2" 2>/dev/null; then
    echo "Installing opencv-python-headless (no GUI required)..."
    # Uninstall regular opencv if present
    pip3 uninstall -y opencv-python 2>/dev/null || true
    # Install headless version
    pip3 install --user opencv-python-headless
    echo "✓ opencv-python-headless installed"
else
    # Check if it's the headless version
    if pip3 list --user | grep -q "opencv-python-headless"; then
        echo "✓ opencv-python-headless already installed"
        python3 -c "import cv2; print(f'   OpenCV version: {cv2.__version__}')"
    else
        echo "Switching to opencv-python-headless..."
        pip3 uninstall -y opencv-python
        pip3 install --user opencv-python-headless
        echo "✓ opencv-python-headless installed"
    fi
fi

# Install numpy (usually comes with opencv)
if ! python3 -c "import numpy" 2>/dev/null; then
    echo "Installing numpy..."
    pip3 install --user numpy
    echo "✓ numpy installed"
else
    echo "✓ numpy already installed"
fi

echo ""
echo "Step 2: Creating directories..."
mkdir -p ~/maurottito/speed_layer
mkdir -p ~/maurottito/logs
echo "✓ Directories created"

echo ""
echo "Step 3: Checking script..."
if [[ -f ~/maurottito/speed_layer/auto_update_live_camera.py ]]; then
    chmod +x ~/maurottito/speed_layer/auto_update_live_camera.py
    echo "✓ Script ready: ~/maurottito/speed_layer/auto_update_live_camera.py"
else
    echo "⚠ Script not found. Upload via IntelliJ deployment first."
    exit 1
fi

echo ""
echo "Step 4: Testing camera connection and car detection..."
python3 ~/maurottito/speed_layer/auto_update_live_camera.py --test

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Camera test successful!"
else
    echo ""
    echo "✗ Camera test failed"
    echo "Check the error messages above"
    exit 1
fi

echo ""
echo "Step 5: Creating service management scripts..."

# Start script
cat > ~/maurottito/speed_layer/start_live_camera.sh << 'EOF'
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

chmod +x ~/maurottito/speed_layer/start_live_camera.sh
echo "✓ Created start_live_camera.sh"

# Stop script
cat > ~/maurottito/speed_layer/stop_live_camera.sh << 'EOF'
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

chmod +x ~/maurottito/speed_layer/stop_live_camera.sh
echo "��� Created stop_live_camera.sh"

# Status script
cat > ~/maurottito/speed_layer/status_live_camera.sh << 'EOF'
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
    grep "Camera Analysis" $LOG_FILE | tail -5
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

chmod +x ~/maurottito/speed_layer/status_live_camera.sh
echo "✓ Created status_live_camera.sh"

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "📹 Live Camera Feed:"
echo "   https://2-fss-2.streamhoster.com/pl_126/200612-1195858-1/playlist.m3u8"
echo ""
echo "🚀 Start the service:"
echo "   bash ~/maurottito/speed_layer/start_live_camera.sh"
echo ""
echo "📊 Check status:"
echo "   bash ~/maurottito/speed_layer/status_live_camera.sh"
echo ""
echo "📝 View live updates:"
echo "   tail -f ~/maurottito/logs/parking_live_camera.log"
echo ""
echo "🛑 Stop the service:"
echo "   bash ~/maurottito/speed_layer/stop_live_camera.sh"
echo ""

