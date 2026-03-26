const ordersService = require('./orders.service');

function listOrders(req, res, next) {
  try {
    const orders = ordersService.listOrdersForRole(req.user);
    res.json({ orders });
  } catch (error) {
    next(error);
  }
}

function createOrder(req, res, next) {
  try {
    const order = ordersService.createOrder({
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

function updateStatus(req, res, next) {
  try {
    const order = ordersService.updateOrderStatus(req.params.id, req.body.status, req.user);
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
