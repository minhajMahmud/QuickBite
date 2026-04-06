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
 * Convert database coupon to admin model (includes close state details)
 */
function toAdminCouponModel(row) {
  const coupon = toOfferModel(row);
  coupon.adminState = row.admin_state || 'active';

  switch (coupon.adminState) {
    case 'manual_closed':
      coupon.closeReason = 'Manually closed by admin';
      break;
    case 'auto_closed_timer':
      coupon.closeReason = 'Auto closed by timer';
      break;
    case 'auto_closed_usage':
      coupon.closeReason = 'Auto closed by usage limit';
      break;
    case 'scheduled':
      coupon.closeReason = 'Scheduled (not started yet)';
      break;
    default:
      coupon.closeReason = 'Active';
  }

  return coupon;
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
 * Get all coupons for admin panel (active + closed + scheduled)
 */
async function getAllCouponsForAdmin() {
  console.log('🎁 [OFFERS_SERVICE] Fetching all coupons for admin...');

  const rows = await repository.listAllCouponsForAdmin();
  const coupons = rows.map(toAdminCouponModel);

  console.log(`✅ [OFFERS_SERVICE] Returning ${coupons.length} admin coupons`);
  return coupons;
}

/**
 * Manually close/reopen coupon from admin panel
 */
async function setCouponActiveState(couponId, isActive) {
  const coupon = await repository.getCouponByIdAny(couponId);
  if (!coupon) {
    throw new ApiError(404, 'Coupon not found');
  }

  if (isActive === true) {
    const now = new Date();
    const validUntil = coupon.valid_until ? new Date(coupon.valid_until) : null;
    const validFrom = coupon.valid_from ? new Date(coupon.valid_from) : null;
    const usageCapped = Number(coupon.max_usage) !== -1;
    const usageExhausted = usageCapped && Number(coupon.current_usage) >= Number(coupon.max_usage);

    if (validUntil && validUntil <= now) {
      throw new ApiError(
        400,
        'Cannot reopen: coupon expired by timer. Extend validity first.'
      );
    }

    if (usageExhausted) {
      throw new ApiError(
        400,
        'Cannot reopen: coupon usage limit has already been reached.'
      );
    }

    // If scheduled in future, reopening is allowed; it will remain scheduled until valid_from.
    if (validFrom && validFrom > now) {
      // intentionally allowed
    }
  }

  const updated = await repository.setCouponIsActive(couponId, isActive);
  if (!updated) {
    throw new ApiError(500, 'Failed to update coupon state');
  }

  return {
    coupon: toAdminCouponModel({
      ...updated,
      admin_state: isActive ? 'active' : 'manual_closed',
    }),
    message: isActive
      ? 'Coupon reopened successfully'
      : 'Coupon manually closed successfully',
  };
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
 * Create a new coupon (admin only)
 */
async function createCoupon(couponData, createdBy) {
  console.log('🎁 [OFFERS_SERVICE] Creating new coupon...');
  
  const { code, description, discountType, discountValue, maxDiscount, minOrderValue, maxUsage, usagePerUser, validFrom, validUntil } = couponData;

  // Validation
  if (!code || code.trim() === '') {
    throw new ApiError(400, 'Coupon code is required');
  }

  if (!discountValue || Number(discountValue) <= 0) {
    throw new ApiError(400, 'Discount value must be greater than 0');
  }

  if (discountType === 'percentage' && Number(discountValue) > 100) {
    throw new ApiError(400, 'Percentage discount cannot exceed 100%');
  }

  if (maxDiscount && Number(maxDiscount) < 0) {
    throw new ApiError(400, 'Max discount cannot be negative');
  }

  if (minOrderValue && Number(minOrderValue) < 0) {
    throw new ApiError(400, 'Minimum order value cannot be negative');
  }

  const validFromDate = validFrom ? new Date(validFrom) : null;
  const validUntilDate = validUntil ? new Date(validUntil) : null;

  if (validFromDate && Number.isNaN(validFromDate.getTime())) {
    throw new ApiError(400, 'Valid from date is invalid');
  }

  if (validUntilDate && Number.isNaN(validUntilDate.getTime())) {
    throw new ApiError(400, 'Valid until date is invalid');
  }

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  if (validFromDate && validFromDate < startOfToday) {
    throw new ApiError(400, 'Valid from date cannot be in the past');
  }

  if (validUntilDate && validUntilDate < startOfToday) {
    throw new ApiError(400, 'Valid until date cannot be in the past');
  }

  if (validFromDate && validUntilDate && validFromDate > validUntilDate) {
    throw new ApiError(400, 'Valid from date must be before valid until date');
  }

  const coupon = await repository.createCoupon(
    {
      code,
      description,
      discountType,
      discountValue,
      maxDiscount,
      minOrderValue,
      maxUsage,
      usagePerUser,
      validFrom,
      validUntil,
    },
    createdBy
  );

  if (!coupon) {
    throw new ApiError(500, 'Failed to create coupon');
  }

  console.log(`✅ [OFFERS_SERVICE] Coupon created successfully: ${coupon.id}`);
  return {
    coupon: toAdminCouponModel(coupon),
    message: 'Coupon created successfully',
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
  getAllCouponsForAdmin,
  setCouponActiveState,
  createCoupon,
  getOfferById,
  validateCoupon,
  applyCoupon,
};
