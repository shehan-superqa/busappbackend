const net = require('net');

const HOST = 'localhost';
const PORT = 8080;

// Test cases
const testCases = [
  {
    name: 'Valid data with single passenger',
    data: {
      deviceId: "BUS001",
      timestamp: Date.now(),
      passengers: [
        { cardId: "ABC123", timestamp: Date.now() }
      ],
      location: { latitude: 6.9271, longitude: 79.8612 }
    },
    expected: 'OK'
  },
  {
    name: 'Valid data with multiple passengers',
    data: {
      deviceId: "BUS002",
      timestamp: Date.now(),
      passengers: [
        { cardId: "CARD1", timestamp: Date.now() },
        { cardId: "CARD2", timestamp: Date.now() + 1000 }
      ],
      location: { latitude: 6.9271, longitude: 79.8612 }
    },
    expected: 'OK'
  },
  {
    name: 'Invalid data (missing deviceId)',
    data: {
      timestamp: Date.now(),
      passengers: [{ cardId: "ABC123", timestamp: Date.now() }],
      location: { latitude: 6.9271, longitude: 79.8612 }
    },
    expected: 'ERROR'
  }
];

let currentTestIndex = 0;

function runTest(testCase) {
  return new Promise((resolve, reject) => {
    console.log(`\n[Test ${currentTestIndex + 1}/${testCases.length}] ${testCase.name}`);
    console.log('-'.repeat(50));

    const client = new net.Socket();
    let connectionAcknowledged = false;
    let dataSent = false;

    client.connect(PORT, HOST, () => {
      console.log('✓ Connected');
    });

    client.on('data', (data) => {
      const response = data.toString().trim();

      if (!connectionAcknowledged) {
        if (response === 'CONNECTED') {
          console.log('✓ Connection acknowledged');
          connectionAcknowledged = true;

          if (!dataSent) {
            dataSent = true;
            const jsonData = JSON.stringify(testCase.data);
            console.log('Sending:', jsonData);
            client.write(jsonData);
          }
        }
      } else {
        console.log('Response:', response);

        if (testCase.expected === 'OK' && response === 'OK') {
          console.log('✓ Test PASSED');
          resolve(true);
        } else if (testCase.expected === 'ERROR' && response.startsWith('ERROR:')) {
          console.log('✓ Test PASSED (expected error received)');
          resolve(true);
        } else {
          console.log('✗ Test FAILED (unexpected response)');
          resolve(false);
        }

        client.destroy();
      }
    });

    client.on('error', (err) => {
      console.error('✗ Connection error:', err.message);
      reject(err);
    });

    client.setTimeout(5000);
    client.on('timeout', () => {
      console.error('✗ Timeout');
      client.destroy();
      reject(new Error('Timeout'));
    });
  });
}

async function runAllTests() {
  console.log('='.repeat(50));
  console.log('TCP Server Test Suite');
  console.log('='.repeat(50));

  const results = [];

  for (let i = 0; i < testCases.length; i++) {
    currentTestIndex = i;
    try {
      const result = await runTest(testCases[i]);
      results.push(result);
      // Wait a bit between tests
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      console.error('Test failed with error:', error.message);
      results.push(false);
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('Test Summary');
  console.log('='.repeat(50));
  const passed = results.filter(r => r).length;
  const failed = results.filter(r => !r).length;
  console.log(`Total: ${results.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log('='.repeat(50));

  process.exit(failed > 0 ? 1 : 0);
}

runAllTests();

