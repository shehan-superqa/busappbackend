const net = require('net');

// Configuration - Deployed Server
const HOST = '67.207.90.123'; // Deployed DigitalOcean droplet IP
const PORT = 8080; // TCP socket port

// Test data
const testData = {
  deviceId: "BUS001",
  timestamp: Date.now(),
  passengers: [
    {
      cardId: "ABC123",
      timestamp: Date.now()
    },
    {
      cardId: "XYZ789",
      timestamp: Date.now() + 1000
    }
  ],
  location: {
    latitude: 6.9271,
    longitude: 79.8612
  }
};

console.log('='.repeat(50));
console.log('TCP Client Test Script - Deployed Server');
console.log('='.repeat(50));
console.log(`Connecting to deployed server at ${HOST}:${PORT}...\n`);

// Create TCP client
const client = new net.Socket();

let connectionAcknowledged = false;
let dataSent = false;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 3;

// Handle connection
client.connect(PORT, HOST, () => {
  console.log(`✓ Connected to deployed server at ${HOST}:${PORT}`);
  console.log('Waiting for connection acknowledgment...\n');
  reconnectAttempts = 0; // Reset on successful connection
});

// Handle incoming data
client.on('data', (data) => {
  const response = data.toString().trim();
  
  if (!connectionAcknowledged) {
    // First response should be CONNECTED
    if (response === 'CONNECTED') {
      console.log('✓ Connection acknowledgment received:', response);
      console.log('Connection established successfully!\n');
      connectionAcknowledged = true;
      
      // Now send test data
      if (!dataSent) {
        dataSent = true;
        const jsonData = JSON.stringify(testData);
        console.log('Sending test data...');
        console.log('Data:', jsonData);
        console.log('');
        client.write(jsonData);
      }
    } else {
      console.log('⚠ Unexpected response on connection:', response);
    }
  } else {
    // Subsequent responses (OK or ERROR)
    if (response === 'OK') {
      console.log('✓ Data processed successfully:', response);
      console.log('✓ Test completed successfully!\n');
      console.log('='.repeat(50));
      console.log('Summary:');
      console.log(`  Server: ${HOST}:${PORT}`);
      console.log(`  Status: Connected and data processed`);
      console.log(`  Device ID: ${testData.deviceId}`);
      console.log(`  Passengers: ${testData.passengers.length}`);
      console.log('='.repeat(50));
      client.destroy();
      process.exit(0);
    } else if (response.startsWith('ERROR:')) {
      console.error('✗ Error from server:', response);
      client.destroy();
      process.exit(1);
    } else {
      console.log('Response:', response);
    }
  }
});

// Handle connection close
client.on('close', () => {
  if (connectionAcknowledged && dataSent) {
    console.log('✓ Connection closed gracefully');
  } else {
    console.log('⚠ Connection closed unexpectedly');
  }
  console.log('='.repeat(50));
});

// Handle errors
client.on('error', (err) => {
  console.error('✗ Connection error:', err.message);
  
  if (err.code === 'ECONNREFUSED') {
    console.error(`\nServer at ${HOST}:${PORT} refused the connection.`);
    console.error('Possible reasons:');
    console.error('  1. Server is not running');
    console.error('  2. Firewall is blocking the connection');
    console.error('  3. Port 8080 is not open in DigitalOcean firewall');
    console.error('  4. Server is still initializing (wait a few minutes after deployment)');
  } else if (err.code === 'ETIMEDOUT') {
    console.error(`\nConnection to ${HOST}:${PORT} timed out.`);
    console.error('Possible reasons:');
    console.error('  1. Server is down');
    console.error('  2. Network connectivity issues');
    console.error('  3. Firewall is blocking the connection');
  } else if (err.code === 'ENOTFOUND') {
    console.error(`\nCould not resolve hostname: ${HOST}`);
  } else {
    console.error(`\nError code: ${err.code}`);
  }
  
  // Attempt reconnection for network errors
  if ((err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') && reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
    reconnectAttempts++;
    const delay = reconnectAttempts * 2000; // Exponential backoff: 2s, 4s, 6s
    console.log(`\nRetrying connection in ${delay/1000} seconds... (Attempt ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})`);
    
    setTimeout(() => {
      console.log(`Attempting to reconnect to ${HOST}:${PORT}...`);
      client.connect(PORT, HOST);
    }, delay);
  } else {
    console.error('\n✗ Failed to connect after multiple attempts');
    process.exit(1);
  }
});

// Handle timeout
client.setTimeout(15000); // 15 seconds for remote connections
client.on('timeout', () => {
  console.error('✗ Connection timeout (15 seconds)');
  console.error('The server may be slow to respond or unreachable.');
  client.destroy();
  process.exit(1);
});

// Graceful shutdown on Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\nShutting down...');
  if (!client.destroyed) {
    client.destroy();
  }
  process.exit(0);
});

// Add connection timeout warning
setTimeout(() => {
  if (!connectionAcknowledged) {
    console.log('\n⚠ Still waiting for connection...');
    console.log('This may take a moment if the server is still initializing.');
  }
}, 5000);

