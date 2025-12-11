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

