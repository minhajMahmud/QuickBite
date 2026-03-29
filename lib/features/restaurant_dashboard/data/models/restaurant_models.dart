// Models for Restaurant Dashboard

// ============================================================================
// DASHBOARD OVERVIEW
// ============================================================================
class DashboardOverview {
  final Restaurant restaurant;
  final DashboardMetrics metrics;
  final List<OperatingHours> operatingHours;

  DashboardOverview({
    required this.restaurant,
    required this.metrics,
    required this.operatingHours,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      restaurant: Restaurant.fromJson(json['restaurant'] ?? {}),
      metrics: DashboardMetrics.fromJson(json['metrics'] ?? {}),
      operatingHours: (json['operatingHours'] as List?)
              ?.map((e) => OperatingHours.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'restaurant': restaurant.toJson(),
        'metrics': metrics.toJson(),
        'operatingHours': operatingHours.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// RESTAURANT MODEL
// ============================================================================
class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String? cuisine;
  final double rating;
  final int reviewCount;
  final String? deliveryTime;
  final double deliveryFee;
  final String priceRange;
  final bool isPopular;
  final String status;
  final bool isApproved;
  final int totalOrders;
  final double totalRevenue;
  final String? ownerId;
  final String? phone;
  final String? email;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.cuisine,
    required this.rating,
    required this.reviewCount,
    this.deliveryTime,
    required this.deliveryFee,
    required this.priceRange,
    required this.isPopular,
    required this.status,
    required this.isApproved,
    required this.totalOrders,
    required this.totalRevenue,
    this.ownerId,
    this.phone,
    this.email,
    this.streetAddress,
    this.city,
    this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      cuisine: json['cuisine'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      deliveryTime: json['delivery_time'],
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      priceRange: json['price_range'] ?? '\$\$',
      isPopular: json['is_popular'] ?? false,
      status: json['status'] ?? 'closed',
      isApproved: json['is_approved'] ?? false,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      ownerId: json['owner_id'],
      phone: json['phone'],
      email: json['email'],
      streetAddress: json['street_address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image': image,
        'cuisine': cuisine,
        'rating': rating,
        'review_count': reviewCount,
        'delivery_time': deliveryTime,
        'delivery_fee': deliveryFee,
        'price_range': priceRange,
        'is_popular': isPopular,
        'status': status,
        'is_approved': isApproved,
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'owner_id': ownerId,
        'phone': phone,
        'email': email,
        'street_address': streetAddress,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ============================================================================
// DASHBOARD METRICS
// ============================================================================
class DashboardMetrics {
  final int totalOrders;
  final int pendingOrders;
  final int preparingOrders;
  final int readyOrders;
  final int onTheWayOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double grossSales;
  final double deliveredSales;
  final double averageOrderValue;

  DashboardMetrics({
    required this.totalOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.onTheWayOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.grossSales,
    required this.deliveredSales,
    required this.averageOrderValue,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      preparingOrders: json['preparing_orders'] ?? 0,
      readyOrders: json['ready_orders'] ?? 0,
      onTheWayOrders: json['on_the_way_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      grossSales: (json['gross_sales'] as num?)?.toDouble() ?? 0.0,
      deliveredSales: (json['delivered_sales'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_orders': totalOrders,
        'pending_orders': pendingOrders,
        'preparing_orders': preparingOrders,
        'ready_orders': readyOrders,
        'on_the_way_orders': onTheWayOrders,
        'delivered_orders': deliveredOrders,
        'cancelled_orders': cancelledOrders,
        'gross_sales': grossSales,
        'delivered_sales': deliveredSales,
        'average_order_value': averageOrderValue,
      };
}

// ============================================================================
// OPERATING HOURS
// ============================================================================
class OperatingHours {
  final String id;
  final String dayOfWeek;
  final String openingTime;
  final String closingTime;
  final bool isClosed;

  OperatingHours({
    required this.id,
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      id: json['id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      openingTime: json['opening_time'] ?? '',
      closingTime: json['closing_time'] ?? '',
      isClosed: json['is_closed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_of_week': dayOfWeek,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'is_closed': isClosed,
      };
}

// ============================================================================
// MENU ITEM
// ============================================================================
class MenuItem {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String categoryName;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final double rating;
  final int reviewCount;
  final bool isPopular;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final String availability;
  final int ordersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.rating,
    required this.reviewCount,
    required this.isPopular,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.availability,
    required this.ordersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      isPopular: json['is_popular'] ?? false,
      isVegetarian: json['is_vegetarian'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isGlutenFree: json['is_gluten_free'] ?? false,
      availability: json['availability'] ?? 'available',
      ordersCount: json['orders_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurant_id': restaurantId,
        'category_id': categoryId,
        'category_name': categoryName,
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'rating': rating,
        'review_count': reviewCount,
        'is_popular': isPopular,
        'is_vegetarian': isVegetarian,
        'is_vegan': isVegan,
        'is_gluten_free': isGlutenFree,
        'availability': availability,
        'orders_count': ordersCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ============================================================================
// ORDER
// ============================================================================
class Order {
  final String id;
  final String userId;
  final String customerName;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? specialInstructions;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.specialInstructions,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      orderStatus: json['order_status'] ?? '',
      specialInstructions: json['special_instructions'],
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'customer_name': customerName,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'order_status': orderStatus,
        'special_instructions': specialInstructions,
        'items': items.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
  }
}

// ============================================================================
// ORDER ITEM
// ============================================================================
class OrderItem {
  final String id;
  final String foodItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double itemTotal;
  final String? specialInstructions;

  OrderItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      foodItemId: json['foodItemId'] ?? json['food_item_id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? json['unit_price'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (json['itemTotal'] ?? json['item_total'] as num?)?.toDouble() ?? 0.0,
      specialInstructions: json['specialInstructions'] ?? json['special_instructions'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodItemId': foodItemId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'itemTotal': itemTotal,
        'specialInstructions': specialInstructions,
      };
}

// ============================================================================
// ANALYTICS
// ============================================================================
class Analytics {
  final int rangeDays;
  final List<DailySales> dailySales;
  final List<TopSellingItem> topItems;

  Analytics({
    required this.rangeDays,
    required this.dailySales,
    required this.topItems,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      rangeDays: json['rangeDays'] ?? 30,
      dailySales: (json['dailySales'] as List?)
              ?.map((e) => DailySales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topItems: (json['topItems'] as List?)
              ?.map((e) => TopSellingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'rangeDays': rangeDays,
        'dailySales': dailySales.map((e) => e.toJson()).toList(),
        'topItems': topItems.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// DAILY SALES
// ============================================================================
class DailySales {
  final String day;
  final int orders;
  final double revenue;

  DailySales({
    required this.day,
    required this.orders,
    required this.revenue,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      day: json['day'] ?? '',
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'orders': orders,
        'revenue': revenue,
      };
}

// ============================================================================
// TOP SELLING ITEM
// ============================================================================
class TopSellingItem {
  final String id;
  final String name;
  final int totalQuantity;
  final double totalSales;

  TopSellingItem({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.totalSales,
  });

  factory TopSellingItem.fromJson(Map<String, dynamic> json) {
    return TopSellingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      totalQuantity: json['total_quantity'] ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'total_quantity': totalQuantity,
        'total_sales': totalSales,
      };
}
