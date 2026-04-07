const { pool } = require('../../config/db');

/**
 * List all users with optional filtering
 */
async function listUsersForAdmin({ role, status, limit = 50, offset = 0 } = {}) {
  let query = `
    SELECT
      u.id,
      u.name,
      u.email,
      u.role,
      u.status,
      u.approved,
      u.phone,
      u.avatar,
      u.total_orders,
      u.total_spent,
      u.joined_at,
      u.last_login,
      u.created_at,
      u.updated_at
    FROM users u
    WHERE u.deleted_at IS NULL
  `;

  const params = [];

  if (role && ['customer', 'restaurant', 'delivery_partner', 'admin'].includes(role)) {
    query += ` AND u.role = $${params.length + 1}`;
    params.push(role);
  }

  if (status && ['active', 'inactive', 'banned'].includes(status)) {
    query += ` AND u.status = $${params.length + 1}`;
    params.push(status);
  }

  query += `
    ORDER BY
      CASE
        WHEN u.status = 'banned' THEN 0
        WHEN u.approved = FALSE AND u.role IN ('restaurant', 'delivery_partner') THEN 1
        WHEN u.role = 'admin' THEN 2
        ELSE 3
      END,
      u.created_at DESC
    LIMIT $${params.length + 1}
    OFFSET $${params.length + 2}
  `;

  params.push(limit, offset);

  const { rows } = await pool.query(query, params);
  return rows;
}

/**
 * Count total users with optional filtering
 */
async function countUsersForAdmin({ role, status } = {}) {
  let query = `
    SELECT COUNT(*) as total
    FROM users u
    WHERE u.deleted_at IS NULL
  `;

  const params = [];

  if (role && ['customer', 'restaurant', 'delivery_partner', 'admin'].includes(role)) {
    query += ` AND u.role = $${params.length + 1}`;
    params.push(role);
  }

  if (status && ['active', 'inactive', 'banned'].includes(status)) {
    query += ` AND u.status = $${params.length + 1}`;
    params.push(status);
  }

  const { rows } = await pool.query(query, params);
  return parseInt(rows[0].total, 10);
}

/**
 * Get user with full details including orders/deliveries
 */
async function getUserDetailsForAdmin(userId) {
  const user = await pool.query(
    `
    SELECT
      u.id,
      u.name,
      u.email,
      u.role,
      u.status,
      u.approved,
      u.phone,
      u.avatar,
      u.gender,
      u.date_of_birth,
      u.total_orders,
      u.total_spent,
      u.joined_at,
      u.last_login,
      u.created_at,
      u.updated_at
    FROM users u
    WHERE u.id = $1
      AND u.deleted_at IS NULL
    LIMIT 1
    `,
    [userId]
  );

  if (!user.rows.length) {
    return null;
  }

  const userData = user.rows[0];

  // Get customer orders
  let orders = [];
  if (userData.role === 'customer') {
    const ordersResult = await pool.query(
      `
      SELECT
        o.id,
        o.user_id,
        o.restaurant_id,
        o.total_amount as totalAmount,
        o.status,
        o.payment_status as paymentStatus,
        o.created_at as createdAt,
        r.name as restaurantName,
        COUNT(oi.id) as itemCount
      FROM orders o
      LEFT JOIN restaurants r ON r.id = o.restaurant_id
      LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.user_id = $1
      GROUP BY o.id, r.id, r.name
      ORDER BY o.created_at DESC
      LIMIT 20
      `,
      [userId]
    );
    orders = ordersResult.rows;
  }

  // Get delivery partner details
  let deliveryDetails = null;
  if (userData.role === 'delivery_partner') {
    const columnInfo = await pool.query(
      `
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'orders'
      `
    );

    const orderColumns = new Set(columnInfo.rows.map((r) => r.column_name));
    const deliveryFkColumn = orderColumns.has('delivery_partner_id')
      ? 'delivery_partner_id'
      : orderColumns.has('delivery_agent_id')
        ? 'delivery_agent_id'
        : null;
    const statusColumn = orderColumns.has('status')
      ? 'status'
      : orderColumns.has('order_status')
        ? 'order_status'
        : null;

    if (deliveryFkColumn) {
      const completedExpr = statusColumn
        ? `COUNT(CASE WHEN o.${statusColumn} = 'delivered' THEN 1 END)`
        : '0';

      const deliveryResult = await pool.query(
        `
        SELECT
          COUNT(o.id) as "totalDeliveries",
          0::numeric as "avgRating",
          ${completedExpr} as "completedDeliveries"
        FROM orders o
        WHERE o.${deliveryFkColumn} = $1
        `,
        [userId]
      );

      deliveryDetails = deliveryResult.rows[0] || {
        totalDeliveries: 0,
        avgRating: 0,
        completedDeliveries: 0,
      };
    } else {
      deliveryDetails = {
        totalDeliveries: 0,
        avgRating: 0,
        completedDeliveries: 0,
      };
    }
  }

  return {
    user: userData,
    orders,
    deliveryDetails,
  };
}

/**
 * Update user status (ban/unban/activate/deactivate)
 */
async function updateUserStatus({ userId, status }) {
  const validStatuses = ['active', 'inactive', 'banned'];
  if (!validStatuses.includes(status)) {
    throw new Error(`Invalid status: ${status}`);
  }

  const result = await pool.query(
    `
    UPDATE users
    SET status = $1, updated_at = CURRENT_TIMESTAMP
    WHERE id = $2
      AND deleted_at IS NULL
    RETURNING *
    `,
    [status, userId]
  );

  return result.rows[0] || null;
}

/**
 * Get user statistics
 */
async function getUserStatistics() {
  const result = await pool.query(
    `
    SELECT
      COUNT(*) as totalUsers,
      SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as activeUsers,
      SUM(CASE WHEN status = 'banned' THEN 1 ELSE 0 END) as bannedUsers,
      SUM(CASE WHEN role = 'customer' THEN 1 ELSE 0 END) as totalCustomers,
      SUM(CASE WHEN role = 'delivery_partner' THEN 1 ELSE 0 END) as totalDeliveryPartners,
      SUM(CASE WHEN role = 'restaurant' THEN 1 ELSE 0 END) as totalRestaurants,
      COALESCE(SUM(CASE WHEN role = 'customer' THEN total_spent ELSE 0 END)::numeric, 0) as totalCustomerSpent
    FROM users
    WHERE deleted_at IS NULL
    `
  );

  return result.rows[0];
}

/**
 * Find user by ID
 */
async function findUserById(userId) {
  const result = await pool.query(
    `
    SELECT
      id,
      name,
      email,
      role,
      status,
      approved,
      phone,
      avatar,
      created_at,
      updated_at
    FROM users
    WHERE id = $1
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [userId]
  );

  return result.rows[0] || null;
}

module.exports = {
  listUsersForAdmin,
  countUsersForAdmin,
  getUserDetailsForAdmin,
  updateUserStatus,
  getUserStatistics,
  findUserById,
};
