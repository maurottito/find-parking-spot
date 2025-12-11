#!/bin/bash
# HBase Data Verification Script for EMR
# Run this on your EMR master node to check your parking app tables

echo "============================================"
echo "HBase Tables Verification for Parking App"
echo "============================================"
echo ""

echo "1️⃣ Checking if HBase is accessible..."
echo "----------------------------------------"
hbase version 2>/dev/null | head -3
if [ $? -eq 0 ]; then
    echo "✅ HBase is accessible"
else
    echo "❌ HBase is not accessible"
    exit 1
fi
echo ""

echo "2️⃣ Listing all tables..."
echo "----------------------------------------"
echo "list" | hbase shell -n 2>/dev/null | grep -v "TABLE" | grep -v "row(s)"
echo ""

echo "3️⃣ Checking maurottito_parking_locations table..."
echo "----------------------------------------"
echo "exists 'maurottito_parking_locations'" | hbase shell -n 2>/dev/null
if [ $? -eq 0 ]; then
    echo ""
    echo "Row count:"
    echo "count 'maurottito_parking_locations'" | hbase shell -n 2>/dev/null | tail -2
    echo ""
    echo "Sample data (first 3 rows):"
    echo "scan 'maurottito_parking_locations', {LIMIT => 3}" | hbase shell -n 2>/dev/null | head -30
else
    echo "❌ Table maurottito_parking_locations does not exist!"
fi
echo ""

echo "4️⃣ Checking maurottito_parking_availability table..."
echo "----------------------------------------"
echo "exists 'maurottito_parking_availability'" | hbase shell -n 2>/dev/null
if [ $? -eq 0 ]; then
    echo ""
    echo "Row count:"
    echo "count 'maurottito_parking_availability'" | hbase shell -n 2>/dev/null | tail -2
    echo ""
    echo "Sample data (first 3 rows):"
    echo "scan 'maurottito_parking_availability', {LIMIT => 3}" | hbase shell -n 2>/dev/null | head -30
else
    echo "❌ Table maurottito_parking_availability does not exist!"
fi
echo ""

echo "5️⃣ Checking HBase REST API (Thrift)..."
echo "----------------------------------------"
echo "Testing connection to localhost:8070..."
curl -s http://localhost:8070/version 2>/dev/null
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ HBase REST API is accessible on port 8070"
else
    echo "❌ HBase REST API is not accessible on port 8070"
    echo "Trying port 9090..."
    curl -s http://localhost:9090/version 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ HBase REST API is accessible on port 9090"
    else
        echo "❌ HBase REST API is not accessible"
    fi
fi
echo ""

echo "============================================"
echo "Verification Complete!"
echo "============================================"

