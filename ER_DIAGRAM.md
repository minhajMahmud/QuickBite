# QuickBite ER Diagram & Relationships

## Complete Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ USER_ADDRESSES : has
    USERS ||--o{ ORDERS : places
    USERS ||--o{ USER_FAVORITES : has
    USERS ||--o{ FOOD_ITEM_RATINGS : gives
    USERS ||--o{ DELIVERY_AGENT_RATINGS : gives
    USERS ||--o{ RESTAURANT_RATINGS : gives
    USERS ||--o{ COUPON_USAGE : uses
    
    RESTAURANTS ||--o{ FOOD_ITEMS : offers
    RESTAURANTS ||--o{ OPERATING_HOURS : has
    RESTAURANTS ||--o{ RESTAURANT_RATINGS : receives
    RESTAURANTS ||--o{ ORDERS : receives
    
    CATEGORIES ||--o{ FOOD_ITEMS : contains
    
    FOOD_ITEMS ||--o{ FOOD_ITEM_RATINGS : receives
    FOOD_ITEMS ||--o{ ORDER_ITEMS : in
    
    ORDERS ||--o{ ORDER_ITEMS : contains
    ORDERS ||--o{ ORDER_STATUS_HISTORY : tracks
    ORDERS }o--|| DELIVERY_AGENTS : "assigned to"
    ORDERS }o--|| COUPONS : uses
    ORDERS }o--|| USER_ADDRESSES : "delivered to"
    
    DELIVERY_AGENTS ||--o{ DELIVERY_AGENT_RATINGS : receives
    
    COUPONS ||--o{ COUPON_USAGE : used_in
    
    USER_FAVORITES }o--|| RESTAURANTS : references
    
    ADMIN_USERS ||--o{ ADMIN_ACTIVITIES : performs
    ADMIN_USERS ||--o{ NOTIFICATIONS : sends
    
    NOTIFICATIONS ||--o{ USERS : "sent to"
    NOTIFICATIONS ||--o{ DELIVERY_AGENTS : "sent to"
    
    REVENUE_STATISTICS : Aggregate_Data
```

---

## Detailed Entity Descriptions

### Core Entities

#### USERS
- **Purpose**: Store customer/user data
- **Key Fields**: id, name, email, avatar, status, total_orders, total_spent
- **Relationships**:
  - ← Creates multiple ORDERS
  - ← Maintains multiple USER_ADDRESSES
  - ← Marks multiple USER_FAVORITES
  - ← Gives FOOD_ITEM_RATINGS, RESTAURANT_RATINGS, DELIVERY_AGENT_RATINGS
  - ← Uses COUPONS via COUPON_USAGE

#### RESTAURANTS
- **Purpose**: Store restaurant/vendor information
- **Key Fields**: id, name, cuisine, rating, review_count, status, is_approved
- **Relationships**:
  - → Offers multiple FOOD_ITEMS
  - → Defines OPERATING_HOURS for each day
  - ← Receives multiple RESTAURANT_RATINGS
  - ← Receives multiple ORDERS

#### CATEGORIES
- **Purpose**: Organize food items into categories
- **Key Fields**: id, name, icon, display_order
- **Relationships**:
  - → Contains multiple FOOD_ITEMS

#### FOOD_ITEMS
- **Purpose**: Store menu items from restaurants
- **Key Fields**: id, name, price, image, category_id, restaurant_id
- **Relationships**:
  - ← Belongs to RESTAURANT
  - ← Belongs to CATEGORY
  - → Part of multiple ORDER_ITEMS
  - ← Receives multiple FOOD_ITEM_RATINGS

#### DELIVERY_AGENTS
- **Purpose**: Store delivery partner information
- **Key Fields**: id, name, phone, rating, status, vehicle_type
- **Relationships**:
  - ← Assigned to multiple ORDERS
  - ← Receives multiple DELIVERY_AGENT_RATINGS

---

### Transaction Entities

#### ORDERS
- **Purpose**: Master record for each customer order
- **Key Fields**: id, user_id, restaurant_id, order_status, total_amount
- **Status Workflow**: pending → confirmed → preparing → ready → on_the_way → delivered
- **Relationships**:
  - ← Placed by USER
  - → From RESTAURANT
  - → Has multiple ORDER_ITEMS (line items)
  - → Has multiple ORDER_STATUS_HISTORY entries
  - → Assigned to optional DELIVERY_AGENT
  - → Uses optional COUPON
  - → Delivered to USER_ADDRESS

#### ORDER_ITEMS
- **Purpose**: Line items in an order
- **Key Fields**: order_id, food_item_id, quantity, unit_price, item_total
- **Relationships**:
  - ← Part of ORDER
  - → References FOOD_ITEM

#### ORDER_STATUS_HISTORY
- **Purpose**: Audit trail of order status changes
- **Key Fields**: order_id, old_status, new_status, changed_at
- **Relationships**:
  - ← Tracks changes in ORDER

---

### User Profile Entities

#### USER_ADDRESSES
- **Purpose**: Store multiple delivery addresses per user
- **Key Fields**: id, user_id, street_address, city, is_default
- **Relationships**:
  - ← Belongs to USER
  - → Used as delivery location in ORDERS

#### USER_FAVORITES
- **Purpose**: User's favorite restaurants (bookmarked)
- **Key Fields**: user_id, restaurant_id
- **Relationships**:
  - ← Created by USER
  - → References RESTAURANT

---

### Rating & Review Entities

#### FOOD_ITEM_RATINGS
- **Purpose**: User ratings for food items
- **Key Fields**: user_id, order_id, food_item_id, rating (1-5), review
- **Relationships**:
  - ← Created by USER
  - → About FOOD_ITEM
  - → References ORDER

#### RESTAURANT_RATINGS
- **Purpose**: User ratings for restaurants
- **Key Fields**: user_id, order_id, restaurant_id, rating (1-5), review
- **Relationships**:
  - ← Created by USER
  - → About RESTAURANT
  - → References ORDER

#### DELIVERY_AGENT_RATINGS
- **Purpose**: User ratings for delivery agents
- **Key Fields**: user_id, order_id, delivery_agent_id, rating (1-5), review
- **Relationships**:
  - ← Created by USER
  - → About DELIVERY_AGENT
  - → References ORDER

---

### Promotion Entities

#### COUPONS
- **Purpose**: Promotional discount codes
- **Key Fields**: id, code, discount_type, discount_value, valid_until
- **Usage Types**:
  - Fixed discount: "$10 off"
  - Percentage discount: "20% off"
- **Relationships**:
  - → Used in multiple ORDERS
  - → Tracked in COUPON_USAGE

#### COUPON_USAGE
- **Purpose**: History of coupon usage
- **Key Fields**: coupon_id, user_id, order_id, discount_applied
- **Relationships**:
  - ← From COUPON
  - ← From USER
  - ← From ORDER

---

### Administrative Entities

#### ADMIN_USERS
- **Purpose**: Store admin/moderator accounts
- **Key Fields**: id, email, role, permissions, is_active
- **Roles**: super_admin, admin, moderator
- **Relationships**:
  - → Performs ADMIN_ACTIVITIES
  - → Sends NOTIFICATIONS

#### ADMIN_ACTIVITIES
- **Purpose**: Audit log of administrative actions
- **Key Fields**: admin_id, action, entity_type, old_values, new_values
- **Examples of Actions**:
  - Create/Update/Delete restaurant
  - Approve/Reject restaurant
  - Ban user
  - Process refund
  - Create coupon
- **Relationships**:
  - ← Performed by ADMIN_USER

---

### System Entities

#### NOTIFICATIONS
- **Purpose**: In-app notifications for users, delivery agents, admins
- **Key Fields**: id, user_id, title, message, is_read, type
- **Notification Types**:
  - order_update: "Your order is being prepared"
  - promotion: "New offer available"
  - system: "Maintenance notice"
  - delivery_update: "Driver 5 mins away"
- **Relationships**:
  - → Sent to USER or DELIVERY_AGENT or ADMIN_USER

#### OPERATING_HOURS
- **Purpose**: Define when restaurants are open
- **Key Fields**: restaurant_id, day_of_week, opening_time, closing_time
- **Relationships**:
  - ← Belongs to RESTAURANT

#### REVENUE_STATISTICS
- **Purpose**: Aggregated monthly revenue data
- **Key Fields**: month_year, total_revenue, total_orders, total_users
- **Update Frequency**: Calculated monthly
- **Usage**: Dashboard analytics

---

## Relationship Types

### One-to-Many (1:N)
| Parent | Child | Cardinality |
|--------|-------|-------------|
| USER | ORDERS | 1 user → many orders |
| USER | USER_ADDRESSES | 1 user → many addresses |
| RESTAURANT | FOOD_ITEMS | 1 restaurant → many items |
| RESTAURANT | OPERATING_HOURS | 1 restaurant → 7 hours (one per day) |
| CATEGORY | FOOD_ITEMS | 1 category → many items |
| ORDER | ORDER_ITEMS | 1 order → many items |
| COUPON | COUPON_USAGE | 1 coupon → many usages |
| ADMIN_USER | ADMIN_ACTIVITIES | 1 admin → many activities |

### Many-to-Many (N:M)
| Entity 1 | Junction Table | Entity 2 | Purpose |
|----------|---|----------|---------|
| USER | USER_FAVORITES | RESTAURANT | Bookmarked restaurants |
| USER | COUPON_USAGE | COUPON | Used coupons by users |
| ORDER | ORDER_ITEMS | FOOD_ITEM | Items in an order |

### One-to-One (1:1)
| Entity 1 | Entity 2 | Condition |
|----------|----------|-----------|
| ORDER | DELIVERY_AGENT | Optional (orders may not have agent assigned) |
| ORDER | COUPON | Optional (orders may not use coupon) |
| ORDER | USER_ADDRESS | Optional (delivery address) |
| RESTAURANT_RATINGS | ORDER | Unique (one rating per order) |
| DELIVERY_AGENT_RATINGS | ORDER | Unique (one rating per order) |

---

## Data Dependencies & Business Rules

### Order Creation Rules
1. **Required Data**:
   - user_id (must be active user)
   - restaurant_id (must be open and approved)
   - delivery_address_id (user must own this address)
   - order_items (at least 1 food item)

2. **Automatic Data**:
   - order_status = 'pending'
   - created_at = CURRENT_TIMESTAMP
   - subtotal = sum of order_items prices

### Order Status Transitions
- pending → confirmed (Payment successful)
- confirmed → preparing (Restaurant confirms)
- preparing → ready (Food is ready)
- ready → on_the_way (Driver picks up)
- on_the_way → delivered (Delivered to address)
- Any status → cancelled (User or restaurant cancels)

### Rating Rules
- **Food Item Rating**: Only allowed after delivery
- **Restaurant Rating**: Only allowed after delivery (one per order)
- **Delivery Agent Rating**: Only allowed after delivery (one per order)
- **Rating Scale**: 1-5 stars

### Coupon Rules
- **Eligibility**: Must be active and within valid date range
- **Minimum Order Value**: Order subtotal must meet minimum
- **Per-User Limit**: Maximum uses per user (usually 1)
- **Global Limit**: Total usage capped (or unlimited if -1)

---

## Critical Constraints

### Foreign Key Constraints
```sql
-- Cascading deletes
- DELETE user → DELETE user_addresses, orders, favorites, ratings, coupon_usage
- DELETE restaurant → DELETE food_items, operating_hours
- DELETE order → DELETE order_items, order_status_history

-- Restricted deletes (prevent deletion)
- Cannot DELETE user if has active orders
- Cannot DELETE restaurant if has pending orders
- Cannot DELETE food_item if in pending order
- Cannot DELETE coupon if used in pending order
```

### Unique Constraints
- user.email (prevent duplicate accounts)
- restaurant.email (prevent duplicate restaurants)
- delivery_agent.email (prevent duplicate agents)
- coupon.code (prevent duplicate codes)
- user_favorites (user_id, restaurant_id) - one favorite per restaurant
- operating_hours (restaurant_id, day_of_week) - one schedule per day
- restaurant_ratings (order_id) - one rating per order
- delivery_agent_ratings (order_id) - one rating per order

### Check Constraints
- rating >= 1 AND rating <= 5
- price > 0
- total_amount >= 0
- quantity > 0

---

## Query Performance Optimization

### Recommended Indexes
```sql
-- User queries
INDEX ON users(email)
INDEX ON users(status)
INDEX ON user_addresses(user_id, is_default)

-- Restaurant discovery
INDEX ON restaurants(cuisine)
INDEX ON restaurants(rating DESC)
INDEX ON restaurants(is_approved)
INDEX ON restaurants(status)

-- Order tracking
INDEX ON orders(user_id)
INDEX ON orders(order_status)
INDEX ON orders(created_at DESC)
INDEX ON orders(delivery_agent_id)

-- Search & browse
INDEX ON food_items(restaurant_id)
INDEX ON food_items(is_popular)
INDEX ON food_items(availability)

-- Time-based queries
INDEX ON orders(created_at DESC)
INDEX ON notifications(user_id, is_read)
INDEX ON revenue_statistics(month_year)
```

### Query Patterns
```sql
-- User Dashboard (Orders)
SELECT * FROM orders 
WHERE user_id = ? 
ORDER BY created_at DESC 
LIMIT 10

-- Restaurant Browse (with Filters)
SELECT * FROM restaurants 
WHERE is_approved = TRUE 
  AND status = 'open' 
  AND cuisine = ? 
ORDER BY rating DESC

-- Food Menu (Restaurant Detail)
SELECT fi.*, c.name as category_name 
FROM food_items fi 
JOIN categories c ON fi.category_id = c.id 
WHERE fi.restaurant_id = ?

-- Recent Orders (Admin Dashboard)
SELECT o.*, u.name, r.name 
FROM orders o 
JOIN users u ON o.user_id = u.id 
JOIN restaurants r ON o.restaurant_id = r.id 
WHERE o.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
```

---

## Migration Path from Flutter App

### Phase 1: Data Modeling
✅ Completed - Schema designed based on Dart models

### Phase 2: Backend API Development
- [ ] Setup database connection pool
- [ ] Create ORM models
- [ ] Implement CRUD endpoints
- [ ] Add authentication middleware

### Phase 3: Data Migration
- [ ] Export existing mock data
- [ ] Transform to relational format
- [ ] Import to production database
- [ ] Verify data integrity

### Phase 4: API Integration
- [ ] Update Flutter app for API calls
- [ ] Implement token management
- [ ] Add offline sync capability
- [ ] Cache management

---

*Last Updated: March 24, 2026*
*Database Schema Version: 1.0*
