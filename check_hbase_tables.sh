#!/bin/bash
# Check HBase tables and data for parking spot finder

echo "=========================================="
echo "HBase Tables Data Verification"
echo "=========================================="
echo ""

echo "Step 1: Listing all HBase tables..."
echo "--------------------------------------"
echo "list" | hbase shell -n 2>&1 | grep -E "(maurottito|TABLE)"
echo ""

echo "Step 2: Checking parking_locations table..."
echo "--------------------------------------"
echo "describe 'maurottito_parking_locations'" | hbase shell -n 2>&1 | tail -20
echo ""

echo "Step 3: Scanning parking_locations data..."
echo "--------------------------------------"
echo "scan 'maurottito_parking_locations'" | hbase shell -n 2>&1 | grep -v "SLF4J" | tail -30
echo ""

echo "Step 4: Checking parking_availability table..."
echo "--------------------------------------"
echo "describe 'maurottito_parking_availability'" | hbase shell -n 2>&1 | tail -20
echo ""

echo "Step 5: Scanning parking_availability data..."
echo "--------------------------------------"
echo "scan 'maurottito_parking_availability'" | hbase shell -n 2>&1 | grep -v "SLF4J" | tail -30
echo ""

echo "Step 6: Counting rows in each table..."
echo "--------------------------------------"
echo "Locations table:"
echo "count 'maurottito_parking_locations'" | hbase shell -n 2>&1 | tail -5
echo ""
echo "Availability table:"
echo "count 'maurottito_parking_availability'" | hbase shell -n 2>&1 | tail -5
echo ""

echo "=========================================="
echo "Summary Complete"
echo "=========================================="

