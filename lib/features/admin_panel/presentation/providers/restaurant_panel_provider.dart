import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/services/api_client.dart';

class RestaurantProfileData {
  final String name;
  final String cuisine;
  final String phone;
  final String email;
  final String address;
  final String hours;
  final String description;
  final String imageUrl;

  const RestaurantProfileData({
    required this.name,
    required this.cuisine,
    required this.phone,
    required this.email,
    required this.address,
    required this.hours,
    required this.description,
    required this.imageUrl,
  });

  RestaurantProfileData copyWith({
    String? name,
    String? cuisine,
    String? phone,
    String? email,
    String? address,
    String? hours,
    String? description,
    String? imageUrl,
  }) {
    return RestaurantProfileData(
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class RestaurantMenuItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final bool popular;
  final bool isAvailable;

  const RestaurantMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.popular = false,
    this.isAvailable = true,
  });

  RestaurantMenuItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    bool? popular,
    bool? isAvailable,
  }) {
    return RestaurantMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      popular: popular ?? this.popular,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class RestaurantMenuCategory {
  final String id;
  final String name;

  const RestaurantMenuCategory({
    required this.id,
    required this.name,
  });
}

class RestaurantPanelOrder {
  final String id;
  final String customerName;
  final List<String> items;
  final String address;
  final String timeAgo;
  final double total;
  final String status; // new, accepted, preparing, ready, picked_up, rejected

  const RestaurantPanelOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.address,
    required this.timeAgo,
    required this.total,
    required this.status,
  });

  RestaurantPanelOrder copyWith({
    String? id,
    String? customerName,
    List<String>? items,
    String? address,
    String? timeAgo,
    double? total,
    String? status,
  }) {
    return RestaurantPanelOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      address: address ?? this.address,
      timeAgo: timeAgo ?? this.timeAgo,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }
}

class RestaurantPanelState {
  final RestaurantProfileData profile;
  final List<RestaurantMenuCategory> categories;
  final List<RestaurantMenuItem> menuItems;
  final List<RestaurantPanelOrder> orders;
  final String? restaurantId;

  const RestaurantPanelState({
    required this.profile,
    required this.categories,
    required this.menuItems,
    required this.orders,
    this.restaurantId,
  });

  RestaurantPanelState copyWith({
    RestaurantProfileData? profile,
    List<RestaurantMenuCategory>? categories,
    List<RestaurantMenuItem>? menuItems,
    List<RestaurantPanelOrder>? orders,
    String? restaurantId,
    bool clearRestaurantId = false,
  }) {
    return RestaurantPanelState(
      profile: profile ?? this.profile,
      categories: categories ?? this.categories,
      menuItems: menuItems ?? this.menuItems,
      orders: orders ?? this.orders,
      restaurantId:
          clearRestaurantId ? null : (restaurantId ?? this.restaurantId),
    );
  }
}

class RestaurantPanelNotifier extends StateNotifier<RestaurantPanelState> {
  static const String _backendOrigin = 'http://localhost:3000';
  final ApiClient _apiClient;
  final String? _authToken;
  final String? _preferredRestaurantId;
  final String? _preferredRestaurantName;
  String? _lastBackendError;

  String? get lastBackendError => _lastBackendError;

  RestaurantPanelNotifier({
    required ApiClient apiClient,
    String? authToken,
    String? preferredRestaurantId,
    String? preferredRestaurantName,
  })  : _apiClient = apiClient,
        _authToken = authToken,
        _preferredRestaurantId = preferredRestaurantId,
        _preferredRestaurantName = preferredRestaurantName,
        super(
          const RestaurantPanelState(
            profile: RestaurantProfileData(
              name: 'The Golden Grill',
              cuisine: 'American Cuisine',
              phone: '+1 (555) 100-2000',
              email: 'contact@goldengrill.com',
              address: '100 Food St, New York, NY 10001',
              hours: '10:00 AM - 11:00 PM',
              description:
                  'Premium burgers and sides made with locally sourced ingredients.',
              imageUrl:
                  'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=400&fit=crop',
            ),
            categories: [
              RestaurantMenuCategory(id: 'cat-2', name: 'Burgers'),
              RestaurantMenuCategory(id: 'cat-6', name: 'Beverages'),
            ],
            menuItems: [],
            orders: [
              RestaurantPanelOrder(
                id: 'ro-001',
                customerName: 'Emma Wilson',
                items: ['Classic Burger x2', 'Truffle Fries x1'],
                address: '123 Main St, Apt 4B',
                timeAgo: '2 min ago',
                total: 34.97,
                status: 'new',
              ),
              RestaurantPanelOrder(
                id: 'ro-002',
                customerName: 'Liam Chen',
                items: ['Caesar Salad x1'],
                address: '456 Oak Ave',
                timeAgo: '5 min ago',
                total: 10.99,
                status: 'new',
              ),
              RestaurantPanelOrder(
                id: 'ro-003',
                customerName: 'Sophia Patel',
                items: ['Double Smash Burger x1', 'Chocolate Milkshake x2'],
                address: '789 Elm Dr',
                timeAgo: '12 min ago',
                total: 29.97,
                status: 'accepted',
              ),
              RestaurantPanelOrder(
                id: 'ro-004',
                customerName: 'Noah Kim',
                items: ['BBQ Chicken Wings x1', 'Onion Rings x1'],
                address: '15 Cedar Lane',
                timeAgo: '20 min ago',
                total: 21.48,
                status: 'preparing',
              ),
              RestaurantPanelOrder(
                id: 'ro-005',
                customerName: 'Olivia Martinez',
                items: ['Grilled Chicken Wrap x3'],
                address: '22 Sunset Blvd',
                timeAgo: '25 min ago',
                total: 34.47,
                status: 'ready',
              ),
            ],
            restaurantId: null,
          ),
        );

  bool get isBackendAvailable =>
      (_authToken != null && _authToken!.trim().isNotEmpty);

  List<RestaurantMenuCategory> _sortCategories(
      List<RestaurantMenuCategory> items) {
    final sorted = [...items];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  RestaurantMenuItem _mapMenuItem(Map<String, dynamic> row) {
    final rawImage = row['image']?.toString() ?? '';
    final image =
        rawImage.startsWith('/') ? '$_backendOrigin$rawImage' : rawImage;

    return RestaurantMenuItem(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? 'Unnamed Item',
      description: row['description']?.toString() ?? '',
      category: row['category_name']?.toString() ?? 'Uncategorized',
      price: _toDouble(row['price']),
      imageUrl: image,
      popular: row['is_popular'] == true,
      isAvailable:
          (row['availability']?.toString() ?? 'available') == 'available',
    );
  }

  String _toPanelOrderStatus(String backendStatus) {
    switch (backendStatus) {
      case 'pending':
        return 'new';
      case 'confirmed':
        return 'accepted';
      case 'preparing':
        return 'preparing';
      case 'ready':
        return 'ready';
      case 'on_the_way':
      case 'delivered':
        return 'picked_up';
      case 'cancelled':
        return 'rejected';
      default:
        return 'new';
    }
  }

  String _toBackendOrderStatus(String panelStatus) {
    switch (panelStatus) {
      case 'new':
        return 'pending';
      case 'accepted':
        return 'confirmed';
      case 'preparing':
        return 'preparing';
      case 'ready':
        return 'ready';
      case 'picked_up':
        return 'delivered';
      case 'rejected':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  RestaurantPanelOrder _mapOrder(Map<String, dynamic> row) {
    final itemsRaw = row['items'];
    final items = <String>[];

    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          final name = item['name']?.toString() ?? 'Item';
          final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          items.add('$name x$qty');
        }
      }
    }

    final dateRaw = row['created_at']?.toString();
    DateTime? createdAt;
    if (dateRaw != null) {
      createdAt = DateTime.tryParse(dateRaw)?.toLocal();
    }

    String timeAgo = 'Just now';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (diff.inHours < 1) {
        timeAgo = '${diff.inMinutes} min ago';
      } else if (diff.inDays < 1) {
        timeAgo = '${diff.inHours} hr ago';
      } else {
        timeAgo = '${diff.inDays} day(s) ago';
      }
    }

    return RestaurantPanelOrder(
      id: row['id']?.toString() ?? '',
      customerName: row['customer_name']?.toString() ?? 'Customer',
      items: items,
      address: 'Address not provided',
      timeAgo: timeAgo,
      total: _toDouble(row['total_amount']),
      status: _toPanelOrderStatus(row['order_status']?.toString() ?? 'pending'),
    );
  }

  RestaurantProfileData _mapProfile(
      Map<String, dynamic> restaurant, List<dynamic> operatingHours) {
    final addressParts = [
      restaurant['street_address']?.toString(),
      restaurant['city']?.toString(),
      restaurant['state']?.toString(),
      restaurant['postal_code']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    String hours = 'Set operating hours';
    if (operatingHours.isNotEmpty) {
      final openDays = operatingHours
          .whereType<Map>()
          .where((h) => h['is_closed'] != true)
          .toList();
      if (openDays.isNotEmpty) {
        final first = openDays.first;
        final opening = first['opening_time']?.toString() ?? '';
        final closing = first['closing_time']?.toString() ?? '';
        hours = '$opening - $closing';
      }
    }

    final rawImage = restaurant['image']?.toString() ?? '';
    final image =
        rawImage.startsWith('/') ? '$_backendOrigin$rawImage' : rawImage;

    return RestaurantProfileData(
      name: restaurant['name']?.toString() ?? state.profile.name,
      cuisine: restaurant['cuisine']?.toString() ?? state.profile.cuisine,
      phone: restaurant['phone']?.toString() ?? state.profile.phone,
      email: restaurant['email']?.toString() ?? state.profile.email,
      address: addressParts.isEmpty ? state.profile.address : addressParts,
      hours: hours,
      description:
          restaurant['description']?.toString() ?? state.profile.description,
      imageUrl: image.isEmpty ? state.profile.imageUrl : image,
    );
  }

  Future<void> hydrateFromBackend() async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      return;
    }

    try {
      final overviewRaw = await _apiClient.getRestaurantDashboardOverview(
        token: _authToken!,
      );
      final categoriesRaw = await _apiClient.getCatalogCategories();
      final menuRaw = await _apiClient.getRestaurantDashboardMenu(
        token: _authToken!,
      );
      final ordersRaw = await _apiClient.getRestaurantDashboardOrders(
        token: _authToken!,
      );

      final categories = categoriesRaw
          .map((row) => RestaurantMenuCategory(
                id: row['id']?.toString() ?? '',
                name: row['name']?.toString() ?? 'Category',
              ))
          .where((item) => item.id.isNotEmpty)
          .toList();

      final menuItems = menuRaw.map(_mapMenuItem).toList();
      final orders = ordersRaw.map(_mapOrder).toList();

      final restaurantRaw = overviewRaw['restaurant'] is Map<String, dynamic>
          ? overviewRaw['restaurant'] as Map<String, dynamic>
          : <String, dynamic>{};
      final operatingHoursRaw = overviewRaw['operatingHours'] is List
          ? overviewRaw['operatingHours'] as List
          : const [];

      state = state.copyWith(
        restaurantId: _preferredRestaurantId ?? state.restaurantId,
        categories:
            categories.isEmpty ? state.categories : _sortCategories(categories),
        menuItems: menuItems,
        orders: orders,
        profile: _mapProfile(restaurantRaw, operatingHoursRaw),
      );
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        restaurantId: _preferredRestaurantId ?? state.restaurantId,
        profile: state.profile.copyWith(
          name: _preferredRestaurantName?.isNotEmpty == true
              ? _preferredRestaurantName!
              : state.profile.name,
        ),
      );
    }
  }

  void updateProfile(RestaurantProfileData profile) {
    state = state.copyWith(profile: profile);
  }

  void addMenuItem(RestaurantMenuItem item) {
    state = state.copyWith(menuItems: [...state.menuItems, item]);
  }

  void updateMenuItem(RestaurantMenuItem item) {
    state = state.copyWith(
      menuItems: state.menuItems
          .map((menuItem) => menuItem.id == item.id ? item : menuItem)
          .toList(),
    );
  }

  void deleteMenuItem(String itemId) {
    state = state.copyWith(
      menuItems: state.menuItems.where((item) => item.id != itemId).toList(),
    );
  }

  void toggleMenuAvailability(String itemId) {
    state = state.copyWith(
      menuItems: state.menuItems
          .map(
            (item) => item.id == itemId
                ? item.copyWith(isAvailable: !item.isAvailable)
                : item,
          )
          .toList(),
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return;
    }

    try {
      final response = await _apiClient.updateRestaurantDashboardOrderStatus(
        token: _authToken!,
        orderId: orderId,
        status: _toBackendOrderStatus(status),
      );

      final orderRaw = response['order'];
      if (orderRaw is Map<String, dynamic>) {
        final mapped = _mapOrder(orderRaw);
        state = state.copyWith(
          orders: state.orders
              .map((order) => order.id == mapped.id ? mapped : order)
              .toList(),
        );
      } else {
        state = state.copyWith(
          orders: state.orders
              .map((order) =>
                  order.id == orderId ? order.copyWith(status: status) : order)
              .toList(),
        );
      }
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<bool> updateProfileInBackend(
    RestaurantProfileData profile, {
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return false;
    }

    try {
      final payload = {
        'name': profile.name,
        'cuisine': profile.cuisine,
        'phone': profile.phone,
        'email': profile.email,
        'address': profile.address,
        'description': profile.description,
        'image': profile.imageUrl,
      };

      final response = await _apiClient.updateRestaurantDashboardProfile(
        token: _authToken!,
        payload: payload,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );

      final restaurantRaw = response['restaurant'];
      if (restaurantRaw is Map<String, dynamic>) {
        final mapped = _mapProfile(restaurantRaw, const []);
        state = state.copyWith(profile: mapped.copyWith(hours: profile.hours));
      } else {
        state = state.copyWith(profile: profile);
      }

      return true;
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> createMenuItemInBackend({
    required String name,
    required String description,
    required String categoryId,
    required String category,
    required double price,
    required String imageUrl,
    Uint8List? imageBytes,
    String? imageMimeType,
    required bool popular,
    required bool available,
  }) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return false;
    }

    try {
      final response = await _apiClient.createRestaurantDashboardMenuItem(
        token: _authToken!,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        isPopular: popular,
        availability: available ? 'available' : 'unavailable',
      );

      final itemRaw = response['item'];
      if (itemRaw is Map<String, dynamic>) {
        addMenuItem(_mapMenuItem(itemRaw));
      } else {
        await hydrateFromBackend();
      }

      return true;
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> updateMenuItemInBackend({
    required String foodItemId,
    required String name,
    required String description,
    required String categoryId,
    required double price,
    required String imageUrl,
    Uint8List? imageBytes,
    String? imageMimeType,
    required bool popular,
    required bool available,
  }) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return false;
    }

    try {
      final response = await _apiClient.updateRestaurantDashboardMenuItem(
        token: _authToken!,
        foodItemId: foodItemId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        isPopular: popular,
        availability: available ? 'available' : 'unavailable',
      );

      final itemRaw = response['item'];
      if (itemRaw is Map<String, dynamic>) {
        updateMenuItem(_mapMenuItem(itemRaw));
      } else {
        await hydrateFromBackend();
      }

      return true;
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> deleteMenuItemInBackend({
    required String foodItemId,
  }) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return false;
    }

    try {
      await _apiClient.deleteRestaurantDashboardMenuItem(
        token: _authToken!,
        foodItemId: foodItemId,
      );

      deleteMenuItem(foodItemId);
      return true;
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> toggleMenuAvailabilityInBackend({
    required String foodItemId,
  }) async {
    _lastBackendError = null;

    if (!isBackendAvailable) {
      _lastBackendError = 'Authentication token missing. Please login again.';
      return false;
    }

    final currentItem = state.menuItems.firstWhere(
      (item) => item.id == foodItemId,
      orElse: () => const RestaurantMenuItem(
        id: '',
        name: '',
        description: '',
        category: '',
        price: 0,
        imageUrl: '',
      ),
    );

    if (currentItem.id.isEmpty) {
      _lastBackendError = 'Menu item not found in state.';
      return false;
    }

    final nextAvailability =
        currentItem.isAvailable ? 'unavailable' : 'available';

    try {
      final response = await _apiClient.updateRestaurantDashboardMenuItem(
        token: _authToken!,
        foodItemId: foodItemId,
        availability: nextAvailability,
      );

      final itemRaw = response['item'];
      if (itemRaw is Map<String, dynamic>) {
        updateMenuItem(_mapMenuItem(itemRaw));
      } else {
        toggleMenuAvailability(foodItemId);
      }

      return true;
    } catch (e) {
      _lastBackendError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}

final restaurantPanelProvider =
    StateNotifierProvider<RestaurantPanelNotifier, RestaurantPanelState>((ref) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  final authToken = ref.watch(authProvider.select((state) => state.token));
  return RestaurantPanelNotifier(
    apiClient: ApiClient(),
    authToken: authToken,
    preferredRestaurantId: authUser?.id,
    preferredRestaurantName: authUser?.name,
  );
});

final restaurantPanelCategoriesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(restaurantPanelProvider);

  final fromBackend = state.categories.map((item) => item.name).toSet();
  final fromItems = state.menuItems.map((item) => item.category).toSet();

  final categories = {...fromBackend, ...fromItems}
      .where((name) => name.trim().isNotEmpty)
      .toList()
    ..sort();

  return ['All', ...categories];
});

final restaurantPanelRevenueProvider = Provider<double>((ref) {
  final orders =
      ref.watch(restaurantPanelProvider.select((state) => state.orders));
  return orders
      .where((order) => order.status != 'rejected')
      .fold<double>(0, (sum, order) => sum + order.total);
});

final restaurantPanelSyncProvider = FutureProvider<void>((ref) async {
  ref.watch(authProvider.select((state) => state.user?.id));
  ref.watch(authProvider.select((state) => state.token));
  await ref.read(restaurantPanelProvider.notifier).hydrateFromBackend();
});
