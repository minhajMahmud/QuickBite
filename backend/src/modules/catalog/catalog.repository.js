const { pool } = require('../../config/db');

async function listCategories() {
  const query = `
    SELECT
      id,
      name,
      COALESCE(icon, '🍽️') AS icon,
      display_order
    FROM categories
    WHERE is_active = TRUE
    ORDER BY display_order ASC, name ASC;
  `;

  const { rows } = await pool.query(query);
  return rows;
}

async function listRestaurants() {
  const query = `
    SELECT
      r.id,
      r.name,
      COALESCE(r.image, '') AS image,
      COALESCE(r.cuisine, 'Food') AS cuisine,
      COALESCE(r.rating, 0)::float AS rating,
      COALESCE(r.delivery_time, '25-35 mins') AS delivery_time,
      COALESCE(r.delivery_fee, 0)::numeric(10,2) AS delivery_fee,
      COALESCE(r.is_popular, FALSE) AS is_popular,
      COALESCE(r.price_range, '$$') AS price_range
    FROM restaurants r
    WHERE r.deleted_at IS NULL
      AND r.is_approved = TRUE
      AND r.status = 'open'
      AND r.id !~ '^rest-'
    ORDER BY r.is_popular DESC, r.rating DESC, r.name ASC;
  `;

  const { rows } = await pool.query(query);
  return rows;
}

async function listFoodItems(restaurantId = null) {
  const values = [];
  const where = [
    'fi.deleted_at IS NULL',
    "fi.availability <> 'out_of_stock'",
    "fi.id !~ '^food-'",
    'r.deleted_at IS NULL',
    'r.is_approved = TRUE',
    "r.status = 'open'",
    "r.id !~ '^rest-'",
  ];

  if (restaurantId) {
    values.push(restaurantId);
    where.push(`fi.restaurant_id = $${values.length}`);
  }

  const query = `
    SELECT
      fi.id,
      fi.restaurant_id,
      fi.name,
      COALESCE(fi.description, '') AS description,
      COALESCE(fi.price, 0)::float AS price,
      COALESCE(fi.image, '') AS image,
      COALESCE(c.name, 'Uncategorized') AS category,
      COALESCE(fi.is_popular, FALSE) AS is_popular
    FROM food_items fi
    JOIN restaurants r ON r.id = fi.restaurant_id
    LEFT JOIN categories c ON c.id = fi.category_id
    WHERE ${where.join(' AND ')}
    ORDER BY fi.is_popular DESC, fi.created_at DESC;
  `;

  const { rows } = await pool.query(query, values);
  return rows;
}

module.exports = {
  listCategories,
  listRestaurants,
  listFoodItems,
};
