import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/restaurant_card.dart';
import '../../../../presentation/widgets/category_chip.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// Browse Screen - Browse all restaurants with filters
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final filteredRestaurants = ref.watch(filteredRestaurantsProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final filters = ref.watch(browseFiltersProvider);
    final authState = ref.watch(authProvider);
    final isGuest = !authState.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Browse Restaurants'),
        elevation: 0,
        backgroundColor: AppColors.lightBackground,
        actions: [
          // Cart button
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          // User/Admin Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'user') {
                context.push('/dashboard');
              } else if (value == 'admin') {
                context.push('/admin');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'user',
                child: Row(
                  children: [
                    Icon(Icons.dashboard, size: 20),
                    SizedBox(width: 12),
                    Text('User Dashboard'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 12),
                    Text('Admin Panel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          /// Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).setQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search restaurants, cuisines...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          /// Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).clear(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedCategory == null
                              ? AppColors.primaryOrange
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: const Text(
                          'All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(
                      categories.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChip(
                          category: categories[index],
                          isSelected:
                              selectedCategory == categories[index].name,
                          onTap: () {
                            ref
                                .read(categoryFilterProvider.notifier)
                                .setCategory(categories[index].name);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Advanced Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('⭐ 4.5+'),
                      selected: filters.minRating == 4.5,
                      onSelected: (_) => ref
                          .read(browseFiltersProvider.notifier)
                          .setMinRating(filters.minRating == 4.5 ? null : 4.5),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('\$ Budget'),
                      selected: filters.priceRange == '\$',
                      onSelected: (_) => ref
                          .read(browseFiltersProvider.notifier)
                          .setPriceRange(
                              filters.priceRange == '\$' ? null : '\$'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('\$\$ Mid'),
                      selected: filters.priceRange == '\$\$',
                      onSelected: (_) => ref
                          .read(browseFiltersProvider.notifier)
                          .setPriceRange(
                              filters.priceRange == '\$\$' ? null : '\$\$'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('🚚 <=30 min'),
                      selected: filters.maxEtaMinutes == 30,
                      onSelected: (_) => ref
                          .read(browseFiltersProvider.notifier)
                          .setMaxEtaMinutes(
                            filters.maxEtaMinutes == 30 ? null : 30,
                          ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('🥗 Dietary'),
                      selected: filters.dietaryOnly,
                      onSelected: (value) => ref
                          .read(browseFiltersProvider.notifier)
                          .setDietaryOnly(value),
                    ),
                    if (filters.minRating != null ||
                        filters.priceRange != null ||
                        filters.maxEtaMinutes != null ||
                        filters.dietaryOnly) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Clear'),
                        onPressed: () =>
                            ref.read(browseFiltersProvider.notifier).clearAll(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          /// Restaurants List
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            sliver: filteredRestaurants.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.muted.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text('No restaurants found'),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: RestaurantCard(
                          restaurant: filteredRestaurants[index],
                          onTap: () => context.push(
                            '/restaurant/${filteredRestaurants[index].id}',
                          ),
                        ),
                      );
                    }, childCount: filteredRestaurants.length),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
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
            isSelected: true,
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
