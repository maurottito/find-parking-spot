#!/bin/bash
# Stop and Start Fresh - Complete reset of the app

echo "🛑 Stopping maurottito_app..."
pm2 delete maurottito_app 2>/dev/null || echo "App not running"

echo ""
echo "🧹 Cleaning up..."
sleep 2

echo ""
echo "🚀 Starting fresh..."
cd /home/ec2-user/maurottito/parking_spot_app

pm2 start app.js --name maurottito_app -- 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070

echo ""
echo "💾 Saving PM2 configuration..."
pm2 save

echo ""
echo "⏳ Waiting for server to initialize..."
sleep 3

echo ""
echo "📊 Process status:"
pm2 status

echo ""
echo "📋 Recent logs:"
pm2 logs maurottito_app --lines 25 --nostream

echo ""
echo "✅ Done! Server started fresh."

