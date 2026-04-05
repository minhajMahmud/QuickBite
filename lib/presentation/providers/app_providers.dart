import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/models.dart';
import '../../data/datasources/catalog_api_service.dart';
import '../../data/datasources/offers_api_service.dart';
import '../../data/datasources/dashboard_api_service.dart' as dashboard;
import '../../features/authentication/presentation/providers/auth_provider.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Restaurants Provider - loads all restaurants
final catalogApiServiceProvider = Provider<CatalogApiService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  const baseUrl = 'http://localhost:3000';
  return CatalogApiService(dio: dio, baseUrl: baseUrl);
});

/// Offers API Service Provider
final offersApiServiceProvider = Provider<OffersApiService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  const baseUrl = 'http://localhost:3000';
  return OffersApiService(dio: dio, baseUrl: baseUrl);
});

/// Offers Provider - loads all active offers
final offersProvider = FutureProvider<List<Offer>>((ref) async {
  final service = ref.watch(offersApiServiceProvider);
  return service.fetchAllOffers();
});

/// Single Offer Provider
final offerDetailProvider =
    FutureProvider.family<Offer?, String>((ref, id) async {
  final service = ref.watch(offersApiServiceProvider);
  return service.fetchOfferById(id);
});

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final service = ref.watch(catalogApiServiceProvider);
  return service.fetchRestaurants();
});

/// Food Items Provider - loads all food items
final foodItemsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final service = ref.watch(catalogApiServiceProvider);
  return service.fetchFoodItems();
});

/// Categories Provider - loads all categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(catalogApiServiceProvider);
  return service.fetchCategories();
});

/// Restaurant Detail Provider - gets a single restaurant by ID
final restaurantDetailProvider = FutureProvider.family<Restaurant?, String>((
  ref,
  id,
) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  for (final restaurant in restaurants) {
    if (restaurant.id == id) return restaurant;
  }
  return null;
});

/// Restaurant Menu Items Provider - gets food items for a specific restaurant
final restaurantMenuProvider = FutureProvider.family<List<FoodItem>, String>((
  ref,
  restaurantId,
) async {
  final service = ref.watch(catalogApiServiceProvider);
  return service.fetchRestaurantMenu(restaurantId);
});

// ============== DASHBOARD PROVIDERS ==============

/// Dashboard API Service Provider
final dashboardApiServiceProvider =
    Provider<dashboard.DashboardApiService>((ref) {
  final token = ref.watch(authProvider.select((state) => state.token));
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  const baseUrl = 'http://localhost:3000';
  return dashboard.DashboardApiService(
    dio: dio,
    baseUrl: baseUrl,
    authToken: token,
  );
});

/// User Stats Provider - Real-time user dashboard statistics
final userStatsProvider = FutureProvider<dashboard.UserStats>((ref) async {
  final service = ref.watch(dashboardApiServiceProvider);
  return service.getUserStats();
});

class UserOverviewData {
  final dashboard.UserStats stats;
  final List<Restaurant> favoriteRestaurants;

  const UserOverviewData({
    required this.stats,
    required this.favoriteRestaurants,
  });
}

/// User Overview Provider - combines live dashboard stats and favorite restaurants
final userOverviewDataProvider = FutureProvider<UserOverviewData>((ref) async {
  final stats = await ref.watch(userStatsProvider.future);
  final restaurants = await ref.watch(restaurantsProvider.future);

  return UserOverviewData(
    stats: stats,
    favoriteRestaurants: restaurants.take(3).toList(),
  );
});

/// Recent Orders Provider - Get user's recent orders
final recentOrdersProvider = FutureProvider<List<dashboard.Order>>((ref) async {
  final service = ref.watch(dashboardApiServiceProvider);
  return service.getRecentOrders();
});

/// Cart State Notifier - manages shopping cart
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add item to cart or increase quantity if already exists
  void addItem(FoodItem foodItem) {
    final existingIndex = state.indexWhere(
      (item) => item.food.id == foodItem.id,
    );
    if (existingIndex >= 0) {
      // Item already in cart, increase quantity
      final updatedItem = CartItem(
        food: state[existingIndex].food,
        quantity: state[existingIndex].quantity + 1,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // New item, add to cart
      state = [...state, CartItem(food: foodItem, quantity: 1)];
    }
  }

  /// Remove item from cart
  void removeItem(String foodId) {
    state = state.where((item) => item.food.id != foodId).toList();
  }

  /// Update item quantity
  void updateQuantity(String foodId, int quantity) {
    if (quantity <= 0) {
      removeItem(foodId);
      return;
    }
    final index = state.indexWhere((item) => item.food.id == foodId);
    if (index >= 0) {
      final updatedItem = CartItem(food: state[index].food, quantity: quantity);
      state = [
        ...state.sublist(0, index),
        updatedItem,
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Clear entire cart
  void clearCart() {
    state = [];
  }

  /// Get total price
  double getTotalPrice() {
    return state.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Get total items count
  int getTotalItems() {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

/// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Cart Summary Providers - combines cart data
final cartTotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.subtotal);
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final deliveryFeeProvider = Provider<double>((ref) {
  final totalPrice = ref.watch(cartTotalPriceProvider);
  return totalPrice > 30 ? 0 : 3.99;
});

final cartGrandTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartTotalPriceProvider);
  final deliveryFee = ref.watch(deliveryFeeProvider);
  return subtotal + deliveryFee;
});

/// Search/Filter State
class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = StateNotifierProvider<SearchNotifier, String>((
  ref,
) {
  return SearchNotifier();
});

/// Category Filter State
class CategoryFilterNotifier extends StateNotifier<String?> {
  CategoryFilterNotifier() : super(null);

  void setCategory(String? category) {
    state = state == category ? null : category; // Toggle
  }

  void clear() {
    state = null;
  }
}

final categoryFilterProvider =
    StateNotifierProvider<CategoryFilterNotifier, String?>((ref) {
  return CategoryFilterNotifier();
});

class NotificationPreferences {
  final bool notificationsEnabled;
  final bool orderUpdates;
  final bool promotions;

  const NotificationPreferences({
    required this.notificationsEnabled,
    required this.orderUpdates,
    required this.promotions,
  });

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? orderUpdates,
    bool? promotions,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
    );
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier()
      : super(
          const NotificationPreferences(
            notificationsEnabled: true,
            orderUpdates: true,
            promotions: false,
          ),
        );

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setOrderUpdates(bool value) {
    state = state.copyWith(orderUpdates: value);
  }

  void setPromotions(bool value) {
    state = state.copyWith(promotions: value);
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  return NotificationPreferencesNotifier();
});

class BrowseFilters {
  final double? minRating;
  final String? priceRange;
  final int? maxEtaMinutes;
  final bool dietaryOnly;

  const BrowseFilters({
    this.minRating,
    this.priceRange,
    this.maxEtaMinutes,
    this.dietaryOnly = false,
  });

  BrowseFilters copyWith({
    double? minRating,
    String? priceRange,
    int? maxEtaMinutes,
    bool? dietaryOnly,
    bool clearMinRating = false,
    bool clearPriceRange = false,
    bool clearMaxEta = false,
  }) {
    return BrowseFilters(
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      maxEtaMinutes: clearMaxEta ? null : (maxEtaMinutes ?? this.maxEtaMinutes),
      dietaryOnly: dietaryOnly ?? this.dietaryOnly,
    );
  }
}

class BrowseFiltersNotifier extends StateNotifier<BrowseFilters> {
  BrowseFiltersNotifier() : super(const BrowseFilters());

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating, clearMinRating: rating == null);
  }

  void setPriceRange(String? range) {
    state = state.copyWith(priceRange: range, clearPriceRange: range == null);
  }

  void setMaxEtaMinutes(int? minutes) {
    state =
        state.copyWith(maxEtaMinutes: minutes, clearMaxEta: minutes == null);
  }

  void setDietaryOnly(bool value) {
    state = state.copyWith(dietaryOnly: value);
  }

  void clearAll() {
    state = const BrowseFilters();
  }
}

final browseFiltersProvider =
    StateNotifierProvider<BrowseFiltersNotifier, BrowseFilters>((ref) {
  return BrowseFiltersNotifier();
});

/// Filtered Restaurants
final filteredRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  final foodItems = await ref.watch(foodItemsProvider.future);
  final searchQuery = ref.watch(searchQueryProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);
  final filters = ref.watch(browseFiltersProvider);

  return restaurants.where((restaurant) {
    final query = searchQuery.toLowerCase();
    final matchesDish = searchQuery.isEmpty ||
        foodItems.any(
          (item) =>
              item.restaurantId == restaurant.id &&
              item.name.toLowerCase().contains(query),
        );

    final matchesSearch = searchQuery.isEmpty ||
        restaurant.name.toLowerCase().contains(query) ||
        restaurant.cuisine.toLowerCase().contains(query) ||
        matchesDish;

    final matchesCategory = categoryFilter == null ||
        restaurant.cuisine.toLowerCase().contains(categoryFilter.toLowerCase());

    final matchesRating =
        filters.minRating == null || restaurant.rating >= filters.minRating!;

    final matchesPriceRange = filters.priceRange == null ||
        restaurant.priceRange == filters.priceRange;

    final eta = _extractEtaMinutes(restaurant.deliveryTime);
    final matchesEta = filters.maxEtaMinutes == null ||
        (eta != null && eta <= filters.maxEtaMinutes!);

    final cuisine = restaurant.cuisine.toLowerCase();
    final isDietaryFriendly = cuisine.contains('vegan') ||
        cuisine.contains('vegetarian') ||
        cuisine.contains('healthy') ||
        cuisine.contains('salad') ||
        cuisine.contains('organic');
    final matchesDietary = !filters.dietaryOnly || isDietaryFriendly;

    return matchesSearch &&
        matchesCategory &&
        matchesRating &&
        matchesPriceRange &&
        matchesEta &&
        matchesDietary;
  }).toList();
});

int? _extractEtaMinutes(String rawDeliveryTime) {
  final normalized = rawDeliveryTime.trim().toLowerCase();
  final regex = RegExp(r'(\d+)');
  final matches = regex.allMatches(normalized).toList();
  if (matches.isEmpty) return null;
  final first = int.tryParse(matches.first.group(1) ?? '');
  if (first == null) return null;
  return first;
}

/// Featured/Popular Restaurants
final featuredRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  return restaurants.where((r) => r.popular).toList();
});

enum OngoingOrderStatus {
  confirmed,
  preparing,
  pickedUp,
  onTheWay,
  delivered,
}

class OngoingOrder {
  final String id;
  final String restaurantName;
  final List<String> items;
  final double total;
  final DateTime createdAt;
  final OngoingOrderStatus status;
  final int etaMinutes;
  final double restaurantLat;
  final double restaurantLng;
  final double customerLat;
  final double customerLng;
  final double riderLat;
  final double riderLng;

  const OngoingOrder({
    required this.id,
    required this.restaurantName,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.etaMinutes,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.customerLat,
    required this.customerLng,
    required this.riderLat,
    required this.riderLng,
  });

  OngoingOrder copyWith({
    String? id,
    String? restaurantName,
    List<String>? items,
    double? total,
    DateTime? createdAt,
    OngoingOrderStatus? status,
    int? etaMinutes,
    double? restaurantLat,
    double? restaurantLng,
    double? customerLat,
    double? customerLng,
    double? riderLat,
    double? riderLng,
  }) {
    return OngoingOrder(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      riderLat: riderLat ?? this.riderLat,
      riderLng: riderLng ?? this.riderLng,
    );
  }
}

class OngoingOrdersNotifier extends StateNotifier<List<OngoingOrder>> {
  OngoingOrdersNotifier() : super(const []);

  OngoingOrder createOrderFromCart({
    required List<CartItem> cartItems,
    required double total,
  }) {
    final now = DateTime.now();
    final id = 'ongoing_${now.millisecondsSinceEpoch}';
    final restaurantName = cartItems.isNotEmpty
        ? cartItems.first.food.restaurantId
        : 'QuickBite Partner';

    const restaurantLat = 23.7806;
    const restaurantLng = 90.4070;
    const customerLat = 23.7678;
    const customerLng = 90.4250;

    final order = OngoingOrder(
      id: id,
      restaurantName: restaurantName,
      items: cartItems.map((e) => '${e.quantity}x ${e.food.name}').toList(),
      total: total,
      createdAt: now,
      status: OngoingOrderStatus.confirmed,
      etaMinutes: 28,
      restaurantLat: restaurantLat,
      restaurantLng: restaurantLng,
      customerLat: customerLat,
      customerLng: customerLng,
      riderLat: restaurantLat,
      riderLng: restaurantLng,
    );

    state = [
      order,
      ...state.where((o) => o.status != OngoingOrderStatus.delivered)
    ];
    return order;
  }

  OngoingOrder? getById(String orderId) {
    for (final order in state) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void advanceTracking(String orderId) {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return;

    final order = state[index];
    if (order.status == OngoingOrderStatus.delivered) return;

    final nextStatus = switch (order.status) {
      OngoingOrderStatus.confirmed => OngoingOrderStatus.preparing,
      OngoingOrderStatus.preparing => OngoingOrderStatus.pickedUp,
      OngoingOrderStatus.pickedUp => OngoingOrderStatus.onTheWay,
      OngoingOrderStatus.onTheWay => OngoingOrderStatus.delivered,
      OngoingOrderStatus.delivered => OngoingOrderStatus.delivered,
    };

    final progressDenominator =
        (order.customerLat - order.restaurantLat).abs() +
            (order.customerLng - order.restaurantLng).abs();
    final statusStep = switch (nextStatus) {
      OngoingOrderStatus.confirmed => 0.0,
      OngoingOrderStatus.preparing => 0.15,
      OngoingOrderStatus.pickedUp => 0.45,
      OngoingOrderStatus.onTheWay => 0.8,
      OngoingOrderStatus.delivered => 1.0,
    };

    final newRiderLat = order.restaurantLat +
        (order.customerLat - order.restaurantLat) * statusStep;
    final newRiderLng = order.restaurantLng +
        (order.customerLng - order.restaurantLng) * statusStep;

    final updated = order.copyWith(
      status: nextStatus,
      etaMinutes: nextStatus == OngoingOrderStatus.delivered
          ? 0
          : (order.etaMinutes - 6).clamp(4, 60),
      riderLat: progressDenominator == 0 ? order.customerLat : newRiderLat,
      riderLng: progressDenominator == 0 ? order.customerLng : newRiderLng,
    );

    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }
}

final ongoingOrdersProvider =
    StateNotifierProvider<OngoingOrdersNotifier, List<OngoingOrder>>((ref) {
  return OngoingOrdersNotifier();
});
