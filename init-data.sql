-- QuickBite Sample Data Initialization
-- This file populates the database with sample data for testing

-- ============================================================================
-- Categories
-- ============================================================================
INSERT INTO categories (id, name, description, icon, display_order, is_active) VALUES
('cat-1', 'Pizza', 'Delicious wood-fired pizzas', 'pizza.svg', 1, true),
('cat-2', 'Burgers', 'Juicy beef and chicken burgers', 'burger.svg', 2, true),
('cat-3', 'Pasta', 'Authentic Italian pasta dishes', 'pasta.svg', 3, true),
('cat-4', 'Salads', 'Fresh and healthy salads', 'salad.svg', 4, true),
('cat-5', 'Desserts', 'Sweet treats and desserts', 'dessert.svg', 5, true),
('cat-6', 'Beverages', 'Drinks and beverages', 'drink.svg', 6, true);

-- ============================================================================
-- Sample Users
-- ============================================================================
INSERT INTO users (id, name, email, password_hash, avatar, phone, status, total_orders, total_spent, joined_at, last_login) VALUES
('user-1', 'John Doe', 'john@example.com', '$2b$10$YourHashedPasswordHere1', 'https://api.example.com/avatars/john.jpg', '+1234567890', 'active', 5, 120.50, NOW(), NOW()),
('user-2', 'Jane Smith', 'jane@example.com', '$2b$10$YourHashedPasswordHere2', 'https://api.example.com/avatars/jane.jpg', '+1234567891', 'active', 12, 342.75, NOW(), NOW()),
('user-3', 'Bob Wilson', 'bob@example.com', '$2b$10$YourHashedPasswordHere3', 'https://api.example.com/avatars/bob.jpg', '+1234567892', 'active', 8, 198.30, NOW(), NOW());

-- ============================================================================
-- Sample User Addresses
-- ============================================================================
INSERT INTO user_addresses (id, user_id, label, street_address, city, state, postal_code, country, latitude, longitude, is_default) VALUES
('addr-1', 'user-1', 'Home', '123 Main Street', 'New York', 'NY', '10001', 'USA', 40.7128, -74.0060, true),
('addr-2', 'user-1', 'Work', '456 Park Avenue', 'New York', 'NY', '10002', 'USA', 40.7489, -73.9680, false),
('addr-3', 'user-2', 'Home', '789 Oak Lane', 'Los Angeles', 'CA', '90001', 'USA', 34.0522, -118.2437, true),
('addr-4', 'user-3', 'Home', '321 Elm Street', 'Chicago', 'IL', '60601', 'USA', 41.8781, -87.6298, true);

-- ============================================================================
-- Sample Restaurants
-- ============================================================================
INSERT INTO restaurants (id, name, description, image, cuisine, rating, review_count, delivery_time, delivery_fee, price_range, is_popular, status, is_approved, total_orders, total_revenue, owner_id, phone, email, street_address, city, state, postal_code, latitude, longitude) VALUES
('rest-1', 'Pizza Palace', 'Authentic Italian pizzas with fresh ingredients', 'https://api.example.com/images/pizza-palace.jpg', 'Italian', 4.8, 156, '25-35 mins', 2.99, '$$', true, 'open', true, 342, 5420.50, 'owner-1', '+1-555-0101', 'contact@pizzapalace.com', '100 Pizza Street', 'New York', 'NY', '10001', 40.7150, -74.0050),
('rest-2', 'Burger King Local', 'Premium burgers and fries', 'https://api.example.com/images/burger-king.jpg', 'American', 4.6, 98, '20-30 mins', 1.99, '$', true, 'open', true, 267, 3210.75, 'owner-2', '+1-555-0102', 'contact@burgerking.com', '200 Burger Ave', 'New York', 'NY', '10002', 40.7160, -74.0040),
('rest-3', 'Pasta Italia', 'Authentic Italian pasta restaurant', 'https://api.example.com/images/pasta-italia.jpg', 'Italian', 4.9, 213, '30-40 mins', 3.99, '$$$', true, 'open', true, 456, 8920.30, 'owner-3', '+1-555-0103', 'contact@pastaitalia.com', '150 Pasta Lane', 'New York', 'NY', '10003', 40.7170, -74.0030),
('rest-4', 'Fresh & Fit Salads', 'Healthy salads and bowls', 'https://api.example.com/images/fresh-fit.jpg', 'Health Food', 4.7, 124, '15-20 mins', 0.99, '$$', false, 'open', true, 189, 2156.80, 'owner-4', '+1-555-0104', 'contact@freshandfit.com', '300 Organic Way', 'New York', 'NY', '10004', 40.7180, -74.0020);

-- ============================================================================
-- Sample Food Items
-- ============================================================================
INSERT INTO food_items (id, restaurant_id, category_id, name, description, price, image, rating, review_count, is_popular, is_vegetarian, is_vegan, is_gluten_free, availability, orders_count) VALUES
-- Pizza Palace menu
('food-1', 'rest-1', 'cat-1', 'Margherita Pizza', 'Classic pizza with tomato, mozzarella, and basil', 12.99, 'https://api.example.com/images/margherita.jpg', 4.8, 89, true, true, false, false, 'available', 245),
('food-2', 'rest-1', 'cat-1', 'Pepperoni Pizza', 'Traditional pizza topped with pepperoni', 14.99, 'https://api.example.com/images/pepperoni.jpg', 4.7, 76, true, false, false, false, 'available', 198),
('food-3', 'rest-1', 'cat-6', 'Italian Soda', 'Refreshing Italian soda drink', 3.99, 'https://api.example.com/images/soda.jpg', 4.5, 34, false, true, true, true, 'available', 142),

-- Burger King menu
('food-4', 'rest-2', 'cat-2', 'Classic Burger', 'Juicy beef burger with lettuce and tomato', 9.99, 'https://api.example.com/images/classic-burger.jpg', 4.6, 67, true, false, false, false, 'available', 156),
('food-5', 'rest-2', 'cat-2', 'Chicken Burger', 'Grilled chicken breast burger', 10.99, 'https://api.example.com/images/chicken-burger.jpg', 4.5, 45, false, false, false, false, 'available', 98),
('food-6', 'rest-2', 'cat-1', 'Loaded Fries', 'French fries with cheese and bacon', 6.99, 'https://api.example.com/images/fries.jpg', 4.7, 52, true, false, false, false, 'available', 134),

-- Pasta Italia menu
('food-7', 'rest-3', 'cat-3', 'Spaghetti Carbonara', 'Creamy spaghetti with pancetta and egg', 16.99, 'https://api.example.com/images/carbonara.jpg', 4.9, 123, true, false, false, false, 'available', 267),
('food-8', 'rest-3', 'cat-3', 'Fettuccine Alfredo', 'Fettuccine in rich Alfredo sauce', 15.99, 'https://api.example.com/images/alfredo.jpg', 4.8, 98, true, true, false, false, 'available', 189),
('food-9', 'rest-3', 'cat-5', 'Tiramisu', 'Classic Italian tiramisu dessert', 7.99, 'https://api.example.com/images/tiramisu.jpg', 4.9, 145, true, true, false, false, 'available', 234),

-- Fresh & Fit menu
('food-10', 'rest-4', 'cat-4', 'Caesar Salad', 'Fresh romaine lettuce with Caesar dressing', 11.99, 'https://api.example.com/images/caesar.jpg', 4.7, 56, true, true, false, false, 'available', 89),
('food-11', 'rest-4', 'cat-4', 'Quinoa Buddha Bowl', 'Healthy quinoa bowl with vegetables', 13.99, 'https://api.example.com/images/buddha-bowl.jpg', 4.8, 78, true, true, true, true, 'available', 156);

-- ============================================================================
-- Sample Delivery Agents
-- ============================================================================
INSERT INTO delivery_agents (id, name, email, password_hash, phone, avatar, vehicle_type, vehicle_number, rating, review_count, total_deliveries, status, is_verified, is_active, bank_account_number, bank_ifsc_code, total_earnings) VALUES
('agent-1', 'Mike Johnson', 'mike@delivery.com', '$2b$10$YourHashedPasswordHere1', '+1-555-0201', 'https://api.example.com/avatars/mike.jpg', 'bike', 'BIKE-001', 4.9, 234, 567, 'online', true, true, '987654321', 'IFSC001', 5670.50),
('agent-2', 'Sarah Davis', 'sarah@delivery.com', '$2b$10$YourHashedPasswordHere2', '+1-555-0202', 'https://api.example.com/avatars/sarah.jpg', 'scooter', 'SCOOTER-001', 4.8, 189, 456, 'online', true, true, '876543210', 'IFSC002', 4560.75),
('agent-3', 'David Lee', 'david@delivery.com', '$2b$10$YourHashedPasswordHere3', '+1-555-0203', 'https://api.example.com/avatars/david.jpg', 'car', 'CAR-001', 4.7, 145, 345, 'offline', true, true, '765432109', 'IFSC003', 3450.30);

-- ============================================================================
-- Sample Orders
-- ============================================================================
INSERT INTO orders (id, user_id, restaurant_id, delivery_address_id, delivery_agent_id, coupon_id, subtotal, delivery_fee, discount_amount, tax_amount, total_amount, payment_method, payment_status, order_status, estimated_delivery_time, actual_delivery_time, rating_given) VALUES
('order-1', 'user-1', 'rest-1', 'addr-1', 'agent-1', NULL, 27.98, 2.99, 0, 2.40, 33.37, 'credit_card', 'completed', 'delivered', NOW() + INTERVAL '30 minutes', NOW() + INTERVAL '32 minutes', true),
('order-2', 'user-2', 'rest-3', 'addr-3', 'agent-2', NULL, 32.98, 3.99, 0, 2.88, 39.85, 'digital_wallet', 'completed', 'delivered', NOW() + INTERVAL '35 minutes', NOW() + INTERVAL '34 minutes', true),
('order-3', 'user-3', 'rest-2', 'addr-4', NULL, NULL, 16.98, 1.99, 0, 1.50, 20.47, 'cash', 'pending', 'pending', NOW() + INTERVAL '25 minutes', NULL, false),
('order-4', 'user-1', 'rest-4', 'addr-1', 'agent-3', NULL, 25.98, 0.99, 0, 2.27, 29.24, 'debit_card', 'completed', 'delivered', NOW() + INTERVAL '20 minutes', NOW() + INTERVAL '19 minutes', true);

-- ============================================================================
-- Sample Order Items
-- ============================================================================
INSERT INTO order_items (id, order_id, food_item_id, quantity, unit_price, item_total, special_instructions) VALUES
('order-item-1', 'order-1', 'food-1', 2, 12.99, 25.98, 'Extra basil please'),
('order-item-2', 'order-1', 'food-3', 1, 3.99, 3.99, 'No ice'),
('order-item-3', 'order-2', 'food-7', 1, 16.99, 16.99, 'Al dente'),
('order-item-4', 'order-2', 'food-9', 1, 7.99, 7.99, 'Extra cream'),
('order-item-5', 'order-3', 'food-4', 2, 9.99, 19.98, 'No onions'),
('order-item-6', 'order-4', 'food-10', 2, 11.99, 23.98, 'Dressing on the side');

-- ============================================================================
-- Sample Order Status History
-- ============================================================================
INSERT INTO order_status_history (id, order_id, old_status, new_status, reason) VALUES
('history-1', 'order-1', 'pending', 'confirmed', 'Payment received'),
('history-2', 'order-1', 'confirmed', 'preparing', 'Order accepted by restaurant'),
('history-3', 'order-1', 'preparing', 'ready', 'Food is ready for pickup'),
('history-4', 'order-1', 'ready', 'on_the_way', 'Driver picked up order'),
('history-5', 'order-1', 'on_the_way', 'delivered', 'Order delivered'),
('history-6', 'order-2', 'pending', 'confirmed', 'Payment received'),
('history-7', 'order-2', 'confirmed', 'preparing', 'Order accepted by restaurant'),
('history-8', 'order-2', 'preparing', 'ready', 'Food is ready for pickup'),
('history-9', 'order-2', 'ready', 'on_the_way', 'Driver picked up order'),
('history-10', 'order-2', 'on_the_way', 'delivered', 'Order delivered');

-- ============================================================================
-- Sample Operating Hours
-- ============================================================================
INSERT INTO operating_hours (id, restaurant_id, day_of_week, opening_time, closing_time, is_closed) VALUES
-- Pizza Palace
('hours-1', 'rest-1', 'Monday', '10:00', '23:00', false),
('hours-2', 'rest-1', 'Tuesday', '10:00', '23:00', false),
('hours-3', 'rest-1', 'Wednesday', '10:00', '23:00', false),
('hours-4', 'rest-1', 'Thursday', '10:00', '23:00', false),
('hours-5', 'rest-1', 'Friday', '10:00', '00:00', false),
('hours-6', 'rest-1', 'Saturday', '11:00', '00:00', false),
('hours-7', 'rest-1', 'Sunday', '11:00', '23:00', false),
-- Burger King
('hours-8', 'rest-2', 'Monday', '09:00', '22:00', false),
('hours-9', 'rest-2', 'Tuesday', '09:00', '22:00', false),
('hours-10', 'rest-2', 'Wednesday', '09:00', '22:00', false),
('hours-11', 'rest-2', 'Thursday', '09:00', '22:00', false),
('hours-12', 'rest-2', 'Friday', '09:00', '23:00', false),
('hours-13', 'rest-2', 'Saturday', '10:00', '23:00', false),
('hours-14', 'rest-2', 'Sunday', '10:00', '22:00', false),
-- Pasta Italia
('hours-15', 'rest-3', 'Monday', '11:00', '23:00', false),
('hours-16', 'rest-3', 'Tuesday', '11:00', '23:00', false),
('hours-17', 'rest-3', 'Wednesday', '11:00', '23:00', false),
('hours-18', 'rest-3', 'Thursday', '11:00', '23:00', false),
('hours-19', 'rest-3', 'Friday', '11:00', '00:00', false),
('hours-20', 'rest-3', 'Saturday', '12:00', '00:00', false),
('hours-21', 'rest-3', 'Sunday', '12:00', '23:00', false),
-- Fresh & Fit
('hours-22', 'rest-4', 'Monday', '08:00', '20:00', false),
('hours-23', 'rest-4', 'Tuesday', '08:00', '20:00', false),
('hours-24', 'rest-4', 'Wednesday', '08:00', '20:00', false),
('hours-25', 'rest-4', 'Thursday', '08:00', '20:00', false),
('hours-26', 'rest-4', 'Friday', '08:00', '21:00', false),
('hours-27', 'rest-4', 'Saturday', '09:00', '21:00', false),
('hours-28', 'rest-4', 'Sunday', '09:00', '20:00', false);

-- ============================================================================
-- Sample User Favorites
-- ============================================================================
INSERT INTO user_favorites (id, user_id, restaurant_id) VALUES
('fav-1', 'user-1', 'rest-1'),
('fav-2', 'user-1', 'rest-3'),
('fav-3', 'user-2', 'rest-1'),
('fav-4', 'user-2', 'rest-4'),
('fav-5', 'user-3', 'rest-2');

-- ============================================================================
-- Sample Coupons
-- ============================================================================
INSERT INTO coupons (id, code, description, discount_type, discount_value, max_discount, min_order_value, max_usage, current_usage, usage_per_user, valid_from, valid_until, is_active) VALUES
('coupon-1', 'WELCOME20', '20% off on first order', 'percentage', 20.00, 10.00, 20.00, 100, 5, 1, NOW(), NOW() + INTERVAL '90 days', true),
('coupon-2', 'SAVE5', '$5 off orders over $30', 'fixed', 5.00, NULL, 30.00, -1, 12, 1, NOW(), NOW() + INTERVAL '60 days', true),
('coupon-3', 'WEEKEND15', '15% off on weekends', 'percentage', 15.00, 25.00, 25.00, 200, 34, 2, NOW(), NOW() + INTERVAL '30 days', true);

-- ============================================================================
-- Sample Ratings
-- ============================================================================
INSERT INTO food_item_ratings (id, food_item_id, order_id, user_id, rating, review) VALUES
('rating-1', 'food-1', 'order-1', 'user-1', 5, 'Excellent pizza! Very fresh ingredients'),
('rating-2', 'food-3', 'order-1', 'user-1', 4, 'Good taste, a bit warm by delivery'),
('rating-3', 'food-7', 'order-2', 'user-2', 5, 'Perfect carbonara! Just like in Italy'),
('rating-4', 'food-9', 'order-2', 'user-2', 5, 'Delicious tiramisu, highly recommend');

INSERT INTO restaurant_ratings (id, restaurant_id, order_id, user_id, rating, review) VALUES
('rest-rating-1', 'rest-1', 'order-1', 'user-1', 5, 'Amazing service and quick delivery!'),
('rest-rating-2', 'rest-3', 'order-2', 'user-2', 5, 'Best Italian restaurant in town');

INSERT INTO delivery_agent_ratings (id, delivery_agent_id, order_id, user_id, rating, review) VALUES
('agent-rating-1', 'agent-1', 'order-1', 'user-1', 5, 'Driver was very friendly and quick'),
('agent-rating-2', 'agent-2', 'order-2', 'user-2', 5, 'Professional and courteous delivery');

-- ============================================================================
-- Sample Admin Users
-- ============================================================================
INSERT INTO admin_users (id, name, email, password_hash, role, is_active) VALUES
('admin-1', 'Admin User', 'admin@quickbite.com', '$2b$10$YourHashedPasswordHere1', 'super_admin', true),
('admin-2', 'Support Manager', 'support@quickbite.com', '$2b$10$YourHashedPasswordHere2', 'admin', true);

-- ============================================================================
-- Sample Revenue Statistics
-- ============================================================================
INSERT INTO revenue_statistics (id, month_year, total_revenue, total_orders, total_users, average_order_value, total_refunds, commission_earned) VALUES
(
    'stats-1',
    DATE_TRUNC('month', CURRENT_DATE),
    15678.50,
    456,
    123,
    34.37,
    125.00,
    1567.85
),
(
    'stats-2',
    DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month'),
    12450.75,
    378,
    98,
    32.95,
    89.50,
    1245.08
);

-- ============================================================================
-- Commit
-- ============================================================================
COMMIT;

-- Verify data was inserted
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Restaurants', COUNT(*) FROM restaurants
UNION ALL
SELECT 'Food Items', COUNT(*) FROM food_items
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'Delivery Agents', COUNT(*) FROM delivery_agents
UNION ALL
SELECT 'Categories', COUNT(*) FROM categories;
