const { pool } = require('../../config/db');

/**
 * Get all active offers
 */
async function listActiveOffers() {
  console.log('📝 [OFFERS_REPO] Fetching active offers...');
  
  const query = `
    SELECT
      id,
      code,
      description,
      discount_type,
      discount_value,
      COALESCE(max_discount, 0) as max_discount,
      min_order_value,
      max_usage,
      current_usage,
      usage_per_user,
      valid_from,
      valid_until,
      is_active,
      created_at,
      updated_at
    FROM public.coupons
    WHERE is_active = TRUE
      AND (valid_until IS NULL OR valid_until > NOW())
      AND (valid_from IS NULL OR valid_from <= NOW())
      AND (max_usage = -1 OR current_usage < max_usage)
    ORDER BY discount_value DESC, created_at DESC;
  `;

  try {
    const { rows } = await pool.query(query);
    console.log(`✅ [OFFERS_REPO] Found ${rows.length} active offers`);
    return rows;
  } catch (error) {
    console.error('❌ [OFFERS_REPO] Failed to fetch offers:', error.message);
    throw error;
  }
}

/**
 * Get offer by code
 */
async function getOfferByCode(code) {
  console.log(`📝 [OFFERS_REPO] Fetching offer by code: ${code}`);
  
  const query = `
    SELECT
      id,
      code,
      description,
      discount_type,
      discount_value,
      COALESCE(max_discount, 0) as max_discount,
      min_order_value,
      max_usage,
      current_usage,
      usage_per_user,
      valid_from,
      valid_until,
      is_active,
      created_at,
      updated_at
    FROM public.coupons
    WHERE UPPER(code) = UPPER($1)
      AND is_active = TRUE
      AND (valid_until IS NULL OR valid_until > NOW())
      AND (valid_from IS NULL OR valid_from <= NOW())
    LIMIT 1;
  `;

  try {
    const { rows } = await pool.query(query, [code]);
    if (rows.length === 0) {
      console.log(`⚠️  [OFFERS_REPO] Offer not found: ${code}`);
      return null;
    }
    console.log(`✅ [OFFERS_REPO] Offer found: ${code}`);
    return rows[0];
  } catch (error) {
    console.error('❌ [OFFERS_REPO] Failed to fetch offer by code:', error.message);
    throw error;
  }
}

/**
 * Get offer by ID
 */
async function getOfferById(id) {
  console.log(`📝 [OFFERS_REPO] Fetching offer by ID: ${id}`);
  
  const query = `
    SELECT
      id,
      code,
      description,
      discount_type,
      discount_value,
      COALESCE(max_discount, 0) as max_discount,
      min_order_value,
      max_usage,
      current_usage,
      usage_per_user,
      valid_from,
      valid_until,
      is_active,
      created_at,
      updated_at
    FROM public.coupons
    WHERE id = $1
      AND is_active = TRUE
    LIMIT 1;
  `;

  try {
    const { rows } = await pool.query(query, [id]);
    if (rows.length === 0) {
      console.log(`⚠️  [OFFERS_REPO] Offer not found: ${id}`);
      return null;
    }
    console.log(`✅ [OFFERS_REPO] Offer found: ${id}`);
    return rows[0];
  } catch (error) {
    console.error('❌ [OFFERS_REPO] Failed to fetch offer by ID:', error.message);
    throw error;
  }
}

/**
 * Check user usage of a coupon
 */
async function getUserCouponUsage(userId, couponId) {
  console.log(`📝 [OFFERS_REPO] Checking user coupon usage: user=${userId}, coupon=${couponId}`);
  
  const query = `
    SELECT COUNT(*) as usage_count
    FROM public.coupon_usage
    WHERE user_id = $1 AND coupon_id = $2;
  `;

  try {
    const { rows } = await pool.query(query, [userId, couponId]);
    const usageCount = parseInt(rows[0].usage_count || 0);
    console.log(`✅ [OFFERS_REPO] User has used coupon ${usageCount} times`);
    return usageCount;
  } catch (error) {
    console.error('❌ [OFFERS_REPO] Failed to check user coupon usage:', error.message);
    throw error;
  }
}

/**
 * Record coupon usage
 */
async function recordCouponUsage(userId, couponId) {
  console.log(`📝 [OFFERS_REPO] Recording coupon usage: user=${userId}, coupon=${couponId}`);
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Record usage
    const usageId = require('crypto').randomUUID();
    const usageQuery = `
      INSERT INTO public.coupon_usage (id, user_id, coupon_id, used_at, created_at)
      VALUES ($1, $2, $3, NOW(), NOW());
    `;
    await client.query(usageQuery, [usageId, userId, couponId]);

    // Increment current_usage counter
    const updateQuery = `
      UPDATE public.coupons
      SET current_usage = current_usage + 1, updated_at = NOW()
      WHERE id = $1;
    `;
    await client.query(updateQuery, [couponId]);

    await client.query('COMMIT');
    console.log(`✅ [OFFERS_REPO] Coupon usage recorded successfully`);
    return true;
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ [OFFERS_REPO] Failed to record coupon usage:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  listActiveOffers,
  getOfferByCode,
  getOfferById,
  getUserCouponUsage,
  recordCouponUsage,
};
