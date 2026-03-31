INSERT INTO admin_users (id, name, email, password_hash, role, permissions, is_active, created_at, updated_at) 
VALUES (
  'admin-quickbite-1', 
  'Admin User', 
  'admin@gmail.com', 
  '$2a$10$VZqB1.ImEKaIADtTzFmmzOeOd9KlBLks4X7/0wKV4/rq777TIZ32C', 
  'admin', 
  '{"manage_users": true, "manage_restaurants": true, "manage_orders": true, "manage_payments": true, "view_analytics": true, "manage_content": true}'::jsonb, 
  TRUE, 
  NOW(), 
  NOW()
) 
ON CONFLICT (email) DO UPDATE SET 
  password_hash = EXCLUDED.password_hash, 
  role = EXCLUDED.role, 
  permissions = EXCLUDED.permissions, 
  is_active = EXCLUDED.is_active, 
  updated_at = NOW();

SELECT id, name, email, role, is_active, permissions FROM admin_users WHERE email='admin@gmail.com';
