const crypto = require('crypto');
const ApiError = require('../../utils/apiError');
const ordersStore = require('./orders.store');

function createOrder({ userId, restaurantId, items, totalAmount }) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError(400, 'Order items are required');
  }

  const order = {
    id: crypto.randomUUID(),
    userId,
    restaurantId,
    items,
    totalAmount: Number(totalAmount),
    status: 'pending',
    createdAt: new Date().toISOString(),
  };

  return ordersStore.createOrder(order);
}

function listOrdersForRole(user) {
  if (user.role === 'admin') {
    return ordersStore.listOrders();
  }

  return ordersStore.listOrdersByUser(user.sub);
}

function updateOrderStatus(orderId, status, user) {
  const order = ordersStore.findOrderById(orderId);
  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (user.role !== 'admin' && user.role !== 'restaurant') {
    throw new ApiError(403, 'Only admin or restaurant can update order status');
  }

  order.status = status;
  return order;
}

module.exports = {
  createOrder,
  listOrdersForRole,
  updateOrderStatus,
};
