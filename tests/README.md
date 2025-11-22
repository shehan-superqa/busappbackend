# TCP Server Test Scripts

This folder contains test scripts for testing the TCP socket server.

## Test Scripts

### 1. `test-tcp-client.js`
Simple test script that:
- Connects to the TCP server
- Receives connection acknowledgment
- Sends test data
- Verifies the response

**Usage:**
```bash
node tests/test-tcp-client.js
```

### 2. `test-tcp-client-advanced.js`
Advanced test suite that runs multiple test cases:
- Valid data with single passenger
- Valid data with multiple passengers
- Invalid data (error handling)

**Usage:**
```bash
node tests/test-tcp-client-advanced.js
```

## Prerequisites

Make sure the TCP server is running before executing the test scripts:

```bash
npm run dev
```

## Configuration

Both scripts connect to `localhost:8080` by default. You can modify the `HOST` and `PORT` constants in the scripts if needed.

## Expected Output

### Simple Test
- Connection established
- Connection acknowledgment received
- Data sent and processed successfully

### Advanced Test
- Runs multiple test cases
- Shows pass/fail for each test
- Provides a summary at the end

