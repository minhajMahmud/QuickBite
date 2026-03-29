import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/services/dashboard_service.dart';

// Service provider
final restaurantDashboardServiceProvider =
    Provider<RestaurantDashboardService>((ref) {
  final dio = Dio();
  const baseUrl = 'http://localhost:3000'; // Update with actual backend URL
  return RestaurantDashboardService(dio: dio, baseUrl: baseUrl);
});

// Restaurant ID state
final selectedRestaurantIdProvider = StateProvider<String?>((ref) => null);

// Dashboard overview
final dashboardOverviewProvider =
    FutureProvider.autoDispose<DashboardOverview>((ref) async {
  final service = ref.watch(restaurantDashboardServiceProvider);
  final restaurantId = ref.watch(selectedRestaurantIdProvider);

  return service.getDashboardOverview(restaurantId: restaurantId);
});

// Menu items
final menuItemsProvider =
    FutureProvider.autoDispose<List<MenuItem>>((ref) async {
  final service = ref.watch(restaurantDashboardServiceProvider);
  final restaurantId = ref.watch(selectedRestaurantIdProvider);

  return service.getMenuItems(restaurantId: restaurantId);
});

// Orders
final ordersProvider = FutureProvider.autoDispose
    .family<List<Order>, String?>((ref, status) async {
  final service = ref.watch(restaurantDashboardServiceProvider);
  final restaurantId = ref.watch(selectedRestaurantIdProvider);

  return service.getOrders(restaurantId: restaurantId, status: status ?? null);
});

// Analytics
final analyticsProvider =
    FutureProvider.autoDispose.family<Analytics, int?>((ref, days) async {
  final service = ref.watch(restaurantDashboardServiceProvider);
  final restaurantId = ref.watch(selectedRestaurantIdProvider);

  return service.getAnalytics(restaurantId: restaurantId, days: days ?? 30);
});

// Create menu item
final createMenuItemProvider =
    FutureProvider.family<MenuItem, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(restaurantDashboardServiceProvider);

  return service.createMenuItem(
    restaurantId: params['restaurantId'] as String,
    categoryId: params['categoryId'] as String,
    name: params['name'] as String,
    price: params['price'] as double,
    description: params['description'] as String?,
    image: params['image'] as String?,
    isPopular: params['isPopular'] as bool? ?? false,
    isVegetarian: params['isVegetarian'] as bool? ?? false,
    isVegan: params['isVegan'] as bool? ?? false,
    isGlutenFree: params['isGlutenFree'] as bool? ?? false,
  );
});

// Update menu item
final updateMenuItemProvider =
    FutureProvider.family<MenuItem, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(restaurantDashboardServiceProvider);

  return service.updateMenuItem(
    foodItemId: params['foodItemId'] as String,
    restaurantId: params['restaurantId'] as String,
    categoryId: params['categoryId'] as String?,
    name: params['name'] as String?,
    description: params['description'] as String?,
    price: params['price'] as double?,
    image: params['image'] as String?,
    isPopular: params['isPopular'] as bool?,
    isVegetarian: params['isVegetarian'] as bool?,
    isVegan: params['isVegan'] as bool?,
    isGlutenFree: params['isGlutenFree'] as bool?,
    availability: params['availability'] as String?,
  );
});

// Update order status
final updateOrderStatusProvider =
    FutureProvider.family<Order, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(restaurantDashboardServiceProvider);

  return service.updateOrderStatus(
    orderId: params['orderId'] as String,
    status: params['status'] as String,
    restaurantId: params['restaurantId'] as String?,
  );
});
