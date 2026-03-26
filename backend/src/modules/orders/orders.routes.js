const express = require('express');
const validate = require('../../middlewares/validate');
const { requireAuth } = require('../../middlewares/auth');
const controller = require('./orders.controller');

const router = express.Router();

router.use(requireAuth);

router.get('/', controller.listOrders);
router.post('/', validate(['restaurantId', 'items', 'totalAmount']), controller.createOrder);
router.patch('/:id/status', validate(['status']), controller.updateStatus);

module.exports = router;
