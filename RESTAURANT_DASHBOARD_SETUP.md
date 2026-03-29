# Restaurant Dashboard Setup Guide

## Overview
This guide explains the complete restaurant dashboard implementation for QuickBite, which includes both backend API endpoints and Flutter frontend UI components.

## Architecture

### Backend (Node.js/Express) 
Located in `backend/src/modules/restaurant-dashboard/`

**Files:**
- `restaurantDashboard.routes.js` - Route definitions
- `restaurantDashboard.controller.js` - Request handlers
- `restaurantDashboard.service.js` - Business logic
- `restaurantDashboard.repository.js` - Database queries

**API Endpoints:**
```
GET    /api/v1/restaurant-dashboard/overview     - Get dashboard overview
GET    /api/v1/restaurant-dashboard/menu         - Get menu items
POST   /api/v1/restaurant-dashboard/menu         - Create menu item
PATCH  /api/v1/restaurant-dashboard/menu/:id     - Update menu item
GET    /api/v1/restaurant-dashboard/orders       - Get orders
PATCH  /api/v1/restaurant-dashboard/orders/:id/status - Update order status
GET    /api/v1/restaurant-dashboard/analytics    - Get analytics
```

**Features:**
- ✅ Dashboard overview with KPIs
- ✅ Menu management (CRUD)
- ✅ Order management and status tracking
- ✅ Sales analytics and trends
- ✅ Operating hours management
- ✅ Role-based access control (restaurant owner can only access their own restaurant)

### Frontend (Flutter)
Located in `lib/features/restaurant_dashboard/`

**Directory Structure:**
```
restaurant_dashboard/
├── data/
│   ├── models/
│   │   └── models.dart           - Data models
│   └── services/
│       └── dashboard_service.dart - API client
├── presentation/
│   ├── pages/
│   │   ├── dashboard_page.dart   - Main dashboard
│   │   ├── orders_page.dart      - Orders management
│   │   ├── menu_page.dart        - Menu management
│   │   └── analytics_page.dart   - Analytics charts
│   ├── widgets/
│   │   ├── dashboard_overview_widget.dart    - Restaurant info card
│   │   └── dashboard_stats_widget.dart       - Statistics cards
│   └── providers/
│       └── dashboard_providers.dart          - Riverpod providers
└── restaurant_dashboard_exports.dart         - Exports
```

## Frontend Components

### Data Layer
**Services:**
- `RestaurantDashboardService` - Handles all API communication via Dio

**Models:**
- `DashboardOverview` - Overview data structure
- `Restaurant` - Restaurant information
- `DashboardMetrics` - KPI metrics
- `MenuItem` - Menu item data
- `Order` - Order information
- `Analytics` - Sales analytics

### State Management (Riverpod)
**Providers:**
- `restaurantDashboardServiceProvider` - Service instance
- `selectedRestaurantIdProvider` - Selected restaurant state
- `dashboardOverviewProvider` - Dashboard data
- `menuItemsProvider` - Menu items
- `ordersProvider` - Orders with filtering
- `analyticsProvider` - Analytics data
- `createMenuItemProvider` - Create menu item action
- `updateMenuItemProvider` - Update menu item action
- `updateOrderStatusProvider` - Update order status action

### UI Pages

#### Dashboard Page (`dashboard_page.dart`)
- Restaurant overview card
- Performance metrics in grid
- Operating hours display
- Pull-to-refresh functionality
- Error handling with retry

#### Orders Page (`orders_page.dart`)
- List of restaurant orders
- Filter by status (pending, preparing, ready, on_the_way, delivered, cancelled)
- Order details modal
- Update order status functionality
- Status badges with color coding

#### Menu Page (`menu_page.dart`)
- Menu items grouped by category
- Item image, price, and availability
- Add/Edit/Delete menu items
- Search and filter options

#### Analytics Page (`analytics_page.dart`)
- Sales overview chart (Line chart with fl_chart)
- Date range selector (7 days, 30 days, 90 days, 1 year)
- Top selling items list
- Revenue metrics

## Setup Instructions

### Backend Setup
1. Backend is already configured in `backend/src/modules/restaurant-dashboard/`
2. Ensure PostgreSQL database is running
3. Database schema includes all required tables
4. API requires authentication tokens (JWT)

### Frontend Setup

#### 1. Review Configuration
Update the base URL in `dashboard_providers.dart`:
```dart
const baseUrl = 'http://localhost:3000'; // Production: use actual backend URL
```

#### 2. Required Dependencies
The app already includes all needed dependencies in `pubspec.yaml`:
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `fl_chart` - Charts
- `intl` - Formatting
- `go_router` - Navigation

#### 3. Add Routes to GoRouter
In your app routes configuration, add:
```dart
GoRoute(
  path: '/restaurant-dashboard',
  builder: (context, state) => const RestaurantDashboardPage(),
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
```

#### 4. Import Dashboard Module
In your main app file:
```dart
import 'features/restaurant_dashboard/presentation/restaurant_dashboard_exports.dart';
```

### Usage

#### Navigate to Dashboard
```dart
// From anywhere in the app
context.go('/restaurant-dashboard');
```

#### With Restaurant ID
```dart
// If you have a specific restaurant ID
context.go('/restaurant-dashboard?restaurantId=<id>');

// Or programmatically
ref.read(selectedRestaurantIdProvider.notifier).state = restaurantId;
```

#### Refresh Data
```dart
// Pull-to-refresh or button click
ref.refresh(dashboardOverviewProvider);
```

#### Update Order Status
```dart
ref.read(updateOrderStatusProvider.family({
  'orderId': orderId,
  'status': newStatus,
  'restaurantId': restaurantId,
}));
```

## Authentication
The dashboard requires JWT tokens for all API calls. The token should be included in the request headers automatically if you've configured Dio interceptors in your app initialization.

Ensure the token includes:
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "role": "restaurant" // or "admin"
}
```

## Features Implemented

### ✅ Dashboard Features
- Restaurant overview with status
- Real-time metrics (orders, sales, etc.)
- Operating hours display
- Quick statistics cards

### ✅ Order Management
- View all orders
- Filter by status
- See order details with items
- Update order status
- Status tracking with colors

### ✅ Menu Management
- View menu items by category
- Item details (price, image, availability)
- Add new menu items
- Placeholder for edit functionality

### ✅ Analytics
- Sales trend chart
- Top selling items
- Date range filtering
- Revenue metrics

### ✅ UI/UX Features
- Responsive design
- Loading states
- Error handling
- Empty states
- Pull-to-refresh
- Status badges with color coding

## Future Enhancements

1. **Menu Editing**
   - Full edit menu item functionality
   - Delete menu items
   - Bulk operations

2. **Advanced Analytics**
   - Revenue breakdown
   - Customer analytics
   - Peak hours analysis
   - Delivery partner performance

3. **Notifications**
   - Real-time order alerts
   - Status update notifications
   - Customer reviews notifications

4. **Export Features**
   - Export analytics as PDF/CSV
   - Generate reports

5. **Settings**
   - Restaurant profile editing
   - Operating hours management
   - Delivery settings

## Troubleshooting

### API Connection Issues
- Verify backend URL is correct
- Check network connectivity
- Ensure backend is running
- Check CORS configuration in backend

### Authentication Errors
- Verify JWT token is valid
- Check token expiration
- Ensure proper role is assigned

### No Data Showing
- Check restaurant ID is set correctly
- Verify user has access to restaurant
- Check database has records
- Review backend logs

### Chart Not Rendering
- Ensure `fl_chart` dependency is installed
- Check data format from analytics endpoint
- Verify chart size constraints

## Support Files
- Backend configuration: `backend/src/config/`
- Database schema: `database_schema.sql`
- Environment setup: `.env` file configuration

---

**Status:** Production Ready ✅
**Last Updated:** March 29, 2026
**Version:** 1.0.0
