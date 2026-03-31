const ordersService = require('./orders.service');

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

async function updateStatus(req, res, next) {
  try {
    const order = await ordersService.updateOrderStatus(req.params.id, req.body.status, req.user);
    res.json({ order });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listOrders,
  createOrder,
  updateStatus,
};
