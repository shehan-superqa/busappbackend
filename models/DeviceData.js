const mongoose = require('mongoose');

const passengerSchema = new mongoose.Schema({
  cardId: {
    type: String,
    required: true,
    index: true
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
    required: true,
    index: true
  },
  timestamp: {
    type: Number,
    required: true,
    index: true
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
    index: true
  }
}, {
  timestamps: true
});

// Indexes for better query performance
deviceDataSchema.index({ deviceId: 1, timestamp: -1 });
deviceDataSchema.index({ 'passengers.cardId': 1, timestamp: -1 });
deviceDataSchema.index({ serverReceivedAt: -1 });

module.exports = mongoose.model('DeviceData', deviceDataSchema);

