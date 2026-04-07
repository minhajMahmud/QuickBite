const express = require('express');
const { requireAuth, requireRole } = require('../../middlewares/auth');
const controller = require('./restaurantDashboard.controller');

const router = express.Router();

router.use(requireAuth, requireRole('admin', 'restaurant'));

router.get('/overview', controller.overview);
router.patch('/profile', controller.updateProfile);
router.get('/menu', controller.listMenu);
router.post('/menu', controller.createMenuItem);
router.patch('/menu/:foodItemId', controller.updateMenuItem);
router.delete('/menu/:foodItemId', controller.deleteMenuItem);
router.get('/orders', controller.listOrders);
router.patch('/orders/:orderId/status', controller.updateOrderStatus);
router.get('/analytics', controller.analytics);

module.exports = router;
