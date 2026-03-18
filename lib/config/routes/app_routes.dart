import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/browse/presentation/pages/browse_screen.dart';
import '../../features/restaurant_detail/presentation/pages/restaurant_detail_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/cart/presentation/pages/checkout_screen.dart';
import '../../features/cart/presentation/pages/order_tracking_screen.dart';
// NEW Enhanced Dashboard Screens
import '../../features/user_dashboard/presentation/pages/user_overview_screen.dart';
import '../../features/user_dashboard/presentation/pages/user_detail_screens.dart';
import '../../features/user_dashboard/presentation/pages/user_settings_screens.dart';
import '../../features/admin_panel/presentation/pages/admin_dashboard_screen.dart';
import '../../features/admin_panel/presentation/pages/admin_management_screens.dart';
import '../../features/admin_panel/presentation/pages/restaurant_panel_screens.dart';
import '../../features/admin_panel/presentation/pages/delivery_partner_screens.dart';
// Authentication Screens
import '../../features/authentication/presentation/pages/login_screen.dart';
import '../../features/authentication/presentation/pages/signup_screen.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/authentication/data/models/user_role.dart';

/// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App Routes
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String browse = '/browse';
  static const String restaurantDetail = '/restaurant/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderTracking = '/order-tracking';
  static const String userDashboard = '/dashboard';
  static const String orderHistory = '/dashboard/orders';
  static const String userFavorites = '/dashboard/favorites';
  static const String userAddresses = '/dashboard/addresses';
  static const String userSettings = '/dashboard/settings';
  static const String adminDashboard = '/admin';
  static const String restaurantPanelOverview = '/admin/restaurant-panel';
  static const String restaurantPanelMenu = '/admin/restaurant-panel/menu';
  static const String restaurantPanelOrders = '/admin/restaurant-panel/orders';
  static const String restaurantPanelAnalytics =
      '/admin/restaurant-panel/analytics';
  static const String restaurantPanelProfile =
      '/admin/restaurant-panel/profile';
  static const String userManagement = '/admin/users';
  static const String restaurantManagement = '/admin/restaurants';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: home,
    refreshListenable: authRouterStateNotifier,
    redirect: (context, state) {
      final authState = authRouterStateNotifier.value;
      final isAuthenticated = authState.isAuthenticated;
      final role = authState.user?.role ?? UserRole.guest;
      final location = state.uri.path;

      final isAuthPage = location == login || location == signup;
      final isAdminRoute = location.startsWith('/admin');
      final isDashboardRoute = location.startsWith('/dashboard');
      final isRestaurantPanelRoute =
          location.startsWith('/admin/restaurant-panel');
      final isDeliveryRoute = location.startsWith('/admin/deliveries');

      if (!isAuthenticated && (isAdminRoute || isDashboardRoute)) {
        return login;
      }

      if (isAuthenticated && isAuthPage) {
        switch (role) {
          case UserRole.admin:
            return adminDashboard;
          case UserRole.restaurant:
            return restaurantPanelOverview;
          case UserRole.deliveryPartner:
            return '/admin/deliveries';
          case UserRole.customer:
          case UserRole.guest:
            return home;
        }
      }

      if (isAuthenticated && isAdminRoute) {
        switch (role) {
          case UserRole.admin:
            break;
          case UserRole.restaurant:
            if (!isRestaurantPanelRoute) {
              return restaurantPanelOverview;
            }
            break;
          case UserRole.deliveryPartner:
            if (!isDeliveryRoute) {
              return '/admin/deliveries';
            }
            break;
          case UserRole.customer:
          case UserRole.guest:
            return home;
        }
      }

      if (isAuthenticated && isDashboardRoute) {
        if (role != UserRole.customer) {
          switch (role) {
            case UserRole.admin:
              return adminDashboard;
            case UserRole.restaurant:
              return restaurantPanelOverview;
            case UserRole.deliveryPartner:
              return '/admin/deliveries';
            case UserRole.customer:
            case UserRole.guest:
              return home;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
        name: 'login',
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
        name: 'signup',
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
        name: 'home',
      ),
      GoRoute(
        path: browse,
        builder: (context, state) => const BrowseScreen(),
        name: 'browse',
      ),
      GoRoute(
        path: restaurantDetail,
        builder: (context, state) {
          final restaurantId = state.pathParameters['id'] ?? '';
          // Guard: ensure restaurantId is not empty before rendering
          if (restaurantId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid restaurant ID'),
              ),
            );
          }
          return RestaurantDetailScreen(restaurantId: restaurantId);
        },
        name: 'restaurant-detail',
      ),
      GoRoute(
        path: cart,
        builder: (context, state) => const CartScreen(),
        name: 'cart',
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutScreen(),
        name: 'checkout',
      ),
      GoRoute(
        path: orderTracking,
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.uri.queryParameters['orderId'],
        ),
        name: 'order-tracking',
      ),
      GoRoute(
        path: userDashboard,
        builder: (context, state) => const UserOverviewScreen(),
        name: 'user-dashboard',
        routes: [
          GoRoute(
            path: 'orders',
            builder: (context, state) => const UserOrderHistoryScreen(),
            name: 'order-history',
          ),
          GoRoute(
            path: 'favorites',
            builder: (context, state) => const UserFavoritesScreen(),
            name: 'user-favorites',
          ),
          GoRoute(
            path: 'addresses',
            builder: (context, state) => const UserAddressesScreen(),
            name: 'user-addresses',
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const UserNotificationsScreen(),
            name: 'user-notifications',
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const UserSettingsScreen(),
            name: 'user-settings',
          ),
        ],
      ),
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
        name: 'admin-dashboard',
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
            name: 'user-management',
          ),
          GoRoute(
            path: 'restaurants',
            builder: (context, state) => const RestaurantManagementScreen(),
            name: 'restaurant-management',
          ),
          GoRoute(
            path: 'deliveries',
            builder: (context, state) => const DeliveryManagementScreen(),
            name: 'delivery-report',
            routes: [
              GoRoute(
                path: 'earnings',
                builder: (context, state) => const DeliveryEarningsScreen(),
                name: 'delivery-earnings',
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const DeliverySettingsScreen(),
                name: 'delivery-settings',
              ),
            ],
          ),
          GoRoute(
            path: 'coupons',
            builder: (context, state) => const CouponManagementScreen(),
            name: 'coupon-management',
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AdminSettingsScreen(),
            name: 'admin-settings',
          ),
          GoRoute(
            path: 'restaurant-panel',
            builder: (context, state) => const RestaurantOverviewScreen(),
            name: 'restaurant-panel-overview',
            routes: [
              GoRoute(
                path: 'menu',
                builder: (context, state) => const RestaurantMenuScreen(),
                name: 'restaurant-panel-menu',
              ),
              GoRoute(
                path: 'orders',
                builder: (context, state) => const RestaurantOrdersScreen(),
                name: 'restaurant-panel-orders',
              ),
              GoRoute(
                path: 'analytics',
                builder: (context, state) => const RestaurantAnalyticsScreen(),
                name: 'restaurant-panel-analytics',
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const RestaurantProfileScreen(),
                name: 'restaurant-panel-profile',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
