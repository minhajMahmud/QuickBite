const express = require('express');
const { requireAuth, requireRole } = require('../../middlewares/auth');
const controller = require('./adminUsers.controller');

const router = express.Router();

// All admin user routes require authentication and admin role
router.use(requireAuth, requireRole('admin'));

// Statistics must come before /:userId to avoid conflicts
router.get('/statistics', controller.getUserStatistics);

// List all users (with optional filters)
router.get('/', controller.listUsers);

// Get specific user details
router.get('/:userId', controller.getUserDetails);

// Update user status (ban/unban/activate/deactivate)
router.patch('/:userId/status', controller.updateUserStatus);

module.exports = router;
