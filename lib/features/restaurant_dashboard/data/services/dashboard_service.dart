import 'package:dio/dio.dart';
import '../models/models.dart';

class RestaurantDashboardService {
  final Dio dio;
  final String baseUrl;

  RestaurantDashboardService({
    required this.dio,
    required this.baseUrl,
  });

  Future<DashboardOverview> getDashboardOverview({
    String? restaurantId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (restaurantId != null) {
        params['restaurantId'] = restaurantId;
      }

      final response = await dio.get(
        '$baseUrl/api/v1/restaurant-dashboard/overview',
        queryParameters: params,
      );

      return DashboardOverview.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<MenuItem>> getMenuItems({
    String? restaurantId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (restaurantId != null) {
        params['restaurantId'] = restaurantId;
      }

      final response = await dio.get(
        '$baseUrl/api/v1/restaurant-dashboard/menu',
        queryParameters: params,
      );

      final menu = response.data['menu'] as List?;
      return menu
              ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MenuItem> createMenuItem({
    required String restaurantId,
    required String categoryId,
    required String name,
    required double price,
    String? description,
    String? image,
    bool isPopular = false,
    bool isVegetarian = false,
    bool isVegan = false,
    bool isGlutenFree = false,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/v1/restaurant-dashboard/menu',
        data: {
          'restaurantId': restaurantId,
          'categoryId': categoryId,
          'name': name,
          'price': price,
          'description': description,
          'image': image,
          'isPopular': isPopular,
          'isVegetarian': isVegetarian,
          'isVegan': isVegan,
          'isGlutenFree': isGlutenFree,
        },
      );

      return MenuItem.fromJson(response.data['item'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MenuItem> updateMenuItem({
    required String foodItemId,
    required String restaurantId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? image,
    bool? isPopular,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    String? availability,
  }) async {
    try {
      final data = <String, dynamic>{'restaurantId': restaurantId};
      if (categoryId != null) data['categoryId'] = categoryId;
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (image != null) data['image'] = image;
      if (isPopular != null) data['isPopular'] = isPopular;
      if (isVegetarian != null) data['isVegetarian'] = isVegetarian;
      if (isVegan != null) data['isVegan'] = isVegan;
      if (isGlutenFree != null) data['isGlutenFree'] = isGlutenFree;
      if (availability != null) data['availability'] = availability;

      final response = await dio.patch(
        '$baseUrl/api/v1/restaurant-dashboard/menu/$foodItemId',
        data: data,
      );

      return MenuItem.fromJson(response.data['item'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Order>> getOrders({
    String? restaurantId,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (restaurantId != null) {
        params['restaurantId'] = restaurantId;
      }
      if (status != null) {
        params['status'] = status;
      }

      final response = await dio.get(
        '$baseUrl/api/v1/restaurant-dashboard/orders',
        queryParameters: params,
      );

      final orders = response.data['orders'] as List?;
      return orders
              ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
    String? restaurantId,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/api/v1/restaurant-dashboard/orders/$orderId/status',
        data: {
          'status': status,
          if (restaurantId != null) 'restaurantId': restaurantId,
        },
      );

      return Order.fromJson(response.data['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Analytics> getAnalytics({
    String? restaurantId,
    int? days,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (restaurantId != null) {
        params['restaurantId'] = restaurantId;
      }
      if (days != null) {
        params['days'] = days;
      }

      final response = await dio.get(
        '$baseUrl/api/v1/restaurant-dashboard/analytics',
        queryParameters: params,
      );

      return Analytics.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'An error occurred';
      return Exception('Error: $message');
    }
    return Exception('Network error: ${e.message}');
  }
}
