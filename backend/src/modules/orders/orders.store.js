const orders = [];

function createOrder(order) {
  orders.push(order);
  return order;
}

function listOrders() {
  return orders;
}

function listOrdersByUser(userId) {
  return orders.filter((order) => order.userId === userId);
}

function findOrderById(id) {
  return orders.find((order) => order.id === id) || null;
}

module.exports = {
  createOrder,
  listOrders,
  listOrdersByUser,
  findOrderById,
};
