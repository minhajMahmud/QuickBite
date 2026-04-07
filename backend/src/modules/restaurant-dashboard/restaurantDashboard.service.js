const crypto = require('crypto');
const ApiError = require('../../utils/apiError');
const repository = require('./restaurantDashboard.repository');
const usersStore = require('../users/users.store');
const path = require('path');
const fs = require('fs/promises');

const VALID_ORDER_STATUSES = new Set([
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'on_the_way',
  'delivered',
  'cancelled',
]);

const VALID_AVAILABILITY = new Set(['available', 'unavailable', 'out_of_stock']);

async function resolveRestaurantId({ user, restaurantId }) {
  if (restaurantId) {
    return restaurantId;
  }

  if (user.role === 'restaurant') {
    let ownedRestaurantId = await repository.findRestaurantByOwnerId(user.sub);
    if (!ownedRestaurantId) {
      const owner = await usersStore.findUserById(user.sub);
      if (!owner) {
        throw new ApiError(400, 'Restaurant account not found');
      }

      ownedRestaurantId = await repository.createRestaurantForOwner({
        ownerId: user.sub,
        name: owner.name,
        email: owner.email,
      });

      if (!ownedRestaurantId) {
        ownedRestaurantId = await repository.findRestaurantByOwnerId(user.sub);
      }
    }

    if (!ownedRestaurantId) {
      throw new ApiError(400, 'Restaurant account has no linked restaurant record');
    }

    return ownedRestaurantId;
  }

  throw new ApiError(400, 'restaurantId is required');
}

async function assertRestaurantAccess({ user, restaurantId }) {
  const restaurant = await repository.findRestaurantById(restaurantId);
  if (!restaurant) {
    throw new ApiError(404, 'Restaurant not found');
  }

  if (user.role === 'restaurant' && restaurant.owner_id && restaurant.owner_id !== user.sub) {
    throw new ApiError(403, 'You can only access your own restaurant dashboard');
  }

  if (user.role === 'restaurant') {
    const owner = await usersStore.findUserById(user.sub);

    if (!owner) {
      throw new ApiError(403, 'Restaurant account not found');
    }

    if (owner.status === 'banned' || owner.status === 'inactive') {
      throw new ApiError(403, 'This restaurant account is restricted');
    }

  }

  return restaurant;
}

async function persistImageFromDataUri(imageData, folderName = 'menu-items') {
  if (!imageData || typeof imageData !== 'string') {
    return null;
  }

  const match = imageData.match(/^data:image\/(png|jpe?g|webp);base64,(.+)$/i);
  if (!match) {
    throw new ApiError(400, 'Invalid image data format. Use data URL with png, jpeg, jpg, or webp.');
  }

  const ext = match[1].toLowerCase() === 'jpeg' ? 'jpg' : match[1].toLowerCase();
  const base64Data = match[2];
  const imageBuffer = Buffer.from(base64Data, 'base64');

  if (!imageBuffer.length) {
    throw new ApiError(400, 'Image payload is empty');
  }

  const uploadsDir = path.join(__dirname, '..', '..', '..', 'uploads', folderName);
  await fs.mkdir(uploadsDir, { recursive: true });

  const fileName = `${crypto.randomUUID()}.${ext}`;
  const filePath = path.join(uploadsDir, fileName);

  await fs.writeFile(filePath, imageBuffer);
  return `/uploads/${folderName}/${fileName}`;
}

async function getOverview({ user, restaurantId }) {
  const resolvedRestaurantId = await resolveRestaurantId({ user, restaurantId });
  const restaurant = await assertRestaurantAccess({ user, restaurantId: resolvedRestaurantId });

  const [overview, operatingHours] = await Promise.all([
    repository.getDashboardOverview(resolvedRestaurantId),
    repository.listOperatingHours(resolvedRestaurantId),
  ]);

  return {
    restaurant,
    metrics: overview,
    operatingHours,
  };
}

async function updateProfile({ user, payload }) {
  const restaurantId = await resolveRestaurantId({
    user,
    restaurantId: payload.restaurantId,
  });
  await assertRestaurantAccess({ user, restaurantId });

  const updates = {
    name: payload.name,
    description: payload.description,
    image: payload.image,
    cuisine: payload.cuisine,
    phone: payload.phone,
    email: payload.email,
    streetAddress: payload.streetAddress || payload.address,
    city: payload.city,
    state: payload.state,
    postalCode: payload.postalCode,
  };

  if (payload.imageData) {
    updates.image = await persistImageFromDataUri(payload.imageData, 'restaurant-profile');
  }

  const cleanedUpdates = Object.fromEntries(
    Object.entries(updates).filter(([, value]) => value !== undefined)
  );

  const updated = await repository.updateRestaurantProfile({
    restaurantId,
    updates: cleanedUpdates,
  });

  if (!updated) {
    throw new ApiError(404, 'Restaurant not found');
  }

  return updated;
}

async function listMenu({ user, restaurantId }) {
  const resolvedRestaurantId = await resolveRestaurantId({ user, restaurantId });
  await assertRestaurantAccess({ user, restaurantId: resolvedRestaurantId });
  return repository.listMenuItems(resolvedRestaurantId);
}

async function addMenuItem({ user, payload }) {
  const restaurantId = await resolveRestaurantId({ user, restaurantId: payload.restaurantId });
  await assertRestaurantAccess({ user, restaurantId });

  if (!payload.categoryId) {
    throw new ApiError(400, 'categoryId is required');
  }

  if (!payload.name) {
    throw new ApiError(400, 'name is required');
  }

  const price = Number(payload.price);
  if (!Number.isFinite(price) || price < 0) {
    throw new ApiError(400, 'price must be a valid non-negative number');
  }

  const availability = payload.availability || 'available';
  if (!VALID_AVAILABILITY.has(availability)) {
    throw new ApiError(400, 'Invalid availability value');
  }

  let image = payload.image || null;
  if (payload.imageData) {
    image = await persistImageFromDataUri(payload.imageData);
  }

  return repository.createMenuItem({
    id: crypto.randomUUID(),
    restaurantId,
    categoryId: payload.categoryId,
    name: payload.name,
    description: payload.description || null,
    price,
    image,
    isPopular: Boolean(payload.isPopular),
    isVegetarian: Boolean(payload.isVegetarian),
    isVegan: Boolean(payload.isVegan),
    isGlutenFree: Boolean(payload.isGlutenFree),
    availability,
  });
}

async function editMenuItem({ user, foodItemId, payload }) {
  const restaurantId = await resolveRestaurantId({ user, restaurantId: payload.restaurantId });
  await assertRestaurantAccess({ user, restaurantId });

  if (payload.imageData) {
    payload.image = await persistImageFromDataUri(payload.imageData);
    delete payload.imageData;
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'availability')) {
    if (!VALID_AVAILABILITY.has(payload.availability)) {
      throw new ApiError(400, 'Invalid availability value');
    }
  }

  if (Object.prototype.hasOwnProperty.call(payload, 'price')) {
    const price = Number(payload.price);
    if (!Number.isFinite(price) || price < 0) {
      throw new ApiError(400, 'price must be a valid non-negative number');
    }
    payload.price = price;
  }

  const updated = await repository.updateMenuItem({
    restaurantId,
    foodItemId,
    updates: payload,
  });

  if (!updated) {
    throw new ApiError(404, 'Menu item not found or no valid fields provided');
  }

  return updated;
}

async function removeMenuItem({ user, foodItemId, payload }) {
  const restaurantId = await resolveRestaurantId({
    user,
    restaurantId: payload?.restaurantId,
  });
  await assertRestaurantAccess({ user, restaurantId });

  const deleted = await repository.deleteMenuItem({
    restaurantId,
    foodItemId,
  });

  if (!deleted) {
    throw new ApiError(404, 'Menu item not found');
  }

  return true;
}

async function listOrders({ user, restaurantId, status, limit, offset }) {
  const resolvedRestaurantId = await resolveRestaurantId({ user, restaurantId });
  await assertRestaurantAccess({ user, restaurantId: resolvedRestaurantId });

  if (status && !VALID_ORDER_STATUSES.has(status)) {
    throw new ApiError(400, 'Invalid order status filter');
  }

  const safeLimit = Number.isFinite(Number(limit)) ? Math.min(Math.max(Number(limit), 1), 100) : 20;
  const safeOffset = Number.isFinite(Number(offset)) ? Math.max(Number(offset), 0) : 0;

  return repository.listRestaurantOrders({
    restaurantId: resolvedRestaurantId,
    status,
    limit: safeLimit,
    offset: safeOffset,
  });
}

async function updateOrderStatus({ user, restaurantId, orderId, status }) {
  const resolvedRestaurantId = await resolveRestaurantId({ user, restaurantId });
  await assertRestaurantAccess({ user, restaurantId: resolvedRestaurantId });

  if (!VALID_ORDER_STATUSES.has(status)) {
    throw new ApiError(400, 'Invalid order status');
  }

  const order = await repository.updateRestaurantOrderStatus({
    restaurantId: resolvedRestaurantId,
    orderId,
    status,
  });

  if (!order) {
    throw new ApiError(404, 'Order not found for this restaurant');
  }

  return order;
}

async function getAnalytics({ user, restaurantId, days }) {
  const resolvedRestaurantId = await resolveRestaurantId({ user, restaurantId });
  await assertRestaurantAccess({ user, restaurantId: resolvedRestaurantId });

  const safeDays = Number.isFinite(Number(days)) ? Math.min(Math.max(Number(days), 1), 365) : 30;

  const [timeSeries, topItems] = await Promise.all([
    repository.getSalesTimeSeries({ restaurantId: resolvedRestaurantId, days: safeDays }),
    repository.getTopSellingItems({ restaurantId: resolvedRestaurantId, days: safeDays, limit: 10 }),
  ]);

  return {
    rangeDays: safeDays,
    dailySales: timeSeries,
    topItems,
  };
}

module.exports = {
  getOverview,
  updateProfile,
  listMenu,
  addMenuItem,
  editMenuItem,
  removeMenuItem,
  listOrders,
  updateOrderStatus,
  getAnalytics,
};
