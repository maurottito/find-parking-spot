# Chicago Parking Spot Finder

Real-time parking availability system using live camera feed processing and computer vision. Implements Lambda Architecture with HBase distributed storage, OpenCV car detection, and real-time web interface updates.

This project was created as a final project for MPCS 53014 Big Data Application Architecture at the University of Chicago.

**Video Demonstration**

[Watch demo and walkthrough](https://youtu.be/dwe3hCHwaGA)

---


## Project Overview

A production-ready parking detection system that:
- Processes live HLS video stream from Chicago
- Uses OpenCV computer vision to detect cars in real-time
- Stores data in HBase distributed NoSQL database
- Displays real-time availability on a web interface
- Updates every 60 seconds automatically

---

## Project Structure

```
find-parking-spot/
├── README.md                          # This comprehensive guide
├── requirements.txt                   # Python dependencies
│
├── data/
│   └── parking_locations.csv          # Source data (5 locations)
│
├── hive_hbase_spark/
│   ├── create_parking_locations.hql   # Hive table creation
│   └── parking_hive_to_hbase.hql      # Hive → HBase transfer
│
├── speed_layer/
│   ├── auto_update_live_camera.py     # Live camera detection service
│   ├── start_live_camera.sh           # Start script
│   ├── stop_live_camera.sh            # Stop script
│   └── status_live_camera.sh          # Status check
│
├── parking_spot_app_deploy/
│   ├── src/
│   │   ├── app.js                     # Node.js web server
│   │   ├── package.json               # npm dependencies
│   │   ├── home.mustache              # Home page template
│   │   ├── parking-table.mustache     # Parking table template
│   │   └── public/
│   │       ├── elegant-aero.css       # Form styling
│   │       └── table.css              # Table styling
│   ├── start_app.sh                   # Web app start script
│   └── logs/                          # Application logs
│
├── run_batch_layer.sh                 # Batch layer deployment
├── cleanup_and_retry.sh               # Cleanup & retry script
├── create_availability_only.sh        # Create availability table
│
└── Documentation/
    ├── PROJECT_SUCCESS.md             # Success summary
    ├── LIVE_CAMERA_README.md          # Live camera guide
    ├── IMPROVED_DETECTION.md          # Detection tuning
    ├── FIX_HBASE_TIMEOUT.md           # Troubleshooting
    └── DEPLOY_FLEXIBLE_DETECTION.md   # Deployment guide
```

---

## Key Features

### Real-time Processing
- Live camera frame extraction every 60 seconds
- OpenCV-based car detection with edge analysis
- Immediate HBase updates with fresh connections
- Sub-second processing time per cycle

### Distributed Storage
- HBase NoSQL database for scalability
- Binary encoding for storage efficiency
- Scalable to millions of parking records
- HDFS-backed data persistence

### Computer Vision
- Canny edge detection algorithm
- Contour analysis for object identification
- Adaptive thresholding techniques
- Multi-angle car recognition (0.2-5.0 aspect ratio)

### Production Ready
- Comprehensive error handling & retry logic
- Automatic HBase reconnection per update
- Full logging and audit trail
- Service management scripts for ops

### Web Interface
- Real-time data display with auto-refresh
- Manual update capability via forms
- Health monitoring endpoints
- RESTful API for integration


---

## Lambda Architecture

### Complete 3-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
│  • CSV Files (Historical Data)                                  │
│  • Live Camera Stream (Real-time)                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┴─────────────────────┐
        ↓                                           ↓
┌───────────────────┐                    ┌──────────────────────┐
│   BATCH LAYER     │                    │    SPEED LAYER       │
│                   │                    │                      │
│  Hive → HBase     │                    │  Live Camera Stream  │
│  (Initial Load)   │                    │         ↓            │
│                   │                    │  OpenCV Detection    │
│  5 Locations      │                    │         ↓            │
│  Loaded Once      │                    │  HBase Update (60s)  │
└───────────────────┘                    └──────────────────────┘
        ↓                                           ↓
        └─────────────────────┬─────────────────────┘
                              ↓
                    ┌──────────────────────┐
                    │   SERVING LAYER      │
                    │                      │
                    │  Node.js Web App     │
                    │  HBase REST Client   │
                    │  Real-time Display   │
                    └──────────────────────┘
                              ↓
                    ┌──────────────────────┐
                    │      WEB UI          │
                    │  Port 3027           │
                    └──────────────────────┘
```

---

## Technologies Stack

### Big Data
- **Hadoop HDFS** - Distributed file storage
- **HBase** - NoSQL database (binary encoding)
- **Hive** - Data warehouse & SQL queries

### Real-time Processing
- **OpenCV 4.12** - Computer vision & car detection
- **Python 3.9** - Speed layer processing
- **Live HLS Stream** - Video source

### Machine Learning / Computer Vision
- **Canny Edge Detection** - Object boundary detection
- **Contour Analysis** - Car shape recognition
- **Adaptive Thresholding** - Image processing

### Backend
- **Node.js 18.20** - Web server
- **Express.js** - Web framework
- **HappyBase** - Python HBase client

### Frontend
- **Mustache** - Template engine
- **HTML/CSS/JavaScript** - Web interface
- **RESTful API** - Data endpoints

### Infrastructure
- **AWS EMR** - Hadoop cluster (ec2-54-89-237-222.compute-1.amazonaws.com)
- **AWS EC2** - Web server (ec2-52-20-203-80.compute-1.amazonaws.com)

---

## Data Architecture

### HBase Tables

#### 1. maurottito_parking_locations
Stores static parking location information.

| Row Key | Column Family | Column | Type | Description |
|---------|---------------|---------|------|-------------|
| location_id | info | location_name | String | Parking lot name |
| location_id | info | latitude | Double | GPS latitude |
| location_id | info | longitude | Double | GPS longitude |
| location_id | info | total_spots | Int (binary) | Total parking spots |

#### 2. maurottito_parking_availability
Stores real-time parking availability (updated by speed layer).

| Row Key | Column Family | Column | Type | Description |
|---------|---------------|---------|------|-------------|
| location_id | stat | available_spots | Int (binary) | Currently available spots |
| location_id | stat | last_updated | String | Timestamp of update |
| location_id | stat | timestamp | Long (binary) | Unix timestamp |

---

## Complete Deployment Guide

### Prerequisites

**On EMR Cluster:**
- Hadoop, HBase, Hive installed
- Python 3.9+
- Access to port 9090 (HBase Thrift)

**On Web Server:**
- Node.js 18+
- npm packages: express, hbase, mustache

**Development:**
- IntelliJ IDEA with deployment configured
- SSH access to both servers

---

## Step 1: Batch Layer Deployment

### A. Upload Data to HDFS

```bash
# SSH to EMR cluster
ssh hadoop@ec2-54-89-237-222.compute-1.amazonaws.com

# Create directory and upload CSV
hdfs dfs -mkdir -p /tmp/maurottito/parking
hdfs dfs -put ~/maurottito/data/parking_locations.csv /tmp/maurottito/parking/

# Verify upload
hdfs dfs -ls /tmp/maurottito/parking/
```

### B. Load Data via Hive to HBase

```bash
cd ~/maurottito
bash run_batch_layer.sh
```

This script automatically:
1. Creates Hive external table from CSV
2. Creates Hive ORC table for efficiency
3. Creates HBase-backed Hive tables
4. Transfers data from Hive to HBase
5. Initializes availability data for all 5 locations

### C. Verify Data Load

```bash
# Open HBase shell
hbase shell

# Check locations table
scan 'maurottito_parking_locations', {LIMIT => 10}

# Check availability table
scan 'maurottito_parking_availability', {LIMIT => 10}

# Count rows
count 'maurottito_parking_locations'
count 'maurottito_parking_availability'

# Exit
exit
```

Expected Output:
- 5 rows in maurottito_parking_locations
- 5 rows in maurottito_parking_availability

---

## Step 2: Speed Layer Deployment (Live Camera)

### A. Install Python Dependencies

```bash
# On EMR cluster
pip3 install --user happybase
pip3 install --user opencv-python-headless
pip3 install --user numpy
```

Note: Use opencv-python-headless (not regular opencv-python) to avoid GUI library dependencies.

### B. Deploy Speed Layer Files via IntelliJ

Files to upload:
1. speed_layer/auto_update_live_camera.py - Main detection service
2. speed_layer/start_live_camera.sh - Start script
3. speed_layer/stop_live_camera.sh - Stop script
4. speed_layer/status_live_camera.sh - Status check

Upload procedure:
1. Right-click each file in IntelliJ
2. Select: Deployment → Upload to ec2-54-89-237-222.compute-1.amazonaws.com
3. Confirm upload

### C. Make Scripts Executable

```bash
# SSH to EMR
ssh hadoop@ec2-54-89-237-222.compute-1.amazonaws.com

# Navigate to speed layer
cd ~/maurottito/speed_layer

# Make executable
chmod +x *.sh
```

### D. Test Camera Connection

```bash
# Run test mode
python3 auto_update_live_camera.py --test
```

### E. Start Live Camera Service

```bash
bash start_live_camera.sh
```

### F. Monitor Live Updates

```bash
tail -f ~/maurottito/logs/parking_live_camera.log
```

---

## Step 3: Serving Layer (Web Application)

### A. Deploy Web Application Files via IntelliJ

Upload to web server (ec2-52-20-203-80.compute-1.amazonaws.com):

```
parking_spot_app_deploy/
├── src/
│   ├── app.js                    # Main server file
│   ├── package.json              # Dependencies
│   ├── home.mustache             # Home page
│   ├── parking-table.mustache    # Parking table view
│   └── public/
│       ├── elegant-aero.css      # Form styling
│       └── table.css             # Table styling
└── start_app.sh                  # Start script
```

### B. Install Node.js Dependencies

```bash
# SSH to web server
ssh ec2-user@ec2-52-20-203-80.compute-1.amazonaws.com

# Navigate to deployment directory
cd ~/parking_spot_app_deploy/src

# Install dependencies
npm install
```

### C. Start Web Server

```bash
cd ~/parking_spot_app_deploy
bash start_app.sh
```

Expected output:
```
Installing Node dependencies...
Started (PID: 2848164)
Logs: /home/hadoop/parking_spot_app_deploy/logs/parking_app_deploy.log
```

### D. Verify Web Application

Test locally on server:
```bash
curl http://localhost:3027/health
# Should return: OK

curl -I http://localhost:3027/home.html
# Should return: HTTP/1.1 200 OK
```

Test from browser:
```
http://ec2-52-20-203-80.compute-1.amazonaws.com:3027/home.html
http://ec2-52-20-203-80.compute-1.amazonaws.com:3027/parking.html
```

---

## Computer Vision Detection Details

### Car Detection Algorithm

The system uses a sophisticated computer vision pipeline:

1. Extract frame from HLS stream (1280x720 resolution)
2. Convert to grayscale
3. Apply Gaussian blur (5x5 kernel) - reduce noise
4. Canny edge detection (thresholds: 30, 120) - find object edges
5. Dilate edges (3 iterations, 5x5 kernel) - connect nearby edges
6. Find contours - identify potential objects
7. Filter by:
   - Area: 800 - 200,000 pixels (catches all car sizes)
   - Aspect ratio: 0.2 - 5.0 (cars from all angles)
8. Count valid cars (0-12 for Millennium Park)
9. Calculate available spots = total_spots - occupied
10. Update HBase with binary-encoded values

### Why This Approach Works

- **Single Frame Analysis** - No need for background model
- **Edge-based Detection** - Robust to lighting changes
- **Flexible Thresholds** - Catches cars at all distances/angles
- **Shape Filtering** - Aspect ratio ensures car-like objects
- **Optimized for Parking Lots** - Static camera, varied lighting

---

## Parking Locations

| ID | Location Name | Latitude | Longitude | Total Spots | Updates |
|----|---------------|----------|-----------|-------------|---------|
| 1 | Millennium Park Garage | 41.8826 | -87.6226 | 12 | Live Camera (60s) |
| 2 | Navy Pier Parking | 41.8917 | -87.6086 | 10 | Manual |
| 3 | Lincoln Park Zoo Lot | 41.9212 | -87.6340 | 14 | Manual |
| 4 | O'Hare Airport Parking | 41.9786 | -87.9048 | 7 | Manual |
| 5 | Loop District Garage | 41.8781 | -87.6298 | 9 | Manual |

**Live Camera Feed (Location 1):**  
https://2-fss-2.streamhoster.com/pl_126/200612-1195858-1/playlist.m3u8

---

## Service Management

### Speed Layer (Live Camera)

```bash
# Check status
bash ~/maurottito/speed_layer/status_live_camera.sh

# Start service
bash ~/maurottito/speed_layer/start_live_camera.sh

# Stop service
bash ~/maurottito/speed_layer/stop_live_camera.sh

# View logs
tail -f ~/maurottito/logs/parking_live_camera.log

# Watch only detection results
tail -f ~/maurottito/logs/parking_live_camera.log | grep "Camera Analysis"

# Check recent updates
tail -50 ~/maurottito/logs/parking_live_camera.log | grep "Occupied"
```

### Web Application

```bash
# On web server - Check if running
ps aux | grep "node app.js"

# View logs
tail -f ~/parking_spot_app_deploy/logs/parking_app_deploy.log

# Restart if needed
PID=$(cat ~/parking_spot_app_deploy/logs/parking_app_deploy.pid)
kill $PID
cd ~/parking_spot_app_deploy
bash start_app.sh
```

### HBase Queries

```bash
# Open HBase shell
hbase shell

# View all locations
scan 'maurottito_parking_locations'

# View current availability
scan 'maurottito_parking_availability'

# Get specific location
get 'maurottito_parking_locations', '1'
get 'maurottito_parking_availability', '1'

# Count rows
count 'maurottito_parking_locations'
count 'maurottito_parking_availability'

# Exit
exit
```

---

## Project Structure

```
find-parking-spot/
├── README.md                          # This comprehensive guide
├── requirements.txt                   # Python dependencies
│
├── data/
│   └── parking_locations.csv          # Source data (5 locations)
│
├── hive_hbase_spark/
│   ├── create_parking_locations.hql   # Hive table creation
│   └── parking_hive_to_hbase.hql      # Hive → HBase transfer
│
├── speed_layer/
│   ├── auto_update_live_camera.py     # Live camera detection service
│   ├── start_live_camera.sh           # Start script
│   ├── stop_live_camera.sh            # Stop script
│   └── status_live_camera.sh          # Status check
│
├── parking_spot_app_deploy/
│   ├── src/
│   │   ├── app.js                     # Node.js web server
│   │   ├── package.json               # npm dependencies
│   │   ├── home.mustache              # Home page template
│   │   ├── parking-table.mustache     # Parking table template
│   │   └── public/
│   │       ├── elegant-aero.css       # Form styling
│   │       └── table.css              # Table styling
│   ├── start_app.sh                   # Web app start script
│   └── logs/                          # Application logs
│
├── run_batch_layer.sh                 # Batch layer deployment
├── cleanup_and_retry.sh               # Cleanup & retry script
├── create_availability_only.sh        # Create availability table
│
└── Documentation/
    ├── PROJECT_SUCCESS.md             # Success summary
    ├── LIVE_CAMERA_README.md          # Live camera guide
    ├── IMPROVED_DETECTION.md          # Detection tuning
    ├── FIX_HBASE_TIMEOUT.md           # Troubleshooting
    └── DEPLOY_FLEXIBLE_DETECTION.md   # Deployment guide
```

---

## Key Features

### Real-time Processing
- Live camera frame extraction every 60 seconds
- OpenCV-based car detection with edge analysis
- Immediate HBase updates with fresh connections
- Sub-second processing time per cycle

### Distributed Storage
- HBase NoSQL database for scalability
- Binary encoding for storage efficiency
- Scalable to millions of parking records
- HDFS-backed data persistence

### Computer Vision
- Canny edge detection algorithm
- Contour analysis for object identification
- Adaptive thresholding techniques
- Multi-angle car recognition (0.2-5.0 aspect ratio)

### Production Ready
- Comprehensive error handling & retry logic
- Automatic HBase reconnection per update
- Full logging and audit trail
- Service management scripts for ops

### Web Interface
- Real-time data display with auto-refresh
- Manual update capability via forms
- Health monitoring endpoints
- RESTful API for integration
