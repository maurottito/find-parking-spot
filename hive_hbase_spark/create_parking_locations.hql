-- Parking locations CSV to Hive
-- Run with: beeline -u jdbc:hive2://localhost:10000/default -n hadoop -d org.apache.hive.jdbc.HiveDriver

-- Create external CSV table
create external table maurottito_parking_locations_csv(
  location_id int,
  location_name string,
  latitude double,
  longitude double,
  total_spots int)
  row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'

WITH SERDEPROPERTIES (
   "separatorChar" = "\,",
   "quoteChar"     = "\""
)
STORED AS TEXTFILE
  location '/tmp/maurottito/parking'
TBLPROPERTIES ("skip.header.line.count"="1");


-- TEST Query
select * from maurottito_parking_locations_csv limit 10;


-- Create an ORC table for parking locations (stored as ORC for efficiency)
create table maurottito_parking_locations(
  location_id int,
  location_name string,
  latitude double,
  longitude double,
  total_spots int)
  stored as orc;


-- Copy the CSV table to the ORC table
insert overwrite table maurottito_parking_locations 
select * from maurottito_parking_locations_csv;

-- Verify data
select * from maurottito_parking_locations;
