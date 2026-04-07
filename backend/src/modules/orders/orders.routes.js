const express = require('express');
const validate = require('../../middlewares/validate');
const { requireAuth } = require('../../middlewares/auth');
const controller = require('./orders.controller');

const router = express.Router();

router.use(requireAuth);

router.get('/', controller.listOrders);
router.post('/', validate(['restaurantId', 'items', 'totalAmount']), controller.createOrder);
router.get('/:id', controller.getOrder);
router.get('/:id/events', controller.streamOrderEvents);
router.patch('/:id/status', validate(['status']), controller.updateStatus);
router.patch('/:id/payment', validate(['paymentMethod']), controller.updatePayment);

module.exports = router;
