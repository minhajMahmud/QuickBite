const { pool } = require('../../config/db');

const transientUserFields = new Map();

const dbFieldMap = {
  name: 'name',
  email: 'email',
  passwordHash: 'password_hash',
  role: 'role',
  approved: 'approved',
  avatar: 'avatar',
  phone: 'phone',
  dateOfBirth: 'date_of_birth',
  gender: 'gender',
  status: 'status',
  totalOrders: 'total_orders',
  totalSpent: 'total_spent',
  lastLogin: 'last_login',
  emailVerified: 'email_verified',
  emailVerificationToken: 'email_verification_token',
  emailVerificationTokenExpiresAt: 'email_verification_token_expires_at',
  emailVerificationCode: 'email_verification_code',
  emailVerificationCodeExpiresAt: 'email_verification_code_expires_at',
  firstLogin: 'first_login',
  lastPasswordChange: 'last_password_change',
};

function toUserModel(row) {
  if (!row) return null;

  return {
    id: row.id,
    name: row.name,
    email: row.email,
    passwordHash: row.password_hash,
    role: row.role,
    approved: row.approved,
    avatar: row.avatar,
    phone: row.phone,
    dateOfBirth: row.date_of_birth,
    gender: row.gender,
    status: row.status,
    totalOrders: row.total_orders,
    totalSpent: Number(row.total_spent || 0),
    joinedAt: row.joined_at,
    lastLogin: row.last_login,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    emailVerified: row.email_verified,
    emailVerificationToken: row.email_verification_token,
    emailVerificationTokenExpiresAt: row.email_verification_token_expires_at,
    emailVerificationCode: row.email_verification_code,
    emailVerificationCodeExpiresAt: row.email_verification_code_expires_at,
    firstLogin: row.first_login,
    lastPasswordChange: row.last_password_change,
  };
}

function withTransientFields(user) {
  if (!user) return null;
  const extra = transientUserFields.get(user.id) || {};
  return {
    ...user,
    ...extra,
    role: user.role || extra.role || 'customer',
    approved: user.approved ?? extra.approved ?? true,
  };
}

function setTransientFields(id, partial) {
  const next = {
    ...(transientUserFields.get(id) || {}),
    ...partial,
  };
  transientUserFields.set(id, next);
}

async function createUser(user) {
  console.log('📝 [USERS_STORE] Creating user...');
  console.log(`   Email: ${user.email}`);
  console.log(`   Name: ${user.name}`);
  console.log(`   ID: ${user.id}`);
  
  const query = `
    INSERT INTO users (
      id, name, email, password_hash, role, approved, avatar, phone, date_of_birth, gender, status,
      email_verified, email_verification_token, email_verification_token_expires_at,
      email_verification_code, email_verification_code_expires_at,
      first_login, last_login, created_at, updated_at
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
      $12, $13, $14,
      $15, $16,
      $17, $18, COALESCE($19, NOW()), NOW()
    )
    RETURNING *;
  `;

  const values = [
    user.id,
    user.name,
    user.email,
    user.passwordHash,
    user.role || 'customer',
    user.approved ?? true,
    user.avatar || null,
    user.phone || null,
    user.dateOfBirth || null,
    user.gender || null,
    user.status || 'active',
    user.emailVerified ?? false,
    user.emailVerificationToken || null,
    user.emailVerificationTokenExpiresAt || null,
    user.emailVerificationCode || null,
    user.emailVerificationCodeExpiresAt || null,
    user.firstLogin ?? true,
    user.lastLogin || null,
    user.createdAt || null,
  ];

  try {
    console.log('   🔄 Executing INSERT query...');
    const { rows } = await pool.query(query, values);
    
    if (!rows || rows.length === 0) {
      throw new Error('INSERT returned no rows - possible constraint violation');
    }
    
    const created = toUserModel(rows[0]);
    console.log(`✅ [USERS_STORE] User created successfully in database!`);
    console.log(`   Created at: ${created.createdAt}`);
    console.log(`   Email verified: ${created.emailVerified}`);

    setTransientFields(created.id, {
      passwordResetToken: user.passwordResetToken || null,
      passwordResetTokenExpiresAt: user.passwordResetTokenExpiresAt || null,
    });

    return withTransientFields(created);
  } catch (error) {
    console.error(`❌ [USERS_STORE] Failed to create user:`, error.message);
    console.error(`   Code: ${error.code}`);
    console.error(`   Detail: ${error.detail}`);
    throw error;
  }
}

async function findUserByEmail(email) {
  const query = `
    SELECT *
    FROM users
    WHERE LOWER(email) = LOWER($1)
      AND deleted_at IS NULL
    LIMIT 1;
  `;
  const { rows } = await pool.query(query, [email]);
  return withTransientFields(toUserModel(rows[0]));
}

async function findUserById(id) {
  const query = `
    SELECT *
    FROM users
    WHERE id = $1
      AND deleted_at IS NULL
    LIMIT 1;
  `;
  const { rows } = await pool.query(query, [id]);
  return withTransientFields(toUserModel(rows[0]));
}

async function updateUser(id, partial) {
  const setClauses = [];
  const values = [];

  Object.entries(partial).forEach(([key, value]) => {
    const dbField = dbFieldMap[key];
    if (!dbField) return;

    values.push(value);
    setClauses.push(`${dbField} = $${values.length}`);
  });

  if (setClauses.length > 0) {
    values.push(id);
    const query = `
      UPDATE users
      SET ${setClauses.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
        AND deleted_at IS NULL
      RETURNING *;
    `;
    const { rows } = await pool.query(query, values);
    if (!rows[0]) {
      return null;
    }

    const transientKeys = ['role', 'approved', 'passwordResetToken', 'passwordResetTokenExpiresAt'];
    const transientPatch = {};
    transientKeys.forEach((key) => {
      if (Object.prototype.hasOwnProperty.call(partial, key)) {
        transientPatch[key] = partial[key];
      }
    });
    if (Object.keys(transientPatch).length > 0) {
      setTransientFields(id, transientPatch);
    }

    return withTransientFields(toUserModel(rows[0]));
  }

  const transientKeys = ['role', 'approved', 'passwordResetToken', 'passwordResetTokenExpiresAt'];
  const transientPatch = {};
  transientKeys.forEach((key) => {
    if (Object.prototype.hasOwnProperty.call(partial, key)) {
      transientPatch[key] = partial[key];
    }
  });
  if (Object.keys(transientPatch).length > 0) {
    setTransientFields(id, transientPatch);
  }

  return findUserById(id);
}

async function listUsers() {
  const query = `
    SELECT *
    FROM users
    WHERE deleted_at IS NULL
    ORDER BY created_at DESC;
  `;

  const { rows } = await pool.query(query);
  return rows.map((row) => withTransientFields(toUserModel(row)));
}

async function listPendingApprovalUsers() {
  const query = `
    SELECT *
    FROM users
    WHERE deleted_at IS NULL
      AND role IN ('restaurant', 'delivery_partner')
      AND approved = FALSE
    ORDER BY created_at ASC;
  `;

  const { rows } = await pool.query(query);
  return rows.map((row) => withTransientFields(toUserModel(row)));
}

async function setApprovalStatus(userId, approved) {
  const query = `
    UPDATE users
    SET approved = $1,
        updated_at = NOW()
    WHERE id = $2
      AND deleted_at IS NULL
    RETURNING *;
  `;

  const { rows } = await pool.query(query, [approved, userId]);
  return withTransientFields(toUserModel(rows[0]));
}

function toAddressModel(row) {
  if (!row) return null;

  return {
    id: row.id,
    userId: row.user_id,
    label: row.label,
    streetAddress: row.street_address,
    city: row.city,
    state: row.state,
    postalCode: row.postal_code,
    country: row.country,
    isDefault: row.is_default,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function countAddressesByUser(userId) {
  const query = `
    SELECT COUNT(*)::int AS count
    FROM user_addresses
    WHERE user_id = $1;
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows[0]?.count || 0;
}

async function listAddressesByUser(userId) {
  const query = `
    SELECT *
    FROM user_addresses
    WHERE user_id = $1
    ORDER BY is_default DESC, created_at DESC;
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows.map(toAddressModel);
}

async function createAddress(address) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (address.isDefault) {
      await client.query(
        `
          UPDATE user_addresses
          SET is_default = FALSE, updated_at = NOW()
          WHERE user_id = $1;
        `,
        [address.userId]
      );
    }

    const query = `
      INSERT INTO user_addresses (
        id, user_id, label, street_address, city, state, postal_code, country, is_default, created_at, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
      RETURNING *;
    `;

    const values = [
      address.id,
      address.userId,
      address.label || null,
      address.streetAddress,
      address.city,
      address.state,
      address.postalCode || null,
      address.country || null,
      Boolean(address.isDefault),
    ];

    const { rows } = await client.query(query, values);
    await client.query('COMMIT');
    return toAddressModel(rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function updateAddress({ addressId, userId, patch }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (patch.isDefault === true) {
      await client.query(
        `
          UPDATE user_addresses
          SET is_default = FALSE, updated_at = NOW()
          WHERE user_id = $1;
        `,
        [userId]
      );
    }

    const setClauses = [];
    const values = [];
    const fieldMap = {
      label: 'label',
      streetAddress: 'street_address',
      city: 'city',
      state: 'state',
      postalCode: 'postal_code',
      country: 'country',
      isDefault: 'is_default',
    };

    Object.entries(fieldMap).forEach(([key, dbCol]) => {
      if (!Object.prototype.hasOwnProperty.call(patch, key)) return;
      values.push(patch[key]);
      setClauses.push(`${dbCol} = $${values.length}`);
    });

    if (setClauses.length === 0) {
      const existing = await client.query(
        `
          SELECT *
          FROM user_addresses
          WHERE id = $1 AND user_id = $2
          LIMIT 1;
        `,
        [addressId, userId]
      );
      await client.query('COMMIT');
      return toAddressModel(existing.rows[0]);
    }

    values.push(addressId);
    values.push(userId);

    const query = `
      UPDATE user_addresses
      SET ${setClauses.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length - 1}
        AND user_id = $${values.length}
      RETURNING *;
    `;

    const { rows } = await client.query(query, values);
    await client.query('COMMIT');
    return toAddressModel(rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function deleteAddress(addressId, userId) {
  const query = `
    DELETE FROM user_addresses
    WHERE id = $1
      AND user_id = $2
    RETURNING id;
  `;

  const { rows } = await pool.query(query, [addressId, userId]);
  return Boolean(rows[0]);
}

async function setDefaultAddress(addressId, userId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const target = await client.query(
      `
        SELECT id
        FROM user_addresses
        WHERE id = $1
          AND user_id = $2
        LIMIT 1;
      `,
      [addressId, userId]
    );

    if (!target.rows[0]) {
      await client.query('ROLLBACK');
      return null;
    }

    await client.query(
      `
        UPDATE user_addresses
        SET is_default = FALSE, updated_at = NOW()
        WHERE user_id = $1;
      `,
      [userId]
    );

    const updated = await client.query(
      `
        UPDATE user_addresses
        SET is_default = TRUE, updated_at = NOW()
        WHERE id = $1
          AND user_id = $2
        RETURNING *;
      `,
      [addressId, userId]
    );

    await client.query('COMMIT');
    return toAddressModel(updated.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function listFavoritesByUser(userId) {
  const query = `
    SELECT
      uf.id,
      uf.user_id,
      uf.restaurant_id,
      uf.created_at,
      r.name AS restaurant_name,
      r.cuisine,
      r.rating,
      r.image
    FROM user_favorites uf
    JOIN restaurants r ON r.id = uf.restaurant_id
    WHERE uf.user_id = $1
    ORDER BY uf.created_at DESC;
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows.map((row) => ({
    id: row.id,
    userId: row.user_id,
    restaurantId: row.restaurant_id,
    createdAt: row.created_at,
    restaurant: {
      id: row.restaurant_id,
      name: row.restaurant_name,
      cuisine: row.cuisine,
      rating: Number(row.rating || 0),
      image: row.image,
    },
  }));
}

async function addFavorite({ id, userId, restaurantId }) {
  const query = `
    INSERT INTO user_favorites (id, user_id, restaurant_id, created_at)
    VALUES ($1, $2, $3, NOW())
    ON CONFLICT (user_id, restaurant_id) DO NOTHING
    RETURNING id;
  `;

  const { rows } = await pool.query(query, [id, userId, restaurantId]);
  if (rows[0]) {
    return rows[0].id;
  }

  const existing = await pool.query(
    `
      SELECT id
      FROM user_favorites
      WHERE user_id = $1
        AND restaurant_id = $2
      LIMIT 1;
    `,
    [userId, restaurantId]
  );

  return existing.rows[0]?.id || null;
}

async function removeFavoriteByRestaurant(userId, restaurantId) {
  const { rows } = await pool.query(
    `
      DELETE FROM user_favorites
      WHERE user_id = $1
        AND restaurant_id = $2
      RETURNING id;
    `,
    [userId, restaurantId]
  );

  return Boolean(rows[0]);
}

async function listNotificationsByUser(userId) {
  const query = `
    SELECT
      id,
      type,
      title,
      message,
      related_entity_type,
      related_entity_id,
      is_read,
      action_url,
      created_at,
      read_at
    FROM notifications
    WHERE user_id = $1
    ORDER BY created_at DESC;
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows.map((row) => ({
    id: row.id,
    type: row.type,
    title: row.title,
    message: row.message,
    relatedEntityType: row.related_entity_type,
    relatedEntityId: row.related_entity_id,
    isRead: row.is_read,
    actionUrl: row.action_url,
    createdAt: row.created_at,
    readAt: row.read_at,
  }));
}

async function markAllNotificationsReadByUser(userId) {
  await pool.query(
    `
      UPDATE notifications
      SET is_read = TRUE,
          read_at = COALESCE(read_at, NOW())
      WHERE user_id = $1
        AND is_read = FALSE;
    `,
    [userId]
  );
}

function toDeliveryDashboardOrder(row) {
  if (!row) return null;

  const customerAddressParts = [
    row.street_address,
    row.city,
    row.state,
    row.postal_code,
  ]
    .filter((part) => part && String(part).trim().length > 0)
    .map((part) => String(part).trim());

  return {
    id: row.id,
    userId: row.user_id,
    restaurantId: row.restaurant_id,
    restaurantName: row.restaurant_name,
    customerName: row.customer_name,
    customerEmail: row.customer_email,
    customerAddress: customerAddressParts.join(', ') || null,
    deliveryAddressId: row.delivery_address_id,
    deliveryFee: Number(row.delivery_fee || 0),
    totalAmount: Number(row.total_amount || 0),
    status: row.order_status,
    paymentStatus: row.payment_status,
    estimatedDeliveryTime: row.estimated_delivery_time,
    actualDeliveryTime: row.actual_delivery_time,
    createdAt: row.created_at,
  };
}

function toDeliveryDashboardProfile(user, agent, averageRating, totalDeliveries) {
  return {
    id: agent?.id || user.id,
    name: agent?.name || user.name,
    email: agent?.email || user.email,
    phone: agent?.phone || user.phone || '-',
    rating: Number(agent?.rating ?? averageRating ?? 0),
    totalDeliveries: Number(agent?.total_deliveries ?? totalDeliveries ?? 0),
    isActive: agent?.is_active ?? (user.status === 'active'),
    vehicleType: agent?.vehicle_type || '-',
    licensePlate: agent?.vehicle_number || '-',
    status: agent?.status || user.status,
    totalEarnings: Number(agent?.total_earnings ?? 0),
  };
}

async function getDeliveryDashboardForUser(userId) {
  const userResult = await pool.query(
    `
    SELECT *
    FROM users
    WHERE id = $1
      AND deleted_at IS NULL
    LIMIT 1
    `,
    [userId]
  );

  if (!userResult.rows[0]) {
    return null;
  }

  const user = withTransientFields(toUserModel(userResult.rows[0]));

  const deliveryAgentResult = await pool.query(
    `
    SELECT *
    FROM delivery_agents
    WHERE LOWER(email) = LOWER($1)
    LIMIT 1
    `,
    [user.email]
  );

  const deliveryAgent = deliveryAgentResult.rows[0] || null;
  const dashboardId = deliveryAgent?.id || user.id;

  const incomingRequestsResult = await pool.query(
    `
    SELECT
      dr.id,
      dr.order_id,
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
      o.delivery_address_id,
      r.name AS restaurant_name,
      r.latitude AS restaurant_latitude,
      r.longitude AS restaurant_longitude,
      cu.name AS customer_name,
      cu.email AS customer_email,
      cu.phone AS customer_phone,
      ua.street_address,
      ua.city,
      ua.state,
      ua.postal_code,
      ua.latitude AS customer_latitude,
      ua.longitude AS customer_longitude,
      (
        SELECT COALESCE(
          json_agg(
            json_build_object(
              'name', COALESCE(fi.name, 'Item'),
              'quantity', COALESCE(oi.quantity, 1)
            )
          ),
          '[]'::json
        )
        FROM order_items oi
        LEFT JOIN food_items fi ON fi.id = oi.food_item_id
        WHERE oi.order_id = o.id
      ) AS order_items
    FROM delivery_requests dr
    JOIN orders o ON o.id = dr.order_id
    LEFT JOIN restaurants r ON r.id = o.restaurant_id
    LEFT JOIN users cu ON cu.id = o.user_id
    LEFT JOIN user_addresses ua ON ua.id = o.delivery_address_id
    WHERE dr.delivery_partner_id = $1
      AND dr.status = 'pending'
      AND o.deleted_at IS NULL
    ORDER BY dr.created_at ASC
    LIMIT 50
    `,
    [dashboardId]
  );

  const acceptedRequestsResult = await pool.query(
    `
    SELECT
      dr.id,
      dr.order_id,
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
      o.actual_delivery_time,
      o.created_at AS order_created_at,
      o.delivery_address_id,
      r.name AS restaurant_name,
      r.latitude AS restaurant_latitude,
      r.longitude AS restaurant_longitude,
      cu.name AS customer_name,
      cu.email AS customer_email,
      cu.phone AS customer_phone,
      ua.street_address,
      ua.city,
      ua.state,
      ua.postal_code,
      ua.latitude AS customer_latitude,
      ua.longitude AS customer_longitude,
      (
        SELECT COALESCE(
          json_agg(
            json_build_object(
              'name', COALESCE(fi.name, 'Item'),
              'quantity', COALESCE(oi.quantity, 1)
            )
          ),
          '[]'::json
        )
        FROM order_items oi
        LEFT JOIN food_items fi ON fi.id = oi.food_item_id
        WHERE oi.order_id = o.id
      ) AS order_items
    FROM delivery_requests dr
    JOIN orders o ON o.id = dr.order_id
    LEFT JOIN restaurants r ON r.id = o.restaurant_id
    LEFT JOIN users cu ON cu.id = o.user_id
    LEFT JOIN user_addresses ua ON ua.id = o.delivery_address_id
    WHERE dr.delivery_partner_id = $1
      AND dr.status = 'accepted'
      AND o.deleted_at IS NULL
    ORDER BY dr.accepted_at DESC NULLS LAST, dr.updated_at DESC
    LIMIT 50
    `,
    [dashboardId]
  );

  const columnInfo = await pool.query(
    `
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'orders'
    `
  );

  const orderColumns = new Set(columnInfo.rows.map((r) => r.column_name));
  const deliveryFkColumn = orderColumns.has('delivery_agent_id')
    ? 'delivery_agent_id'
    : orderColumns.has('delivery_partner_id')
      ? 'delivery_partner_id'
      : null;

  let orders = [];
  if (deliveryFkColumn) {
    const ordersResult = await pool.query(
      `
      SELECT
        o.id,
        o.user_id,
        o.restaurant_id,
        o.delivery_address_id,
        o.delivery_fee,
        o.total_amount,
        o.order_status,
        o.payment_status,
        o.estimated_delivery_time,
        o.actual_delivery_time,
        o.created_at,
        r.name AS restaurant_name,
        u.name AS customer_name,
        u.email AS customer_email,
        ua.street_address,
        ua.city,
        ua.state,
        ua.postal_code
      FROM orders o
      LEFT JOIN restaurants r ON r.id = o.restaurant_id
      LEFT JOIN users u ON u.id = o.user_id
      LEFT JOIN user_addresses ua ON ua.id = o.delivery_address_id
      WHERE o.${deliveryFkColumn} = $1
        AND o.deleted_at IS NULL
      ORDER BY o.created_at DESC
      LIMIT 50
      `,
      [dashboardId]
    );

    orders = ordersResult.rows.map(toDeliveryDashboardOrder);
  }

  const ratingsResult = await pool.query(
    `
    SELECT
      COALESCE(AVG(rating), 0) AS "averageRating",
      COUNT(*)::int AS "ratingCount"
    FROM delivery_agent_ratings
    WHERE delivery_agent_id = $1
    `,
    [dashboardId]
  );

  const ratings = ratingsResult.rows[0] || {
    averageRating: 0,
    ratingCount: 0,
  };

  const now = new Date();
  const weekAgo = new Date(now);
  weekAgo.setDate(now.getDate() - 6);
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  const deliveredOrders = orders.filter((order) => order.status === 'delivered');
  const activeOrders = orders.filter((order) => {
    const status = String(order.status || '').toLowerCase();
    return !['delivered', 'cancelled'].includes(status);
  });

  const deliveredToday = deliveredOrders.filter((order) => {
    const deliveredAt = order.actualDeliveryTime ? new Date(order.actualDeliveryTime) : null;
    const createdAt = order.createdAt ? new Date(order.createdAt) : null;
    const effectiveDate = deliveredAt || createdAt;
    return effectiveDate && effectiveDate >= startOfToday;
  });

  const weeklyTotals = new Map([
    ['Mon', 0],
    ['Tue', 0],
    ['Wed', 0],
    ['Thu', 0],
    ['Fri', 0],
    ['Sat', 0],
    ['Sun', 0],
  ]);

  const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  deliveredOrders.forEach((order) => {
    const date = order.actualDeliveryTime ? new Date(order.actualDeliveryTime) : new Date(order.createdAt);
    if (Number.isNaN(date.getTime()) || date < weekAgo) return;
    const label = weekdayLabels[date.getDay() === 0 ? 6 : date.getDay() - 1];
    weeklyTotals.set(label, (weeklyTotals.get(label) || 0) + Number(order.deliveryFee || 0));
  });

  const profile = toDeliveryDashboardProfile(
    user,
    deliveryAgent,
    ratings.averageRating,
    orders.length
  );

  const mapRequest = (row) => {
    const addressParts = [row.street_address, row.city, row.state, row.postal_code]
      .filter((part) => part && String(part).trim())
      .map((part) => String(part).trim());

    return {
      id: row.id,
      orderId: row.order_id,
      status: row.status,
      rejectionReason: row.rejection_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      respondedAt: row.responded_at,
      acceptedAt: row.accepted_at,
      rejectedAt: row.rejected_at,
      order: {
        id: row.order_id,
        restaurantName: row.restaurant_name,
        restaurantLatitude: row.restaurant_latitude,
        restaurantLongitude: row.restaurant_longitude,
        customerName: row.customer_name,
        customerEmail: row.customer_email,
        customerPhone: row.customer_phone,
        customerAddress: addressParts.join(', ') || null,
        customerLatitude: row.customer_latitude,
        customerLongitude: row.customer_longitude,
        items: Array.isArray(row.order_items) ? row.order_items : [],
        totalAmount: Number(row.total_amount || 0),
        deliveryFee: Number(row.delivery_fee || 0),
        status: row.order_status,
        estimatedDeliveryTime: row.estimated_delivery_time,
        actualDeliveryTime: row.actual_delivery_time,
        createdAt: row.order_created_at,
        deliveryAddressId: row.delivery_address_id,
      },
    };
  };

  return {
    profile,
    summary: {
      totalDeliveries: orders.length,
      completedDeliveries: deliveredOrders.length,
      activeDeliveries: activeOrders.length,
      ratingCount: ratings.ratingCount,
      averageRating: Number(ratings.averageRating || 0),
    },
    metrics: {
      totalEarningsToday: deliveredToday.reduce((sum, order) => sum + Number(order.deliveryFee || 0), 0),
      weeklyEarnings: deliveredOrders
        .filter((order) => {
          const date = order.actualDeliveryTime ? new Date(order.actualDeliveryTime) : new Date(order.createdAt);
          return !Number.isNaN(date.getTime()) && date >= weekAgo;
        })
        .reduce((sum, order) => sum + Number(order.deliveryFee || 0), 0),
      totalDeliveriesToday: deliveredToday.length,
    },
    weeklyEarningsBreakdown: weekdayLabels.map((label) => ({
      day: label,
      amount: weeklyTotals.get(label) || 0,
    })),
    activeDeliveries: acceptedRequestsResult.rows.map(mapRequest),
    incomingRequests: incomingRequestsResult.rows.map(mapRequest),
    earnings: deliveredOrders.map((order) => ({
      id: order.id,
      deliveryId: order.id,
      amount: Number(order.deliveryFee || 0),
      date: order.actualDeliveryTime || order.createdAt,
      status: order.status === 'delivered' ? 'completed' : 'pending',
    })),
  };
}

module.exports = {
  createUser,
  findUserByEmail,
  findUserById,
  updateUser,
  listUsers,
  listPendingApprovalUsers,
  setApprovalStatus,
  countAddressesByUser,
  listAddressesByUser,
  createAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
  listFavoritesByUser,
  addFavorite,
  removeFavoriteByRestaurant,
  listNotificationsByUser,
  markAllNotificationsReadByUser,
  getDeliveryDashboardForUser,
};
