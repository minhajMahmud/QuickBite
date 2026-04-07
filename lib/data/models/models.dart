import 'package:equatable/equatable.dart';

const String _backendOrigin = 'http://localhost:3000';

String _normalizeImageUrl(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    final host = (uri?.host ?? '').toLowerCase();
    if (host == 'api.example.com') return '';
    return raw;
  }
  if (raw.startsWith('/')) return '$_backendOrigin$raw';
  return raw;
}

String _appendImageVersion(String imageUrl, dynamic version) {
  final rawVersion = version?.toString().trim() ?? '';
  if (imageUrl.isEmpty || rawVersion.isEmpty) return imageUrl;

  final uri = Uri.tryParse(imageUrl);
  if (uri == null) {
    return '$imageUrl${imageUrl.contains('?') ? '&' : '?'}v=${Uri.encodeQueryComponent(rawVersion)}';
  }

  final nextQuery = Map<String, String>.from(uri.queryParameters);
  nextQuery['v'] = rawVersion;
  return uri.replace(queryParameters: nextQuery).toString();
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

/// Restaurant Model
class Restaurant extends Equatable {
  final String id;
  final String name;
  final String image;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final String deliveryFee;
  final bool popular;
  final String priceRange;

  const Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.popular,
    required this.priceRange,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        cuisine,
        rating,
        deliveryTime,
        deliveryFee,
        popular,
        priceRange,
      ];

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      image: _normalizeImageUrl(json['image']),
      cuisine: (json['cuisine'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      deliveryTime:
          (json['deliveryTime'] ?? json['delivery_time'] ?? '').toString(),
      deliveryFee:
          (json['deliveryFee'] ?? json['delivery_fee'] ?? 'Free').toString(),
      popular: (json['popular'] ?? json['is_popular']) == true,
      priceRange:
          (json['priceRange'] ?? json['price_range'] ?? '\$').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'cuisine': cuisine,
        'rating': rating,
        'deliveryTime': deliveryTime,
        'deliveryFee': deliveryFee,
        'popular': popular,
        'priceRange': priceRange,
      };
}

/// Food Item Model
class FoodItem extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool popular;
  final String? updatedAt;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.popular,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        description,
        price,
        image,
        category,
        popular,
        updatedAt,
      ];

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: (json['id'] ?? '').toString(),
      restaurantId:
          (json['restaurantId'] ?? json['restaurant_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _toDouble(json['price']),
      image: _appendImageVersion(
        _normalizeImageUrl(json['image']),
        json['updatedAt'] ?? json['updated_at'],
      ),
      category: (json['category'] ?? '').toString(),
      popular: (json['popular'] ?? json['is_popular']) == true,
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'category': category,
        'popular': popular,
        'updatedAt': updatedAt,
      };
}

/// Category Model
class Category extends Equatable {
  final String id;
  final String name;
  final String icon;

  const Category({required this.id, required this.name, required this.icon});

  @override
  List<Object?> get props => [id, name, icon];

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};
}

/// Cart Item Model
class CartItem extends Equatable {
  final FoodItem food;
  final int quantity;

  const CartItem({required this.food, required this.quantity});

  @override
  List<Object?> get props => [food, quantity];

  double get subtotal => food.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      food: FoodItem.fromJson(json['food'] ?? {}),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'food': food.toJson(),
        'quantity': quantity,
      };
}

/// Order Model
class Order extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String restaurant;
  final List<String> items;
  final double total;
  final String status; // pending, preparing, on_the_way, delivered, cancelled
  final String date;

  const Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurant,
    required this.items,
    required this.total,
    required this.status,
    required this.date,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        restaurant,
        items,
        total,
        status,
        date,
      ];

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      restaurant: json['restaurant'] ?? '',
      items: List<String>.from(json['items'] ?? []),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'restaurant': restaurant,
        'items': items,
        'total': total,
        'status': status,
        'date': date,
      };
}
