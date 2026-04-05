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
 * GET /api/v1/offers/admin/all
 * Get all coupons for admin panel
 */
async function getAllCouponsForAdmin(req, res, next) {
  try {
    console.log('🎁 [OFFERS_CONTROLLER] GET /offers/admin/all requested');
    const coupons = await service.getAllCouponsForAdmin();
    res.json({
      success: true,
      message: `Found ${coupons.length} coupons`,
      coupons,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/offers/admin/:id/status
 * Manual close/reopen coupon
 * Body: { isActive: boolean }
 */
async function setCouponStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { isActive } = req.body || {};

    if (typeof isActive !== 'boolean') {
      throw new ApiError(400, 'Field "isActive" must be boolean');
    }

    const result = await service.setCouponActiveState(id, isActive);

    res.json({
      success: true,
      message: result.message,
      coupon: result.coupon,
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
  getAllCouponsForAdmin,
  setCouponStatus,
  getOfferById,
  validateCoupon,
  applyCoupon,
};
