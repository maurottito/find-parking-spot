#!/bin/bash
# Troubleshooting script for parking table issues

echo "🔍 Troubleshooting Parking Table on EC2..."
echo ""

# Test if tables exist in HBase
echo "1️⃣ Checking if HBase tables exist..."
echo "----------------------------------------"

# Check parking locations table
echo "Checking maurottito_parking_locations table:"
echo "scan 'maurottito_parking_locations', {LIMIT => 5}" | hbase shell -n 2>/dev/null | head -30

echo ""
echo "Checking maurottito_parking_availability table:"
echo "scan 'maurottito_parking_availability', {LIMIT => 5}" | hbase shell -n 2>/dev/null | head -30

echo ""
echo "2️⃣ Testing parking.html endpoint..."
echo "----------------------------------------"
curl -s http://localhost:3027/parking.html | head -50

echo ""
echo "3️⃣ Checking for errors in server logs..."
echo "----------------------------------------"
pm2 logs maurottito_app --lines 20 --nostream 2>/dev/null || tail -20 server.log 2>/dev/null

echo ""
echo "4️⃣ Testing HBase connection..."
echo "----------------------------------------"
curl -v https://ec2-34-230-47-10.compute-1.amazonaws.com:8070 2>&1 | head -20

echo ""
echo "✅ Troubleshooting complete!"
echo ""
echo "Common issues:"
echo "- If tables don't exist: Create them using HBase shell"
echo "- If HBase connection fails: Check HBase server is running"
echo "- If data parsing fails: Check data format in HBase"

