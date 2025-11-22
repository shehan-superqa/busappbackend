const DeviceData = require('../models/DeviceData');

// Get all devices
exports.getAllDevices = async (req, res, next) => {
  try {
    const devices = await DeviceData.distinct('deviceId');
    res.json({
      success: true,
      count: devices.length,
      devices
    });
  } catch (error) {
    next(error);
  }
};

// Get data for specific device
exports.getDeviceData = async (req, res, next) => {
  try {
    const { deviceId } = req.params;
    const { limit = 50, offset = 0, startDate, endDate } = req.query;
    
    const query = { deviceId };
    
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = parseInt(startDate);
      if (endDate) query.timestamp.$lte = parseInt(endDate);
    }
    
    const data = await DeviceData.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(offset));
    
    const total = await DeviceData.countDocuments(query);
    
    res.json({
      success: true,
      deviceId,
      total,
      count: data.length,
      data
    });
  } catch (error) {
    next(error);
  }
};

// Manually add device data (for testing)
exports.createDeviceData = async (req, res, next) => {
  try {
    const { deviceId, timestamp, passengers, location } = req.body;
    
    // Validate required fields
    if (!deviceId || !timestamp || !passengers || !location) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: deviceId, timestamp, passengers, location'
      });
    }
    
    if (!Array.isArray(passengers)) {
      return res.status(400).json({
        success: false,
        error: 'passengers must be an array'
      });
    }
    
    if (typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      return res.status(400).json({
        success: false,
        error: 'location must have latitude and longitude as numbers'
      });
    }
    
    const now = new Date();
    const deviceData = new DeviceData({
      deviceId,
      timestamp,
      passengers,
      location,
      serverReceivedAt: now,
      createdtime: now
    });
    
    await deviceData.save();
    
    res.status(201).json({
      success: true,
      message: 'Device data created successfully',
      data: deviceData
    });
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        details: Object.values(error.errors).map(e => e.message)
      });
    }
    next(error);
  }
};

// Get location history for a device
exports.getDeviceLocationHistory = async (req, res, next) => {
  try {
    const { deviceId } = req.params;
    const { limit = 100, offset = 0 } = req.query;
    
    const data = await DeviceData.find({ deviceId })
      .select('location timestamp serverReceivedAt')
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(offset));
    
    const total = await DeviceData.countDocuments({ deviceId });
    
    res.json({
      success: true,
      deviceId,
      total,
      count: data.length,
      locations: data
    });
  } catch (error) {
    next(error);
  }
};

