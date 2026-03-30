const express = require('express');
const controller = require('./offers.controller');

const router = express.Router();

// Get all active offers
router.get('/', controller.getAllOffers);

// Get single offer by ID
router.get('/:id', controller.getOfferById);

// Validate coupon code (public - no auth required)
router.post('/validate', controller.validateCoupon);

// Apply coupon (could require auth later if needed)
router.post('/apply', controller.applyCoupon);

module.exports = router;
