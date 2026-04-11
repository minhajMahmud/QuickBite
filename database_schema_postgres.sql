-- QuickBite Database Schema (PostgreSQL Native)
-- Created: March 24, 2026

-- ============================================================================
-- SAFETY / SETUP
-- ============================================================================
SET client_min_messages TO WARNING;

DO $$
BEGIN
    IF current_database() <> 'quickbite' THEN
        RAISE EXCEPTION 'This script must be run on database "quickbite". Current database is "%".', current_database();
    END IF;
END $$;

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'restaurant', 'delivery_partner', 'admin')),
    approved BOOLEAN NOT NULL DEFAULT TRUE,
    avatar VARCHAR(500),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(30),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
    total_orders INT NOT NULL DEFAULT 0,
    total_spent NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- ============================================================================
-- 2. USER_ADDRESSES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_addresses (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    label VARCHAR(50),
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    country VARCHAR(100),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_addresses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 3. CATEGORIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(500),
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. RESTAURANTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurants (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image VARCHAR(500),
    cuisine VARCHAR(100),
    rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    review_count INT NOT NULL DEFAULT 0,
    delivery_time VARCHAR(50),
    delivery_fee NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    price_range VARCHAR(4) NOT NULL DEFAULT '$$' CHECK (price_range IN ('$', '$$', '$$$', '$$$$')),
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'closed' CHECK (status IN ('open', 'closed')),
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    total_orders INT NOT NULL DEFAULT 0,
    total_revenue NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    owner_id VARCHAR(36),
    phone VARCHAR(20),
    email VARCHAR(255),
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- ============================================================================
-- 5. FOOD_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS food_items (
    id VARCHAR(36) PRIMARY KEY,
    restaurant_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    image VARCHAR(500),
    rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    review_count INT NOT NULL DEFAULT 0,
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    is_vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
    is_vegan BOOLEAN NOT NULL DEFAULT FALSE,
    is_gluten_free BOOLEAN NOT NULL DEFAULT FALSE,
    availability VARCHAR(20) NOT NULL DEFAULT 'available' CHECK (availability IN ('available', 'unavailable', 'out_of_stock')),
    orders_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_food_items_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    CONSTRAINT fk_food_items_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
);

-- ============================================================================
-- 6. DELIVERY_AGENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS delivery_agents (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    avatar VARCHAR(500),
    vehicle_type VARCHAR(20) NOT NULL DEFAULT 'bike' CHECK (vehicle_type IN ('bike', 'scooter', 'car')),
    vehicle_number VARCHAR(50),
    rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    review_count INT NOT NULL DEFAULT 0,
    total_deliveries INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'on_delivery', 'break')),
    current_latitude NUMERIC(10, 8),
    current_longitude NUMERIC(11, 8),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    bank_account_number VARCHAR(50),
    bank_ifsc_code VARCHAR(20),
    total_earnings NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP
);

-- ============================================================================
-- 7. COUPONS TABLE (before orders to allow FK)
-- ============================================================================
CREATE TABLE IF NOT EXISTS coupons (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL DEFAULT 'fixed' CHECK (discount_type IN ('fixed', 'percentage')),
    discount_value NUMERIC(10, 2) NOT NULL,
    max_discount NUMERIC(10, 2),
    min_order_value NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    max_usage INT NOT NULL DEFAULT -1,
    current_usage INT NOT NULL DEFAULT 0,
    usage_per_user INT NOT NULL DEFAULT 1,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(36),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    restaurant_id VARCHAR(36) NOT NULL,
    delivery_address_id VARCHAR(36),
    delivery_agent_id VARCHAR(36),
    coupon_id VARCHAR(36),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee NUMERIC(8, 2) NOT NULL DEFAULT 0.00 CHECK (delivery_fee >= 0),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    payment_method VARCHAR(20) NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('credit_card', 'debit_card', 'digital_wallet', 'cash')),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    order_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'preparing', 'ready', 'on_the_way', 'delivered', 'cancelled')),
    special_instructions TEXT,
    estimated_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    rating_given BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_delivery_address FOREIGN KEY (delivery_address_id) REFERENCES user_addresses(id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_delivery_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL
);

-- ============================================================================
-- 9. ORDER_ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS order_items (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL,
    food_item_id VARCHAR(36) NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    item_total NUMERIC(12, 2) NOT NULL CHECK (item_total >= 0),
    special_instructions TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_food_item FOREIGN KEY (food_item_id) REFERENCES food_items(id) ON DELETE RESTRICT
);

-- ============================================================================
-- 10. ORDER_STATUS_HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS order_status_history (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by VARCHAR(36),
    reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_status_history_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ============================================================================
-- 11. OPERATING_HOURS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS operating_hours (
    id VARCHAR(36) PRIMARY KEY,
    restaurant_id VARCHAR(36) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    opening_time TIME NOT NULL,
    closing_time TIME NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_operating_hours_restaurant_day UNIQUE (restaurant_id, day_of_week),
    CONSTRAINT fk_operating_hours_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);

-- ============================================================================
-- 12. USER_FAVORITES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_favorites (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    restaurant_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_favorites_user_restaurant UNIQUE (user_id, restaurant_id),
    CONSTRAINT fk_user_favorites_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_favorites_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
);

-- ============================================================================
-- 13. COUPON_USAGE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS coupon_usage (
    id VARCHAR(36) PRIMARY KEY,
    coupon_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    order_id VARCHAR(36) NOT NULL,
    discount_applied NUMERIC(12, 2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coupon_usage_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE,
    CONSTRAINT fk_coupon_usage_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_coupon_usage_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- ============================================================================
-- 14. FOOD_ITEM_RATINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS food_item_ratings (
    id VARCHAR(36) PRIMARY KEY,
    food_item_id VARCHAR(36) NOT NULL,
    order_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_food_item_ratings_food_item FOREIGN KEY (food_item_id) REFERENCES food_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_food_item_ratings_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_food_item_ratings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 15. RESTAURANT_RATINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS restaurant_ratings (
    id VARCHAR(36) PRIMARY KEY,
    restaurant_id VARCHAR(36) NOT NULL,
    order_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_restaurant_ratings_order UNIQUE (order_id),
    CONSTRAINT fk_restaurant_ratings_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    CONSTRAINT fk_restaurant_ratings_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_restaurant_ratings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 16. DELIVERY_AGENT_RATINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS delivery_agent_ratings (
    id VARCHAR(36) PRIMARY KEY,
    delivery_agent_id VARCHAR(36) NOT NULL,
    order_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_delivery_agent_ratings_order UNIQUE (order_id),
    CONSTRAINT fk_delivery_agent_ratings_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_agent_ratings_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_agent_ratings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 17. DELIVERY_REQUESTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS delivery_requests (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL,
    delivery_partner_id VARCHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    rejection_reason TEXT,
    responded_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_delivery_requests_order_partner UNIQUE (order_id, delivery_partner_id),
    CONSTRAINT fk_delivery_requests_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_requests_partner FOREIGN KEY (delivery_partner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 17. ADMIN_USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin_users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (role IN ('super_admin', 'admin', 'moderator')),
    avatar VARCHAR(500),
    permissions JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 18. ADMIN_ACTIVITIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin_activities (
    id VARCHAR(36) PRIMARY KEY,
    admin_id VARCHAR(36) NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id VARCHAR(36),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_admin_activities_admin FOREIGN KEY (admin_id) REFERENCES admin_users(id) ON DELETE RESTRICT
);

-- ============================================================================
-- 19. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    delivery_agent_id VARCHAR(36),
    admin_id VARCHAR(36),
    type VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id VARCHAR(36),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    action_url VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    CONSTRAINT chk_notifications_target CHECK (
        user_id IS NOT NULL
        OR delivery_agent_id IS NOT NULL
        OR admin_id IS NOT NULL
    ),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_delivery_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_admin FOREIGN KEY (admin_id) REFERENCES admin_users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 20. REVENUE_STATISTICS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS revenue_statistics (
    id VARCHAR(36) PRIMARY KEY,
    month_year DATE NOT NULL UNIQUE,
    total_revenue NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    total_orders INT NOT NULL DEFAULT 0,
    total_users INT NOT NULL DEFAULT 0,
    average_order_value NUMERIC(12, 2),
    total_refunds NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    commission_earned NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_role_approved ON users(role, approved);

CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_default ON user_addresses(user_id, is_default);

CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_display_order ON categories(display_order);

CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON restaurants(cuisine);
CREATE INDEX IF NOT EXISTS idx_restaurants_status ON restaurants(status);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_approved ON restaurants(is_approved);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_popular ON restaurants(is_popular);
CREATE INDEX IF NOT EXISTS idx_restaurants_rating ON restaurants(rating DESC);

CREATE INDEX IF NOT EXISTS idx_food_items_restaurant_id ON food_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_food_items_category_id ON food_items(category_id);
CREATE INDEX IF NOT EXISTS idx_food_items_is_popular ON food_items(is_popular);
CREATE INDEX IF NOT EXISTS idx_food_items_availability ON food_items(availability);

CREATE INDEX IF NOT EXISTS idx_delivery_agents_status ON delivery_agents(status);
CREATE INDEX IF NOT EXISTS idx_delivery_agents_is_verified ON delivery_agents(is_verified);
CREATE INDEX IF NOT EXISTS idx_delivery_agents_is_active ON delivery_agents(is_active);

CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_is_active ON coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_coupons_valid_period ON coupons(valid_from, valid_until);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_agent_id ON orders(delivery_agent_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_food_item_id ON order_items(food_item_id);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

CREATE INDEX IF NOT EXISTS idx_operating_hours_restaurant_id ON operating_hours(restaurant_id);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);

CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon_id ON coupon_usage(coupon_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_user_id ON coupon_usage(user_id);

CREATE INDEX IF NOT EXISTS idx_food_item_ratings_food_item_id ON food_item_ratings(food_item_id);
CREATE INDEX IF NOT EXISTS idx_food_item_ratings_user_id ON food_item_ratings(user_id);

CREATE INDEX IF NOT EXISTS idx_restaurant_ratings_restaurant_id ON restaurant_ratings(restaurant_id);

CREATE INDEX IF NOT EXISTS idx_delivery_agent_ratings_agent_id ON delivery_agent_ratings(delivery_agent_id);

CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_is_active ON admin_users(is_active);

CREATE INDEX IF NOT EXISTS idx_admin_activities_admin_id ON admin_activities(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activities_created_at ON admin_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_activities_entity ON admin_activities(entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_delivery_agent_id ON notifications(delivery_agent_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_revenue_statistics_month_year ON revenue_statistics(month_year);

-- ============================================================================
-- UPDATED_AT TRIGGER FOR TABLES THAT HAVE updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_user_addresses_updated_at ON user_addresses;
CREATE TRIGGER trg_user_addresses_updated_at
BEFORE UPDATE ON user_addresses
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_categories_updated_at ON categories;
CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_restaurants_updated_at ON restaurants;
CREATE TRIGGER trg_restaurants_updated_at
BEFORE UPDATE ON restaurants
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_food_items_updated_at ON food_items;
CREATE TRIGGER trg_food_items_updated_at
BEFORE UPDATE ON food_items
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_delivery_agents_updated_at ON delivery_agents;
CREATE TRIGGER trg_delivery_agents_updated_at
BEFORE UPDATE ON delivery_agents
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_coupons_updated_at ON coupons;
CREATE TRIGGER trg_coupons_updated_at
BEFORE UPDATE ON coupons
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_operating_hours_updated_at ON operating_hours;
CREATE TRIGGER trg_operating_hours_updated_at
BEFORE UPDATE ON operating_hours
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_admin_users_updated_at ON admin_users;
CREATE TRIGGER trg_admin_users_updated_at
BEFORE UPDATE ON admin_users
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

DROP TRIGGER IF EXISTS trg_revenue_statistics_updated_at ON revenue_statistics;
CREATE TRIGGER trg_revenue_statistics_updated_at
BEFORE UPDATE ON revenue_statistics
FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================
CREATE OR REPLACE VIEW active_users AS
SELECT
    u.id,
    u.name,
    u.email,
    u.total_orders,
    u.total_spent,
    u.joined_at,
    u.last_login
FROM users u
WHERE u.status = 'active'
  AND u.deleted_at IS NULL;

CREATE OR REPLACE VIEW popular_restaurants AS
SELECT
    r.id,
    r.name,
    r.cuisine,
    r.rating,
    r.review_count,
    r.total_orders,
    r.total_revenue,
    r.is_approved
FROM restaurants r
WHERE r.is_approved = TRUE
  AND r.status = 'open'
  AND r.deleted_at IS NULL
ORDER BY r.rating DESC, r.total_orders DESC;

CREATE OR REPLACE VIEW recent_orders AS
SELECT
    o.id,
    o.user_id,
    u.name AS user_name,
    o.restaurant_id,
    r.name AS restaurant_name,
    o.total_amount,
    o.order_status,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN restaurants r ON o.restaurant_id = r.id
WHERE o.deleted_at IS NULL
ORDER BY o.created_at DESC;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
