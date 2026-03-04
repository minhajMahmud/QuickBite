import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const RestaurantPanelState({
    required this.profile,
    required this.menuItems,
    required this.orders,
  });

  RestaurantPanelState copyWith({
    RestaurantProfileData? profile,
    List<RestaurantMenuItem>? menuItems,
    List<RestaurantPanelOrder>? orders,
  }) {
    return RestaurantPanelState(
      profile: profile ?? this.profile,
      menuItems: menuItems ?? this.menuItems,
      orders: orders ?? this.orders,
    );
  }
}

class RestaurantPanelNotifier extends StateNotifier<RestaurantPanelState> {
  RestaurantPanelNotifier()
      : super(
          RestaurantPanelState(
            profile: const RestaurantProfileData(
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
            menuItems: const [
              RestaurantMenuItem(
                id: 'm-1',
                name: 'Classic Burger',
                description:
                    'Angus beef, cheddar, lettuce, tomato, special sauce',
                category: 'Burgers',
                price: 12.99,
                imageUrl:
                    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=500&fit=crop',
                popular: true,
                isAvailable: true,
              ),
              RestaurantMenuItem(
                id: 'm-2',
                name: 'Truffle Fries',
                description: 'Hand-cut fries with truffle oil and parmesan',
                category: 'Sides',
                price: 8.99,
                imageUrl:
                    'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=800&h=500&fit=crop',
                popular: true,
                isAvailable: true,
              ),
              RestaurantMenuItem(
                id: 'm-3',
                name: 'Caesar Salad',
                description: 'Romaine, croutons, parmesan, caesar dressing',
                category: 'Salads',
                price: 10.99,
                imageUrl:
                    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&h=500&fit=crop',
                isAvailable: true,
              ),
              RestaurantMenuItem(
                id: 'm-4',
                name: 'Grilled Chicken Wrap',
                description: 'Chicken breast, avocado, mixed greens, ranch',
                category: 'Wraps',
                price: 11.49,
                imageUrl:
                    'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=800&h=500&fit=crop',
                isAvailable: true,
              ),
              RestaurantMenuItem(
                id: 'm-5',
                name: 'Fresh Lemonade',
                description: 'Fresh squeezed lemons, mint, and cane sugar',
                category: 'Drinks',
                price: 4.50,
                imageUrl:
                    'https://images.unsplash.com/photo-1523677011781-c91d1bbe2f9e?w=800&h=500&fit=crop',
                isAvailable: true,
              ),
            ],
            orders: const [
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
          ),
        );

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

  void updateOrderStatus(String orderId, String status) {
    state = state.copyWith(
      orders: state.orders
          .map((order) =>
              order.id == orderId ? order.copyWith(status: status) : order)
          .toList(),
    );
  }
}

final restaurantPanelProvider =
    StateNotifierProvider<RestaurantPanelNotifier, RestaurantPanelState>((ref) {
  return RestaurantPanelNotifier();
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
