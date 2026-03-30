const service = require('./offers.service');
const ApiError = require('../../utils/apiError');

/**
 * GET /api/v1/offers
 * Get all active offers
 */
async function getAllOffers(req, res, next) {
  try {
    console.log('🎁 [OFFERS_CONTROLLER] GET /offers requested');
    const offers = await service.getAllOffers();
    res.json({
      success: true,
      message: `Found ${offers.length} active offers`,
      offers,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/offers/:id
 * Get single offer by ID
 */
async function getOfferById(req, res, next) {
  try {
    const { id } = req.params;
    console.log(`🎁 [OFFERS_CONTROLLER] GET /offers/${id} requested`);
    
    const offer = await service.getOfferById(id);
    
    res.json({
      success: true,
      offer,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/offers/validate
 * Validate a coupon code
 * Body: { code, orderAmount }
 */
async function validateCoupon(req, res, next) {
  try {
    const { code, orderAmount } = req.body;
    console.log(`🎁 [OFFERS_CONTROLLER] POST /offers/validate: code=${code}`);

    if (!code || !orderAmount) {
      throw new ApiError(400, 'Missing required fields: code, orderAmount');
    }

    if (orderAmount <= 0) {
      throw new ApiError(400, 'Order amount must be greater than 0');
    }

    const result = await service.validateCoupon(code, orderAmount);

    res.json({
      success: true,
      message: 'Coupon is valid',
      ...result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/offers/apply
 * Apply coupon code to order
 * Body: { code, orderAmount, userId? }
 */
async function applyCoupon(req, res, next) {
  try {
    const { code, orderAmount, userId } = req.body;
    
    console.log(`🎁 [OFFERS_CONTROLLER] POST /offers/apply: code=${code}`);

    if (!code || !orderAmount) {
      throw new ApiError(400, 'Missing required fields: code, orderAmount');
    }

    if (orderAmount <= 0) {
      throw new ApiError(400, 'Order amount must be greater than 0');
    }

    const result = await service.applyCoupon(code, userId, orderAmount);

    res.json({
      success: true,
      message: 'Coupon applied successfully',
      ...result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllOffers,
  getOfferById,
  validateCoupon,
  applyCoupon,
};
