# Parking Spot App

A small Node.js/Express application to view and update parking availability backed by HBase.

Contents
- app.js — main server
- Templates: `home.mustache`, `parking-table.mustache`, `map.mustache`, `update.mustache`, `update-form.mustache`
- public/ — static assets (CSS, test.html)

## Deploy first
Deploy these files to your EC2 server before making other changes or running in production. Quick steps:

1) Upload project to the server using IntelliJ Deployment / Start SSH Session:

```bash
# In IntelliJ: open Tools → Start SSH Session (or Deployment) to connect to your EC2 host
# Upload files via SFTP to /home/ec2-user/maurottito/parking_spot_app using your configured Deployment profile
# Use the Deployment configuration named 'webserver' (or set one up in Settings → Build, Execution, Deployment → Deployment)
```

2) Start the app with PM2 on the EC2 instance (recommended):

```bash
cd /home/ec2-user/maurottito/parking_spot_app
# If replacing an existing process:
pm2 delete maurottito_app || true
# Start with port and HBase URL (include http:// or https:// as needed):
pm2 start app.js --name maurottito_app -- 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
pm2 save
```

Notes:
- Replace `3027` and the HBase URL above with the port and HBase HTTP URL you use.
- If you prefer to run without PM2 for testing, run:

```bash
node app.js 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
```

Quick start
1. Install dependencies:

```bash
npm ci
```

2. Run locally (example):

```bash
node app.js 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
```

3. Run with PM2 on the server (example):

```bash
pm2 start app.js --name maurottito_app -- 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
pm2 save
```

Key endpoints
- GET /home.html — Home page
- GET /parking.html — Table view of parking locations
- GET /map.html — Map view
- GET /update.html — Update form (if enabled)
- POST /update — Update availability (JSON payload)
- GET /health — Liveness check

HBase
- The app connects to an HBase REST server (default example: `http://ec2-54-89-237-222.compute-1.amazonaws.com:8070`).
- Tables used:
  - `maurottito_parking_locations` (family `info`)
  - `maurottito_parking_availability` (family `stat`)

Notes
- Geolocation (GPS) requires HTTPS or localhost to prompt the browser.
- If you see TLS/EPROTO errors, ensure the HBase URL uses `http://` when the server does not support HTTPS.

Troubleshooting
- Check logs: `pm2 logs maurottito_app --lines 200`
- Restart: `pm2 restart maurottito_app` or delete+start if args changed
