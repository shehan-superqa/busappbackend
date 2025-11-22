const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');

// GET /api/locations/:deviceId - Get location history for a device
router.get('/:deviceId', deviceController.getDeviceLocationHistory);

module.exports = router;

