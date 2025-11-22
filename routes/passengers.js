const express = require('express');
const router = express.Router();
const passengerController = require('../controllers/passengerController');

// GET /api/passengers - Get all passenger records (with pagination)
router.get('/', passengerController.getAllPassengers);

// GET /api/passengers/:cardId - Get records for specific passenger card
router.get('/:cardId', passengerController.getPassengerRecords);

module.exports = router;

