#!/bin/bash
# Quick Fix for OpenCV Import Error
# Run this on EMR cluster to fix the libGL.so.1 error

echo "=========================================="
echo "OpenCV Quick Fix"
echo "=========================================="
echo ""
echo "Problem: opencv-python requires GUI libraries"
echo "Solution: Switch to opencv-python-headless"
echo ""

echo "Step 1: Uninstalling opencv-python..."
pip3 uninstall -y opencv-python

echo ""
echo "Step 2: Installing opencv-python-headless..."
pip3 install --user opencv-python-headless

echo ""
echo "Step 3: Testing OpenCV import..."
python3 -c "import cv2; print(f'✓ OpenCV {cv2.__version__} imported successfully')"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Fix Complete!"
    echo "=========================================="
    echo ""
    echo "Now run:"
    echo "  python3 ~/maurottito/speed_layer/auto_update_live_camera.py --test"
else
    echo ""
    echo "✗ Still having issues. Check error above."
fi

