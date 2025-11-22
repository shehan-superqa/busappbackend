require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/database');
const TCPServer = require('./tcp-server');

// Import routes
const deviceRoutes = require('./routes/devices');
const passengerRoutes = require('./routes/passengers');
const statsRoutes = require('./routes/stats');
const locationRoutes = require('./routes/locations');

const app = express();
const PORT = process.env.PORT || 3000;
const TCP_PORT = process.env.TCP_PORT || 8080;

// Connect to database
connectDB();

// Middleware
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/devices', deviceRoutes);
app.use('/api/passengers', passengerRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/locations', locationRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.path
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start Express server
const expressServer = app.listen(PORT, () => {
  console.log(`[HTTP] Express server running on port ${PORT}`);
});

// Start TCP server
const tcpServer = new TCPServer(TCP_PORT);
tcpServer.start();

// Graceful shutdown
const shutdown = async () => {
  console.log('\n[SHUTDOWN] Graceful shutdown initiated...');
  
  // Close Express server
  expressServer.close(() => {
    console.log('[SHUTDOWN] Express server closed');
  });
  
  // Close TCP server
  await tcpServer.stop();
  
  // Close database connection
  const mongoose = require('mongoose');
  await mongoose.connection.close();
  console.log('[SHUTDOWN] Database connection closed');
  
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

module.exports = app;

