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

