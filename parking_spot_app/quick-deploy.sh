#!/bin/bash
# Quick deploy script - Upload app.js and restart server

echo "🚀 Deploying updated app.js to EC2..."
echo ""

# Upload app.js via SCP
echo "📤 Uploading app.js..."
scp app.js ec2-52-20-203-80.compute-1.amazonaws.com:/home/ec2-user/maurottito/parking_spot_app/app.js

if [ $? -eq 0 ]; then
    echo "✅ Upload successful!"
    echo ""

    # Restart PM2 process
    echo "🔄 Restarting server..."
    ssh ec2-52-20-203-80.compute-1.amazonaws.com 'cd /home/ec2-user/maurottito/parking_spot_app && pm2 restart maurottito_app'

    echo ""
    echo "⏳ Waiting 3 seconds for server to start..."
    sleep 3

    echo ""
    echo "📋 Checking logs..."
    ssh ec2-52-20-203-80.compute-1.amazonaws.com 'pm2 logs maurottito_app --lines 20 --nostream'

    echo ""
    echo "✅ Deployment complete!"
else
    echo "❌ Upload failed!"
    exit 1
fi

