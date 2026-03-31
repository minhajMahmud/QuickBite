const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const ApiError = require('../../utils/apiError');
const usersStore = require('../users/users.store');
const emailService = require('../../utils/emailService');

/**
 * Generate a secure token
 */
function generateSecureToken() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Generate hash of a token (for storage)
 */
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

/**
 * Register user with email verification
 */
async function register({ name, email, password, role = 'customer' }) {
    const allowedRoles = new Set(['customer', 'restaurant', 'delivery_partner']);
    if (!allowedRoles.has(role)) {
      throw new ApiError(400, 'Invalid role selected for registration');
    }

  console.log('📝 [AUTH_SERVICE] Starting user registration...');
  console.log(`   Email: ${email}`);
  console.log(`   Name: ${name}`);
  console.log(`   Role: ${role}`);
  
  // Check if user already exists
  console.log('   Checking if user already exists...');
  const existing = await usersStore.findUserByEmail(email);
  if (existing) {
    console.warn(`⚠️  User already registered: ${email}`);
    throw new ApiError(409, 'Email already registered');
  }

  // Hash password
  console.log('   Hashing password...');
  const passwordHash = await bcrypt.hash(password, 10);

  // Generate email verification token
  const emailVerificationToken = generateSecureToken();
  const tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  // Create user in database
  console.log('   📦 Calling usersStore.createUser()...');
  const user = await usersStore.createUser({
    id: crypto.randomUUID(),
    name,
    email,
    passwordHash,
    role,
    approved: role === 'customer', // Business accounts require admin approval
    emailVerified: false, // Not verified yet
    emailVerificationToken,
    emailVerificationTokenExpiresAt: tokenExpiry,
    firstLogin: true,
    createdAt: new Date().toISOString(),
  });

  console.log(`✅ [AUTH_SERVICE] User created! ID: ${user.id}`);

  // Send verification email
  try {
    console.log('   📧 Sending verification email...');
    await emailService.sendVerificationEmail(
      email,
      name,
      emailVerificationToken,
      env.frontend.emailVerificationUrl
    );

    // Also send account confirmation email
    await emailService.sendAccountConfirmationEmail(email, name);
    console.log('✅ Verification emails sent successfully');
  } catch (emailError) {
    console.error('⚠️  Email sending failed during registration:', emailError.message);
    // Don't fail registration if email fails - log it and continue
  }

  // Generate JWT token but mark as unverified
  console.log('   🔐 Generating JWT token...');
  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role || 'customer', verified: false },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );

  console.log(`✅ [AUTH_SERVICE] Registration complete! Returning token...`);

  return {
    success: true,
    message: 'Account created! Please verify your email to continue.',
    token,
    user: sanitizeUser(user),
    requiresEmailVerification: true,
  };
}

/**
 * Verify email with token
 */
async function verifyEmail(email, verificationToken) {
  const user = await usersStore.findUserByEmail(email);
  
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  if (user.emailVerified) {
    throw new ApiError(400, 'Email already verified');
  }

  // Check token validity
  if (!user.emailVerificationToken || user.emailVerificationToken !== verificationToken) {
    throw new ApiError(401, 'Invalid verification token');
  }

  if (new Date(user.emailVerificationTokenExpiresAt) < new Date()) {
    throw new ApiError(401, 'Verification token has expired');
  }

  // Update user as verified
  await usersStore.updateUser(user.id, {
    emailVerified: true,
    emailVerificationToken: null,
    emailVerificationTokenExpiresAt: null,
  });

  return {
    success: true,
    message: 'Email verified successfully! You can now use all features.',
  };
}

/**
 * Resend verification email
 */
async function resendVerificationEmail(email) {
  const user = await usersStore.findUserByEmail(email);
  
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  if (user.emailVerified) {
    throw new ApiError(400, 'Email already verified');
  }

  // Generate new token
  const emailVerificationToken = generateSecureToken();
  const tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  await usersStore.updateUser(user.id, {
    emailVerificationToken,
    emailVerificationTokenExpiresAt: tokenExpiry,
  });

  // Send verification email
  try {
    await emailService.sendVerificationEmail(
      email,
      user.name,
      emailVerificationToken,
      env.frontend.emailVerificationUrl
    );
  } catch (error) {
    console.error('Error sending verification email:', error);
    throw new ApiError(500, 'Failed to send verification email');
  }

  return {
    success: true,
    message: 'Verification email sent successfully',
  };
}

/**
 * Login user
 */
async function login({ email, password }) {
  const user = await usersStore.findUserByEmail(email);
  if (!user) {
    throw new ApiError(401, 'Invalid credentials');
  }

  // Verify password
  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    throw new ApiError(401, 'Invalid credentials');
  }

  // Check if account is approved (for restaurant/delivery partners)
  if (!user.approved && (user.role === 'restaurant' || user.role === 'delivery_partner')) {
    throw new ApiError(403, 'Account pending admin approval');
  }

  // Check email verification for critical roles
  if (!user.emailVerified && (user.role === 'restaurant' || user.role === 'delivery_partner')) {
    throw new ApiError(403, 'Please verify your email before logging in');
  }

  // Track first login
  const isFirstLogin = user.firstLogin === true;
  
  if (isFirstLogin) {
    // Send first login email
    try {
      await emailService.sendFirstLoginEmail(email, user.name);
    } catch (error) {
      console.error('Error sending first login email:', error);
      // Don't fail login if email fails
    }

    // Update first login status
    await usersStore.updateUser(user.id, {
      firstLogin: false,
      lastLogin: new Date().toISOString(),
    });
  } else {
    // Update last login time
    await usersStore.updateUser(user.id, {
      lastLogin: new Date().toISOString(),
    });
  }

  // Generate JWT
  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role || 'customer', verified: user.emailVerified },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );

  return {
    success: true,
    token,
    user: sanitizeUser(user),
    isFirstLogin,
  };
}

/**
 * Request password reset
 */
async function requestPasswordReset(email) {
  const user = await usersStore.findUserByEmail(email);
  
  // Don't reveal if email exists or not (security best practice)
  if (!user) {
    return {
      success: true,
      message: 'If that email address is in our system, we will send a password reset link',
    };
  }

  // Generate reset token
  const resetToken = generateSecureToken();
  const tokenHash = hashToken(resetToken);
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

  // Store token hash (not the actual token for security)
  await usersStore.updateUser(user.id, {
    passwordResetToken: tokenHash,
    passwordResetTokenExpiresAt: expiresAt,
  });

  // Send reset email with actual token (sent once, not stored in DB)
  try {
    await emailService.sendPasswordResetEmail(
      email,
      user.name,
      resetToken,
      env.frontend.resetPasswordUrl
    );
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw new ApiError(500, 'Failed to send password reset email');
  }

  return {
    success: true,
    message: 'If that email address is in our system, we will send a password reset link',
  };
}

/**
 * Reset password with token
 */
async function resetPassword(email, resetToken, newPassword) {
  const user = await usersStore.findUserByEmail(email);
  
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Validate token
  const tokenHash = hashToken(resetToken);
  if (!user.passwordResetToken || user.passwordResetToken !== tokenHash) {
    throw new ApiError(401, 'Invalid reset token');
  }

  if (!user.passwordResetTokenExpiresAt || new Date(user.passwordResetTokenExpiresAt) < new Date()) {
    throw new ApiError(401, 'Reset token has expired');
  }

  // Hash new password
  const passwordHash = await bcrypt.hash(newPassword, 10);

  // Update password and clear reset token
  await usersStore.updateUser(user.id, {
    passwordHash,
    passwordResetToken: null,
    passwordResetTokenExpiresAt: null,
    lastPasswordChange: new Date().toISOString(),
  });

  return {
    success: true,
    message: 'Password reset successfully! You can now login with your new password.',
  };
}

/**
 * Sanitize user data (remove sensitive fields)
 */
function sanitizeUser(user) {
  const { 
    passwordHash, 
    emailVerificationToken, 
    passwordResetToken, 
    ...safeUser 
  } = user;
  return safeUser;
}

module.exports = {
  register,
  verifyEmail,
  resendVerificationEmail,
  login,
  requestPasswordReset,
  resetPassword,
  sanitizeUser,
};
