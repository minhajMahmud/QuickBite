import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../data/models/models.dart';
import '../../../../presentation/widgets/food_item_card.dart';
import '../../../../presentation/widgets/adaptive_app_image.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// Restaurant Detail Screen - View restaurant menu and items
class RestaurantDetailScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailScreen({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Safety check: prevent routing to admin if route params are invalid
    if (restaurantId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Invalid restaurant ID provided'),
            ],
          ),
        ),
      );
    }

    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final menuItemsAsync = ref.watch(restaurantMenuProvider(restaurantId));
    final restaurant = restaurantAsync.asData?.value;
    final menuItems = menuItemsAsync.asData?.value ?? <FoodItem>[];
    final isGuest = !ref.watch(authProvider).isAuthenticated;

    if (restaurantAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant')),
        body: const Center(child: Text('Restaurant not found')),
        bottomNavigationBar: CurvedPanelBottomNav(
          items: [
            CurvedNavItemData(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: false,
              onTap: () => context.go('/'),
            ),
            CurvedNavItemData(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: 'Browse',
              isSelected: false,
              onTap: () => context.go('/browse'),
            ),
            CurvedNavItemData(
              icon: Icons.shopping_cart_outlined,
              selectedIcon: Icons.shopping_cart,
              label: 'Cart',
              isSelected: false,
              onTap: () => context.go('/cart'),
            ),
            CurvedNavItemData(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Account',
              isSelected: false,
              onTap: () =>
                  isGuest ? context.push('/login') : context.go('/dashboard'),
            ),
          ],
        ),
      );
    }

    final categories = menuItems.map((item) => item.category).toSet().toList();
    final averagePrice = menuItems.isEmpty
        ? 0.0
        : menuItems.fold<double>(0, (sum, item) => sum + item.price) /
            menuItems.length;
    final reviewCount = 120 + menuItems.length * 7;
    final highlights = menuItems.take(3).map((e) => e.name).toList();
    final fullDescription =
        '${restaurant.name} serves premium ${restaurant.cuisine} dishes with fresh ingredients and fast delivery. '
        'Expected delivery time is ${restaurant.deliveryTime}. '
        '${highlights.isNotEmpty ? 'Popular items: ${highlights.join(', ')}.' : ''}';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        bottom: true,
        child: CustomScrollView(
          slivers: [
            /// Restaurant Hero Image
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.width * 0.58,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    AdaptiveAppImage(
                      source: restaurant.image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      error: Container(color: AppColors.secondaryLight),
                    ),
                    Container(color: Colors.black.withOpacity(0.3)),
                  ],
                ),
              ),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),

            /// Restaurant Info Card
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightBackground,
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fullDescription,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.star_rounded,
                              label:
                                  '${restaurant.rating} ($reviewCount reviews)',
                              iconColor: AppColors.warning,
                            ),
                            _InfoChip(
                              icon: Icons.access_time,
                              label: restaurant.deliveryTime,
                            ),
                            _InfoChip(
                              icon: Icons.attach_money,
                              label: averagePrice == 0
                                  ? 'No pricing yet'
                                  : 'Avg \$${averagePrice.toStringAsFixed(2)}',
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                restaurant.deliveryFee == 'Free'
                                    ? 'Free Delivery'
                                    : 'Delivery: ${restaurant.deliveryFee}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: menuItems.isEmpty
                                    ? null
                                    : () {
                                        final first = menuItems.first;
                                        ref
                                            .read(cartProvider.notifier)
                                            .addItem(first);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${first.name} added to cart'),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Add to Cart'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Restaurant contact will be available soon.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.support_agent_outlined),
                                label: const Text('Contact'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Menu Items by Category
            ...categories.map((category) {
              final categoryItems =
                  menuItems.where((item) => item.category == category).toList();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ...categoryItems.map(
                        (food) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: FoodItemCard(
                            foodItem: food,
                            onAddToCart: () {
                              ref.read(cartProvider.notifier).addItem(food);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${food.name} added to cart'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cart'),
        heroTag: 'restaurant-detail-cart-fab',
        child: const Icon(Icons.shopping_cart),
      ),
      bottomNavigationBar: CurvedPanelBottomNav(
        items: [
          CurvedNavItemData(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () => context.go('/'),
          ),
          CurvedNavItemData(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Browse',
            isSelected: false,
            onTap: () => context.go('/browse'),
          ),
          CurvedNavItemData(
            icon: Icons.shopping_cart_outlined,
            selectedIcon: Icons.shopping_cart,
            label: 'Cart',
            isSelected: false,
            onTap: () => context.go('/cart'),
          ),
          CurvedNavItemData(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Account',
            isSelected: false,
            onTap: () =>
                isGuest ? context.push('/login') : context.go('/dashboard'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightForeground,
                ),
          ),
        ],
      ),
    );
  }
}
