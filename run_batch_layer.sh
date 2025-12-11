#!/bin/bash
# Batch Layer Deployment and Execution Guide
# Your batch layer uses Hive to ingest CSV data into HBase

echo "=========================================="
echo "Batch Layer Deployment - Hive to HBase"
echo "=========================================="
echo ""

# Step 1: Upload CSV data to HDFS
echo "Step 1: Uploading parking data to HDFS..."
hdfs dfs -mkdir -p /tmp/maurottito/parking
hdfs dfs -put -f ~/maurottito/data/parking_locations.csv /tmp/maurottito/parking/
hdfs dfs -ls /tmp/maurottito/parking/
echo ""

# Step 2: Run Hive script to create tables and load CSV
echo "Step 2: Creating Hive tables from CSV..."
beeline -u jdbc:hive2://localhost:10000/default -n hadoop \
  -d org.apache.hive.jdbc.HiveDriver \
  -f ~/maurottito/hive_hbase_spark/create_parking_locations.hql
echo ""

# Step 3: Transfer data from Hive to HBase
echo "Step 3: Transferring data from Hive to HBase..."
beeline -u jdbc:hive2://localhost:10000/default -n hadoop \
  -d org.apache.hive.jdbc.HiveDriver \
  -f ~/maurottito/hive_hbase_spark/parking_hive_to_hbase.hql
echo ""

# Step 4: Verify HBase tables
echo "Step 4: Verifying HBase tables..."
echo "list" | hbase shell -n | grep maurottito
echo ""

# Step 5: Check data in HBase
echo "Step 5: Scanning HBase data..."
echo "scan 'maurottito_parking_locations', {LIMIT => 5}" | hbase shell -n
echo ""
echo "scan 'maurottito_parking_availability', {LIMIT => 5}" | hbase shell -n
echo ""

echo "=========================================="
echo "Batch Layer Deployment Complete!"
echo "=========================================="
echo ""
echo "Your data is now in HBase and ready for the webapp!"

