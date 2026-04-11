const express = require('express');
const controller = require('./users.controller');
const { requireAuth, requireRole } = require('../../middlewares/auth');

const router = express.Router();

router.get('/me', requireAuth, controller.me);
router.get('/me/delivery-dashboard', requireAuth, controller.getMyDeliveryDashboard);
router.patch('/me', requireAuth, controller.updateMe);
router.get('/me/addresses', requireAuth, controller.listMyAddresses);
router.post('/me/addresses', requireAuth, controller.createMyAddress);
router.patch('/me/addresses/:id', requireAuth, controller.updateMyAddress);
router.patch('/me/addresses/:id/default', requireAuth, controller.setMyDefaultAddress);
router.delete('/me/addresses/:id', requireAuth, controller.deleteMyAddress);
router.get('/me/favorites', requireAuth, controller.listMyFavorites);
router.post('/me/favorites', requireAuth, controller.addMyFavorite);
router.delete('/me/favorites/:restaurantId', requireAuth, controller.removeMyFavorite);
router.get('/me/notifications', requireAuth, controller.listMyNotifications);
router.patch('/me/notifications/read-all', requireAuth, controller.markMyNotificationsRead);
router.get('/pending-approvals', requireAuth, requireRole('admin'), controller.listPendingApprovals);
router.patch('/:id/approval', requireAuth, requireRole('admin'), controller.setUserApproval);
router.get('/', requireAuth, requireRole('admin'), controller.listUsers);

module.exports = router;
