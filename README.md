# Contactless Bus Ticketing System - Backend Server

Express.js backend server for a contactless bus ticketing system that receives passenger data from ESP32 devices via TCP sockets.

## Features

- **TCP Socket Server**: Receives real-time data from ESP32 devices on port 8080
- **REST API**: Express.js API for querying device and passenger data
- **MongoDB Integration**: Stores all device data, passenger records, and GPS locations
- **Error Handling**: Comprehensive error handling for TCP and HTTP requests
- **Logging**: Request logging with Morgan middleware
- **CORS Support**: Enabled for frontend access
- **Graceful Shutdown**: Handles SIGTERM and SIGINT signals

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher) - running locally or remote instance
- npm or yarn

## Installation

1. Clone the repository and navigate to the server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file from the example:
```bash
cp .env.example .env
```

4. Update `.env` with your configuration:
```env
PORT=3000
TCP_PORT=8080
NODE_ENV=development
DB_URL=mongodb://localhost:27017/busticketing
```

5. Make sure MongoDB is running on your system.

## Running the Server

### Development Mode (with auto-reload):
```bash
npm run dev
```

### Production Mode:
```bash
npm start
```

The server will start:
- **HTTP Server** on port 3000 (or PORT from .env)
- **TCP Server** on port 8080 (or TCP_PORT from .env)

## API Endpoints

### Health Check
- `GET /health` - Server health check

### Devices
- `GET /api/devices` - List all devices
- `GET /api/devices/:deviceId` - Get data for specific device
  - Query params: `limit`, `offset`, `startDate`, `endDate`
- `GET /api/devices/:deviceId/locations` - Get location history for a device
  - Query params: `limit`, `offset`
- `POST /api/devices` - Manually add device data (for testing)

### Passengers
- `GET /api/passengers` - Get all passenger records (with pagination)
  - Query params: `limit`, `offset`, `startDate`, `endDate`, `deviceId`
- `GET /api/passengers/:cardId` - Get records for specific passenger card
  - Query params: `limit`, `offset`, `startDate`, `endDate`

### Statistics
- `GET /api/stats` - Get statistics (total passengers, active devices, etc.)
  - Query params: `startDate`, `endDate`

## TCP Data Format

The ESP32 should send JSON data in this format:

```json
{
  "deviceId": "BUS001",
  "timestamp": 1234567890,
  "passengers": [
    {
      "cardId": "ABC123",
      "timestamp": 1234567890
    }
  ],
  "location": {
    "latitude": 6.9271,
    "longitude": 79.8612
  }
}
```

## Testing

### Testing TCP Server with netcat (Linux/Mac):

```bash
# Connect to TCP server
nc localhost 8080

# Paste JSON data:
{"deviceId":"BUS001","timestamp":1234567890,"passengers":[{"cardId":"ABC123","timestamp":1234567890}],"location":{"latitude":6.9271,"longitude":79.8612}}

# You should receive "OK" response
```

### Testing TCP Server with PowerShell (Windows):

```powershell
# Create a TCP client
$client = New-Object System.Net.Sockets.TcpClient("localhost", 8080)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)

# Send JSON data
$json = '{"deviceId":"BUS001","timestamp":1234567890,"passengers":[{"cardId":"ABC123","timestamp":1234567890}],"location":{"latitude":6.9271,"longitude":79.8612}}'
$writer.WriteLine($json)
$writer.Flush()

# Read response
$response = $reader.ReadLine()
Write-Host $response

# Close connection
$writer.Close()
$reader.Close()
$client.Close()
```

### Testing REST API with curl:

```bash
# Health check
curl http://localhost:3000/health

# Get all devices
curl http://localhost:3000/api/devices

# Get device data
curl http://localhost:3000/api/devices/BUS001

# Get passenger records
curl http://localhost:3000/api/passengers

# Get specific passenger
curl http://localhost:3000/api/passengers/ABC123

# Get statistics
curl http://localhost:3000/api/stats

# Create device data (POST)
curl -X POST http://localhost:3000/api/devices \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "BUS001",
    "timestamp": 1234567890,
    "passengers": [
      {
        "cardId": "ABC123",
        "timestamp": 1234567890
      }
    ],
    "location": {
      "latitude": 6.9271,
      "longitude": 79.8612
    }
  }'
```

### Testing with Postman:

Import the following collection or create requests manually:

1. **Health Check**: GET `http://localhost:3000/health`
2. **Get All Devices**: GET `http://localhost:3000/api/devices`
3. **Get Device Data**: GET `http://localhost:3000/api/devices/BUS001`
4. **Create Device Data**: POST `http://localhost:3000/api/devices` with JSON body
5. **Get Passengers**: GET `http://localhost:3000/api/passengers`
6. **Get Stats**: GET `http://localhost:3000/api/stats`

## Project Structure

```
server/
├── server.js              # Main Express server
├── tcp-server.js          # TCP socket server
├── package.json           # Dependencies
├── .env.example           # Environment variables example
├── README.md              # This file
├── config/
│   └── database.js        # MongoDB connection
├── models/
│   └── DeviceData.js      # Database schema
├── routes/
│   ├── devices.js         # Device routes
│   ├── passengers.js      # Passenger routes
│   └── stats.js           # Statistics routes
└── controllers/
    ├── deviceController.js    # Device business logic
    ├── passengerController.js # Passenger business logic
    └── statsController.js     # Statistics logic
```

## Database Schema

The `DeviceData` collection stores:
- `deviceId` (String, indexed)
- `timestamp` (Number, indexed)
- `passengers` (Array of objects with `cardId` and `timestamp`)
- `location` (Object with `latitude` and `longitude`)
- `serverReceivedAt` (Date, indexed)
- `createdAt` and `updatedAt` (automatic timestamps)

## Error Handling

The server handles:
- TCP connection errors
- JSON parsing errors
- Database connection errors
- Validation errors
- Missing required fields

All errors are logged to the console and appropriate HTTP status codes are returned.

## Environment Variables

- `PORT`: HTTP server port (default: 3000)
- `TCP_PORT`: TCP socket server port (default: 8080)
- `DB_URL`: MongoDB connection string (default: mongodb://localhost:27017/busticketing)
- `NODE_ENV`: Environment mode (development/production)

## License

ISC

