const repository = require('./catalog.repository');

function toRestaurantModel(row) {
  const deliveryFeeNumber = Number(row.delivery_fee || 0);

  return {
    id: row.id,
    name: row.name,
    image: row.image || '',
    cuisine: row.cuisine,
    rating: Number(row.rating || 0),
    deliveryTime: row.delivery_time || '25-35 mins',
    deliveryFee: deliveryFeeNumber <= 0 ? 'Free' : `$${deliveryFeeNumber.toFixed(2)}`,
    popular: Boolean(row.is_popular),
    priceRange: row.price_range || '$$',
  };
}

function toFoodItemModel(row) {
  return {
    id: row.id,
    restaurantId: row.restaurant_id,
    name: row.name,
    description: row.description || '',
    price: Number(row.price || 0),
    image: row.image || '',
    category: row.category || 'Uncategorized',
    popular: Boolean(row.is_popular),
  };
}

function toCategoryModel(row) {
  const fallbackIconMap = {
    pizza: '🍕',
    burgers: '🍔',
    burger: '🍔',
    pasta: '🍝',
    salads: '🥗',
    salad: '🥗',
    desserts: '🍰',
    dessert: '🍰',
    beverages: '🥤',
    drinks: '🥤',
    sushi: '🍣',
    tacos: '🌮',
    coffee: '☕',
  };

  const normalized = String(row.name || '').trim().toLowerCase();
  const emojiIcon = fallbackIconMap[normalized] || '🍽️';

  return {
    id: row.id,
    name: row.name,
    icon: row.icon && row.icon.includes('.') ? emojiIcon : (row.icon || emojiIcon),
  };
}

async function getCategories() {
  const rows = await repository.listCategories();
  return rows.map(toCategoryModel);
}

async function getRestaurants() {
  const rows = await repository.listRestaurants();
  return rows.map(toRestaurantModel);
}

async function getFoodItems({ restaurantId }) {
  const rows = await repository.listFoodItems(restaurantId || null);
  return rows.map(toFoodItemModel);
}

module.exports = {
  getCategories,
  getRestaurants,
  getFoodItems,
};
