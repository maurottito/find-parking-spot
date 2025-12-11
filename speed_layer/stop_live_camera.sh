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

