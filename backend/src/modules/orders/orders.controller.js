const ordersService = require('./orders.service');
const ordersEvents = require('./orders.events');

async function listOrders(req, res, next) {
  try {
    const orders = await ordersService.listOrdersForRole(req.user);
    res.json({ orders });
  } catch (error) {
    next(error);
  }
}

async function createOrder(req, res, next) {
  try {
    const order = await ordersService.createOrder({
      userId: req.user.sub,
      restaurantId: req.body.restaurantId,
      items: req.body.items,
      totalAmount: req.body.totalAmount,
    });

    res.status(201).json({ order });
  } catch (error) {
    next(error);
  }
}

async function getOrder(req, res, next) {
  try {
    const order = await ordersService.getOrderByIdForRole(req.params.id, req.user);
    res.json({ order });
  } catch (error) {
    next(error);
  }
}

async function updateStatus(req, res, next) {
  try {
    const order = await ordersService.updateOrderStatus(req.params.id, req.body.status, req.user);
    res.json({ order });
  } catch (error) {
    next(error);
  }
}

async function updatePayment(req, res, next) {
  try {
    const order = await ordersService.updateOrderPayment(
      req.params.id,
      req.body.paymentMethod,
      req.user
    );

    res.json({ order });
  } catch (error) {
    next(error);
  }
}

async function streamOrderEvents(req, res, next) {
  try {
    const order = await ordersService.getOrderByIdForRole(req.params.id, req.user);

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();

    const sendEvent = (payload) => {
      res.write(`event: orderUpdated\n`);
      res.write(`data: ${JSON.stringify(payload)}\n\n`);
    };

    sendEvent(order);

    const heartbeat = setInterval(() => {
      res.write(': keep-alive\n\n');
    }, 25000);

    const handler = (updatedOrder) => {
      if (!updatedOrder || updatedOrder.id !== req.params.id) {
        return;
      }
      sendEvent(updatedOrder);
    };

    ordersEvents.on('orderUpdated', handler);

    req.on('close', () => {
      clearInterval(heartbeat);
      ordersEvents.off('orderUpdated', handler);
      res.end();
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listOrders,
  createOrder,
  getOrder,
  updateStatus,
  updatePayment,
  streamOrderEvents,
};
