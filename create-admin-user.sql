-- Create Admin User Script
-- Run this in your database to create the first admin user

-- First, make sure the users table exists and has the right structure
-- If you're using MySQL, you might need to adjust the syntax

-- Create admin user (password: admin123)
INSERT INTO users (
  id,
  email,
  password_hash,
  first_name,
  last_name,
  language_preference,
  subscription_plan,
  is_active,
  is_verified,
  is_admin,
  created_at,
  updated_at
) VALUES (
  UUID(), -- or generate a UUID/GUID
  'admin@teekoob.com',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5u.Gi', -- admin123
  'Admin',
  'User',
  'en',
  'lifetime',
  1,
  1,
  1,
  NOW(),
  NOW()
);

-- Alternative: If you want to use a different email/password
-- INSERT INTO users (
--   id,
--   email,
--   password_hash,
--   first_name,
--   last_name,
--   language_preference,
--   subscription_plan,
--   is_active,
--   is_verified,
--   is_admin,
--   created_at,
--   updated_at
-- ) VALUES (
--   UUID(),
--   'your-email@example.com',
--   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5u.Gi', -- admin123
--   'Your',
--   'Name',
--   'en',
--   'lifetime',
--   1,
--   1,
--   1,
--   NOW(),
--   NOW()
-- );

-- Verify the user was created
SELECT id, email, first_name, last_name, is_admin, is_active, is_verified FROM users WHERE email = 'admin@teekoob.com';
