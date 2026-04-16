const crypto = require('crypto');
const { pool } = require('../../config/db');

let tableEnsured = false;

async function ensureChatMessagesTable() {
  if (tableEnsured) return;

  await pool.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id UUID PRIMARY KEY,
      order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
      sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      message_type VARCHAR(20) NOT NULL DEFAULT 'text',
      content TEXT NOT NULL DEFAULT '',
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      address TEXT,
      is_live_location BOOLEAN NOT NULL DEFAULT FALSE,
      status VARCHAR(20) NOT NULL DEFAULT 'sent',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(
    `CREATE INDEX IF NOT EXISTS idx_chat_messages_order_created_at ON chat_messages(order_id, created_at);`
  );

  tableEnsured = true;
}

function mapChatRow(row) {
  if (!row) return null;

  return {
    id: row.id,
    conversationId: row.order_id,
    senderId: row.sender_id,
    senderName: row.sender_name || 'User',
    senderAvatar: row.sender_avatar || null,
    type: row.message_type,
    content: row.content || '',
    timestamp: row.created_at,
    status: row.status || 'sent',
    latitude: row.latitude == null ? null : Number(row.latitude),
    longitude: row.longitude == null ? null : Number(row.longitude),
    address: row.address || null,
    isLiveLocation: Boolean(row.is_live_location),
    isCustomer: row.customer_user_id ? row.sender_id === row.customer_user_id : false,
  };
}

async function findOrder(orderId) {
  const { rows } = await pool.query(
    `
      SELECT id, user_id
      FROM orders
      WHERE id = $1
        AND deleted_at IS NULL
      LIMIT 1;
    `,
    [orderId]
  );

  return rows[0] || null;
}

async function isAcceptedDeliveryPartner(orderId, userId) {
  const { rows } = await pool.query(
    `
      SELECT 1
      FROM delivery_requests
      WHERE order_id = $1
        AND delivery_partner_id = $2
        AND status = 'accepted'
      LIMIT 1;
    `,
    [orderId, userId]
  );

  return Boolean(rows[0]);
}

async function listMessages(orderId) {
  await ensureChatMessagesTable();

  const { rows } = await pool.query(
    `
      SELECT
        cm.id,
        cm.order_id,
        cm.sender_id,
        cm.message_type,
        cm.content,
        cm.latitude,
        cm.longitude,
        cm.address,
        cm.is_live_location,
        cm.status,
        cm.created_at,
        u.name AS sender_name,
        u.avatar AS sender_avatar,
        o.user_id AS customer_user_id
      FROM chat_messages cm
      JOIN users u ON u.id = cm.sender_id
      JOIN orders o ON o.id = cm.order_id
      WHERE cm.order_id = $1
      ORDER BY cm.created_at ASC;
    `,
    [orderId]
  );

  return rows.map(mapChatRow);
}

async function createMessage({
  orderId,
  senderId,
  type,
  content,
  latitude,
  longitude,
  address,
  isLiveLocation,
}) {
  await ensureChatMessagesTable();

  const id = crypto.randomUUID();
  const safeType = String(type || 'text').toLowerCase();

  const { rows } = await pool.query(
    `
      INSERT INTO chat_messages (
        id,
        order_id,
        sender_id,
        message_type,
        content,
        latitude,
        longitude,
        address,
        is_live_location,
        status,
        created_at,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'sent', NOW(), NOW())
      RETURNING id;
    `,
    [
      id,
      orderId,
      senderId,
      safeType,
      content || '',
      latitude ?? null,
      longitude ?? null,
      address ?? null,
      Boolean(isLiveLocation),
    ]
  );

  if (!rows[0]) {
    return null;
  }

  const messages = await listMessages(orderId);
  return messages.find((m) => m.id === id) || null;
}

module.exports = {
  findOrder,
  isAcceptedDeliveryPartner,
  listMessages,
  createMessage,
};
