const service = require('./catalog.service');

async function categories(_req, res, next) {
  try {
    const categories = await service.getCategories();
    res.json({ categories });
  } catch (error) {
    next(error);
  }
}

async function restaurants(_req, res, next) {
  try {
    const restaurants = await service.getRestaurants();
    res.json({ restaurants });
  } catch (error) {
    next(error);
  }
}

async function foodItems(req, res, next) {
  try {
    const items = await service.getFoodItems({
      restaurantId: req.query.restaurantId,
    });
    res.json({ items });
  } catch (error) {
    next(error);
  }
}

async function restaurantMenu(req, res, next) {
  try {
    const menu = await service.getFoodItems({
      restaurantId: req.params.restaurantId,
    });
    res.json({ menu });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  categories,
  restaurants,
  foodItems,
  restaurantMenu,
};
