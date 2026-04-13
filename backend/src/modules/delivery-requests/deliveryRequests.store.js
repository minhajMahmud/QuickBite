const { pool } = require('../../config/db');
const crypto = require('crypto');

function mapRequestRow(row) {
  if (!row) return null;

  return {
    id: row.id,
    orderId: row.order_id,
    deliveryPartnerId: row.delivery_partner_id,
    status: row.status,
    rejectionReason: row.rejection_reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    respondedAt: row.responded_at,
    acceptedAt: row.accepted_at,
    rejectedAt: row.rejected_at,
    order: row.order_id
      ? {
          id: row.order_id,
          restaurantName: row.restaurant_name,
          customerName: row.customer_name,
          customerPhone: row.customer_phone,
          customerEmail: row.customer_email,
          customerAddress: row.customer_address,
          totalAmount: Number(row.total_amount || 0),
          deliveryFee: Number(row.delivery_fee || 0),
          status: row.order_status,
          createdAt: row.order_created_at,
          estimatedDeliveryTime: row.estimated_delivery_time,
        }
      : null,
    deliveryPartner: row.delivery_partner_name
      ? {
          id: row.delivery_partner_id,
          name: row.delivery_partner_name,
          email: row.delivery_partner_email,
          phone: row.delivery_partner_phone,
          rating: Number(row.delivery_partner_rating || 0),
          totalDeliveries: Number(row.delivery_partner_total_deliveries || 0),
          vehicleType: row.delivery_partner_vehicle_type,
          vehicleNumber: row.delivery_partner_vehicle_number,
        }
      : null,
  };
}

async function createRequestsForOrder(orderId) {
  const eligiblePartners = await pool.query(
    `
    SELECT id
    FROM users
    WHERE deleted_at IS NULL
      AND role = 'delivery_partner'
      AND approved = TRUE
      AND status = 'active'
    ORDER BY created_at ASC
    `
  );

  if (eligiblePartners.rows.length === 0) {
    return [];
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const created = [];

    for (const partner of eligiblePartners.rows) {
      const requestId = require('crypto').randomUUID();
      const result = await client.query(
        `
        INSERT INTO delivery_requests (
          id,
          order_id,
          delivery_partner_id,
          status,
          created_at,
          updated_at
        )
        VALUES ($1, $2, $3, 'pending', NOW(), NOW())
        ON CONFLICT (order_id, delivery_partner_id) DO NOTHING
        RETURNING *
        `,
        [requestId, orderId, partner.id]
      );

      if (result.rows[0]) {
        created.push(result.rows[0]);
      }
    }

    await client.query('COMMIT');
    return created.map(mapRequestRow);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function listAvailableDeliveryPartners() {
  const { rows } = await pool.query(
    `
    SELECT
      u.id,
      u.name,
      u.email,
      u.phone,
      COALESCE(da.rating, 0)::numeric AS rating,
      COALESCE(da.total_deliveries, 0)::int AS total_deliveries,
      da.vehicle_type,
      da.vehicle_number
    FROM users u
    LEFT JOIN delivery_agents da ON LOWER(da.email) = LOWER(u.email)
    WHERE u.deleted_at IS NULL
      AND u.role = 'delivery_partner'
      AND u.approved = TRUE
      AND u.status = 'active'
    ORDER BY u.name ASC
    `
  );

  return rows.map((row) => ({
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone,
    rating: Number(row.rating || 0),
    totalDeliveries: Number(row.total_deliveries || 0),
    vehicleType: row.vehicle_type || null,
    vehicleNumber: row.vehicle_number || null,
  }));
}

async function createRequestForOrderAndPartner(orderId, deliveryPartnerId) {
  const eligibility = await pool.query(
    `
    SELECT id
    FROM users
    WHERE id = $1
      AND deleted_at IS NULL
      AND role = 'delivery_partner'
      AND approved = TRUE
      AND status = 'active'
    LIMIT 1
    `,
    [deliveryPartnerId]
  );

  if (!eligibility.rows[0]) {
    throw new Error('Selected delivery partner is not available');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `
      UPDATE delivery_requests
      SET status = 'cancelled',
          responded_at = COALESCE(responded_at, NOW()),
          updated_at = NOW()
      WHERE order_id = $1
        AND delivery_partner_id <> $2
        AND status = 'pending'
      `,
      [orderId, deliveryPartnerId]
    );

    const result = await client.query(
      `
      INSERT INTO delivery_requests (
        id,
        order_id,
        delivery_partner_id,
        status,
        rejection_reason,
        responded_at,
        accepted_at,
        rejected_at,
        created_at,
        updated_at
      )
      VALUES ($1, $2, $3, 'pending', NULL, NULL, NULL, NULL, NOW(), NOW())
      ON CONFLICT (order_id, delivery_partner_id)
      DO UPDATE
      SET status = 'pending',
          rejection_reason = NULL,
          responded_at = NULL,
          accepted_at = NULL,
          rejected_at = NULL,
          updated_at = NOW()
      RETURNING *
      `,
      [crypto.randomUUID(), orderId, deliveryPartnerId]
    );

    await client.query('COMMIT');
    return mapRequestRow(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function listIncomingRequestsForPartner(partnerId) {
  const { rows } = await pool.query(
    `
    SELECT
      dr.id,
      dr.order_id,
      dr.delivery_partner_id,
      dr.status,
      dr.rejection_reason,
      dr.created_at,
      dr.updated_at,
      dr.responded_at,
      dr.accepted_at,
      dr.rejected_at,
      o.total_amount,
      o.delivery_fee,
      o.order_status,
      o.estimated_delivery_time,
      o.created_at AS order_created_at,
      r.name AS restaurant_name,
      cu.name AS customer_name,
      cu.email AS customer_email,
      cu.phone AS customer_phone,
      ua.street_address,
      ua.city,
      ua.state,
      ua.postal_code,
      dp.name AS delivery_partner_name,
      dp.email AS delivery_partner_email,
      dp.phone AS delivery_partner_phone,
      COALESCE(da.rating, 0)::numeric AS delivery_partner_rating,
      COALESCE(da.total_deliveries, 0)::int AS delivery_partner_total_deliveries,
      da.vehicle_type AS delivery_partner_vehicle_type,
      da.vehicle_number AS delivery_partner_vehicle_number
    FROM delivery_requests dr
    JOIN orders o ON o.id = dr.order_id
    LEFT JOIN restaurants r ON r.id = o.restaurant_id
    LEFT JOIN users cu ON cu.id = o.user_id
    LEFT JOIN user_addresses ua ON ua.id = o.delivery_address_id
    LEFT JOIN users dp ON dp.id = dr.delivery_partner_id
    LEFT JOIN delivery_agents da ON LOWER(da.email) = LOWER(dp.email)
    WHERE dr.delivery_partner_id = $1
      AND dr.status = 'pending'
      AND o.deleted_at IS NULL
    ORDER BY dr.created_at ASC
    `,
    [partnerId]
  );

  return rows.map((row) => {
    const mapped = mapRequestRow(row);
    const addressParts = [row.street_address, row.city, row.state, row.postal_code]
      .filter((part) => part && String(part).trim())
      .map((part) => String(part).trim());

    return {
      ...mapped,
      order: mapped.order
        ? {
            ...mapped.order,
            customerAddress: addressParts.join(', ') || null,
          }
        : null,
    };
  });
}

async function getAcceptedRequestForOrder(orderId) {
  const { rows } = await pool.query(
    `
    SELECT
      dr.id,
      dr.order_id,
      dr.delivery_partner_id,
      dr.status,
      dr.rejection_reason,
      dr.created_at,
      dr.updated_at,
      dr.responded_at,
      dr.accepted_at,
      dr.rejected_at,
      dp.name AS delivery_partner_name,
      dp.email AS delivery_partner_email,
      dp.phone AS delivery_partner_phone,
      COALESCE(da.rating, 0)::numeric AS delivery_partner_rating,
      COALESCE(da.total_deliveries, 0)::int AS delivery_partner_total_deliveries,
      da.vehicle_type AS delivery_partner_vehicle_type,
      da.vehicle_number AS delivery_partner_vehicle_number
    FROM delivery_requests dr
    JOIN users dp ON dp.id = dr.delivery_partner_id
    LEFT JOIN delivery_agents da ON LOWER(da.email) = LOWER(dp.email)
    WHERE dr.order_id = $1
      AND dr.status = 'accepted'
    ORDER BY dr.accepted_at DESC NULLS LAST, dr.updated_at DESC
    LIMIT 1
    `,
    [orderId]
  );

  return mapRequestRow(rows[0]);
}

async function acceptRequest(requestId, partnerId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const current = await client.query(
      `
      SELECT *
      FROM delivery_requests
      WHERE id = $1
        AND delivery_partner_id = $2
      FOR UPDATE
      `,
      [requestId, partnerId]
    );

    const request = current.rows[0];
    if (!request) {
      await client.query('ROLLBACK');
      return null;
    }

    if (request.status !== 'pending') {
      await client.query('ROLLBACK');
      throw new Error('Request is no longer pending');
    }

    await client.query(
      `
      UPDATE delivery_requests
      SET status = 'accepted',
          responded_at = NOW(),
          accepted_at = NOW(),
          updated_at = NOW()
      WHERE id = $1
      `,
      [requestId]
    );

    await client.query(
      `
      UPDATE delivery_requests
      SET status = 'cancelled',
          responded_at = COALESCE(responded_at, NOW()),
          updated_at = NOW()
      WHERE order_id = $1
        AND id <> $2
        AND status = 'pending'
      `,
      [request.order_id, requestId]
    );

    await client.query(
      `
      UPDATE orders
      SET order_status = COALESCE(order_status, 'confirmed'),
          updated_at = NOW()
      WHERE id = $1
      `,
      [request.order_id]
    );

    const result = await client.query(
      `
      SELECT
        dr.id,
        dr.order_id,
        dr.delivery_partner_id,
        dr.status,
        dr.rejection_reason,
        dr.created_at,
        dr.updated_at,
        dr.responded_at,
        dr.accepted_at,
        dr.rejected_at
      FROM delivery_requests dr
      WHERE dr.id = $1
      LIMIT 1
      `,
      [requestId]
    );

    await client.query('COMMIT');
    return mapRequestRow(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function rejectRequest(requestId, partnerId, rejectionReason = null) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const current = await client.query(
      `
      SELECT *
      FROM delivery_requests
      WHERE id = $1
        AND delivery_partner_id = $2
      FOR UPDATE
      `,
      [requestId, partnerId]
    );

    const request = current.rows[0];
    if (!request) {
      await client.query('ROLLBACK');
      return null;
    }

    if (request.status !== 'pending') {
      await client.query('ROLLBACK');
      throw new Error('Request is no longer pending');
    }

    await client.query(
      `
      UPDATE delivery_requests
      SET status = 'rejected',
          rejection_reason = $2,
          responded_at = NOW(),
          rejected_at = NOW(),
          updated_at = NOW()
      WHERE id = $1
      `,
      [requestId, rejectionReason]
    );

    const result = await client.query(
      `
      SELECT
        dr.id,
        dr.order_id,
        dr.delivery_partner_id,
        dr.status,
        dr.rejection_reason,
        dr.created_at,
        dr.updated_at,
        dr.responded_at,
        dr.accepted_at,
        dr.rejected_at
      FROM delivery_requests dr
      WHERE dr.id = $1
      LIMIT 1
      `,
      [requestId]
    );

    await client.query('COMMIT');
    return mapRequestRow(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  createRequestsForOrder,
  createRequestForOrderAndPartner,
  listAvailableDeliveryPartners,
  listIncomingRequestsForPartner,
  getAcceptedRequestForOrder,
  acceptRequest,
  rejectRequest,
};
