const { pool } = require('../../config/db');

const transientUserFields = new Map();

const dbFieldMap = {
  name: 'name',
  email: 'email',
  passwordHash: 'password_hash',
  avatar: 'avatar',
  phone: 'phone',
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
    avatar: row.avatar,
    phone: row.phone,
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
    role: 'customer',
    approved: true,
    ...user,
    ...extra,
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
      id, name, email, password_hash, avatar, phone, status,
      email_verified, email_verification_token, email_verification_token_expires_at,
      first_login, last_login, created_at, updated_at
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7,
      $8, $9, $10,
      $11, $12, COALESCE($13, NOW()), NOW()
    )
    RETURNING *;
  `;

  const values = [
    user.id,
    user.name,
    user.email,
    user.passwordHash,
    user.avatar || null,
    user.phone || null,
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
      role: user.role || 'customer',
      approved: user.approved ?? true,
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

module.exports = {
  createUser,
  findUserByEmail,
  findUserById,
  updateUser,
  listUsers,
};
