import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../data/models/models.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/offers_section.dart';

const _feedShortcuts = [
  _FeedShortcut(
    type: _ShortcutType.offers,
    icon: Icons.local_offer_outlined,
    label: 'Offers',
    title: 'Offers & Discounts',
    description:
        'Find the best deals, free-delivery partners, and top-rated restaurants with active promotions.',
  ),
  _FeedShortcut(
    type: _ShortcutType.mart,
    icon: Icons.shopping_basket_outlined,
    label: 'Mart',
    title: 'Mart Essentials',
    description:
        'Shop groceries and everyday essentials quickly from nearby stores and restaurant marts.',
  ),
  _FeedShortcut(
    type: _ShortcutType.newArrivals,
    icon: Icons.new_releases_outlined,
    label: 'New',
    title: 'New on QuickBite',
    description:
        'Discover newly added places and recently featured restaurants before everyone else.',
  ),
  _FeedShortcut(
    type: _ShortcutType.pickup,
    icon: Icons.storefront_outlined,
    label: 'Pick-up',
    title: 'Pick-up Friendly Spots',
    description:
        'Skip delivery wait and collect your order directly from partner restaurants near you.',
  ),
];

enum _ShortcutType { offers, mart, newArrivals, pickup }

/// Home Screen - Customer feed style landing page
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final featuredRestaurantsAsync = ref.watch(featuredRestaurantsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final restaurants = restaurantsAsync.asData?.value ?? <Restaurant>[];
    final featuredRestaurants =
        featuredRestaurantsAsync.asData?.value ?? <Restaurant>[];
    final categories = categoriesAsync.asData?.value ?? <Category>[];

    final isLoadingInitial =
        (restaurantsAsync.isLoading || categoriesAsync.isLoading) &&
            restaurants.isEmpty &&
            categories.isEmpty;
    final authState = ref.watch(authProvider);
    final isGuest = !authState.isAuthenticated;
    final popular =
        featuredRestaurants.isNotEmpty ? featuredRestaurants : restaurants;
    final discounted = restaurants.reversed.toList();

    if (isLoadingInitial) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 8, horizontalPadding, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryAmber],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '3804',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Dhaka',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border,
                              color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => context.push('/cart'),
                          icon: const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white),
                        ),
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'login') {
                              context.push('/login');
                            } else if (value == 'logout') {
                              ref.read(authProvider.notifier).logout();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out successfully'),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) {
                            if (isGuest) {
                              return const [
                                PopupMenuItem<String>(
                                  value: 'login',
                                  child: Text('Sign In'),
                                ),
                              ];
                            }
                            return [
                              PopupMenuItem<String>(
                                value: 'profile',
                                enabled: false,
                                child: Text(authState.user?.name ?? 'Account'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Text('Logout'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => context.push('/browse'),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.muted),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search for restaurants and groceries',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 360;
                        final titleSize = isNarrow ? 22.0 : 28.0;
                        final imageWidth = isNarrow
                            ? (constraints.maxWidth * 0.55)
                                .clamp(120.0, 180.0)
                                .toDouble()
                            : 130.0;
                        final imageHeight = isNarrow ? 100.0 : 110.0;

                        return Container(
                          padding: EdgeInsets.fromLTRB(
                            isNarrow ? 12 : 16,
                            16,
                            isNarrow ? 12 : 8,
                            16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Here's 50% off & free\ndelivery on your first\norder!",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Start ordering ➜',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=280&fit=crop',
                                          width: imageWidth,
                                          height: imageHeight,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Here's 50% off & free\ndelivery on your first\norder!",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: titleSize,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Start ordering ➜',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=280&fit=crop',
                                        width: imageWidth,
                                        height: imageHeight,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 16, horizontalPadding, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: _feedShortcuts
                          .map(
                            (shortcut) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: _ShortcutAction(
                                  item: shortcut,
                                  onTap: () => _showShortcutDetails(
                                    context,
                                    shortcut,
                                    restaurants,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return InkWell(
                            onTap: () => context.push('/browse'),
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 70,
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.icon,
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Active Offers',
                      onTap: () => context.push('/browse'),
                    ),
                    const SizedBox(height: 10),
                    const OffersSection(),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Special Deals',
                      onTap: () => context.push('/browse'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 186,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => _PromoDealCard(
                          title: index == 0
                              ? 'Flat 50% off\n1st order'
                              : index == 1
                                  ? 'Ramadan picks\nTk.150 off'
                                  : 'Tasty combo\nSpecial deal',
                          code: index == 0
                              ? 'YUMPANDA'
                              : index == 1
                                  ? 'DEALNAO'
                                  : 'BITE50',
                          imageUrl:
                              'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=420&h=280&fit=crop',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Popular Restaurants',
                      onTap: () => context.push('/browse'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: popular.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final restaurant = popular[index];
                          return _RestaurantFeedCard(
                            restaurant: restaurant,
                            onTap: () =>
                                context.push('/restaurant/${restaurant.id}'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Flat 15% off entire menu',
                      onTap: () => context.push('/browse'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: discounted.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final restaurant = discounted[index];
                          return _RestaurantFeedCard(
                            restaurant: restaurant,
                            onTap: () =>
                                context.push('/restaurant/${restaurant.id}'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isGuest)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login),
                          label: const Text('Sign In to Order Faster'),
                        ),
                      ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: CurvedPanelBottomNav(
        items: [
          CurvedNavItemData(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: true,
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

  void _showShortcutDetails(
    BuildContext context,
    _FeedShortcut shortcut,
    List<Restaurant> restaurants,
  ) {
    final matchedRestaurants = _matchedRestaurantsForShortcut(
      shortcut.type,
      restaurants,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          shortcut.icon,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shortcut.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${matchedRestaurants.length} places found',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shortcut.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (matchedRestaurants.isNotEmpty)
                    ...matchedRestaurants
                        .take(4)
                        .map(
                          (restaurant) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFFEEEEF1),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF8F8FA),
                                child: Icon(
                                  _iconForShortcutType(shortcut.type),
                                  color: AppColors.primaryOrange,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                restaurant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${restaurant.cuisine} • ${restaurant.deliveryTime}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '★ ${restaurant.rating}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push('/restaurant/${restaurant.id}');
                              },
                            ),
                          ),
                        )
                        .toList(),
                  if (matchedRestaurants.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No matching restaurants yet. Try browsing all places.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/browse');
                          },
                          child: const Text('Browse more'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Restaurant> _matchedRestaurantsForShortcut(
    _ShortcutType type,
    List<Restaurant> restaurants,
  ) {
    switch (type) {
      case _ShortcutType.offers:
        return restaurants
            .where(
              (r) => r.popular || r.deliveryFee.toLowerCase().contains('free'),
            )
            .toList();
      case _ShortcutType.mart:
        final mart = restaurants
            .where(
              (r) =>
                  r.cuisine.toLowerCase().contains('grocery') ||
                  r.cuisine.toLowerCase().contains('mart'),
            )
            .toList();
        return mart.isEmpty ? restaurants.take(6).toList() : mart;
      case _ShortcutType.newArrivals:
        return restaurants.reversed.take(8).toList();
      case _ShortcutType.pickup:
        final pickup = restaurants
            .where((r) => r.deliveryFee.toLowerCase().contains('free'))
            .toList();
        return pickup.isEmpty ? restaurants.take(6).toList() : pickup;
    }
  }

  IconData _iconForShortcutType(_ShortcutType type) {
    switch (type) {
      case _ShortcutType.offers:
        return Icons.local_offer_outlined;
      case _ShortcutType.mart:
        return Icons.shopping_basket_outlined;
      case _ShortcutType.newArrivals:
        return Icons.new_releases_outlined;
      case _ShortcutType.pickup:
        return Icons.storefront_outlined;
    }
  }
}

class _FeedShortcut {
  final _ShortcutType type;
  final IconData icon;
  final String label;
  final String title;
  final String description;

  const _FeedShortcut({
    required this.type,
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
  });
}

class _ShortcutAction extends StatelessWidget {
  final _FeedShortcut item;
  final VoidCallback onTap;

  const _ShortcutAction({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final iconSize = screenWidth < 360 ? 50.0 : 54.0;
    final labelSize = screenWidth < 360 ? 12.0 : 13.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: const Color(0xFFFF0A78)),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleSize = screenWidth < 360
        ? 24.0
        : screenWidth < 420
            ? 28.0
            : 34.0;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFE6E6E8)),
            ),
            child: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ],
    );
  }
}

class _PromoDealCard extends StatelessWidget {
  final String title;
  final String code;
  final String imageUrl;

  const _PromoDealCard({
    required this.title,
    required this.code,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.62).clamp(190.0, 260.0).toDouble();
    final titleSize = screenWidth < 360 ? 22.0 : 28.0;
    final imageWidth = (cardWidth * 0.57).clamp(104.0, 140.0).toDouble();
    final imageHeight = (cardWidth * 0.44).clamp(88.0, 110.0).toDouble();

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF5F053D), Color(0xFFFF0A78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Free delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'code $code',
                    style: const TextStyle(
                      color: Color(0xFFFF0A78),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantFeedCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantFeedCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.7).clamp(220.0, 300.0).toDouble();
    final imageHeight = (cardWidth * 0.56).clamp(130.0, 170.0).toDouble();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    restaurant.image,
                    width: cardWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: cardWidth,
                      height: imageHeight,
                      color: const Color(0xFFECECF0),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 18),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Ad',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${restaurant.deliveryTime} • ${restaurant.cuisine}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFA000), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${restaurant.rating}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '${restaurant.deliveryFee} delivery',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
