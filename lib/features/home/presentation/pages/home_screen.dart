import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../data/models/models.dart';
import '../../../../data/datasources/offers_api_service.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../presentation/widgets/adaptive_app_image.dart';
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

final homeRestaurantFilterProvider =
    StateProvider<_HomeRestaurantFilter>((ref) => _HomeRestaurantFilter.all);

final favoriteRestaurantIdsProvider =
    StateNotifierProvider<_FavoriteRestaurantIdsNotifier, Set<String>>((ref) {
  return _FavoriteRestaurantIdsNotifier();
});

const _restaurantFilters = [
  _RestaurantFilterItem(
    filter: _HomeRestaurantFilter.all,
    label: 'All',
    icon: Icons.apps,
  ),
  _RestaurantFilterItem(
    filter: _HomeRestaurantFilter.topRated,
    label: 'Top rated',
    icon: Icons.star_outline,
  ),
  _RestaurantFilterItem(
    filter: _HomeRestaurantFilter.fastDelivery,
    label: 'Fast delivery',
    icon: Icons.bolt_outlined,
  ),
  _RestaurantFilterItem(
    filter: _HomeRestaurantFilter.freeDelivery,
    label: 'Free delivery',
    icon: Icons.local_shipping_outlined,
  ),
];

enum _ShortcutType { offers, mart, newArrivals, pickup }

enum _HomeRestaurantFilter { all, topRated, fastDelivery, freeDelivery }

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
    final offersAsync = ref.watch(offersProvider);

    final restaurants = restaurantsAsync.asData?.value ?? <Restaurant>[];
    final featuredRestaurants =
        featuredRestaurantsAsync.asData?.value ?? <Restaurant>[];
    final categories = categoriesAsync.asData?.value ?? <Category>[];
    final offers = offersAsync.asData?.value ?? <Offer>[];
    final selectedRestaurantFilter = ref.watch(homeRestaurantFilterProvider);
    final favoriteRestaurantIds = ref.watch(favoriteRestaurantIdsProvider);

    final isLoadingInitial =
        (restaurantsAsync.isLoading || categoriesAsync.isLoading) &&
            restaurants.isEmpty &&
            categories.isEmpty;
    final authState = ref.watch(authProvider);
    final isGuest = !authState.isAuthenticated;
    final popular =
        featuredRestaurants.isNotEmpty ? featuredRestaurants : restaurants;
    final filteredPopular =
        _applyPopularFilter(popular, selectedRestaurantFilter);
    final discounted = restaurants.reversed.toList();

    if (isLoadingInitial) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshHomeData(ref),
          color: const Color(0xFF2563EB),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 8, horizontalPadding, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F2937), Color(0xFF334155)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QuickBite',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Smart delivery, better dining',
                                  style: TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.favorite_border,
                                color: Color(0xFFE5E7EB)),
                          ),
                          IconButton(
                            onPressed: () => context.push('/cart'),
                            icon: const Icon(Icons.shopping_cart_outlined,
                                color: Color(0xFFE5E7EB)),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Color(0xFFE5E7EB)),
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
                                  child:
                                      Text(authState.user?.name ?? 'Account'),
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
                      const SizedBox(height: 16),
                      _AnimatedReveal(
                        delayMs: 60,
                        child: InkWell(
                          onTap: () => context.push('/browse'),
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: Color(0xFF6B7280)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Search for restaurants and groceries',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedReveal(
                        delayMs: 140,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 360;
                            final titleSize = isNarrow ? 22.0 : 28.0;

                            return Container(
                              padding: EdgeInsets.fromLTRB(
                                isNarrow ? 12 : 16,
                                16,
                                isNarrow ? 12 : 8,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: isNarrow
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Here's 50% off & free\ndelivery on your first\norder!",
                                          style: TextStyle(
                                            color: Color(0xFFF9FAFB),
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Start ordering ➜',
                                          style: TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
                                                  color: Color(0xFFF9FAFB),
                                                  fontSize: titleSize,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'Start ordering ➜',
                                                style: TextStyle(
                                                  color: Color(0xFFFBBF24),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  delayMs: 220,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDFDFE),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 18,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 16, horizontalPadding, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: _feedShortcuts
                              .map(
                                (shortcut) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
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
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 94,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
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
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            category.icon,
                                            style:
                                                const TextStyle(fontSize: 26),
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
                        const SizedBox(height: 16),
                        _SectionHeader(
                          title: 'Offers',
                          onTap: () => _showAllOffersSheet(context, offers),
                        ),
                        const SizedBox(height: 10),
                        const OffersSection(),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: 'Popular Restaurants',
                          onTap: () => context.push('/browse'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _restaurantFilters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filterItem = _restaurantFilters[index];
                              final isSelected =
                                  selectedRestaurantFilter == filterItem.filter;
                              return ChoiceChip(
                                selected: isSelected,
                                onSelected: (_) {
                                  ref
                                      .read(
                                          homeRestaurantFilterProvider.notifier)
                                      .state = filterItem.filter;
                                },
                                avatar: Icon(
                                  filterItem.icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                                label: Text(filterItem.label),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: const Color(0xFFF3F4F6),
                                selectedColor: const Color(0xFF2563EB),
                                side: BorderSide.none,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filteredPopular.isNotEmpty)
                          SizedBox(
                            height: 260,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: filteredPopular.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final restaurant = filteredPopular[index];
                                return _RestaurantFeedCard(
                                  restaurant: restaurant,
                                  isFavorite: favoriteRestaurantIds
                                      .contains(restaurant.id),
                                  onToggleFavorite: () {
                                    ref
                                        .read(favoriteRestaurantIdsProvider
                                            .notifier)
                                        .toggleFavorite(restaurant.id);
                                  },
                                  onTap: () => context
                                      .push('/restaurant/${restaurant.id}'),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_alt_off,
                                    color: AppColors.muted),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'No restaurants match this filter yet.',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(homeRestaurantFilterProvider
                                            .notifier)
                                        .state = _HomeRestaurantFilter.all;
                                  },
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final restaurant = discounted[index];
                              return _RestaurantFeedCard(
                                restaurant: restaurant,
                                isFavorite: favoriteRestaurantIds
                                    .contains(restaurant.id),
                                onToggleFavorite: () {
                                  ref
                                      .read(favoriteRestaurantIdsProvider
                                          .notifier)
                                      .toggleFavorite(restaurant.id);
                                },
                                onTap: () => context
                                    .push('/restaurant/${restaurant.id}'),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isGuest)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/login'),
                              icon: const Icon(Icons.login),
                              label: const Text('Sign In to Order Faster'),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
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

  Future<void> _refreshHomeData(WidgetRef ref) async {
    ref.invalidate(restaurantsProvider);
    ref.invalidate(featuredRestaurantsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(offersProvider);

    await Future.wait([
      ref.read(restaurantsProvider.future),
      ref.read(featuredRestaurantsProvider.future),
      ref.read(categoriesProvider.future),
      ref.read(offersProvider.future),
    ]);
  }

  List<Restaurant> _applyPopularFilter(
    List<Restaurant> restaurants,
    _HomeRestaurantFilter filter,
  ) {
    switch (filter) {
      case _HomeRestaurantFilter.all:
        return restaurants;
      case _HomeRestaurantFilter.topRated:
        return restaurants.where((r) => r.rating >= 4.5).toList();
      case _HomeRestaurantFilter.fastDelivery:
        return restaurants.where((r) {
          final mins = _extractDeliveryMinutes(r.deliveryTime);
          return mins != null && mins <= 30;
        }).toList();
      case _HomeRestaurantFilter.freeDelivery:
        return restaurants
            .where((r) => _isFreeDelivery(r.deliveryFee))
            .toList();
    }
  }

  bool _isFreeDelivery(String feeText) {
    final normalized = feeText.toLowerCase().trim();
    final numericOnly = normalized.replaceAll(RegExp(r'[^0-9.]'), '');
    return normalized.contains('free') ||
        numericOnly == '0' ||
        numericOnly == '0.0' ||
        numericOnly == '0.00';
  }

  int? _extractDeliveryMinutes(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return int.tryParse(match?.group(1) ?? '');
  }

  void _showAllOffersSheet(BuildContext context, List<Offer> offers) {
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'All Offers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${offers.length} total',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: offers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child:
                                  Text('No active offers available right now'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: offers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final offer = offers[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.deepOrange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offer.code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      offer.discountDisplay,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      offer.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Min order: ৳${offer.minOrderValue}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _RestaurantFilterItem {
  final _HomeRestaurantFilter filter;
  final String label;
  final IconData icon;

  const _RestaurantFilterItem({
    required this.filter,
    required this.label,
    required this.icon,
  });
}

class _FavoriteRestaurantIdsNotifier extends StateNotifier<Set<String>> {
  static const _storageKey = 'favorite_restaurant_ids';

  _FavoriteRestaurantIdsNotifier() : super(const <String>{}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? <String>[];
    state = ids.toSet();
  }

  Future<void> toggleFavorite(String restaurantId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(restaurantId)) {
      updated.remove(restaurantId);
    } else {
      updated.add(restaurantId);
    }
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList());
  }
}

class _AnimatedReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedReveal({
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<_AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<_AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curve);

    final safeDelay = widget.delayMs < 0 ? 0 : widget.delayMs;
    if (safeDelay == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: safeDelay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
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
        ? 20.0
        : screenWidth < 420
            ? 22.0
            : 26.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFE6E6E8)),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantFeedCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _RestaurantFeedCard({
    required this.restaurant,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

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
                  child: AdaptiveAppImage(
                    source: restaurant.image,
                    width: cardWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onToggleFavorite,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937).withOpacity(0.75),
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
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
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
                Expanded(
                  child: Text(
                    '${restaurant.deliveryFee} delivery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
