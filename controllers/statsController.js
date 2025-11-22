const DeviceData = require('../models/DeviceData');

// Get statistics
exports.getStats = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    
    const matchQuery = {};
    
    if (startDate || endDate) {
      matchQuery.timestamp = {};
      if (startDate) matchQuery.timestamp.$gte = parseInt(startDate);
      if (endDate) matchQuery.timestamp.$lte = parseInt(endDate);
    }
    
    // Total passengers
    const totalPassengersPipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      { $count: 'total' }
    ];
    
    const totalPassengersResult = await DeviceData.aggregate(totalPassengersPipeline);
    const totalPassengers = totalPassengersResult[0]?.total || 0;
    
    // Active devices (devices that sent data in the time range)
    const activeDevices = await DeviceData.distinct('deviceId', matchQuery);
    
    // Total records
    const totalRecords = await DeviceData.countDocuments(matchQuery);
    
    // Unique passenger cards
    const uniquePassengersPipeline = [
      { $match: matchQuery },
      { $unwind: '$passengers' },
      { $group: { _id: '$passengers.cardId' } },
      { $count: 'total' }
    ];
    
    const uniquePassengersResult = await DeviceData.aggregate(uniquePassengersPipeline);
    const uniquePassengers = uniquePassengersResult[0]?.total || 0;
    
    // Device statistics
    const deviceStatsPipeline = [
      { $match: matchQuery },
      {
        $group: {
          _id: '$deviceId',
          recordCount: { $sum: 1 },
          passengerCount: { $sum: { $size: '$passengers' } },
          lastUpdate: { $max: '$timestamp' }
        }
      },
      { $sort: { recordCount: -1 } }
    ];
    
    const deviceStats = await DeviceData.aggregate(deviceStatsPipeline);
    
    res.json({
      success: true,
      stats: {
        totalPassengers,
        uniquePassengers,
        activeDevices: activeDevices.length,
        totalRecords,
        deviceStats,
        timeRange: {
          startDate: startDate || null,
          endDate: endDate || null
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

