const express = require('express');
const { requireAuth, requireRole } = require('../../middlewares/auth');
const controller = require('./deliveryRequests.controller');

const router = express.Router();

router.use(requireAuth, requireRole('delivery_partner'));

router.get('/incoming', controller.listIncomingRequests);
router.post('/:requestId/accept', controller.acceptRequest);
router.post('/:requestId/reject', controller.rejectRequest);

module.exports = router;
