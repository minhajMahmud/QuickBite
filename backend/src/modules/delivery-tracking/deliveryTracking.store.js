const { pool } = require('../../config/db');

function toNumber(value) {
  if (typeof value === 'number') return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function getAcceptedTrackingContext(orderId, deliveryPartnerId) {
  const { rows } = await pool.query(
    `
    SELECT
      dr.id AS request_id,
      dr.order_id,
      dr.delivery_partner_id,
      dr.status AS request_status,
      o.order_status,
      o.estimated_delivery_time,
      o.actual_delivery_time,
      o.created_at,
      r.id AS restaurant_id,
      r.name AS restaurant_name,
      r.latitude AS restaurant_latitude,
      r.longitude AS restaurant_longitude,
      ua.id AS address_id,
      ua.street_address,
      ua.city,
      ua.state,
      ua.postal_code,
      ua.latitude AS customer_latitude,
      ua.longitude AS customer_longitude,
      da.current_latitude,
      da.current_longitude,
      da.status AS rider_status,
      u.name AS rider_name,
      u.phone AS rider_phone,
      u.email AS rider_email
    FROM delivery_requests dr
    JOIN orders o ON o.id = dr.order_id
    LEFT JOIN restaurants r ON r.id = o.restaurant_id
    LEFT JOIN user_addresses ua ON ua.id = o.delivery_address_id
    LEFT JOIN users u ON u.id = dr.delivery_partner_id
    LEFT JOIN delivery_agents da ON LOWER(da.email) = LOWER(u.email)
    WHERE dr.order_id = $1
      AND dr.delivery_partner_id = $2
      AND dr.status = 'accepted'
      AND o.deleted_at IS NULL
    ORDER BY dr.accepted_at DESC NULLS LAST, dr.updated_at DESC
    LIMIT 1
    `,
    [orderId, deliveryPartnerId]
  );

  const row = rows[0];
  if (!row) return null;

  const customerAddress = [row.street_address, row.city, row.state, row.postal_code]
    .filter((part) => part && String(part).trim().length > 0)
    .map((part) => String(part).trim())
    .join(', ');

  return {
    requestId: row.request_id,
    orderId: row.order_id,
    deliveryPartnerId: row.delivery_partner_id,
    requestStatus: row.request_status,
    orderStatus: row.order_status,
    estimatedDeliveryTime: row.estimated_delivery_time,
    actualDeliveryTime: row.actual_delivery_time,
    createdAt: row.created_at,
    rider: {
      name: row.rider_name,
      phone: row.rider_phone,
      email: row.rider_email,
      status: row.rider_status,
      latitude: toNumber(row.current_latitude),
      longitude: toNumber(row.current_longitude),
    },
    pickup: {
      id: row.restaurant_id,
      name: row.restaurant_name,
      latitude: toNumber(row.restaurant_latitude),
      longitude: toNumber(row.restaurant_longitude),
    },
    dropoff: {
      id: row.address_id,
      address: customerAddress || null,
      latitude: toNumber(row.customer_latitude),
      longitude: toNumber(row.customer_longitude),
    },
  };
}

async function updateDeliveryPartnerCurrentLocation({
  deliveryPartnerId,
  latitude,
  longitude,
}) {
  const { rows } = await pool.query(
    `
    UPDATE delivery_agents da
    SET
      current_latitude = $2,
      current_longitude = $3,
      updated_at = NOW()
    FROM users u
    WHERE u.id = $1
      AND LOWER(da.email) = LOWER(u.email)
    RETURNING da.current_latitude, da.current_longitude, da.updated_at
    `,
    [deliveryPartnerId, latitude, longitude]
  );

  if (!rows[0]) {
    return null;
  }

  return {
    latitude: toNumber(rows[0].current_latitude),
    longitude: toNumber(rows[0].current_longitude),
    updatedAt: rows[0].updated_at,
  };
}

module.exports = {
  getAcceptedTrackingContext,
  updateDeliveryPartnerCurrentLocation,
};
