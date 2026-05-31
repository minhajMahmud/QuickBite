# QuickBite Frontend UI/UX Blueprint (Production-Ready)

> Package/App ID: `com.quickbite.mobile`  
> Primary stack: **Flutter**  
> Alternatives: React Native / React.js

---

## 1) Objective

Create a complete role-based food delivery frontend for:

- Customer
- Restaurant
- Delivery Partner
- Admin

The frontend must support secure authentication, role-based routing, approval-based access control, responsive UX, and real-time order experiences.

---

## 2) Recommended Stack

- Flutter 3.x + Dart 3.x
- Riverpod (state management)
- GoRouter (navigation and guards)
- Dio/http (API integration)
- WebSocket/SSE (live updates)
- Google Maps Flutter (tracking + navigation)

Optional:

- Firebase Auth (social auth helpers)
- Stripe/Razorpay SDK (payments)
- Hive/SharedPreferences (local persistence)
- Lottie/Flutter Animate (animations)

---

## 3) User Roles & Dashboards

### 3.1 Customer

Features:

- Sign up/login (email, phone OTP, optional social login)
- Discover restaurants, search, and filters
- Browse menu with customization/add-ons
- Cart and checkout with promo support
- Real-time order tracking with ETA/map
- Ratings/reviews and notifications
- Profile: addresses, payment methods, preferences

Dashboard sections:

- Explore
- Restaurant/Menu
- Cart/Checkout
- Orders/Tracking
- Profile
- Notifications

### 3.2 Restaurant

Features:

- Sign up/login (admin approval required)
- Menu CRUD with images, availability toggles, prices
- Order management (accept/reject/update status)
- Sales and popular-items analytics
- Business profile and operating hours

Dashboard sections:

- Today summary
- Orders
- Menu Management
- Analytics
- Profile

### 3.3 Delivery Partner

Features:

- Sign up/login (admin approval required)
- Accept/reject delivery assignments
- Pickup/drop details with map navigation
- Delivery OTP confirmation
- Earnings and delivery history

Dashboard sections:

- Pending deliveries
- Active orders
- Navigation
- Earnings
- History

### 3.4 Admin

Features:

- Manage and approve restaurants/delivery partners
- Suspend/ban users
- Live order monitoring and dispute handling
- Pricing, commissions, coupons, campaigns
- Revenue and growth analytics

Dashboard sections:

- User Management
- Orders Live Monitor
- Pricing & Commission
- Promotions
- Reports

---

## 4) Role-Based Authentication & Routing

### 4.1 JWT Claims

Required token claims:

- `sub`
- `role`
- `approved`
- `exp`

### 4.2 Access Rules

- Customer: dashboard access after auth
- Restaurant: dashboard only if `approved=true`
- Delivery Partner: dashboard only if `approved=true`
- Admin: admin dashboard access by role

### 4.3 Redirect Flow

- `customer` → `/dashboard/customer`
- `restaurant + approved=true` → `/dashboard/restaurant`
- `delivery_partner + approved=true` → `/dashboard/delivery`
- `admin` → `/dashboard/admin`
- `restaurant/delivery_partner + approved=false` → `/approval-pending`

---

## 5) Form Blueprint (Compulsory vs Optional)

| Role | Field | Required | Notes |
| --- | --- | --- | --- |
| Customer | Full Name | Yes | Minimum 2 characters |
| Customer | Email | Yes | Valid format |
| Customer | Phone | Yes | OTP required |
| Customer | Password | Yes | Strong policy |
| Customer | Social Login | No | Google/Apple/Facebook |
| Restaurant | Owner Name | Yes | Legal identity |
| Restaurant | Business Name | Yes | Display/business name |
| Restaurant | Business Email | Yes | Official communication |
| Restaurant | Phone | Yes | OTP required |
| Restaurant | License/Docs | Yes | Required for approval |
| Delivery Partner | Full Name | Yes | Legal identity |
| Delivery Partner | Phone | Yes | OTP required |
| Delivery Partner | Vehicle Type | Yes | Bike/Scooter/Car |
| Delivery Partner | License/Docs | Yes | Required for approval |
| Admin | Email | Yes | Admin account |
| Admin | Password | Yes | Strong auth (+MFA recommended) |

Validation requirements:

- Mandatory field checks
- Email format checks
- Password complexity checks
- OTP verification for phone
- Document upload checks for business roles

---

## 6) Route Structure (GoRouter)

```txt
/
├── /login
├── /signup
├── /otp-verify
├── /approval-pending
├── /dashboard/customer
│   ├── /explore
│   ├── /restaurant/:id
│   ├── /cart
│   ├── /checkout
│   ├── /order/:id/tracking
│   └── /profile
├── /dashboard/restaurant
│   ├── /orders
│   ├── /menu
│   ├── /analytics
│   └── /profile
├── /dashboard/delivery
│   ├── /deliveries
│   ├── /delivery/:id
│   ├── /navigation/:id
│   └── /earnings
└── /dashboard/admin
    ├── /users
    ├── /orders/live
    ├── /pricing
    ├── /promotions
    └── /reports
```

---

## 7) Frontend Folder Structure

```txt
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── guards/
│       ├── auth_guard.dart
│       └── role_guard.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   └── services/
│       ├── api_client.dart
│       ├── socket_service.dart
│       └── storage_service.dart
├── features/
│   ├── auth/
│   ├── customer/
│   ├── restaurant/
│   ├── delivery/
│   └── admin/
└── main.dart
```

---

## 8) Core Reusable Components

- `QBTextField`
- `QBPrimaryButton`
- `RoleSelector`
- `RestaurantCard`
- `MenuItemCard`
- `OrderStatusStepper`
- `LiveTrackingMap`
- `AnalyticsCard`
- `ApprovalBadge`
- `EmptyState`, `ErrorState`, `LoadingSkeleton`

---

## 9) API Placeholder Endpoints

Auth:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/verify-otp`
- `POST /api/v1/auth/refresh`

Customer:

- `GET /api/v1/catalog/restaurants`
- `GET /api/v1/catalog/restaurants/:id/menu`
- `POST /api/v1/orders`
- `GET /api/v1/orders/:id`
- `GET /api/v1/orders/:id/events` (SSE)

Restaurant:

- `GET /api/v1/restaurant-dashboard/orders`
- `PATCH /api/v1/restaurant-dashboard/orders/:id/status`
- `POST /api/v1/restaurant-dashboard/menu`
- `PATCH /api/v1/restaurant-dashboard/menu/:id`
- `DELETE /api/v1/restaurant-dashboard/menu/:id`

Delivery:

- `GET /api/v1/delivery-requests/incoming`
- `POST /api/v1/delivery-requests/:id/accept`
- `POST /api/v1/delivery-requests/:id/reject`
- `POST /api/v1/delivery-tracking/orders/:id/location`

Admin:

- `GET /api/v1/admin/users`
- `PATCH /api/v1/admin/users/:id/status`
- `GET /api/v1/admin/restaurants`
- `PATCH /api/v1/admin/restaurants/:id/approval`

---

## 10) Mock Data Samples

User session:

```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "u_101",
    "name": "Jane Doe",
    "role": "restaurant",
    "approved": false
  }
}
```

Tracking event (SSE):

```json
{
  "orderId": "ord_9001",
  "status": "on_the_way",
  "etaMinutes": 14,
  "rider": {
    "lat": 23.7806,
    "lng": 90.407
  }
}
```

---

## 11) Admin Approval Logic

1. Restaurant/delivery partner signs up
2. Account created with `approved=false`
3. Login allowed but dashboard blocked
4. Redirect to `/approval-pending`
5. Status refresh checks approval updates
6. Once approved, route to respective dashboard

---

## 12) Advanced (Optional) Features

- AI-based recommendations
- Scheduled pre-orders
- Loyalty program
- In-app support chat
- Contactless delivery toggle
- Multi-language and multi-currency
- Free-delivery subscription model

---

## 13) Non-Functional UX Requirements

- Mobile-first responsive layouts
- Smooth transitions and loading states
- Clear validation + friendly error messages
- Secure auth/token handling
- Real-time order/tracking updates
- High dashboard availability

---

## 14) Delivery Phases

- Phase 1: Auth + role routing + customer core
- Phase 2: Restaurant dashboard and menu/order workflows
- Phase 3: Delivery workflow with live map tracking
- Phase 4: Admin panel with reports/promotions
- Phase 5: Optimization, QA hardening, advanced features

---

## 15) Developer Quick Start

1. Build auth flows and route guards first
2. Add role-based dashboard shells
3. Implement feature modules per role
4. Connect APIs + live updates (SSE/WebSocket)
5. Final polish: UX, accessibility, performance

---

## 16) Final Note

This README is a production-ready frontend blueprint with required vs optional scope, role-based navigation logic, and implementation-ready module structure.
