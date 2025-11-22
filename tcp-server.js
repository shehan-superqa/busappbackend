const net = require('net');
const DeviceData = require('./models/DeviceData');

class TCPServer {
  constructor(port = 8080) {
    this.port = port;
    this.server = null;
    this.clients = new Map();
  }

  start() {
    this.server = net.createServer((socket) => {
      const clientId = `${socket.remoteAddress}:${socket.remotePort}`;
      console.log(`[TCP] New client connected: ${clientId}`);
      
      // Send connection acknowledgment immediately
      try {
        socket.write('CONNECTED\n');
        console.log(`[TCP] Connection acknowledgment sent to ${clientId}`);
      } catch (error) {
        console.error(`[TCP] Error sending connection acknowledgment to ${clientId}:`, error.message);
      }
      
      let buffer = '';

      socket.on('data', async (data) => {
        try {
          buffer += data.toString();
          
          // Try to parse complete JSON objects
          let jsonEnd = this.findJsonEnd(buffer);
          
          while (jsonEnd !== -1) {
            const jsonStr = buffer.substring(0, jsonEnd + 1);
            buffer = buffer.substring(jsonEnd + 1).trim();
            
            try {
              await this.handleData(jsonStr, socket);
            } catch (error) {
              console.error(`[TCP] Error handling data from ${clientId}:`, error.message);
              socket.write('ERROR: ' + error.message + '\n');
            }
            
            jsonEnd = this.findJsonEnd(buffer);
          }
        } catch (error) {
          console.error(`[TCP] Error processing data from ${clientId}:`, error.message);
          socket.write('ERROR: Invalid data format\n');
        }
      });

      socket.on('error', (error) => {
        console.error(`[TCP] Socket error for ${clientId}:`, error.message);
      });

      socket.on('close', () => {
        console.log(`[TCP] Client disconnected: ${clientId}`);
        this.clients.delete(clientId);
      });

      this.clients.set(clientId, socket);
    });

    this.server.on('error', (error) => {
      console.error('[TCP] Server error:', error.message);
    });

    this.server.listen(this.port, () => {
      console.log(`[TCP] Server listening on port ${this.port}`);
    });
  }

  findJsonEnd(str) {
    let depth = 0;
    let inString = false;
    let escapeNext = false;

    for (let i = 0; i < str.length; i++) {
      const char = str[i];

      if (escapeNext) {
        escapeNext = false;
        continue;
      }

      if (char === '\\') {
        escapeNext = true;
        continue;
      }

      if (char === '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char === '{') {
        depth++;
      } else if (char === '}') {
        depth--;
        if (depth === 0) {
          return i;
        }
      }
    }

    return -1;
  }

  async handleData(jsonStr, socket) {
    try {
      const data = JSON.parse(jsonStr);
      
      // Validate required fields
      this.validateData(data);
      
      // Log received data
      console.log('[TCP] Received data:', JSON.stringify(data, null, 2));
      
      // Create device data document
      const deviceData = new DeviceData({
        deviceId: data.deviceId,
        timestamp: data.timestamp,
        passengers: data.passengers,
        location: data.location,
        serverReceivedAt: new Date()
      });
      
      // Save to database
      await deviceData.save();
      
      console.log(`[TCP] Data saved successfully for device: ${data.deviceId}`);
      
      // Send acknowledgment
      socket.write('OK\n');
      
    } catch (error) {
      if (error.name === 'ValidationError') {
        throw new Error(`Validation failed: ${Object.values(error.errors).map(e => e.message).join(', ')}`);
      }
      throw error;
    }
  }

  validateData(data) {
    if (!data.deviceId || typeof data.deviceId !== 'string') {
      throw new Error('deviceId is required and must be a string');
    }
    
    if (!data.timestamp || typeof data.timestamp !== 'number') {
      throw new Error('timestamp is required and must be a number');
    }
    
    if (!Array.isArray(data.passengers)) {
      throw new Error('passengers is required and must be an array');
    }
    
    data.passengers.forEach((passenger, index) => {
      if (!passenger.cardId || typeof passenger.cardId !== 'string') {
        throw new Error(`passengers[${index}].cardId is required and must be a string`);
      }
      if (!passenger.timestamp || typeof passenger.timestamp !== 'number') {
        throw new Error(`passengers[${index}].timestamp is required and must be a number`);
      }
    });
    
    if (!data.location || typeof data.location !== 'object') {
      throw new Error('location is required and must be an object');
    }
    
    if (typeof data.location.latitude !== 'number') {
      throw new Error('location.latitude is required and must be a number');
    }
    
    if (typeof data.location.longitude !== 'number') {
      throw new Error('location.longitude is required and must be a number');
    }
  }

  stop() {
    return new Promise((resolve) => {
      if (this.server) {
        this.server.close(() => {
          console.log('[TCP] Server closed');
          resolve();
        });
        
        // Close all client connections
        this.clients.forEach((socket) => {
          socket.destroy();
        });
        this.clients.clear();
      } else {
        resolve();
      }
    });
  }
}

module.exports = TCPServer;

