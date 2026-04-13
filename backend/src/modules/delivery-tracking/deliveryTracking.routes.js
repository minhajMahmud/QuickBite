const express = require('express');
const { requireAuth, requireRole } = require('../../middlewares/auth');
const controller = require('./deliveryTracking.controller');

const router = express.Router();

router.use(requireAuth, requireRole('delivery_partner'));

router.get('/orders/:orderId/current', controller.getCurrentTracking);
router.post('/orders/:orderId/location', controller.updateCurrentLocation);
router.get('/orders/:orderId/stream', controller.streamTracking);

module.exports = router;
