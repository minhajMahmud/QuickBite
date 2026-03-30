const express = require('express');
const validate = require('../../middlewares/validate');
const controller = require('./auth.controller');

const router = express.Router();

// Register new user
router.post('/register', validate(['name', 'email', 'password']), controller.register);

// Login
router.post('/login', validate(['email', 'password']), controller.login);

// Email verification
router.post('/verify-email', validate(['email', 'token']), controller.verifyEmail);

// Resend verification email
router.post('/resend-verification', validate(['email']), controller.resendVerificationEmail);

// Forgot password - request reset
router.post('/forgot-password', validate(['email']), controller.requestPasswordReset);

// Reset password with token
router.post('/reset-password', validate(['email', 'token', 'newPassword']), controller.resetPassword);

module.exports = router;
