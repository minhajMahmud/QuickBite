const ApiError = require('../../utils/apiError');
const chatsStore = require('./chats.store');

const VALID_TYPES = new Set(['text', 'location', 'system']);

async function assertCanAccessOrderChat(orderId, user) {
  const order = await chatsStore.findOrder(orderId);
  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (user.role === 'admin') {
    return order;
  }

  if (order.user_id === user.sub) {
    return order;
  }

  if (user.role === 'delivery_partner') {
    const isAssigned = await chatsStore.isAcceptedDeliveryPartner(orderId, user.sub);
    if (isAssigned) return order;
  }

  throw new ApiError(403, 'Forbidden: cannot access this chat');
}

async function listMessagesForOrder(orderId, user) {
  await assertCanAccessOrderChat(orderId, user);
  return chatsStore.listMessages(orderId);
}

async function sendMessageForOrder(orderId, user, payload) {
  await assertCanAccessOrderChat(orderId, user);

  const type = String(payload.type || 'text').toLowerCase();
  if (!VALID_TYPES.has(type)) {
    throw new ApiError(400, 'Invalid message type');
  }

  if (type === 'text' && !String(payload.content || '').trim()) {
    throw new ApiError(400, 'Message content is required');
  }

  const message = await chatsStore.createMessage({
    orderId,
    senderId: user.sub,
    type,
    content: payload.content,
    latitude: payload.latitude,
    longitude: payload.longitude,
    address: payload.address,
    isLiveLocation: payload.isLiveLocation,
  });

  if (!message) {
    throw new ApiError(500, 'Failed to send message');
  }

  return message;
}

module.exports = {
  listMessagesForOrder,
  sendMessageForOrder,
};
