/// App Constants
class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.quickbite.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // App Information
  static const String appName = 'QuickBite';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // Delivery Configuration
  static const double freeDeliveryThreshold =
      30.0; // Free delivery for orders > $30
  static const double defaultDeliveryFee = 3.99;

  // Pagination
  static const int pageSize = 20;

  // Asset Paths
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';
  static const String assetsAnimations = 'assets/animations/';

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableOfflineMode = true;

  // UI Configuration
  static const double standardBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;

  // Animation Durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorUnknown = 'Something went wrong. Please try again.';
  static const String errorEmptyCart =
      'Your cart is empty. Add items to continue.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';

  // Success Messages
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successItemAdded = 'Item added to cart';
  static const String successItemRemoved = 'Item removed from cart';
  static const String successOrderCancelled = 'Order cancelled';

  // Phone & Contact
  static const String supportPhone = '+1-800-QUICKBITE';
  static const String supportEmail = 'support@quickbite.com';

  // Social Links
  static const String facebookUrl = 'https://facebook.com/quickbite';
  static const String instagramUrl = 'https://instagram.com/quickbite';
  static const String twitterUrl = 'https://twitter.com/quickbite';
}
