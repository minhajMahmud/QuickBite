const express = require('express');
const controller = require('./catalog.controller');

const router = express.Router();

router.get('/categories', controller.categories);
router.get('/restaurants', controller.restaurants);
router.get('/food-items', controller.foodItems);
router.get('/restaurants/:restaurantId/menu', controller.restaurantMenu);

module.exports = router;
