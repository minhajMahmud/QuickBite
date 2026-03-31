const crypto = require('crypto');
const ApiError = require('../../utils/apiError');
const ordersStore = require('./orders.store');

async function createOrder({ userId, restaurantId, items, totalAmount }) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError(400, 'Order items are required');
  }

  if (!restaurantId) {
    throw new ApiError(400, 'Restaurant is required');
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

async function listOrdersForRole(user) {
  if (user.role === 'admin') {
    return ordersStore.listOrders();
  }

  return ordersStore.listOrdersByUser(user.sub);
}

async function updateOrderStatus(orderId, status, user) {
  const order = await ordersStore.findOrderById(orderId);
  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (user.role !== 'admin' && user.role !== 'restaurant') {
    throw new ApiError(403, 'Only admin or restaurant can update order status');
  }

  if (user.role === 'restaurant') {
    const canManage = await ordersStore.canRestaurantManageOrder(orderId, user.sub);
    if (!canManage) {
      throw new ApiError(403, 'Forbidden: cannot modify orders for other restaurants');
    }
  }

  const updated = await ordersStore.updateOrderStatus(orderId, status);
  if (!updated) {
    throw new ApiError(404, 'Order not found');
  }

  return updated;
}

module.exports = {
  createOrder,
  listOrdersForRole,
  updateOrderStatus,
};
