const express = require('express');
const controller = require('./offers.controller');
const { requireAuth, requireRole } = require('../../middlewares/auth');

const router = express.Router();

// Get all active offers
router.get('/', controller.getAllOffers);

// Get all coupons for admin panel
router.get(
	'/admin/all',
	requireAuth,
	requireRole('admin'),
	controller.getAllCouponsForAdmin
);

// Create new coupon (admin only)
router.post(
	'/admin/create',
	requireAuth,
	requireRole('admin'),
	controller.createCoupon
);

router.patch(
	'/admin/:id/status',
	requireAuth,
	requireRole('admin'),
	controller.setCouponStatus
);

// Get single offer by ID
router.get('/:id', controller.getOfferById);

// Validate coupon code (public - no auth required)
router.post('/validate', controller.validateCoupon);

// Apply coupon (could require auth later if needed)
router.post('/apply', controller.applyCoupon);

module.exports = router;
