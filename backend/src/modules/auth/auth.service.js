const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const ApiError = require('../../utils/apiError');
const usersStore = require('../users/users.store');

async function register({ name, email, password, role = 'customer' }) {
  const existing = usersStore.findUserByEmail(email);
  if (existing) {
    throw new ApiError(409, 'Email already exists');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = usersStore.createUser({
    id: crypto.randomUUID(),
    name,
    email,
    passwordHash,
    role,
    approved: role === 'customer',
    createdAt: new Date().toISOString(),
  });

  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );

  return {
    token,
    user: sanitizeUser(user),
  };
}

async function login({ email, password }) {
  const user = usersStore.findUserByEmail(email);
  if (!user) {
    throw new ApiError(401, 'Invalid credentials');
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    throw new ApiError(401, 'Invalid credentials');
  }

  if (!user.approved && (user.role === 'restaurant' || user.role === 'delivery_partner')) {
    throw new ApiError(403, 'Account pending admin approval');
  }

  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );

  return {
    token,
    user: sanitizeUser(user),
  };
}

function sanitizeUser(user) {
  const { passwordHash, ...safeUser } = user;
  return safeUser;
}

module.exports = {
  register,
  login,
};
