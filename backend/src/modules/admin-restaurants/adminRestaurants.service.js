const repository = require('./adminRestaurants.repository');
const ApiError = require('../../utils/apiError');

async function listRestaurants() {
  return repository.listRestaurantsForAdmin();
}

async function setApproval({ restaurantId, approved }) {
  const current = await repository.findRestaurantWithOwner(restaurantId);
  if (!current) {
    throw new ApiError(404, 'Restaurant not found');
  }

  const updated = await repository.setRestaurantApproval({
    restaurantId,
    approved,
  });

  if (!updated || !updated.restaurant) {
    throw new ApiError(404, 'Restaurant not found');
  }

  return updated;
}

async function setRestriction({ restaurantId, restricted }) {
  const current = await repository.findRestaurantWithOwner(restaurantId);
  if (!current) {
    throw new ApiError(404, 'Restaurant not found');
  }

  const updated = await repository.setRestaurantRestriction({
    restaurantId,
    restricted,
  });

  if (!updated || !updated.restaurant) {
    throw new ApiError(404, 'Restaurant not found');
  }

  return updated;
}

module.exports = {
  listRestaurants,
  setApproval,
  setRestriction,
};
