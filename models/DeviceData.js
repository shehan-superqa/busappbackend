const mongoose = require('mongoose');

const passengerSchema = new mongoose.Schema({
  cardId: {
    type: String,
    required: true
    // Note: Cannot index array fields in timeseries collections
  },
  timestamp: {
    type: Number,
    required: true
  }
}, { _id: false });

const locationSchema = new mongoose.Schema({
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  }
}, { _id: false });

const deviceDataSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true
    // Indexed via metaField in timeseries config
  },
  timestamp: {
    type: Number,
    required: true
  },
  passengers: {
    type: [passengerSchema],
    required: true,
    default: []
  },
  location: {
    type: locationSchema,
    required: true
  },
  serverReceivedAt: {
    type: Date,
    default: Date.now,
    required: true
  },
  createdtime: {
    type: Date,
    default: Date.now,
    required: true
  }
}, {
  timestamps: true,
  // Configure as timeseries collection
  timeseries: {
    timeField: 'createdtime',
    metaField: 'deviceId',
    granularity: 'seconds'
  }
});

// Note: In timeseries collections:
// - metaField (deviceId) is automatically indexed
// - timeField (createdtime) is automatically indexed
// - Array fields (like passengers) cannot be indexed
// - Do not create explicit indexes on array fields or it will cause errors

// Use the 'sensoridata' collection name
module.exports = mongoose.model('DeviceData', deviceDataSchema, 'sensoridata');

