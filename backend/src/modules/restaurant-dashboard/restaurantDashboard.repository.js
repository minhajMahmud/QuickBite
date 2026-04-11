const { pool } = require('../../config/db');
const crypto = require('crypto');

async function createRestaurantForOwner({ ownerId, name, email }) {
  const query = `
    INSERT INTO restaurants (
      id,
      name,
      description,
      owner_id,
      email,
      status,
      is_approved,
      created_at,
      updated_at
    ) VALUES (
      $1,
      $2,
      $3,
      $4,
      $5,
      'closed',
      FALSE,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    )
    RETURNING id;
  `;

  const fallbackName = name && String(name).trim().length > 0
    ? `${String(name).trim()}'s Restaurant`
    : 'My Restaurant';

  const id = crypto.randomUUID();

  const { rows } = await pool.query(query, [
    id,
    fallbackName,
    'New restaurant account. Update your profile details from the restaurant panel.',
    ownerId,
    email || null,
  ]);

  return rows[0]?.id || null;
}

async function findRestaurantById(restaurantId) {
  const query = `
    SELECT
      id,
      name,
      description,
      image,
      cuisine,
      rating,
      review_count,
      delivery_time,
      delivery_fee,
      price_range,
      is_popular,
      status,
      is_approved,
      total_orders,
      total_revenue,
      owner_id,
      phone,
      email,
      street_address,
      city,
      state,
      postal_code,
      latitude,
      longitude,
      created_at,
      updated_at
    FROM restaurants
    WHERE id = $1
      AND deleted_at IS NULL
    LIMIT 1;
  `;

  const { rows } = await pool.query(query, [restaurantId]);
  return rows[0] || null;
}

async function findRestaurantByOwnerId(ownerId) {
  const query = `
    SELECT id
    FROM restaurants
    WHERE owner_id = $1
      AND deleted_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
  `;

  const { rows } = await pool.query(query, [ownerId]);
  return rows[0]?.id || null;
}

async function listOperatingHours(restaurantId) {
  const query = `
    SELECT
      id,
      day_of_week,
      opening_time,
      closing_time,
      is_closed
    FROM operating_hours
    WHERE restaurant_id = $1
    ORDER BY CASE day_of_week
      WHEN 'Monday' THEN 1
      WHEN 'Tuesday' THEN 2
      WHEN 'Wednesday' THEN 3
      WHEN 'Thursday' THEN 4
      WHEN 'Friday' THEN 5
      WHEN 'Saturday' THEN 6
      WHEN 'Sunday' THEN 7
      ELSE 8
    END;
  `;

  const { rows } = await pool.query(query, [restaurantId]);
  return rows;
}

async function updateRestaurantProfile({ restaurantId, updates }) {
  const allowed = {
    name: 'name',
    description: 'description',
    image: 'image',
    cuisine: 'cuisine',
    phone: 'phone',
    email: 'email',
    streetAddress: 'street_address',
    city: 'city',
    state: 'state',
    postalCode: 'postal_code',
  };

  const setParts = [];
  const values = [];
  let idx = 1;

  Object.keys(allowed).forEach((key) => {
    if (Object.prototype.hasOwnProperty.call(updates, key)) {
      setParts.push(`${allowed[key]} = $${idx}`);
      values.push(updates[key]);
      idx += 1;
    }
  });

  if (setParts.length === 0) {
    return findRestaurantById(restaurantId);
  }

  setParts.push('updated_at = CURRENT_TIMESTAMP');

  const query = `
    UPDATE restaurants
    SET ${setParts.join(', ')}
    WHERE id = $${idx}
      AND deleted_at IS NULL
    RETURNING *;
  `;

  values.push(restaurantId);

  const { rows } = await pool.query(query, values);
  return rows[0] || null;
}

async function listMenuItems(restaurantId) {
  const query = `
    SELECT
      fi.id,
      fi.restaurant_id,
      fi.category_id,
      c.name AS category_name,
      fi.name,
      fi.description,
      fi.price,
      fi.image,
      fi.rating,
      fi.review_count,
      fi.is_popular,
      fi.is_vegetarian,
      fi.is_vegan,
      fi.is_gluten_free,
      fi.availability,
      fi.orders_count,
      fi.created_at,
      fi.updated_at
    FROM food_items fi
    JOIN categories c ON c.id = fi.category_id
    WHERE fi.restaurant_id = $1
      AND fi.deleted_at IS NULL
    ORDER BY fi.created_at DESC;
  `;

  const { rows } = await pool.query(query, [restaurantId]);
  return rows;
}

async function createMenuItem(item) {
  const query = `
    INSERT INTO food_items (
      id,
      restaurant_id,
      category_id,
      name,
      description,
      price,
      image,
      is_popular,
      is_vegetarian,
      is_vegan,
      is_gluten_free,
      availability,
      created_at,
      updated_at
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    RETURNING *;
  `;

  const values = [
    item.id,
    item.restaurantId,
    item.categoryId,
    item.name,
    item.description,
    item.price,
    item.image,
    item.isPopular,
    item.isVegetarian,
    item.isVegan,
    item.isGlutenFree,
    item.availability,
  ];

  const { rows } = await pool.query(query, values);
  return rows[0];
}

async function updateMenuItem({ restaurantId, foodItemId, updates }) {
  const allowed = {
    categoryId: 'category_id',
    name: 'name',
    description: 'description',
    price: 'price',
    image: 'image',
    isPopular: 'is_popular',
    isVegetarian: 'is_vegetarian',
    isVegan: 'is_vegan',
    isGlutenFree: 'is_gluten_free',
    availability: 'availability',
  };

  const setParts = [];
  const values = [];
  let idx = 1;

  Object.keys(allowed).forEach((key) => {
    if (Object.prototype.hasOwnProperty.call(updates, key)) {
      setParts.push(`${allowed[key]} = $${idx}`);
      values.push(updates[key]);
      idx += 1;
    }
  });

  if (setParts.length === 0) {
    return null;
  }

  setParts.push(`updated_at = CURRENT_TIMESTAMP`);

  const query = `
    UPDATE food_items
    SET ${setParts.join(', ')}
    WHERE id = $${idx}
      AND restaurant_id = $${idx + 1}
      AND deleted_at IS NULL
    RETURNING *;
  `;

  values.push(foodItemId, restaurantId);

  const { rows } = await pool.query(query, values);
  return rows[0] || null;
}

async function deleteMenuItem({ restaurantId, foodItemId }) {
  const query = `
    UPDATE food_items
    SET deleted_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = $1
      AND restaurant_id = $2
      AND deleted_at IS NULL
    RETURNING id;
  `;

  const { rows } = await pool.query(query, [foodItemId, restaurantId]);
  return Boolean(rows[0]);
}

async function listRestaurantOrders({ restaurantId, status, limit, offset }) {
  const where = ['o.restaurant_id = $1', 'o.deleted_at IS NULL'];
  const values = [restaurantId];

  if (status) {
    where.push(`o.order_status = $${values.length + 1}`);
    values.push(status);
  }

  values.push(limit, offset);
  const limitParam = `$${values.length - 1}`;
  const offsetParam = `$${values.length}`;

  const query = `
    SELECT
      o.id,
      o.user_id,
      u.name AS customer_name,
      dp.name AS delivery_partner_name,
      dp.email AS delivery_partner_email,
      dp.phone AS delivery_partner_phone,
      o.subtotal,
      o.delivery_fee,
      o.discount_amount,
      o.tax_amount,
      o.total_amount,
      o.payment_method,
      o.payment_status,
      o.order_status,
      o.special_instructions,
      o.created_at,
      o.updated_at,
      COALESCE(
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', oi.id,
            'foodItemId', oi.food_item_id,
            'name', fi.name,
            'quantity', oi.quantity,
            'unitPrice', oi.unit_price,
            'itemTotal', oi.item_total,
            'specialInstructions', oi.special_instructions
          )
        ) FILTER (WHERE oi.id IS NOT NULL),
        '[]'::json
      ) AS items
    FROM orders o
    JOIN users u ON u.id = o.user_id
    LEFT JOIN LATERAL (
      SELECT dr.delivery_partner_id
      FROM delivery_requests dr
      WHERE dr.order_id = o.id
        AND dr.status = 'accepted'
      ORDER BY dr.accepted_at DESC NULLS LAST, dr.updated_at DESC
      LIMIT 1
    ) accepted_request ON TRUE
    LEFT JOIN users dp ON dp.id = accepted_request.delivery_partner_id
    LEFT JOIN order_items oi ON oi.order_id = o.id
    LEFT JOIN food_items fi ON fi.id = oi.food_item_id
    WHERE ${where.join(' AND ')}
    GROUP BY o.id, u.name, dp.name, dp.email, dp.phone
    ORDER BY o.created_at DESC
    LIMIT ${limitParam}
    OFFSET ${offsetParam};
  `;

  const { rows } = await pool.query(query, values);
  return rows;
}

async function updateRestaurantOrderStatus({ restaurantId, orderId, status }) {
  const query = `
    UPDATE orders
    SET order_status = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = $2
      AND restaurant_id = $3
      AND deleted_at IS NULL
    RETURNING *;
  `;

  const { rows } = await pool.query(query, [status, orderId, restaurantId]);
  return rows[0] || null;
}

async function getDashboardOverview(restaurantId) {
  const query = `
    SELECT
      COUNT(*)::int AS total_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'pending' THEN 1 ELSE 0 END), 0)::int AS pending_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'preparing' THEN 1 ELSE 0 END), 0)::int AS preparing_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'ready' THEN 1 ELSE 0 END), 0)::int AS ready_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'on_the_way' THEN 1 ELSE 0 END), 0)::int AS on_the_way_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END), 0)::int AS delivered_orders,
      COALESCE(SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END), 0)::int AS cancelled_orders,
      COALESCE(SUM(o.total_amount), 0)::numeric(15,2) AS gross_sales,
      COALESCE(SUM(CASE WHEN o.order_status = 'delivered' THEN o.total_amount ELSE 0 END), 0)::numeric(15,2) AS delivered_sales,
      COALESCE(AVG(o.total_amount), 0)::numeric(12,2) AS average_order_value
    FROM orders o
    WHERE o.restaurant_id = $1
      AND o.deleted_at IS NULL;
  `;

  const { rows } = await pool.query(query, [restaurantId]);
  return rows[0];
}

async function getSalesTimeSeries({ restaurantId, days }) {
  const query = `
    SELECT
      DATE_TRUNC('day', o.created_at)::date AS day,
      COUNT(*)::int AS orders,
      COALESCE(SUM(o.total_amount), 0)::numeric(15,2) AS revenue
    FROM orders o
    WHERE o.restaurant_id = $1
      AND o.deleted_at IS NULL
      AND o.created_at >= NOW() - ($2::text || ' days')::interval
    GROUP BY DATE_TRUNC('day', o.created_at)
    ORDER BY day ASC;
  `;

  const { rows } = await pool.query(query, [restaurantId, days]);
  return rows;
}

async function getTopSellingItems({ restaurantId, days, limit = 5 }) {
  const query = `
    SELECT
      fi.id,
      fi.name,
      SUM(oi.quantity)::int AS total_quantity,
      COALESCE(SUM(oi.item_total), 0)::numeric(15,2) AS total_sales
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    JOIN food_items fi ON fi.id = oi.food_item_id
    WHERE o.restaurant_id = $1
      AND o.deleted_at IS NULL
      AND o.created_at >= NOW() - ($2::text || ' days')::interval
    GROUP BY fi.id, fi.name
    ORDER BY total_quantity DESC, total_sales DESC
    LIMIT $3;
  `;

  const { rows } = await pool.query(query, [restaurantId, days, limit]);
  return rows;
}

module.exports = {
  createRestaurantForOwner,
  findRestaurantById,
  findRestaurantByOwnerId,
  listOperatingHours,
  updateRestaurantProfile,
  listMenuItems,
  createMenuItem,
  updateMenuItem,
  deleteMenuItem,
  listRestaurantOrders,
  updateRestaurantOrderStatus,
  getDashboardOverview,
  getSalesTimeSeries,
  getTopSellingItems,
};
