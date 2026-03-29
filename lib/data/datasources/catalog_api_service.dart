import 'package:dio/dio.dart';
import '../models/models.dart';

class CatalogApiService {
  final Dio _dio;
  final String baseUrl;

  CatalogApiService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  Future<List<Category>> fetchCategories() async {
    final response = await _dio.get('$baseUrl/api/v1/catalog/categories');
    final list = (response.data['categories'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Category.fromJson).toList();
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    final response = await _dio.get('$baseUrl/api/v1/catalog/restaurants');
    final list = (response.data['restaurants'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Restaurant.fromJson).toList();
  }

  Future<List<FoodItem>> fetchFoodItems({String? restaurantId}) async {
    final response = await _dio.get(
      '$baseUrl/api/v1/catalog/food-items',
      queryParameters: restaurantId == null
          ? null
          : <String, dynamic>{'restaurantId': restaurantId},
    );
    final list = (response.data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(FoodItem.fromJson).toList();
  }

  Future<List<FoodItem>> fetchRestaurantMenu(String restaurantId) async {
    final response = await _dio
        .get('$baseUrl/api/v1/catalog/restaurants/$restaurantId/menu');
    final list = (response.data['menu'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(FoodItem.fromJson).toList();
  }
}
