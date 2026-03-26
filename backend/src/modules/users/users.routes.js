const express = require('express');
const controller = require('./users.controller');
const { requireAuth, requireRole } = require('../../middlewares/auth');

const router = express.Router();

router.get('/me', requireAuth, controller.me);
router.get('/', requireAuth, requireRole('admin'), controller.listUsers);

module.exports = router;
