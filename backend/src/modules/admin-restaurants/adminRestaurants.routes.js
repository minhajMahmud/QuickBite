const express = require('express');
const { requireAuth, requireRole } = require('../../middlewares/auth');
const controller = require('./adminRestaurants.controller');

const router = express.Router();

router.use(requireAuth, requireRole('admin'));
router.get('/', controller.listRestaurants);
router.patch('/:restaurantId/approval', controller.setRestaurantApproval);
router.patch('/:restaurantId/restriction', controller.setRestaurantRestriction);

module.exports = router;
