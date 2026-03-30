const repository = require('./offers.repository');
const ApiError = require('../../utils/apiError');

/**
 * Convert database offer to API model
 */
function toOfferModel(row) {
  const offer = {
    id: row.id,
    code: row.code,
    description: row.description || '',
    discountType: row.discount_type, // 'fixed' or 'percentage'
    discountValue: Number(row.discount_value || 0),
    maxDiscount: Number(row.max_discount || 0),
    minOrderValue: Number(row.min_order_value || 0),
    usage: {
      total: parseInt(row.max_usage) === -1 ? 'Unlimited' : parseInt(row.max_usage),
      current: parseInt(row.current_usage || 0),
      perUser: parseInt(row.usage_per_user || 1),
    },
    validity: {
      from: row.valid_from,
      until: row.valid_until,
      isActive: Boolean(row.is_active),
    },
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };

  // Format discount display
  if (row.discount_type === 'percentage') {
    offer.discountDisplay = `${row.discount_value}% Off`;
    if (row.max_discount > 0) {
      offer.discountDisplay += ` (Max: $${Number(row.max_discount).toFixed(2)})`;
    }
  } else {
    offer.discountDisplay = `$${Number(row.discount_value).toFixed(2)} Off`;
  }

  return offer;
}

/**
 * Get all active offers
 */
async function getAllOffers() {
  console.log('🎁 [OFFERS_SERVICE] Fetching all active offers...');
  
  const rows = await repository.listActiveOffers();
  const offers = rows.map(toOfferModel);
  
  console.log(`✅ [OFFERS_SERVICE] Returning ${offers.length} offers`);
  return offers;
}

/**
 * Get single offer by ID
 */
async function getOfferById(id) {
  console.log(`🎁 [OFFERS_SERVICE] Fetching offer: ${id}`);
  
  const row = await repository.getOfferById(id);
  if (!row) {
    throw new ApiError(404, 'Offer not found');
  }

  const offer = toOfferModel(row);
  console.log(`✅ [OFFERS_SERVICE] Offer retrieved: ${id}`);
  return offer;
}

/**
 * Validate and apply coupon code
 */
async function validateCoupon(code, orderAmount, userId = null) {
  console.log(`🎁 [OFFERS_SERVICE] Validating coupon: code=${code}, amount=${orderAmount}`);
  
  // Check if offer exists
  const coupon = await repository.getOfferByCode(code);
  if (!coupon) {
    console.warn(`⚠️  [OFFERS_SERVICE] Coupon not found: ${code}`);
    throw new ApiError(404, `Coupon code "${code}" not found or expired`);
  }

  // Check minimum order value
  if (Number(coupon.min_order_value) > orderAmount) {
    console.warn(
      `⚠️  [OFFERS_SERVICE] Order amount too low: ${orderAmount} < ${coupon.min_order_value}`
    );
    throw new ApiError(
      400,
      `Minimum order amount is $${Number(coupon.min_order_value).toFixed(2)}`
    );
  }

  // Check usage limit
  if (
    parseInt(coupon.max_usage) !== -1 &&
    parseInt(coupon.current_usage) >= parseInt(coupon.max_usage)
  ) {
    console.warn(`⚠️  [OFFERS_SERVICE] Coupon usage limit exceeded: ${code}`);
    throw new ApiError(400, `Coupon code "${code}" has reached maximum usage`);
  }

  // Check per-user usage limit if userId provided
  if (userId) {
    const userUsage = await repository.getUserCouponUsage(userId, coupon.id);
    if (userUsage >= parseInt(coupon.usage_per_user)) {
      console.warn(
        `⚠️  [OFFERS_SERVICE] User has already used coupon: ${code}`
      );
      throw new ApiError(400, `You have already used this coupon`);
    }
  }

  // Calculate discount
  let discount = 0;
  if (coupon.discount_type === 'fixed') {
    discount = Number(coupon.discount_value);
  } else if (coupon.discount_type === 'percentage') {
    discount = (orderAmount * Number(coupon.discount_value)) / 100;
  }

  // Apply max discount cap if exists
  if (Number(coupon.max_discount) > 0) {
    discount = Math.min(discount, Number(coupon.max_discount));
  }

  const finalAmount = Math.max(0, orderAmount - discount);

  console.log(`✅ [OFFERS_SERVICE] Coupon validated successfully`);
  console.log(`   Original: $${orderAmount.toFixed(2)}`);
  console.log(`   Discount: $${discount.toFixed(2)}`);
  console.log(`   Final: $${finalAmount.toFixed(2)}`);

  return {
    valid: true,
    couponId: coupon.id,
    code: coupon.code,
    description: coupon.description,
    originalAmount: Number(orderAmount.toFixed(2)),
    discount: Number(discount.toFixed(2)),
    finalAmount: Number(finalAmount.toFixed(2)),
    discountType: coupon.discount_type,
  };
}

/**
 * Apply coupon to order (record usage)
 */
async function applyCoupon(couponCode, userId, orderAmount) {
  console.log(`🎁 [OFFERS_SERVICE] Applying coupon: ${couponCode}`);
  
  // Validate first
  const validation = await validateCoupon(couponCode, orderAmount, userId);

  // Record usage
  const coupon = await repository.getOfferByCode(couponCode);
  await repository.recordCouponUsage(userId, coupon.id);

  console.log(`✅ [OFFERS_SERVICE] Coupon successfully applied and recorded`);
  return validation;
}

module.exports = {
  getAllOffers,
  getOfferById,
  validateCoupon,
  applyCoupon,
};
