const express = require('express');
const controller = require('./users.controller');
const { requireAuth } = require('../../middlewares/auth');

const router = express.Router();

router.get('/me', requireAuth, controller.me);
router.get('/', requireAuth, controller.listUsers);

module.exports = router;
