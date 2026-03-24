# QuickBite Database Schema - Quick Reference

## 📊 Schema Overview

**Total Tables**: 20  
**Total Relationships**: 40+  
**Primary Storage Type**: Relational Database (MySQL/PostgreSQL)  
**Total Entities**: ~5 million records (estimated at scale)  

---

## 🗂️ Table Categories

### User Management (3 tables)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `users` | Customer accounts | id, email |
| `user_addresses` | Delivery addresses | user_id, is_default |
| `user_favorites` | Bookmarked restaurants | user_id, restaurant_id |

### Business Entities (6 tables)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `restaurants` | Vendor information | id, is_approved |
| `food_items` | Menu items | restaurant_id, category_id |
| `categories` | Food categories | id, display_order |
| `delivery_agents` | Delivery partners | id, status |
| `operating_hours` | Restaurant schedules | restaurant_id, day_of_week |
| `notifications` | System messages | is_read, type |

### Order Processing (4 tables)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `orders` | Orders master | user_id, order_status |
| `order_items` | Order line items | order_id, food_item_id |
| `order_status_history` | Status audit trail | order_id, new_status |
| `coupon_usage` | Applied discounts | coupon_id, order_id |

### Promotions (1 table)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `coupons` | Discount codes | code, is_active |

### Ratings & Reviews (3 tables)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `food_item_ratings` | Food reviews | food_item_id, order_id |
| `restaurant_ratings` | Restaurant reviews | restaurant_id, order_id |
| `delivery_agent_ratings` | Delivery reviews | delivery_agent_id, order_id |

### Administration (3 tables)
| Table | Purpose | Key Field |
|-------|---------|-----------|
| `admin_users` | Admin accounts | email, role |
| `admin_activities` | Audit logs | admin_id, entity_type |
| `revenue_statistics` | Analytics | month_year |

---

## 📋 Entity Summary

### Core Entities & Their Relationships

```
USER
├─ places ──► ORDERS
│            ├─ contains ──► ORDER_ITEMS ──► FOOD_ITEMS
│            ├─ includes ──► ORDER_STATUS_HISTORY
│            ├─ uses ──► COUPON
│            └─ assigned to ──► DELIVERY_AGENT
├─ has ──► USER_ADDRESSES
├─ marks ──► USER_FAVORITES ──► RESTAURANTS
└─ gives ──► RATINGS (Food, Restaurant, Delivery Agent)

RESTAURANT
├─ offers ──► FOOD_ITEMS
│            ├─ in category ──► CATEGORIES
│            └─ rated by ──► FOOD_ITEM_RATINGS
├─ has ──► OPERATING_HOURS
└─ receives ──► RESTAURANT_RATINGS

DELIVERY_AGENT
├─ assigned to ──► ORDERS
└─ receives ──► DELIVERY_AGENT_RATINGS

COUPON
└─ tracked in ──► COUPON_USAGE
```

---

## 🔄 Order Lifecycle

```
PENDING
    ↓ (Payment verified)
CONFIRMED
    ↓ (Restaurant accepts)
PREPARING
    ↓ (Food ready)
READY
    ↓ (Driver picks up)
ON_THE_WAY
    ↓ (Delivered)
DELIVERED ──► User can rate
    ↓
CLOSED

Alternative paths:
    Any ──► CANCELLED (by user or restaurant)
    Any ──► REFUNDED (by admin)
```

---

## 💾 Data Schema Cheat Sheet

### Common Query Patterns

#### Get User's Orders
```sql
SELECT o.*, r.name as restaurant_name, 
       oi.*, f.name as food_name
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN food_items f ON oi.food_item_id = f.id
WHERE o.user_id = ? AND o.deleted_at IS NULL
ORDER BY o.created_at DESC;
```

#### Browse Restaurants
```sql
SELECT r.*, COUNT(DISTINCT o.id) as total_orders,
       AVG(rr.rating) as avg_rating
FROM restaurants r
LEFT JOIN orders o ON r.id = o.restaurant_id
LEFT JOIN restaurant_ratings rr ON r.id = rr.restaurant_id
WHERE r.is_approved = TRUE AND r.status = 'open'
GROUP BY r.id
ORDER BY avg_rating DESC, total_orders DESC;
```

#### Get Restaurant Menu
```sql
SELECT f.*, c.name as category_name,
       AVG(fir.rating) as avg_rating,
       COUNT(fir.id) as review_count
FROM food_items f
JOIN categories c ON f.category_id = c.id
LEFT JOIN food_item_ratings fir ON f.id = fir.food_item_id
WHERE f.restaurant_id = ?
GROUP BY f.id
ORDER BY c.display_order, f.name;
```

#### Calculate Order Total
```sql
SELECT SUM(oi.item_total) as subtotal,
       o.delivery_fee,
       o.tax_amount,
       o.discount_amount,
       (SUM(oi.item_total) + o.delivery_fee + 
        o.tax_amount - o.discount_amount) as total
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
WHERE o.id = ?
GROUP BY o.id;
```

---

## 📈 Performance Metrics

### Index Coverage
- ✅ All foreign keys indexed
- ✅ Status fields indexed (frequently filtered)
- ✅ Time-based queries optimized
- ✅ Composite indexes for common joins

### Expected Query Times
| Query | Latency |
|-------|---------|
| User login (email lookup) | < 10ms |
| Browse restaurants (100 results) | < 50ms |
| Get order details with items | < 20ms |
| List user orders (paginated) | < 30ms |
| Admin dashboard (aggregated) | < 200ms |

---

## 🔐 Security Features

### Data Protection
- ✅ Soft deletes for audit trails
- ✅ Password hashing (SHA-256/bcrypt)
- ✅ Admin audit logging
- ✅ IP address tracking
- ✅ Rate limiting (via API layer)

### Access Control
- Role-based: super_admin, admin, moderator
- User data isolation: users only see their own data
- Restaurant data: owner-specific access
- Delivery agent: only assigned order visibility

---

## 📊 Analytics Views

### Available Dashboard Queries

```
Active Users
├─ Total active users
├─ New users this month
├─ Active orders
└─ Orders pending delivery

Restaurant Performance
├─ Top restaurants by rating
├─ Top restaurants by orders
├─ Revenue by restaurant
└─ Most popular cuisines

Order Analytics
├─ Orders by status
├─ Average order value
├─ Orders by payment method
└─ Peak order times

Delivery Performance
├─ Available delivery agents
├─ Average delivery time
├─ Delivery agent ratings
└─ On-time delivery rate

Revenue Insights
├─ Monthly revenue
├─ Commission earned
├─ Refunds processed
└─ Average order value trend
```

---

## 🚀 Scalability Considerations

### Current Design Supports
- ✅ Millions of orders
- ✅ Hundreds of thousands of users
- ✅ Tens of thousands of restaurants
- ✅ Horizontal scaling via read replicas
- ✅ Sharding by user_id for massive scale

### Future Optimization
- **Denormalization**: Pre-calculate aggregate ratings
- **Caching**: Redis for menu, ratings, operating hours
- **Archiving**: Move old orders to separate storage
- **Partitioning**: Orders table by month
- **Search Index**: Elasticsearch for restaurant search

---

## 📝 Database Setup Instructions

### 1. Create Database
```sql
CREATE DATABASE quickbite CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quickbite;
```

### 2. Import Schema
```bash
mysql -u root -p quickbite < database_schema.sql
```

### 3. Create Indexes
```sql
-- All indexes are included in database_schema.sql
-- Execute as part of schema creation
```

### 4. Initialize Sample Data
```sql
-- Insert categories
INSERT INTO categories (id, name, icon, display_order) VALUES
('cat-1', 'Pizza', 'pizza.svg', 1),
('cat-2', 'Burgers', 'burger.svg', 2),
('cat-3', 'Pasta', 'pasta.svg', 3);

-- Insert test restaurant
INSERT INTO restaurants (id, name, cuisine, image, rating, status, is_approved) VALUES
('rest-1', 'Pizza Palace', 'Italian', 'pizza.jpg', 4.5, 'open', true);

-- Insert sample menu items
INSERT INTO food_items (id, restaurant_id, category_id, name, price, image) VALUES
('food-1', 'rest-1', 'cat-1', 'Margherita Pizza', 12.99, 'marg.jpg');
```

### 5. Verify Setup
```sql
-- Check all tables
SHOW TABLES;

-- Check table structure
DESCRIBE users;

-- Check sample data
SELECT COUNT(*) FROM restaurants;
```

---

## 🔄 Data Synchronization

### Keeping Data Consistent

#### Order Total Recalculation
```sql
-- Trigger to update order totals on item changes
CREATE TRIGGER update_order_total AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
  UPDATE orders SET subtotal = (
    SELECT SUM(item_total) FROM order_items WHERE order_id = NEW.order_id
  ) WHERE id = NEW.order_id;
END;
```

#### User Statistics Update
```sql
-- Update user stats after order completion
UPDATE users 
SET total_orders = total_orders + 1,
    total_spent = total_spent + (SELECT total_amount FROM orders WHERE id = ?)
WHERE id = (SELECT user_id FROM orders WHERE id = ?);
```

#### Restaurant Rating Recalculation
```sql
-- Update restaurant rating from ratings
UPDATE restaurants
SET rating = (
  SELECT AVG(rating) FROM restaurant_ratings WHERE restaurant_id = ?
),
review_count = (
  SELECT COUNT(*) FROM restaurant_ratings WHERE restaurant_id = ?
)
WHERE id = ?;
```

---

## 📂 File Structure

The database schema is provided in three formats:

1. **DATABASE_SCHEMA.md** - Comprehensive documentation with explanations
2. **database_schema.sql** - Executable SQL file (MySQL/PostgreSQL)
3. **ER_DIAGRAM.md** - Entity relationships and business rules
4. **SCHEMA_QUICK_REFERENCE.md** - This file

---

## 🔗 Integration Checklist

- [ ] Database created and schema installed
- [ ] Test data inserted for development
- [ ] Connection pooling configured
- [ ] Backup strategy implemented
- [ ] Monitoring queries set up
- [ ] API endpoints developed
- [ ] Order transaction handling implemented
- [ ] Notification system integrated
- [ ] Admin panel connected
- [ ] Analytics dashboard configured
- [ ] Mobile app connected to API
- [ ] Webhook handlers for payment/delivery

---

## 📞 Support & Reference

### Common Troubleshooting

**Issue**: Foreign key constraint error
**Solution**: Check parent record exists before inserting child

**Issue**: Duplicate coupon code
**Solution**: UNIQUE constraint prevents duplicates

**Issue**: Order total mismatch
**Solution**: Use calculated field from ORDER_ITEMS

**Issue**: Slow dashboard queries
**Solution**: Use pre-calculated REVENUE_STATISTICS table

---

*Database Schema Documentation*  
*QuickBite - Food Delivery Platform*  
*Version 1.0 - March 24, 2026*
