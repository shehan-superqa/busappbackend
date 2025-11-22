const DeviceData = require('../models/DeviceData');

// Get all passenger records with pagination
exports.getAllPassengers = async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, startDate, endDate, deviceId } = req.query;
    
    const matchQuery = {};
    
    if (startDate || endDate) {
      matchQuery.timestamp = {};
      if (startDate) matchQuery.timestamp.$gte = parseInt(startDate);
      if (endDate) matchQuery.timestamp.$lte = parseInt(endDate);
    }
    
    if (deviceId) {
      matchQuery.deviceId = deviceId;
    }
    
    // Aggregate to get all passenger records
    const pipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      {
        $project: {
          cardId: '$passengers.cardId',
          timestamp: '$passengers.timestamp',
          deviceId: 1,
          location: 1,
          serverReceivedAt: 1
        }
      },
      { $sort: { timestamp: -1 } },
      { $skip: parseInt(offset) },
      { $limit: parseInt(limit) }
    ];
    
    const data = await DeviceData.aggregate(pipeline);
    
    // Get total count
    const countPipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      { $count: 'total' }
    ];
    
    const countResult = await DeviceData.aggregate(countPipeline);
    const total = countResult[0]?.total || 0;
    
    res.json({
      success: true,
      total,
      count: data.length,
      data
    });
  } catch (error) {
    next(error);
  }
};

// Get records for specific passenger card
exports.getPassengerRecords = async (req, res, next) => {
  try {
    const { cardId } = req.params;
    const { limit = 50, offset = 0, startDate, endDate } = req.query;
    
    const matchQuery = {
      'passengers.cardId': cardId
    };
    
    if (startDate || endDate) {
      matchQuery['passengers.timestamp'] = {};
      if (startDate) matchQuery['passengers.timestamp'].$gte = parseInt(startDate);
      if (endDate) matchQuery['passengers.timestamp'].$lte = parseInt(endDate);
    }
    
    const pipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      { $match: { 'passengers.cardId': cardId } },
      {
        $project: {
          cardId: '$passengers.cardId',
          timestamp: '$passengers.timestamp',
          deviceId: 1,
          location: 1,
          serverReceivedAt: 1
        }
      },
      { $sort: { timestamp: -1 } },
      { $skip: parseInt(offset) },
      { $limit: parseInt(limit) }
    ];
    
    const data = await DeviceData.aggregate(pipeline);
    
    // Get total count
    const countPipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      { $match: { 'passengers.cardId': cardId } },
      { $count: 'total' }
    ];
    
    const countResult = await DeviceData.aggregate(countPipeline);
    const total = countResult[0]?.total || 0;
    
    res.json({
      success: true,
      cardId,
      total,
      count: data.length,
      data
    });
  } catch (error) {
    next(error);
  }
};

