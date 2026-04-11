const service = require('./deliveryRequests.service');
const ordersEvents = require('../orders/orders.events');
const ordersStore = require('../orders/orders.store');
const usersStore = require('../users/users.store');

async function listIncomingRequests(req, res, next) {
  try {
    const requests = await service.listIncomingRequests(req.user.sub);
    return res.json({ requests });
  } catch (error) {
    return next(error);
  }
}

async function acceptRequest(req, res, next) {
  try {
    const { requestId } = req.params;
    const request = await service.acceptRequest({
      requestId,
      partnerId: req.user.sub,
    });

    const partner = await usersStore.findUserById(req.user.sub);

    const order = await ordersStore.findOrderById(request.orderId);
    if (order) {
      const orderWithPartner = {
        ...order,
        deliveryPartner: {
          id: partner?.id || req.user.sub,
          name: partner?.name || req.user.name || req.user.email,
          email: partner?.email || req.user.email,
          phone: partner?.phone || '-',
        },
        deliveryRequest: request,
      };
      ordersEvents.emit('orderUpdated', orderWithPartner);
    }

    return res.json({
      message: 'Delivery request accepted successfully',
      request,
    });
  } catch (error) {
    return next(error);
  }
}

async function rejectRequest(req, res, next) {
  try {
    const { requestId } = req.params;
    const { reason } = req.body || {};
    const request = await service.rejectRequest({
      requestId,
      partnerId: req.user.sub,
      rejectionReason: reason || null,
    });

    return res.json({
      message: 'Delivery request rejected successfully',
      request,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listIncomingRequests,
  acceptRequest,
  rejectRequest,
};
