const { pool } = require('../../config/db');

function mapOrderRow(row) {
  if (!row) return null;

  return {
    id: row.id,
    userId: row.user_id,
    restaurantId: row.restaurant_id,
    restaurantName: row.restaurant_name,
    items: Array.isArray(row.items) ? row.items : [],
    totalAmount: Number(row.total_amount || 0),
    status: row.order_status,
    createdAt: row.created_at,
  };
}

async function createOrder(order) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const insertOrderQuery = `
      INSERT INTO orders (
        id,
        user_id,
        restaurant_id,
        subtotal,
        delivery_fee,
        discount_amount,
        tax_amount,
        total_amount,
        order_status,
        payment_method,
        payment_status,
        created_at,
        updated_at
      )
      VALUES (
        $1, $2, $3, $4, 0, 0, 0, $5, 'pending', 'cash', 'pending', NOW(), NOW()
      )
      RETURNING id, user_id, restaurant_id, total_amount, order_status, created_at;
    `;

    const orderValues = [
      order.id,
      order.userId,
      order.restaurantId,
      Number(order.totalAmount),
      Number(order.totalAmount),
    ];

    const orderResult = await client.query(insertOrderQuery, orderValues);
    const createdOrder = orderResult.rows[0];

    if (Array.isArray(order.items) && order.items.length > 0) {
      let itemIndex = 0;
      for (const item of order.items) {
        const foodItemId = item.foodItemId || item.id || null;
        if (!foodItemId) continue;

        itemIndex += 1;
        const quantity = Number(item.quantity || 1);
        const unitPrice = Number(item.unitPrice ?? item.price ?? 0);
        const itemTotal = Number(item.itemTotal ?? unitPrice * quantity);

        await client.query(
          `
            INSERT INTO order_items (
              id,
              order_id,
              food_item_id,
              quantity,
              unit_price,
              item_total,
              special_instructions,
              created_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, NOW());
          `,
          [
            `${order.id}-item-${itemIndex}`,
            order.id,
            foodItemId,
            quantity,
            unitPrice,
            itemTotal,
            item.specialInstructions || null,
          ]
        );
      }
    }

    await client.query('COMMIT');

    const withRestaurant = await client.query(
      `
        SELECT
          o.id,
          o.user_id,
          o.restaurant_id,
          o.total_amount,
          o.order_status,
          o.created_at,
          r.name AS restaurant_name
        FROM orders o
        JOIN restaurants r ON r.id = o.restaurant_id
        WHERE o.id = $1
        LIMIT 1;
      `,
      [order.id]
    );

    return {
      ...mapOrderRow(withRestaurant.rows[0] || createdOrder),
      items: order.items || [],
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function listOrders() {
  const query = `
    SELECT
      o.id,
      o.user_id,
      o.restaurant_id,
      o.total_amount,
      o.order_status,
      o.created_at,
      r.name AS restaurant_name
    FROM orders o
    JOIN restaurants r ON r.id = o.restaurant_id
    WHERE o.deleted_at IS NULL
    ORDER BY o.created_at DESC;
  `;

  const { rows } = await pool.query(query);
  return rows.map(mapOrderRow);
}

async function listOrdersByUser(userId) {
  const query = `
    SELECT
      o.id,
      o.user_id,
      o.restaurant_id,
      o.total_amount,
      o.order_status,
      o.created_at,
      r.name AS restaurant_name
    FROM orders o
    JOIN restaurants r ON r.id = o.restaurant_id
    WHERE o.user_id = $1
      AND o.deleted_at IS NULL
    ORDER BY o.created_at DESC;
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows.map(mapOrderRow);
}

async function findOrderById(id) {
  const query = `
    SELECT
      o.id,
      o.user_id,
      o.restaurant_id,
      o.total_amount,
      o.order_status,
      o.created_at,
      r.name AS restaurant_name
    FROM orders o
    JOIN restaurants r ON r.id = o.restaurant_id
    WHERE o.id = $1
      AND o.deleted_at IS NULL
    LIMIT 1;
  `;

  const { rows } = await pool.query(query, [id]);
  return mapOrderRow(rows[0]);
}

async function updateOrderStatus(id, status) {
  const query = `
    UPDATE orders
    SET order_status = $1, updated_at = NOW()
    WHERE id = $2
      AND deleted_at IS NULL
    RETURNING id;
  `;

  const { rows } = await pool.query(query, [status, id]);
  if (!rows[0]) {
    return null;
  }

  return findOrderById(id);
}

async function canRestaurantManageOrder(orderId, ownerUserId) {
  const query = `
    SELECT 1
    FROM orders o
    JOIN restaurants r ON r.id = o.restaurant_id
    WHERE o.id = $1
      AND r.owner_id = $2
      AND o.deleted_at IS NULL
    LIMIT 1;
  `;

  const { rows } = await pool.query(query, [orderId, ownerUserId]);
  return Boolean(rows[0]);
}

module.exports = {
  createOrder,
  listOrders,
  listOrdersByUser,
  findOrderById,
  updateOrderStatus,
  canRestaurantManageOrder,
};
