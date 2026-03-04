import 'package:equatable/equatable.dart';

/// User Model
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String status; // active, inactive, banned
  final int orders;
  final double spent;
  final String joinedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.status,
    required this.orders,
    required this.spent,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatar,
        status,
        orders,
        spent,
        joinedAt,
      ];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? 'active',
      orders: json['orders'] ?? 0,
      spent: (json['spent'] ?? 0).toDouble(),
      joinedAt: json['joinedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'status': status,
        'orders': orders,
        'spent': spent,
        'joinedAt': joinedAt,
      };
}

/// Delivery Agent Model
class DeliveryAgent extends Equatable {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final int deliveries;
  final String status; // online, offline, delivering

  const DeliveryAgent({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.deliveries,
    required this.status,
  });

  @override
  List<Object?> get props => [id, name, avatar, rating, deliveries, status];

  factory DeliveryAgent.fromJson(Map<String, dynamic> json) {
    return DeliveryAgent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      deliveries: json['deliveries'] ?? 0,
      status: json['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'rating': rating,
        'deliveries': deliveries,
        'status': status,
      };
}

/// Dashboard Restaurant Model
class DashboardRestaurant extends Equatable {
  final String id;
  final String name;
  final String image;
  final String cuisine;
  final double rating;
  final int orders;
  final double revenue;
  final String status; // open, closed
  final bool approved;

  const DashboardRestaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.cuisine,
    required this.rating,
    required this.orders,
    required this.revenue,
    required this.status,
    required this.approved,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        cuisine,
        rating,
        orders,
        revenue,
        status,
        approved,
      ];

  factory DashboardRestaurant.fromJson(Map<String, dynamic> json) {
    return DashboardRestaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      cuisine: json['cuisine'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      status: json['status'] ?? 'open',
      approved: json['approved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'cuisine': cuisine,
        'rating': rating,
        'orders': orders,
        'revenue': revenue,
        'status': status,
        'approved': approved,
      };
}

/// Monthly Revenue Model
class MonthlyRevenue extends Equatable {
  final String month;
  final double revenue;
  final int orders;
  final int users;

  const MonthlyRevenue({
    required this.month,
    required this.revenue,
    required this.orders,
    required this.users,
  });

  @override
  List<Object?> get props => [month, revenue, orders, users];

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      users: json['users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'revenue': revenue,
        'orders': orders,
        'users': users,
      };
}

/// KPI Data Model
class KPIData extends Equatable {
  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final int savedAddresses;

  const KPIData({
    required this.totalOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.savedAddresses,
  });

  @override
  List<Object?> get props => [
        totalOrders,
        totalSpent,
        loyaltyPoints,
        savedAddresses,
      ];

  factory KPIData.fromJson(Map<String, dynamic> json) {
    return KPIData(
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      savedAddresses: json['savedAddresses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'loyaltyPoints': loyaltyPoints,
        'savedAddresses': savedAddresses,
      };
}
