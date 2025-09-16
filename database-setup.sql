-- Teekoob Database Setup Script
-- Run this in phpMyAdmin to create the database and tables

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS teekoob CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use the database
USE teekoob;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(255),
    avatar_url VARCHAR(500),
    language_preference ENUM('en', 'so', 'ar') DEFAULT 'en',
    theme_preference ENUM('light', 'dark', 'sepia', 'night') DEFAULT 'light',
    subscription_plan ENUM('free', 'premium', 'lifetime') DEFAULT 'free',
    subscription_status ENUM('active', 'inactive', 'cancelled', 'expired') DEFAULT 'active',
    subscription_expires_at TIMESTAMP NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_subscription_status (subscription_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create books table
CREATE TABLE IF NOT EXISTS books (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    title_somali VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    description_somali TEXT NOT NULL,
    authors JSON NOT NULL,
    authors_somali JSON NOT NULL,
    genre VARCHAR(100) NOT NULL,
    genre_somali VARCHAR(100) NOT NULL,
    language ENUM('en', 'so', 'ar') NOT NULL,
    format ENUM('ebook', 'audiobook', 'both') NOT NULL,
    cover_image_url VARCHAR(500),
    audio_url VARCHAR(500),
    ebook_url VARCHAR(500),
    sample_url VARCHAR(500),
    duration INT NULL COMMENT 'Duration in minutes',
    page_count INT NULL,
    rating DECIMAL(3,2) NULL,
    review_count INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_new_release BOOLEAN DEFAULT FALSE,
    is_premium BOOLEAN DEFAULT FALSE,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_language (language),
    INDEX idx_format (format),
    INDEX idx_genre (genre),
    INDEX idx_is_featured (is_featured),
    INDEX idx_is_new_release (is_new_release),
    INDEX idx_is_premium (is_premium),
    INDEX idx_created_at (created_at),
    FULLTEXT idx_search (title, title_somali, description, description_somali)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create user_library table
CREATE TABLE IF NOT EXISTS user_library (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    book_id VARCHAR(36) NOT NULL,
    status ENUM('reading', 'completed', 'wishlist', 'archived') DEFAULT 'reading',
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    current_position VARCHAR(100) NULL COMMENT 'Current page or timestamp',
    bookmarks JSON NULL,
    notes JSON NULL,
    highlights JSON NULL,
    reading_preferences JSON NULL,
    audio_preferences JSON NULL,
    is_downloaded BOOLEAN DEFAULT FALSE,
    downloaded_at TIMESTAMP NULL,
    last_opened_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_user_book (user_id, book_id),
    INDEX idx_user_id (user_id),
    INDEX idx_book_id (book_id),
    INDEX idx_status (status),
    INDEX idx_is_downloaded (is_downloaded),
    INDEX idx_last_opened (last_opened_at),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    plan_type ENUM('free', 'premium', 'lifetime') NOT NULL,
    status ENUM('active', 'inactive', 'cancelled', 'expired') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(100) NULL,
    payment_provider VARCHAR(50) NULL,
    payment_provider_subscription_id VARCHAR(255) NULL,
    starts_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_plan_type (plan_type),
    INDEX idx_expires_at (expires_at),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create categories table for admin management
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_somali VARCHAR(100) NOT NULL,
    description TEXT,
    description_somali TEXT,
    color VARCHAR(7) DEFAULT '#1E3A8A',
    icon VARCHAR(50) DEFAULT 'book',
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_name (name),
    INDEX idx_is_active (is_active),
    INDEX idx_sort_order (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create book_categories junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS book_categories (
    id VARCHAR(36) PRIMARY KEY,
    book_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_book_category (book_id, category_id),
    INDEX idx_book_id (book_id),
    INDEX idx_category_id (category_id),
    
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default categories
INSERT INTO categories (id, name, name_somali, description, description_somali, color, icon, sort_order) VALUES
('cat-001', 'Fiction', 'Sheeko', 'Fictional stories and novels', 'Sheekooyin iyo riwaayado', '#1E3A8A', 'book', 1),
('cat-002', 'Non-Fiction', 'Sheeko-dhaqameed', 'Non-fictional books and educational content', 'Buugag dhaqameed iyo waxbarasho', '#059669', 'school', 2),
('cat-003', 'Science Fiction', 'Sayniska Sheekada', 'Science fiction and fantasy', 'Sayniska sheekada iyo khayaal', '#7C3AED', 'rocket', 3),
('cat-004', 'Mystery', 'Sirta', 'Mystery and thriller books', 'Sirta iyo xiisaha', '#DC2626', 'search', 4),
('cat-005', 'Romance', 'Jacaylka', 'Romance and love stories', 'Jacaylka iyo sheekooyin', '#EC4899', 'heart', 5),
('cat-006', 'Self-Help', 'Caawimada Nafta', 'Self-help and personal development', 'Caawimada nafta iyo horumarinta', '#F59E0B', 'lightbulb', 6),
('cat-007', 'Business', 'Ganacsiga', 'Business and entrepreneurship', 'Ganacsiga iyo ganacsiga', '#10B981', 'briefcase', 7),
('cat-008', 'Technology', 'Teknoolajiyada', 'Technology and computer science', 'Teknoolajiyada iyo sayniska kombiyuutarka', '#3B82F6', 'computer', 8),
('cat-009', 'Health', 'Caafimaadka', 'Health and wellness', 'Caafimaadka iyo fayoobka', '#EF4444', 'medical', 9),
('cat-010', 'History', 'Taariikhda', 'Historical books and biographies', 'Taariikhda iyo taariikhyada', '#8B5CF6', 'landmark', 10),
('cat-011', 'Poetry', 'Maansada', 'Poetry and literature', 'Maansada iyo adabka', '#F97316', 'pen', 11),
('cat-012', 'Children', 'Carruurta', 'Children\'s books and stories', 'Buugagta carruurta iyo sheekooyin', '#06B6D4', 'child', 12),
('cat-013', 'Education', 'Waxbarashada', 'Educational and academic books', 'Waxbarashada iyo cilmi-baadhiska', '#84CC16', 'graduation-cap', 13),
('cat-014', 'Adventure', 'Macaanka', 'Adventure and action stories', 'Macaanka iyo sheekooyin', '#22C55E', 'compass', 14),
('cat-015', 'Philosophy', 'Falsafada', 'Philosophy and religion', 'Falsafada iyo diinta', '#6366F1', 'brain', 15);

-- Link existing books to categories (based on their current genre)
INSERT INTO book_categories (id, book_id, category_id) VALUES
-- The Great Adventure -> Adventure
('bc-001', '550e8400-e29b-41d4-a716-446655440003', 'cat-014'),
-- Learning Somali -> Education
('bc-002', '550e8400-e29b-41d4-a716-446655440004', 'cat-013');

-- Now let's migrate existing books to use the new category system
-- First, remove the old genre columns
-- ALTER TABLE books DROP COLUMN genre;
-- ALTER TABLE books DROP COLUMN genre_somali;

-- Insert sample data for testing
INSERT INTO users (id, email, password_hash, first_name, last_name, display_name, language_preference, subscription_plan, is_verified, is_active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'admin@teekoob.com', '$2b$10$example.hash.here', 'Admin', 'User', 'Admin', 'en', 'lifetime', TRUE, TRUE),
('550e8400-e29b-41d4-a716-446655440002', 'user@teekoob.com', '$2b$10$example.hash.here', 'Test', 'User', 'TestUser', 'en', 'free', TRUE, TRUE);

-- Insert sample books with comprehensive categories
INSERT INTO books (id, title, title_somali, description, description_somali, authors, authors_somali, genre, genre_somali, language, format, cover_image_url, audio_url, ebook_url, sample_url, duration, page_count, rating, review_count, is_featured, is_new_release, is_premium, metadata, created_at, updated_at) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'The Great Adventure', 'Macaanka Waaweyn', 'An exciting adventure story for all ages', 'Sheeko xiiso leh oo ka dhacda macaanka', '["John Doe"]', '["John Doe"]', 'fiction', 'sheeko', 'en', 'both', NULL, NULL, NULL, NULL, 12, 150, 4.5, 25, 1, 0, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440004', 'Learning Somali', 'Barashada Afka Soomaaliga', 'A comprehensive guide to learning Somali language', 'Hagida buuxa oo ku saabsan barashada afka Soomaali', '["Ahmed Hassan"]', '["Ahmed Hassan"]', 'education', 'barasho', 'so', 'both', NULL, NULL, NULL, NULL, 45, 200, 4.8, 30, 1, 1, 1, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440005', 'Mystery of the Night', 'Sirta Habeenka', 'A thrilling mystery novel', 'Sheeko xiiso leh oo ka dhacda habeenka', '["Sarah Wilson"]', '["Sarah Wilson"]', 'mystery', 'sir', 'en', 'both', NULL, NULL, NULL, NULL, 20, 180, 4.2, 18, 0, 1, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440006', 'Business Success', 'Guulka Ganacsiga', 'Guide to successful business practices', 'Hagida ku saabsan ganacsiga guuleysan', '["Michael Chen"]', '["Michael Chen"]', 'business', 'ganacsi', 'en', 'both', NULL, NULL, NULL, NULL, 30, 250, 4.6, 22, 1, 0, 1, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440007', 'Science Today', 'Sayniska Maanta', 'Latest developments in modern science', 'Horumarka cusub ee sayniska', '["Dr. Emily Brown"]', '["Dr. Emily Brown"]', 'science', 'saynis', 'en', 'both', NULL, NULL, NULL, NULL, 25, 300, 4.7, 28, 0, 1, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440008', 'Romance in Spring', 'Jacaylka Gu', 'A beautiful love story', 'Sheeko jacayl oo qurux badan', '["Lisa Garcia"]', '["Lisa Garcia"]', 'romance', 'jacayl', 'en', 'both', NULL, NULL, NULL, NULL, 15, 160, 4.3, 20, 0, 0, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440009', 'Self-Help Guide', 'Hagida Caawimada Nafta', 'Personal development and self-improvement', 'Horumarinta shakhsiyaadka iyo hagaajinta nafta', '["David Johnson"]', '["David Johnson"]', 'self-help', 'caawimada-nafta', 'en', 'both', NULL, NULL, NULL, NULL, 18, 180, 4.4, 24, 1, 0, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440010', 'Historical Tales', 'Sheekooyin Taariikhi ah', 'Stories from ancient times', 'Sheekooyin ka dhacay zamanaha hore', '["Maria Rodriguez"]', '["Maria Rodriguez"]', 'historical', 'taariikhi', 'en', 'both', NULL, NULL, NULL, NULL, 22, 220, 4.1, 16, 0, 0, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440011', 'Technology Future', 'Mustaqbalka Teknoolajiyada', 'The future of technology', 'Mustaqbalka teknoolajiyada', '["Alex Kim"]', '["Alex Kim"]', 'technology', 'teknoolaji', 'en', 'both', NULL, NULL, NULL, NULL, 28, 280, 4.8, 32, 1, 1, 1, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440012', 'Health & Wellness', 'Caafimaadka iyo Fayoobka', 'Complete guide to health and wellness', 'Hagida buuxa oo ku saabsan caafimaadka iyo fayoobka', '["Dr. Sarah Miller"]', '["Dr. Sarah Miller"]', 'health', 'caafimaad', 'en', 'both', NULL, NULL, NULL, NULL, 35, 320, 4.6, 26, 0, 0, 1, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440013', 'Poetry Collection', 'Diwaanka Gabayada', 'Beautiful poems in Somali and English', 'Gabay qurux badan oo ku qoran afka Soomaali iyo Ingiriisi', '["Amina Hassan"]', '["Amina Hassan"]', 'poetry', 'gabay', 'so', 'both', NULL, NULL, NULL, NULL, 10, 80, 4.9, 35, 1, 0, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440014', 'Children Stories', 'Sheekooyin Carruurta', 'Fun stories for children', 'Sheekooyin madadaalo leh oo loogu talagalay carruurta', '["Fatima Ali"]', '["Fatima Ali"]', 'children', 'carruur', 'so', 'both', NULL, NULL, NULL, NULL, 8, 60, 4.7, 29, 0, 1, 0, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),

('550e8400-e29b-41d4-a716-446655440015', 'Philosophy Today', 'Falsafada Maanta', 'Modern philosophical thoughts', 'Fikradaha falsafadeed ee casriga ah', '["Prof. James Wilson"]', '["Prof. James Wilson"]', 'philosophy', 'falsafad', 'en', 'both', NULL, NULL, NULL, NULL, 40, 400, 4.5, 21, 0, 0, 1, NULL, '2025-08-17 17:51:06', '2025-08-17 17:51:06');

-- Insert sample books with different languages
INSERT INTO books (id, title, title_somali, description, description_somali, authors, authors_somali, genre, genre_somali, language, format, cover_image_url, audio_url, ebook_url, sample_url, duration, page_count, rating, review_count, is_featured, is_new_release, is_premium, created_at, updated_at) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'The Great Adventure', 'Macaanka Waaweyn', 'An exciting adventure story for all ages', 'Sheeko xiiso leh oo ka dhacda macaanka', '["John Doe"]', '["John Doe"]', 'fiction', 'sheeko', 'en', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, 0, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),
('550e8400-e29b-41d4-a716-446655440004', 'Learning Somali', 'Barashada Afka Soomaaliga', 'A comprehensive guide to learning Somali language', 'Hagida buuxa oo ku saabsan barashada afka Soomaali', '["Ahmed Hassan"]', '["Ahmed Hassan"]', 'education', 'barasho', 'so', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, 1, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),
('550e8400-e29b-41d4-a716-446655440005', 'Arabic Poetry Collection', 'Diwaanka Sheekooyin Carabi', 'A beautiful collection of classical Arabic poetry', 'Urur qurux badan oo sheekooyin carabi ah', '["Fatima Al-Zahra"]', '["Fatima Al-Zahra"]', 'poetry', 'shiir', 'ar', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, 0, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),
('550e8400-e29b-41d4-a716-446655440006', 'English Classics', 'Buugaagta Ingiriisiga', 'Collection of classic English literature', 'Urur buugaagta caanka ah ee Ingiriisiga', '["William Shakespeare", "Jane Austen"]', '["William Shakespeare", "Jane Austen"]', 'classics', 'qurux', 'en', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, 1, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),
('550e8400-e29b-41d4-a716-446655440007', 'Somali Folktales', 'Sheekooyin Soomaali', 'Traditional Somali folktales and stories', 'Sheekooyin dhaqameed iyo sheekooyin Soomaali', '["Halima Mohamed"]', '["Halima Mohamed"]', 'folktales', 'sheekooyin', 'so', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, 0, '2025-08-17 17:51:06', '2025-08-17 17:51:06'),
('550e8400-e29b-41d4-a716-446655440008', 'Arabic Calligraphy', 'Khatt Carabi', 'The art and history of Arabic calligraphy', 'Fanka iyo taariikhda khatta Carabi', '["Omar Al-Rashid"]', '["Omar Al-Rashid"]', 'art', 'fanka', 'ar', 'both', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, 1, '2025-08-17 17:51:06', '2025-08-17 17:51:06');

-- Insert sample library entries
INSERT INTO user_library (id, user_id, book_id, status, progress_percentage) VALUES
('550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 'reading', 25.50);

-- Insert sample subscription
INSERT INTO subscriptions (id, user_id, plan_type, status, amount, starts_at, expires_at) VALUES
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 'free', 'active', 0.00, NOW(), NULL);

-- Create additional indexes for better performance
CREATE INDEX idx_books_language_format ON books(language, format);
CREATE INDEX idx_books_genre_language ON books(genre, language);
CREATE INDEX idx_user_library_user_status ON user_library(user_id, status);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);

-- Show success message
SELECT 'Teekoob database setup completed successfully!' as status;
