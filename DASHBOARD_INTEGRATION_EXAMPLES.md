// Quick Integration Examples for Restaurant Dashboard

// ============================================================================
// 1. BASIC SETUP - Add to your main app routes
// ============================================================================

import 'package:go_router/go_router.dart';
import 'features/restaurant_dashboard/presentation/restaurant_dashboard_exports.dart';

final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // Restaurant Dashboard Routes
    GoRoute(
      path: '/restaurant-dashboard',
      builder: (context, state) => const RestaurantDashboardPage(),
      routes: [
        GoRoute(
          path: 'orders',
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          path: 'menu',
          builder: (context, state) => const MenuPage(),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),
      ],
    ),
  ],
);

// ============================================================================
// 2. NAVIGATION EXAMPLES
// ============================================================================

// Navigate to dashboard
void navigateToDashboard(BuildContext context) {
  context.go('/restaurant-dashboard');
}

// Navigate with restaurant ID
void navigateToDashboardWithId(BuildContext context, String restaurantId) {
  context.go('/restaurant-dashboard?restaurantId=$restaurantId');
}

// Navigate to orders page
void navigateToOrders(BuildContext context) {
  context.go('/restaurant-dashboard/orders');
}

// Navigate to menu page
void navigateToMenu(BuildContext context) {
  context.go('/restaurant-dashboard/menu');
}

// Navigate to analytics page
void navigateToAnalytics(BuildContext context) {
  context.go('/restaurant-dashboard/analytics');
}

// ============================================================================
// 3. PROVIDER USAGE EXAMPLES
// ============================================================================

// In a ConsumerWidget or ConsumerStatefulWidget

// Get dashboard overview
final dashboardData = ref.watch(dashboardOverviewProvider);

// Get menu items
final menuItems = ref.watch(menuItemsProvider);

// Get orders with optional status filter
final allOrders = ref.watch(ordersProvider(null));
final pendingOrders = ref.watch(ordersProvider('pending'));
final preparingOrders = ref.watch(ordersProvider('preparing'));

// Get analytics
final analytics = ref.watch(analyticsProvider(30)); // Last 30 days

// Refresh data
ref.refresh(dashboardOverviewProvider);
ref.refresh(menuItemsProvider);
ref.refresh(ordersProvider(null));
ref.refresh(analyticsProvider(30));

// ============================================================================
// 4. UPDATE OPERATIONS EXAMPLES
// ============================================================================

// Update order status
void updateOrderStatus(WidgetRef ref, String orderId, String newStatus) {
  ref.read(updateOrderStatusProvider.family({
    'orderId': orderId,
    'status': newStatus,
    'restaurantId': restaurantId,
  })).whenData((_) {
    // Refresh orders list
    ref.invalidate(ordersProvider);
  });
}

// Create menu item
void createMenuItemExample(WidgetRef ref, String restaurantId) {
  ref.read(createMenuItemProvider.family({
    'restaurantId': restaurantId,
    'categoryId': 'cat_123',
    'name': 'Grilled Chicken',
    'price': 15.99,
    'description': 'Tender grilled chicken with herbs',
    'image': null,
    'isPopular': false,
    'isVegetarian': false,
    'isVegan': false,
    'isGlutenFree': false,
  })).whenData((_) {
    // Refresh menu
    ref.invalidate(menuItemsProvider);
  }).catchError((error) {
    // Handle error
    print('Error creating menu item: $error');
  });
}

// Update menu item
void updateMenuItemExample(WidgetRef ref, String restaurantId, String itemId) {
  ref.read(updateMenuItemProvider.family({
    'foodItemId': itemId,
    'restaurantId': restaurantId,
    'name': 'Updated Item Name',
    'price': 19.99,
    'availability': 'out_of_stock',
    'isPopular': true,
  })).whenData((_) {
    // Refresh menu
    ref.invalidate(menuItemsProvider);
  });
}

// ============================================================================
// 5. BINDING TO UI EXAMPLES
// ============================================================================

// In a ConsumerWidget build method:

@override
Widget build(BuildContext context, WidgetRef ref) {
  final dashboardAsync = ref.watch(dashboardOverviewProvider);

  return dashboardAsync.when(
    data: (dashboard) {
      return Column(
        children: [
          // Use dashboard.restaurant
          Text(dashboard.restaurant.name),
          // Use dashboard.metrics
          Text('Orders: ${dashboard.metrics.totalOrders}'),
          // Use dashboard.operatingHours
          ...dashboard.operatingHours.map((hours) {
            return Text('${hours.dayOfWeek}: ${hours.openingTime}');
          }).toList(),
        ],
      );
    },
    loading: () => const CircularProgressIndicator(),
    error: (err, stack) => Text('Error: $err'),
  );
}

// ============================================================================
// 6. FILTERING AND PAGINATION EXAMPLES
// ============================================================================

// Filter orders by status with pagination
class OrdersWithPagination extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(orderStatusFilterProvider);
    final ordersAsync = ref.watch(ordersProvider(status));

    return ordersAsync.when(
      data: (orders) {
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return OrderTile(order: orders[index]);
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}

// ============================================================================
// 7. FAB BUTTON EXAMPLE
// ============================================================================

// Add refresh button to dashboard page
FloatingActionButton(
  onPressed: () {
    ref.refresh(dashboardOverviewProvider);
    ref.refresh(menuItemsProvider);
    ref.refresh(ordersProvider(null));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard refreshed')),
    );
  },
  child: const Icon(Icons.refresh),
)

// ============================================================================
// 8. ERROR HANDLING EXAMPLES
// ============================================================================

void handleApiError(Object error, BuildContext context) {
  final message = error.toString();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $message'),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () {
          // Retry operation
        },
      ),
    ),
  );
}

// ============================================================================
// 9. COMPREHENSIVE EXAMPLE - Full Dashboard Screen
// ============================================================================

class RestaurantDashboardExampleScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDashboardExampleScreen({
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDashboardExampleScreen> createState() =>
      _RestaurantDashboardExampleScreenState();
}

class _RestaurantDashboardExampleScreenState
    extends ConsumerState<RestaurantDashboardExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Set restaurant ID
    ref.read(selectedRestaurantIdProvider.notifier).state =
        widget.restaurantId;
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Orders'),
              Tab(text: 'Menu'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Overview Tab
            overviewAsync.when(
              data: (overview) => RestaurantDashboardPage(
                restaurantId: widget.restaurantId,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            // Orders Tab
            OrdersPage(restaurantId: widget.restaurantId),
            // Menu Tab
            MenuPage(restaurantId: widget.restaurantId),
            // Analytics Tab
            AnalyticsPage(restaurantId: widget.restaurantId),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ref.refresh(dashboardOverviewProvider);
            ref.refresh(menuItemsProvider);
            ref.refresh(ordersProvider(null));
            ref.refresh(analyticsProvider(30));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dashboard refreshed')),
            );
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

// ============================================================================
// 10. CONFIGURATION SETUP
// ============================================================================

// Update this in dashboard_providers.dart before use:
/*
final restaurantDashboardServiceProvider = Provider<RestaurantDashboardService>((ref) {
  final dio = Dio();
  
  // Add your authentication interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add JWT token
        final token = ref.read(authTokenProvider); // Your auth provider
        options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ),
  );
  
  const baseUrl = 'http://your-backend-url:3000'; // Update this
  return RestaurantDashboardService(dio: dio, baseUrl: baseUrl);
});
*/

// ============================================================================
// NOTES:
// - All providers are auto-disposing to prevent memory leaks
// - Use ref.invalidate() to invalidate cached data
// - Use ref.refresh() to invalidate and reload immediately
// - Data persists during the widget lifecycle
// - Error handling is built into each provider
// - Consider adding your own caching strategy for offline support
// ============================================================================
