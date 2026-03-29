// Import extension definition documentation
// Place this in your app routing configuration

// Example routes to add to GoRouter:
/*
  GoRoute(
    path: '/restaurant-dashboard',
    builder: (context, state) =>  const RestaurantDashboardPage(),
    routes: [
      GoRoute(
        path: 'overview',
        builder: (context, state) => const RestaurantDashboardPage(),
      ),
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
*/

export 'pages/dashboard_page.dart';
export 'pages/orders_page.dart';
export 'pages/menu_page.dart';
export 'providers/dashboard_providers.dart';
export 'widgets/dashboard_overview_widget.dart';
export 'widgets/dashboard_stats_widget.dart';
