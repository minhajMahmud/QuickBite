import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User Dashboard Models
class UserStats {
  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final int savedAddresses;
  final List<dynamic> recentOrders;
  final String userName;
  final String userEmail;

  UserStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.savedAddresses,
    required this.recentOrders,
    required this.userName,
    required this.userEmail,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      savedAddresses: json['savedAddresses'] ?? 0,
      recentOrders: json['recentOrders'] ?? [],
      userName: json['userName'] ?? 'User',
      userEmail: json['userEmail'] ?? '',
    );
  }
}

class Order {
  final String id;
  final String restaurantName;
  final double amount;
  final String status;
  final DateTime createdAt;
  final List<dynamic> items;

  Order({
    required this.id,
    required this.restaurantName,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      restaurantName: json['restaurantName'] ?? 'Restaurant',
      amount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(
              json['createdAt'] ?? DateTime.now().toIso8601String()) ??
          DateTime.now(),
      items: json['items'] ?? [],
    );
  }
}

/// Dashboard API Service
class DashboardApiService {
  final Dio _dio;
  final String baseUrl;

  DashboardApiService({Dio? dio, required this.baseUrl}) : _dio = dio ?? Dio();

  /// Get user statistics and KPIs
  Future<UserStats> getUserStats() async {
    try {
      print('📊 Fetching user stats from $baseUrl/api/v1/users/me');
      final response = await _dio.get('$baseUrl/api/v1/users/me');

      if (response.statusCode == 200) {
        print('✅ User stats received: ${response.data}');

        // Fetch orders separately
        final ordersResponse = await getRecentOrders();

        final stats = UserStats.fromJson(response.data);

        // Create enriched stats with orders
        return UserStats(
          totalOrders: ordersResponse.length,
          totalSpent: _calculateTotalSpent(ordersResponse),
          loyaltyPoints: stats.loyaltyPoints,
          savedAddresses: stats.savedAddresses,
          recentOrders: ordersResponse.take(5).toList(),
          userName: stats.userName,
          userEmail: stats.userEmail,
        );
      }

      throw Exception('Failed to fetch user stats: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching user stats: $e');
      rethrow;
    }
  }

  /// Get user's recent orders
  Future<List<Order>> getRecentOrders() async {
    try {
      print('📋 Fetching recent orders from $baseUrl/api/v1/orders');
      final response = await _dio.get('$baseUrl/api/v1/orders');

      if (response.statusCode == 200) {
        print('✅ Orders received: ${response.data}');

        if (response.data is List) {
          return (response.data as List)
              .map((order) => Order.fromJson(order as Map<String, dynamic>))
              .toList();
        } else if (response.data is Map && response.data['data'] is List) {
          return (response.data['data'] as List)
              .map((order) => Order.fromJson(order as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Failed to fetch orders: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// Calculate total spent from orders
  double _calculateTotalSpent(List<Order> orders) {
    return orders.fold(0, (sum, order) => sum + order.amount);
  }
}
