const net = require('net');

// Configuration
const HOST = 'localhost';
const PORT = 8080;

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
console.log('TCP Client Test Script');
console.log('='.repeat(50));
console.log(`Connecting to ${HOST}:${PORT}...\n`);

// Create TCP client
const client = new net.Socket();

let connectionAcknowledged = false;
let dataSent = false;

// Handle connection
client.connect(PORT, HOST, () => {
  console.log(`✓ Connected to server at ${HOST}:${PORT}`);
  console.log('Waiting for connection acknowledgment...\n');
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
      client.destroy();
    } else if (response.startsWith('ERROR:')) {
      console.error('✗ Error from server:', response);
      client.destroy();
    } else {
      console.log('Response:', response);
    }
  }
});

// Handle connection close
client.on('close', () => {
  console.log('Connection closed');
  console.log('='.repeat(50));
});

// Handle errors
client.on('error', (err) => {
  console.error('✗ Connection error:', err.message);
  if (err.code === 'ECONNREFUSED') {
    console.error('Make sure the TCP server is running on port', PORT);
  }
});

// Handle timeout (optional)
client.setTimeout(10000); // 10 seconds
client.on('timeout', () => {
  console.error('✗ Connection timeout');
  client.destroy();
});

// Graceful shutdown on Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\nShutting down...');
  client.destroy();
  process.exit(0);
});

