const { pool } = require('../../config/db');

async function listRestaurantsForAdmin() {
  const query = `
    SELECT
      r.id,
      r.name,
      r.description,
      r.image,
      r.cuisine,
      r.rating,
      r.review_count,
      r.delivery_time,
      r.delivery_fee,
      r.price_range,
      r.is_popular,
      r.status,
      r.is_approved,
      r.total_orders,
      r.total_revenue,
      r.owner_id,
      r.phone,
      r.email,
      r.street_address,
      r.city,
      r.state,
      r.postal_code,
      r.latitude,
      r.longitude,
      r.created_at,
      r.updated_at,
      COALESCE(u.name, '') AS owner_name,
      COALESCE(u.email, '') AS owner_email,
      COALESCE(u.status, 'active') AS owner_status,
      COALESCE(u.approved, TRUE) AS owner_approved,
      COALESCE(u.role, 'restaurant') AS owner_role,
      CASE
        WHEN COALESCE(u.status, 'active') = 'banned' THEN 'restricted'
        WHEN COALESCE(u.approved, TRUE) = FALSE THEN 'request'
        WHEN r.is_approved = FALSE THEN 'request'
        WHEN r.status = 'open' THEN 'active'
        ELSE 'inactive'
      END AS admin_state
    FROM restaurants r
    LEFT JOIN users u ON u.id = r.owner_id
    WHERE r.deleted_at IS NULL
    ORDER BY
      CASE
        WHEN COALESCE(u.status, 'active') = 'banned' THEN 0
        WHEN COALESCE(u.approved, TRUE) = FALSE OR r.is_approved = FALSE THEN 1
        WHEN r.status = 'open' THEN 2
        ELSE 3
      END,
      r.created_at DESC;
  `;

  const { rows } = await pool.query(query);
  return rows;
}

async function findRestaurantWithOwner(restaurantId) {
  const query = `
    SELECT
      r.id,
      r.name,
      r.status,
      r.is_approved,
      r.owner_id,
      u.id AS owner_user_id,
      u.name AS owner_name,
      u.email AS owner_email,
      u.role AS owner_role,
      u.status AS owner_status,
      u.approved AS owner_approved
    FROM restaurants r
    LEFT JOIN users u ON u.id = r.owner_id
    WHERE r.id = $1
      AND r.deleted_at IS NULL
    LIMIT 1;
  `;

  const { rows } = await pool.query(query, [restaurantId]);
  return rows[0] || null;
}

async function setRestaurantApproval({ restaurantId, approved }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const current = await client.query(
      `
      SELECT r.id, r.owner_id
      FROM restaurants r
      WHERE r.id = $1
        AND r.deleted_at IS NULL
      LIMIT 1;
      `,
      [restaurantId]
    );

    if (!current.rows[0]) {
      await client.query('ROLLBACK');
      return null;
    }

    const nextRestaurantStatus = approved ? 'open' : 'closed';
    const restaurantResult = await client.query(
      `
      UPDATE restaurants
      SET is_approved = $1,
          status = $2,
          updated_at = NOW()
      WHERE id = $3
        AND deleted_at IS NULL
      RETURNING *;
      `,
      [approved, nextRestaurantStatus, restaurantId]
    );

    const ownerId = current.rows[0].owner_id;
    let owner = null;

    if (ownerId) {
      const ownerResult = await client.query(
        `
        UPDATE users
        SET approved = $1,
            updated_at = NOW()
        WHERE id = $2
          AND deleted_at IS NULL
        RETURNING id, name, email, role, status, approved;
        `,
        [approved, ownerId]
      );
      owner = ownerResult.rows[0] || null;
    }

    await client.query('COMMIT');
    return {
      restaurant: restaurantResult.rows[0] || null,
      owner,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function setRestaurantRestriction({ restaurantId, restricted }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const current = await client.query(
      `
      SELECT r.id, r.owner_id, r.is_approved
      FROM restaurants r
      WHERE r.id = $1
        AND r.deleted_at IS NULL
      LIMIT 1;
      `,
      [restaurantId]
    );

    if (!current.rows[0]) {
      await client.query('ROLLBACK');
      return null;
    }

    const row = current.rows[0];
    const nextRestaurantStatus = restricted
      ? 'closed'
      : row.is_approved
          ? 'open'
          : 'closed';

    const restaurantResult = await client.query(
      `
      UPDATE restaurants
      SET status = $1,
          updated_at = NOW()
      WHERE id = $2
        AND deleted_at IS NULL
      RETURNING *;
      `,
      [nextRestaurantStatus, restaurantId]
    );

    let owner = null;
    if (row.owner_id) {
      const nextOwnerStatus = restricted ? 'banned' : 'active';
      const ownerResult = await client.query(
        `
        UPDATE users
        SET status = $1,
            updated_at = NOW()
        WHERE id = $2
          AND deleted_at IS NULL
        RETURNING id, name, email, role, status, approved;
        `,
        [nextOwnerStatus, row.owner_id]
      );
      owner = ownerResult.rows[0] || null;
    }

    await client.query('COMMIT');
    return {
      restaurant: restaurantResult.rows[0] || null,
      owner,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  listRestaurantsForAdmin,
  findRestaurantWithOwner,
  setRestaurantApproval,
  setRestaurantRestriction,
};
