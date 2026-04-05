const service = require('./adminRestaurants.service');
const ApiError = require('../../utils/apiError');

async function listRestaurants(_req, res, next) {
  try {
    const restaurants = await service.listRestaurants();
    res.json({ restaurants });
  } catch (error) {
    next(error);
  }
}

async function setRestaurantApproval(req, res, next) {
  try {
    const restaurantId = req.params.restaurantId;
    if (!restaurantId) {
      throw new ApiError(400, 'restaurantId is required');
    }

    const approved = Boolean(req.body?.approved);
    const data = await service.setApproval({ restaurantId, approved });

    res.json({
      message: approved
          ? 'Restaurant approved successfully'
          : 'Restaurant rejected successfully',
      ...data,
    });
  } catch (error) {
    next(error);
  }
}

async function setRestaurantRestriction(req, res, next) {
  try {
    const restaurantId = req.params.restaurantId;
    if (!restaurantId) {
      throw new ApiError(400, 'restaurantId is required');
    }

    const restricted = Boolean(req.body?.restricted);
    const data = await service.setRestriction({ restaurantId, restricted });

    res.json({
      message: restricted
          ? 'Restaurant has been restricted'
          : 'Restaurant restriction removed',
      ...data,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listRestaurants,
  setRestaurantApproval,
  setRestaurantRestriction,
};
