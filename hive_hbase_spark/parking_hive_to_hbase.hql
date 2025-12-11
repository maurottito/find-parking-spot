-- Transfer parking locations from Hive to HBase
-- Run with: beeline -u jdbc:hive2://localhost:10000/default -n hadoop -d org.apache.hive.jdbc.HiveDriver

-- Create EXTERNAL HBase-backed Hive table for parking locations (table already exists in HBase)
create external table if not exists maurottito_parking_locations_hbase (
  location_id int,
  location_name string,
  latitude double,
  longitude double,
  total_spots int)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES (
  'hbase.columns.mapping' = ':key,info:location_name,info:latitude,info:longitude,info:total_spots#b'
)
TBLPROPERTIES ('hbase.table.name' = 'maurottito_parking_locations');



-- Create HBase-backed Hive table for parking availability (will create HBase table)
create table if not exists maurottito_parking_availability_hbase (
  location_id int,
  available_spots int,
  last_updated string,
  ts bigint)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES (
  'hbase.columns.mapping' = ':key,stat:available_spots#b,stat:last_updated,stat:timestamp#b'
)
TBLPROPERTIES ('hbase.table.name' = 'maurottito_parking_availability');

-- Initialize parking availability with current total_spots (all spots available)
insert overwrite table maurottito_parking_availability_hbase
select 
  location_id,
  total_spots as available_spots,
  from_unixtime(unix_timestamp()) as last_updated,
  unix_timestamp() as ts
from maurottito_parking_locations
WHERE location_id IS NOT NULL;

-- Verify data
select * from maurottito_parking_locations_hbase;
select * from maurottito_parking_availability_hbase;
