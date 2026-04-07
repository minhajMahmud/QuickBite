const service = require('./restaurantDashboard.service');

async function overview(req, res, next) {
  try {
    const data = await service.getOverview({
      user: req.user,
      restaurantId: req.query.restaurantId,
    });
    res.json(data);
  } catch (error) {
    next(error);
  }
}

async function updateProfile(req, res, next) {
  try {
    const restaurant = await service.updateProfile({
      user: req.user,
      payload: req.body,
    });
    res.json({ restaurant });
  } catch (error) {
    next(error);
  }
}

async function listMenu(req, res, next) {
  try {
    const menu = await service.listMenu({
      user: req.user,
      restaurantId: req.query.restaurantId,
    });
    res.json({ menu });
  } catch (error) {
    next(error);
  }
}

async function createMenuItem(req, res, next) {
  try {
    const item = await service.addMenuItem({
      user: req.user,
      payload: req.body,
    });
    res.status(201).json({ item });
  } catch (error) {
    next(error);
  }
}

async function updateMenuItem(req, res, next) {
  try {
    const item = await service.editMenuItem({
      user: req.user,
      foodItemId: req.params.foodItemId,
      payload: req.body,
    });
    res.json({ item });
  } catch (error) {
    next(error);
  }
}

async function deleteMenuItem(req, res, next) {
  try {
    const deleted = await service.removeMenuItem({
      user: req.user,
      foodItemId: req.params.foodItemId,
      payload: req.body || {},
    });
    res.json({ deleted });
  } catch (error) {
    next(error);
  }
}

async function listOrders(req, res, next) {
  try {
    const orders = await service.listOrders({
      user: req.user,
      restaurantId: req.query.restaurantId,
      status: req.query.status,
      limit: req.query.limit,
      offset: req.query.offset,
    });

    res.json({ orders });
  } catch (error) {
    next(error);
  }
}

async function updateOrderStatus(req, res, next) {
  try {
    const order = await service.updateOrderStatus({
      user: req.user,
      restaurantId: req.body.restaurantId || req.query.restaurantId,
      orderId: req.params.orderId,
      status: req.body.status,
    });
    res.json({ order });
  } catch (error) {
    next(error);
  }
}

async function analytics(req, res, next) {
  try {
    const data = await service.getAnalytics({
      user: req.user,
      restaurantId: req.query.restaurantId,
      days: req.query.days,
    });
    res.json(data);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  overview,
  updateProfile,
  listMenu,
  createMenuItem,
  updateMenuItem,
  deleteMenuItem,
  listOrders,
  updateOrderStatus,
  analytics,
};
