const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');

// GET /api/devices - List all devices
router.get('/', deviceController.getAllDevices);

// GET /api/devices/:deviceId - Get data for specific device
router.get('/:deviceId', deviceController.getDeviceData);

// POST /api/devices - Manually add device data (for testing)
router.post('/', deviceController.createDeviceData);

// GET /api/devices/:deviceId/locations - Get location history for a device
router.get('/:deviceId/locations', deviceController.getDeviceLocationHistory);

module.exports = router;

