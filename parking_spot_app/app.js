'use strict';
const http = require('http');
var assert = require('assert');
const express= require('express');
const app = express();
const mustache = require('mustache');
const filesystem = require('fs');

// Defaults to run on EC2 if no args are provided
const DEFAULT_PORT = 3027;
const port = Number(process.argv[2] || DEFAULT_PORT);

const hbase = require('hbase')

// Parse HBase URL from command line argument or use default
let hbaseUrlString = process.argv[3] || 'http://ec2-54-89-237-222.compute-1.amazonaws.com:8070';
// Add http:// prefix if no protocol is specified
if (!hbaseUrlString.startsWith('http://') && !hbaseUrlString.startsWith('https://')) {
	hbaseUrlString = 'http://' + hbaseUrlString;
}
const url = new URL(hbaseUrlString);
console.log(url)

var hclient = hbase({
	host: url.hostname,
	path: url.pathname ?? "/",
	port: url.port,
	protocol: url.protocol.slice(0, -1), // Don't want the colon
	encoding: 'latin1',
	// Explicitly disable SSL/TLS
	https: false,
	krb5: {
		principal: null
	}
});

// Log the HBase configuration
console.log('HBase client configuration:', {
	host: hclient.options.host,
	port: hclient.options.port,
	protocol: hclient.options.protocol,
	path: hclient.options.path
});

app.use(express.static('public'));
app.use(express.json()); // Parse JSON request bodies

// Health endpoint for quick liveness checks (does not depend on HBase)
app.get('/health', function (req, res) {
  res.status(200).send('OK');
});

console.log(`Starting web server on port ${port} (HBase: ${hclient.options.protocol}://${hclient.options.host}:${hclient.options.port}${hclient.options.path})`);

// Home page
app.get('/home.html',function (req, res) {
var template = filesystem.readFileSync("home.mustache").toString();
	var html = mustache.render(template)
	res.send(html)
});

// Parking availability view
app.get('/parking.html', function (req, res) {
// Get parking locations
hclient.table('maurottito_parking_locations').scan({ maxVersions: 1}, (err, locationCells) => {
		if (err) {
			console.error('Error reading parking locations:', err);

			// Check if it's an SSL/TLS error
			if (err.code === 'EPROTO' || err.errno === -71) {
				res.status(500).send(`
					<h1>SSL/TLS Connection Error</h1>
					<p><strong>Error:</strong> Cannot connect to HBase using HTTPS.</p>
					<p><strong>Solution:</strong> HBase server likely only supports HTTP (not HTTPS).</p>
					<p>Restart your app with HTTP instead:</p>
					<pre>pm2 delete maurottito_app
pm2 start app.js --name maurottito_app -- 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
pm2 save</pre>
					<p><a href="/home.html">← Back to Home</a></p>
				`);
			} else {
				res.status(500).send(`<h1>Error reading parking locations</h1><pre>${JSON.stringify(err, null, 2)}</pre><p><a href="/home.html">← Back to Home</a></p>`);
			}
			return;
		}
		
		console.log(`Found ${locationCells ? locationCells.length : 0} location cells`);

		// Get parking availability
		hclient.table('maurottito_parking_availability').scan({ maxVersions: 1}, (err, availCells) => {
			if (err) {
				console.error('Error reading parking availability:', err);
				res.status(500).send(`<h1>Error reading parking availability</h1><pre>${JSON.stringify(err, null, 2)}</pre>`);
				return;
			}
			
			console.log(`Found ${availCells ? availCells.length : 0} availability cells`);

			// Process locations data
			var locations = {};
			locationCells.forEach(function(cell) {
				var locationId = cell['key'];
				if (!locations[locationId]) {
					locations[locationId] = { location_id: locationId };
				}
				var colName = cell['column'].replace('info:', '');
				var value = cell['$'];

				// Convert numeric fields
				if (colName === 'total_spots') {
					locations[locationId][colName] = bytesToInt(value);
				} else {
					locations[locationId][colName] = value;
				}
			});
			
			// Process availability data
			availCells.forEach(function(cell) {
				var locationId = cell['key'];
				if (!locations[locationId]) {
					locations[locationId] = { location_id: locationId };
				}
				var colName = cell['column'].replace('stat:', '');
				var value = cell['$'];

				// Convert numeric/timestamp fields
				if (colName === 'available_spots' || colName === 'timestamp') {
					locations[locationId][colName] = bytesToInt(value);
				} else {
					locations[locationId][colName] = value;
				}
			});
			
			// Convert to array and sort by location_id
			var parkingData = Object.values(locations).sort((a, b) => 
				parseInt(a.location_id) - parseInt(b.location_id)
			);
			
			// Convert timestamp to readable date in CST
			parkingData.forEach(function(loc) {
				if (loc.timestamp) {
					var date = new Date(loc.timestamp * 1000);
					loc.last_updated = date.toLocaleString('en-US', {
						year: 'numeric',
						month: '2-digit',
						day: '2-digit',
						hour: '2-digit',
						minute: '2-digit',
						second: '2-digit',
						hour12: false,
						timeZone: 'America/Chicago'
					});
				} else {
					loc.last_updated = 'N/A';
				}
			});

			console.log(`Processed ${parkingData.length} parking locations`);
			if (parkingData.length > 0) {
				console.log('Sample location data:', JSON.stringify(parkingData[0], null, 2));
			}

			// Render template
			var template = filesystem.readFileSync("parking-table.mustache").toString();
			var html = mustache.render(template, {
locations: parkingData
});
			res.send(html);
		});
	});
});

// Map view endpoint
app.get('/map.html', function (req, res) {
	// Get parking locations
	hclient.table('maurottito_parking_locations').scan({ maxVersions: 1}, (err, locationCells) => {
		if (err) {
			console.error('Error reading parking locations for map:', err);

			if (err.code === 'EPROTO' || err.errno === -71) {
				res.status(500).send(`
					<h1>SSL/TLS Connection Error</h1>
					<p><strong>Error:</strong> Cannot connect to HBase using HTTPS.</p>
					<p><strong>Solution:</strong> HBase server likely only supports HTTP (not HTTPS).</p>
					<p>Restart your app with HTTP instead:</p>
					<pre>pm2 delete maurottito_app
pm2 start app.js --name maurottito_app -- 3027 http://ec2-54-89-237-222.compute-1.amazonaws.com:8070
pm2 save</pre>
					<p><a href="/home.html">← Back to Home</a></p>
				`);
			} else {
				res.status(500).send(`<h1>Error reading parking locations</h1><pre>${JSON.stringify(err, null, 2)}</pre><p><a href="/home.html">← Back to Home</a></p>`);
			}
			return;
		}

		console.log(`Found ${locationCells ? locationCells.length : 0} location cells for map`);

		// Get parking availability
		hclient.table('maurottito_parking_availability').scan({ maxVersions: 1}, (err, availCells) => {
			if (err) {
				console.error('Error reading parking availability for map:', err);
				res.status(500).send(`<h1>Error reading parking availability</h1><pre>${JSON.stringify(err, null, 2)}</pre><p><a href="/home.html">← Back to Home</a></p>`);
				return;
			}

			console.log(`Found ${availCells ? availCells.length : 0} availability cells for map`);

			// Process locations data
			var locations = {};
			locationCells.forEach(function(cell) {
				var locationId = cell['key'];
				if (!locations[locationId]) {
					locations[locationId] = { location_id: locationId };
				}
				var colName = cell['column'].replace('info:', '');
				var value = cell['$'];

				// Convert numeric fields
				if (colName === 'total_spots') {
					locations[locationId][colName] = bytesToInt(value);
				} else {
					locations[locationId][colName] = value;
				}
			});

			// Process availability data
			availCells.forEach(function(cell) {
				var locationId = cell['key'];
				if (!locations[locationId]) {
					locations[locationId] = { location_id: locationId };
				}
				var colName = cell['column'].replace('stat:', '');
				var value = cell['$'];

				// Convert numeric/timestamp fields
				if (colName === 'available_spots' || colName === 'timestamp') {
					locations[locationId][colName] = bytesToInt(value);
				} else {
					locations[locationId][colName] = value;
				}
			});

			// Convert to array
			var parkingData = Object.values(locations).sort((a, b) =>
				parseInt(a.location_id) - parseInt(b.location_id)
			);

			// Convert timestamp to readable date in CST
			parkingData.forEach(function(loc) {
				if (loc.timestamp) {
					var date = new Date(loc.timestamp * 1000);
					loc.last_updated = date.toLocaleString('en-US', {
						year: 'numeric',
						month: '2-digit',
						day: '2-digit',
						hour: '2-digit',
						minute: '2-digit',
						second: '2-digit',
						hour12: false,
						timeZone: 'America/Chicago'
					});
				} else {
					loc.last_updated = 'N/A';
				}
			});

			console.log(`Processed ${parkingData.length} parking locations for map`);

			// Render map template
			var template = filesystem.readFileSync("map.mustache").toString();
			var html = mustache.render(template, {
				locations: parkingData,
				locationsJson: JSON.stringify(parkingData)
			});
			res.send(html);
		});
	});
});

// Update form page
app.get('/update.html', function (req, res) {
	hclient.table('maurottito_parking_locations').scan({ maxVersions: 1}, (err, locationCells) => {
		if (err) {
			console.error('Error reading parking locations for update form:', err);
			res.status(500).send(`<h1>Error loading locations</h1><pre>${JSON.stringify(err, null, 2)}</pre>`);
			return;
		}

		// Process locations data
		var locations = {};
		locationCells.forEach(function(cell) {
			var locationId = cell['key'];
			if (!locations[locationId]) {
				locations[locationId] = { location_id: locationId };
			}
			var colName = cell['column'].replace('info:', '');
			var value = cell['$'];

			if (colName === 'total_spots') {
				locations[locationId][colName] = bytesToInt(value);
			} else {
				locations[locationId][colName] = value;
			}
		});

		var locationsList = Object.values(locations).sort((a, b) =>
			parseInt(a.location_id) - parseInt(b.location_id)
		);

		var template = filesystem.readFileSync("update.mustache").toString();
		var html = mustache.render(template, {
			locations: locationsList
		});
		res.send(html);
	});
});

// Update endpoint - saves new availability and current timestamp
app.post('/update', function (req, res) {
	const { location_id, available_spots } = req.body;

	if (!location_id || available_spots === undefined) {
		return res.status(400).json({
			success: false,
			message: 'Missing location_id or available_spots'
		});
	}

	const spots = parseInt(available_spots);
	if (isNaN(spots) || spots < 0) {
		return res.status(400).json({
			success: false,
			message: 'Invalid available_spots value. Must be a positive number.'
		});
	}

	// Get CURRENT timestamp (moment of saving)
	const currentTimestamp = Math.floor(Date.now() / 1000);

	console.log(`Updating location ${location_id}: ${spots} spots, timestamp: ${currentTimestamp}`);

	// Write to HBase as strings
	hclient.table('maurottito_parking_availability')
		.row(location_id.toString())
		.put([
			{ column: 'stat:available_spots', $: spots.toString() },
			{ column: 'stat:timestamp', $: currentTimestamp.toString() }
		], function(err) {
			if (err) {
				console.error('Error updating HBase:', err);
				return res.status(500).json({
					success: false,
					message: 'Failed to update database: ' + err.message
				});
			}

			console.log(`✅ Successfully updated location ${location_id}`);
			res.json({
				success: true,
				message: `Updated location ${location_id} to ${spots} available spots`,
				location_id: location_id,
				available_spots: spots,
				timestamp: currentTimestamp
			});
		});
});

// Helper function to convert HBase binary counter to number
function bytesToInt(bytes) {
	// If already a number, return it
	if (typeof bytes === 'number') {
		return bytes;
	}

	// If it's a string that might contain binary data
	if (typeof bytes === 'string') {
		// Check if it looks like binary data (contains null bytes)
		if (bytes.includes('\u0000') || bytes.charCodeAt(0) === 0) {
			// Convert string to buffer and parse as binary
			const buffer = Buffer.from(bytes, 'binary');

			if (buffer.length === 4) {
				return buffer.readInt32BE(0);
			} else if (buffer.length === 8) {
				return Number(buffer.readBigInt64BE(0));
			} else if (buffer.length === 2) {
				return buffer.readInt16BE(0);
			} else if (buffer.length === 1) {
				return buffer.readInt8(0);
			}
		}

		// Try parsing as regular string number
		const parsed = parseInt(bytes);
		return isNaN(parsed) ? 0 : parsed;
	}

	// If it's a buffer or byte array
	if (Buffer.isBuffer(bytes) || (bytes && bytes.length !== undefined)) {
		try {
			const buffer = Buffer.isBuffer(bytes) ? bytes : Buffer.from(bytes);

			if (buffer.length === 4) {
				return buffer.readInt32BE(0);
			} else if (buffer.length === 8) {
				return Number(buffer.readBigInt64BE(0));
			} else if (buffer.length === 2) {
				return buffer.readInt16BE(0);
			} else if (buffer.length === 1) {
				return buffer.readInt8(0);
			}

			// Try as string
			const str = buffer.toString('utf8');
			const parsed = parseInt(str);
			return isNaN(parsed) ? 0 : parsed;
		} catch(e) {
			console.warn('Failed to parse bytes to int:', e.message);
			return 0;
		}
	}

	return 0;
}

// Start server - bind to 0.0.0.0 to allow external access
app.listen(port, '0.0.0.0', () => {
	console.log(`Server listening on port ${port}`);
	console.log(`Local access: http://localhost:${port}/home.html`);
	console.log(`External access: http://<your-ec2-public-ip>:${port}/home.html`);
});
