import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';

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
  final List<RestaurantMenuItem> menuItems;
  final List<RestaurantPanelOrder> orders;
  final String? restaurantId;

  const RestaurantPanelState({
    required this.profile,
    required this.menuItems,
    required this.orders,
    this.restaurantId,
  });

  RestaurantPanelState copyWith({
    RestaurantProfileData? profile,
    List<RestaurantMenuItem>? menuItems,
    List<RestaurantPanelOrder>? orders,
    String? restaurantId,
    bool clearRestaurantId = false,
  }) {
    return RestaurantPanelState(
      profile: profile ?? this.profile,
      menuItems: menuItems ?? this.menuItems,
      orders: orders ?? this.orders,
      restaurantId:
          clearRestaurantId ? null : (restaurantId ?? this.restaurantId),
    );
  }
}

class RestaurantPanelNotifier extends StateNotifier<RestaurantPanelState> {
  final String? _preferredRestaurantId;
  final String? _preferredRestaurantName;

  RestaurantPanelNotifier({
    String? preferredRestaurantId,
    String? preferredRestaurantName,
  })  : _preferredRestaurantId = preferredRestaurantId,
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

  bool get isBackendAvailable => false;

  Future<void> hydrateFromBackend() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }

    // Remote backend removed: retain existing local/mock dashboard state.
    state = state.copyWith(
      restaurantId: _preferredRestaurantId ?? state.restaurantId,
      profile: state.profile.copyWith(
        name: _preferredRestaurantName?.isNotEmpty == true
            ? _preferredRestaurantName!
            : state.profile.name,
      ),
    );
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
    state = state.copyWith(
      orders: state.orders
          .map((order) =>
              order.id == orderId ? order.copyWith(status: status) : order)
          .toList(),
    );
  }

  String _categoryNameToId(String categoryName) {
    switch (categoryName.trim().toLowerCase()) {
      case 'pizza':
        return 'cat-1';
      case 'burgers':
        return 'cat-2';
      case 'pasta':
        return 'cat-3';
      case 'salads':
        return 'cat-4';
      case 'desserts':
        return 'cat-5';
      case 'drinks':
      case 'beverages':
        return 'cat-6';
      case 'sides':
      case 'wraps':
      case 'starters':
      default:
        return 'cat-2';
    }
  }

  Future<bool> createMenuItemInBackend({
    required String name,
    required String description,
    required String category,
    required double price,
    required String imageUrl,
    required bool popular,
    required bool available,
  }) async {
    final itemId = 'food-${DateTime.now().millisecondsSinceEpoch}';
    final _ = _categoryNameToId(category);

    addMenuItem(
      RestaurantMenuItem(
        id: itemId,
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrl: imageUrl,
        popular: popular,
        isAvailable: available,
      ),
    );

    return true;
  }
}

final restaurantPanelProvider =
    StateNotifierProvider<RestaurantPanelNotifier, RestaurantPanelState>((ref) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  return RestaurantPanelNotifier(
    preferredRestaurantId: authUser?.id,
    preferredRestaurantName: authUser?.name,
  );
});

final restaurantPanelCategoriesProvider = Provider<List<String>>((ref) {
  final items =
      ref.watch(restaurantPanelProvider.select((state) => state.menuItems));
  final categories = items.map((item) => item.category).toSet().toList()
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
  await ref.read(restaurantPanelProvider.notifier).hydrateFromBackend();
});
