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
      first_login, last_login, created_at, updated_at
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
      $12, $13, $14,
      $15, $16, COALESCE($17, NOW()), NOW()
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
};
