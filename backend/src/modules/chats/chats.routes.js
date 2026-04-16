const express = require('express');
const { requireAuth } = require('../../middlewares/auth');
const controller = require('./chats.controller');

const router = express.Router();

router.use(requireAuth);
router.get('/:orderId/messages', controller.listMessages);
router.post('/:orderId/messages', controller.sendMessage);

module.exports = router;
