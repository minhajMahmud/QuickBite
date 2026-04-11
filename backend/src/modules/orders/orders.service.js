const crypto = require('crypto');
const ApiError = require('../../utils/apiError');
const ordersStore = require('./orders.store');
const ordersEvents = require('./orders.events');
const deliveryRequestsStore = require('../delivery-requests/deliveryRequests.store');

const VALID_ORDER_STATUSES = new Set([
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'on_the_way',
  'delivered',
  'cancelled',
]);

const VALID_PAYMENT_METHODS = new Set(['cash', 'credit_card']);

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

  const created = await ordersStore.createOrder(order);
  ordersEvents.emit('orderUpdated', created);
  return created;
}

async function listOrdersForRole(user) {
  if (user.role === 'admin') {
    return ordersStore.listOrders();
  }

  return ordersStore.listOrdersByUser(user.sub);
}

async function updateOrderStatus(orderId, status, user) {
  if (!VALID_ORDER_STATUSES.has(status)) {
    throw new ApiError(400, 'Invalid order status');
  }

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

  if (status === 'confirmed') {
    await deliveryRequestsStore.createRequestsForOrder(orderId);
  }

  ordersEvents.emit('orderUpdated', updated);

  return updated;
}

async function _attachDeliveryDetails(order) {
  if (!order) return order;

  const deliveryRequest = await deliveryRequestsStore.getAcceptedRequestForOrder(order.id);
  if (!deliveryRequest) {
    return order;
  }

  return {
    ...order,
    deliveryPartner: deliveryRequest.deliveryPartner
      ? {
          ...deliveryRequest.deliveryPartner,
          requestStatus: deliveryRequest.status,
        }
      : null,
    deliveryRequest,
  };
}

async function getOrderByIdForRole(orderId, user) {
  const order = await ordersStore.findOrderById(orderId);
  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (user.role === 'admin') {
    return _attachDeliveryDetails(order);
  }

  if (user.role === 'restaurant') {
    const canManage = await ordersStore.canRestaurantManageOrder(orderId, user.sub);
    if (!canManage) {
      throw new ApiError(403, 'Forbidden: cannot access orders for other restaurants');
    }
    return _attachDeliveryDetails(order);
  }

  if (order.userId !== user.sub) {
    throw new ApiError(403, 'Forbidden: cannot access other users orders');
  }

  return _attachDeliveryDetails(order);
}

async function updateOrderPayment(orderId, paymentMethod, user) {
  const method = String(paymentMethod || '').trim().toLowerCase();
  if (!VALID_PAYMENT_METHODS.has(method)) {
    throw new ApiError(400, 'Invalid payment method. Use cash or credit_card');
  }

  const order = await ordersStore.findOrderById(orderId);
  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (order.userId !== user.sub) {
    throw new ApiError(403, 'Forbidden: cannot update payment for another user order');
  }

  if (order.status === 'cancelled') {
    throw new ApiError(400, 'Cannot pay for a cancelled order');
  }

  if (order.status !== 'confirmed') {
    throw new ApiError(400, 'Payment is available after restaurant accepts your order');
  }

  const paymentStatus = method === 'cash' ? 'pending' : 'completed';

  const updated = await ordersStore.updateOrderPayment({
    id: orderId,
    paymentMethod: method,
    paymentStatus,
  });

  if (!updated) {
    throw new ApiError(404, 'Order not found');
  }

  ordersEvents.emit('orderUpdated', updated);

  return updated;
}

module.exports = {
  createOrder,
  listOrdersForRole,
  updateOrderStatus,
  getOrderByIdForRole,
  updateOrderPayment,
};
