# QuickBite - Flutter Mobile App

A fully functional Flutter mobile application converted from the QuickBite web platform. This app provides a luxurious food delivery experience with user dashboards and admin panels.

## 📋 Project Overview

**QuickBite** is a modern food delivery mobile application built with Flutter that includes:

- ✅ User authentication and management
- ✅ Restaurant browsing with filtering
- ✅ Food ordering cart system
- ✅ User dashboard with order history, favorites, addresses, notifications
- ✅ Admin panel for management (users, restaurants, deliveries, coupons)
- ✅ Real-time data with Riverpod state management
- ✅ Beautiful UI with custom Material Design widgets
- ✅ Responsive design for all screen sizes

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── config/
│   ├── theme/
│   │   └── app_theme.dart            # Color scheme & typography
│   └── routes/
│       └── app_routes.dart           # Navigation & routing
├── data/
│   ├── models/
│   │   ├── models.dart               # Restaurant, FoodItem, CartItem, Order
│   │   └── user_model.dart           # User, DeliveryAgent, DashboardRestaurant
│   └── datasources/
│       └── mock_data_service.dart    # Mock data provider
├── presentation/
│   ├── providers/
│   │   └── app_providers.dart        # Riverpod state management
│   ├── widgets/
│   │   ├── restaurant_card.dart      # Restaurant card component
│   │   ├── category_chip.dart        # Category filter chips
│   │   └── food_item_card.dart       # Food item card component
│   └── pages/
│       ├── home_screen.dart          # Landing/home page
│       ├── browse_screen.dart        # Restaurant browsing
│       ├── restaurant_detail_screen.dart  # Menu & items
│       ├── cart_screen.dart          # Shopping cart
│       ├── user_dashboard_screen.dart    # User overview
│       ├── user_sub_screens.dart        # Order history, favorites, addresses, settings
│       └── admin_screens.dart           # Admin dashboard & management
└── pubspec.yaml                      # Dependencies

```

## 📱 Features Implemented

### 1. **Home Screen**

- Hero section with promotional banner
- Category browsing
- Featured restaurants showcase
- Search functionality

### 2. **Browse Screen**

- Search restaurants by name/cuisine
- Filter by category
- Restaurant listing with ratings
- Price and delivery info

### 3. **Restaurant Detail**

- Restaurant information (rating, delivery time, fees)
- Menu items grouped by category
- Food item details with images
- Add to cart functionality

### 4. **Shopping Cart**

- View cart items with images
- Adjust quantities
- Remove items
- Delivery fee calculation
- Order total calculation
- Checkout button

### 5. **User Dashboard**

- KPI cards (total orders, spent, loyalty points, saved addresses)
- Quick access menu to:
  - Order history
  - Favorite restaurants
  - Saved addresses
  - Notifications
  - Account settings
  - Admin panel access

### 6. **Admin Panel**

- User management (list, search, filter, actions)
- Restaurant management (list, search, actions)
- Delivery management
- Coupon management

## 🎨 Design System

### Colors

```dart
Primary Orange: #FF7A45
Primary Amber: #FFD700
Success Green: #28A745
Warning Yellow: #FFB800
Destructive Red: #FF4444
```

### Typography

- Font: Plus Jakarta Sans (Google Fonts)
- Weights: 300-800
- Font sizes: 10-32px following Material Design

### Spacing & Layout

- Border radius: 12px (standard)
- Card elevation: 2px
- Padding standards: 16px

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 3.0+
- A code editor (VS Code, Android Studio, IntelliJ)

### Installation Steps

1. **Navigate to Flutter project directory**

   ```bash
   cd flutter
   ```

2. **Get dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app (Android)**

   ```bash
   flutter run -d android
   ```

4. **Run the app (iOS)**

   ```bash
   flutter run -d iphone
   ```

5. **Build APK for production**

   ```bash
   flutter build apk --release
   ```

   **Build AAB for Google Play**

   ```bash
   flutter build appbundle --release
   ```

## 📦 Dependencies

### State Management

- `flutter_riverpod: ^2.4.0` - Reactive state management
- `provider: ^6.0.0` - Alternative state management

### Networking

- `http: ^1.1.0` - HTTP client
- `dio: ^5.3.0` - Advanced HTTP client

### UI & Design

- `google_fonts: ^6.0.0` - Google Fonts integration
- `flutter_svg: ^2.0.0` - SVG support
- `cached_network_image: ^3.3.0` - Image caching

### Navigation

- `go_router: ^11.0.0` - Declarative routing

### Local Storage

- `shared_preferences: ^2.2.0` - Key-value storage
- `hive: ^2.2.0` - NoSQL database

### Utilities

- `intl: ^0.19.0` - Internationalization
- `uuid: ^4.0.0` - UUID generation
- `equatable: ^2.0.0` - Equality comparison
- `logger: ^2.0.0` - Logging

### Charts & Data

- `fl_chart: ^0.63.0` - Charts and graphs

### Animations

- `flutter_animate: ^4.2.0` - Animation utilities
- `lottie: ^2.4.0` - Lottie animations

## 📊 Data Models

### Restaurant

```dart
- id: String
- name: String
- image: String (URL)
- cuisine: String
- rating: double
- deliveryTime: String (e.g., "15-25 min")
- deliveryFee: String (e.g., "Free", "$2.99")
- popular: bool
- priceRange: String (e.g., "$$")
```

### FoodItem

```dart
- id: String
- restaurantId: String
- name: String
- description: String
- price: double
- image: String (URL)
- category: String
- popular: bool
```

### CartItem

```dart
- food: FoodItem
- quantity: int
```

### Order

```dart
- id: String
- userId: String
- restaurant: String
- items: List<String>
- total: double
- status: String (pending, preparing, on_the_way, delivered, cancelled)
- date: String
```

## 🔄 State Management Flow

Using Riverpod for reactive state management:

```dart
// Providers
restaurantsProvider         // All restaurants
foodItemsProvider          // All food items
categoriesProvider         // Categories
cartProvider               // Shopping cart state
cartTotalPriceProvider    // Cart subtotal
cartGrandTotalProvider    // Cart total with delivery fee
searchQueryProvider        // Search query
categoryFilterProvider     // Category filter
filteredRestaurantsProvider // Filtered results
```

## 🎯 Navigation Routes

```
/ (Home)
├── /browse (Browse Restaurants)
├── /restaurant/:id (Restaurant Detail)
├── /cart (Shopping Cart)
├── /dashboard (User Dashboard)
│   ├── /dashboard/orders (Order History)
│   ├── /dashboard/favorites (Favorites)
│   ├── /dashboard/addresses (Addresses)
│   └── /dashboard/settings (Settings)
└── /admin (Admin Dashboard)
    ├── /admin/users (User Management)
    └── /admin/restaurants (Restaurant Management)
```

## 🔌 API Integration

Currently using mock data from `MockDataService`. To integrate with real APIs:

1. Create a `repositories` folder:

   ```dart
   lib/domain/repositories/
   ```

2. Define repository interfaces:

   ```dart
   abstract class RestaurantRepository {
     Future<List<Restaurant>> getRestaurants();
     Future<Restaurant?> getRestaurantById(String id);
   }
   ```

3. Implement HTTP client:

   ```dart
   class RestaurantRepositoryImpl implements RestaurantRepository {
     final HttpClient _httpClient;
     // Implementation
   }
   ```

4. Update providers to use repositories instead of mock data

## 🎨 Customization Guide

### Changing Colors

Edit `lib/config/theme/app_theme.dart`:

```dart
static const Color primaryOrange = Color(0xFFFF7A45); // Change this
```

### Adding New Screens

1. Create feature folder: `lib/features/feature_name/`
2. Add `presentation/pages/` for screens
3. Add routes to `app_routes.dart`
4. Create providers in `app_providers.dart`

### Modifying UI Components

Edit widgets in `lib/presentation/widgets/`

## 🧪 Testing

### Run all tests

```bash
flutter test
```

### Run specific test file

```bash
flutter test test/features/cart_test.dart
```

## 📝 API Endpoints Reference (for future integration)

```
Base URL: https://api.quickbite.com/v1

Public Endpoints:
- GET /restaurants (Browse all)
- GET /restaurants/:id (Details)
- GET /restaurants/:id/menu (Menu items)
- GET /categories (Browse categories)

User Endpoints:
- GET /user/orders (Order history)
- GET /user/favorites (Favorite restaurants)
- GET /user/addresses (Saved addresses)
- POST /orders (Create order)

Admin Endpoints:
- GET /admin/users (User list)
- GET /admin/restaurants (Restaurant list)
- GET /admin/orders (All orders)
- GET /admin/analytics (Dashboard data)
```

## 🐛 Troubleshooting

### Build Issues

```bash
# Clean build cache
flutter clean

# Get fresh dependencies
flutter pub get

# Rebuild
flutter run
```

### Performance Issues

- Enable tree-shock: `flutter build apk --split-per-abi`
- Use `const` constructors where possible
- Implement lazy loading for lists

### Real Device Testing

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d device_id
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (11.0+)
- ⚠️ Web (partial support with go_router)

## 🚢 Production Build Checklist

- [ ] Update version number in `pubspec.yaml`
- [ ] Update app icon in `android/app/src/main/res/`
- [ ] Update app name in `android/app/src/main/AndroidManifest.xml`
- [ ] Test on real devices
- [ ] Configure signing certificates
- [ ] Run `flutter test` - all tests pass
- [ ] Build release APK/AAB
- [ ] Test release build thoroughly

## 📚 Code Comments & Mapping

The code includes comprehensive comments explaining:

- UI component purpose and parameters
- State management setup
- Navigation flow
- Data transformations
- API integration points (marked with `TODO`)

Each feature folder follows clean architecture:

- `data/` - Data models and repositories
- `domain/` - Business logic (entities, use cases)
- `presentation/` - UI (pages, widgets, providers)

## 🤝 Contributing

When adding features:

1. Maintain folder structure
2. Follow Dart style guide
3. Add comments for complex logic
4. Update this README
5. Test thoroughly

## 📄 License

This project is a conversion from the web QuickBite platform to Flutter mobile app.

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [Go Router Navigation](https://pub.dev/packages/go_router)
- [Material Design 3](https://material.io/design)

---

**Ready to build your APK?** Run `flutter build apk --release` from the `flutter/` directory!
