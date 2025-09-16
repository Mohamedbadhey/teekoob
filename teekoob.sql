-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 23, 2025 at 10:34 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `teekoob`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_reading_progress` (IN `p_user_id` VARCHAR(36), IN `p_book_id` VARCHAR(36), IN `p_progress` DECIMAL(5,2), IN `p_reading_time` INT, IN `p_words_read` INT)   BEGIN
    DECLARE v_reading_speed INT;
    DECLARE v_session_id VARCHAR(36);
    
    -- Calculate reading speed if words read provided
    IF p_words_read > 0 AND p_reading_time > 0 THEN
        SET v_reading_speed = (p_words_read / p_reading_time) * 60;
    END IF;
    
    -- Generate UUID for session
    SET v_session_id = UUID();
    
    -- Record reading session
    INSERT INTO reading_sessions (
        id, user_id, book_id, duration_minutes, 
        words_read, reading_speed_wpm,
        started_at, ended_at
    )
    VALUES (
        v_session_id, p_user_id, p_book_id, p_reading_time,
        p_words_read, v_reading_speed,
        DATE_SUB(CURRENT_TIMESTAMP, INTERVAL p_reading_time MINUTE),
        CURRENT_TIMESTAMP
    );
    
    -- Update user_library
    UPDATE user_library
    SET progress_percentage = p_progress,
        total_reading_time = total_reading_time + p_reading_time,
        last_reading_speed = COALESCE(v_reading_speed, last_reading_speed),
        reading_speed_wpm = CASE 
            WHEN v_reading_speed IS NOT NULL 
            THEN (reading_speed_wpm + v_reading_speed) / 2
            ELSE reading_speed_wpm
        END,
        reading_streak_contribution = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id AND book_id = p_book_id;
    
    -- Update streak
    CALL update_reading_streak(p_user_id, CURRENT_DATE);
    
    -- Update achievements
    UPDATE user_achievements ua
    JOIN achievements a ON ua.achievement_id = a.id
    SET ua.progress = CASE
        WHEN a.requirement_type = 'books_read' THEN
            (SELECT COUNT(*) / a.requirement_value
             FROM user_library
             WHERE user_id = p_user_id AND status = 'completed')
        WHEN a.requirement_type = 'reading_speed' THEN
            LEAST(1.0, COALESCE(v_reading_speed, 0) / a.requirement_value)
        WHEN a.requirement_type = 'reading_streak' THEN
            (SELECT LEAST(1.0, current_streak / a.requirement_value)
             FROM reading_streaks
             WHERE user_id = p_user_id)
        WHEN a.requirement_type = 'languages_read' THEN
            (SELECT COUNT(DISTINCT b.language) / a.requirement_value
             FROM user_library ul
             JOIN books b ON ul.book_id = b.id
             WHERE ul.user_id = p_user_id)
    END,
    ua.unlocked_at = CASE
        WHEN ua.progress >= 1.0 AND ua.unlocked_at IS NULL
        THEN CURRENT_TIMESTAMP
        ELSE ua.unlocked_at
    END
    WHERE ua.user_id = p_user_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_reading_streak` (IN `p_user_id` VARCHAR(36), IN `p_reading_date` DATE)   BEGIN
    DECLARE current_streak INT;
    DECLARE longest_streak INT;
    DECLARE last_read DATE;
    
    -- Get current streak info
    SELECT rs.current_streak, rs.longest_streak, rs.last_read_date
    INTO current_streak, longest_streak, last_read
    FROM reading_streaks rs
    WHERE rs.user_id = p_user_id;
    
    -- If no record exists, initialize one
    IF last_read IS NULL THEN
        INSERT INTO reading_streaks (id, user_id, current_streak, longest_streak, last_read_date)
        VALUES (UUID(), p_user_id, 1, 1, p_reading_date);
    ELSE
        -- If reading date is consecutive, increment streak
        IF DATEDIFF(p_reading_date, last_read) = 1 THEN
            SET current_streak = current_streak + 1;
            -- Update longest streak if current is higher
            IF current_streak > longest_streak THEN
                SET longest_streak = current_streak;
            END IF;
        -- If same day, no change
        ELSEIF DATEDIFF(p_reading_date, last_read) = 0 THEN
            SET current_streak = current_streak;
        -- If streak broken, reset to 1
        ELSE
            SET current_streak = 1;
        END IF;
        
        -- Update streak record
        UPDATE reading_streaks
        SET current_streak = current_streak,
            longest_streak = longest_streak,
            last_read_date = p_reading_date,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `achievements`
--

CREATE TABLE `achievements` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `name_somali` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `description_somali` text NOT NULL,
  `icon_name` varchar(50) NOT NULL,
  `requirement_type` enum('books_read','reading_streak','reading_speed','languages_read') NOT NULL,
  `requirement_value` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `achievements`
--

INSERT INTO `achievements` (`id`, `name`, `name_somali`, `description`, `description_somali`, `icon_name`, `requirement_type`, `requirement_value`, `created_at`) VALUES
('ach-001', 'Bookworm', 'Buugworme', 'Read 10 books', 'Akhri 10 buug', 'auto_stories', 'books_read', 10, '2025-08-23 12:46:05'),
('ach-002', 'Speed Reader', 'Akhristaha Degdega', 'Read at 300 words per minute', 'Akhri 300 eray daqiiqadii', 'speed', 'reading_speed', 300, '2025-08-23 12:46:05'),
('ach-003', 'Dedicated Reader', 'Akhristaha Daacada', 'Maintain a 7-day reading streak', 'Hayso 7 maalmood oo isku xigta', 'local_fire_department', 'reading_streak', 7, '2025-08-23 12:46:05'),
('ach-004', 'Polyglot', 'Luqadaha', 'Read books in multiple languages', 'Akhri buugaag luqado kala duwan', 'language', 'languages_read', 2, '2025-08-23 12:46:05');

-- --------------------------------------------------------

--
-- Table structure for table `books`
--

CREATE TABLE `books` (
  `id` varchar(36) NOT NULL,
  `title` varchar(500) NOT NULL,
  `title_somali` varchar(500) NOT NULL,
  `description` text NOT NULL,
  `description_somali` text NOT NULL,
  `authors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`authors`)),
  `authors_somali` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`authors_somali`)),
  `genre` varchar(100) NOT NULL DEFAULT 'general',
  `genre_somali` varchar(100) NOT NULL DEFAULT 'guud',
  `language` enum('en','so','ar') NOT NULL,
  `format` enum('ebook','audiobook','both') NOT NULL,
  `cover_image_url` varchar(500) DEFAULT NULL,
  `audio_url` varchar(500) DEFAULT NULL,
  `ebook_url` varchar(500) DEFAULT NULL,
  `sample_url` varchar(500) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL COMMENT 'Duration in minutes',
  `page_count` int(11) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT NULL,
  `review_count` int(11) DEFAULT 0,
  `is_featured` tinyint(1) DEFAULT 0,
  `is_new_release` tinyint(1) DEFAULT 0,
  `is_premium` tinyint(1) DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `books`
--

INSERT INTO `books` (`id`, `title`, `title_somali`, `description`, `description_somali`, `authors`, `authors_somali`, `genre`, `genre_somali`, `language`, `format`, `cover_image_url`, `audio_url`, `ebook_url`, `sample_url`, `duration`, `page_count`, `rating`, `review_count`, `is_featured`, `is_new_release`, `is_premium`, `metadata`, `created_at`, `updated_at`) VALUES
('f2e28e9f-fc7b-40e5-ae5a-2849105cb78b', 'Marry Before U Know', 'Garaadso Inta Aadan Guursan', 'its a good book', 'waa book fcn', '[\"mohamed\"]', '[\"mohamed\"]', 'Dark romancy', 'Dark Romancy', 'en', 'both', '/uploads/coverImage-1755808840359-909642985.jpg', '/uploads/audioFile-1755808840359-635858533.m4a', '/uploads/ebookFile-1755808840389-931641984.pdf', '/uploads/sampleText-1755808840449-822815787.txt', 15, 126, 0.00, 0, 1, 1, 0, NULL, '2025-08-21 20:40:40', '2025-08-22 09:20:15');

-- --------------------------------------------------------

--
-- Table structure for table `book_categories`
--

CREATE TABLE `book_categories` (
  `id` varchar(36) NOT NULL,
  `book_id` varchar(36) NOT NULL,
  `category_id` varchar(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `book_categories`
--

INSERT INTO `book_categories` (`id`, `book_id`, `category_id`, `created_at`) VALUES
('bc-003', '550e8400-e29b-41d4-a716-446655440005', 'cat-004', '2025-08-18 15:48:25'),
('bc-004', '550e8400-e29b-41d4-a716-446655440006', 'cat-014', '2025-08-18 15:48:25'),
('bc-005', '550e8400-e29b-41d4-a716-446655440007', 'cat-018', '2025-08-18 15:48:25'),
('bc-006', '550e8400-e29b-41d4-a716-446655440008', 'cat-005', '2025-08-18 15:48:25'),
('bc-007', '550e8400-e29b-41d4-a716-446655440009', 'cat-013', '2025-08-18 15:48:25'),
('bc-008', '550e8400-e29b-41d4-a716-446655440010', 'cat-010', '2025-08-18 15:48:25'),
('bc-009', '550e8400-e29b-41d4-a716-446655440011', 'cat-019', '2025-08-18 15:48:25'),
('bc-010', '550e8400-e29b-41d4-a716-446655440012', 'cat-020', '2025-08-18 15:48:25'),
('bc-011', '550e8400-e29b-41d4-a716-446655440013', 'cat-026', '2025-08-18 15:48:25'),
('bc-012', '550e8400-e29b-41d4-a716-446655440014', 'cat-031', '2025-08-18 15:48:25'),
('bc-013', '550e8400-e29b-41d4-a716-446655440015', 'cat-016', '2025-08-18 15:48:25'),
('bc-016', '550e8400-e29b-41d4-a716-446655440005', 'cat-006', '2025-08-18 15:48:25'),
('bc-017', '550e8400-e29b-41d4-a716-446655440006', 'cat-013', '2025-08-18 15:48:25'),
('bc-018', '550e8400-e29b-41d4-a716-446655440007', 'cat-019', '2025-08-18 15:48:25'),
('bc-019', '550e8400-e29b-41d4-a716-446655440011', 'cat-003', '2025-08-18 15:48:25'),
('bc-020', '550e8400-e29b-41d4-a716-446655440012', 'cat-013', '2025-08-18 15:48:25'),
('bc-021', '550e8400-e29b-41d4-a716-446655440013', 'cat-001', '2025-08-18 15:48:25'),
('bc-022', '550e8400-e29b-41d4-a716-446655440014', 'cat-029', '2025-08-18 15:48:25'),
('bc-023', '550e8400-e29b-41d4-a716-446655440015', 'cat-030', '2025-08-18 15:48:25');

-- --------------------------------------------------------

--
-- Table structure for table `book_recommendations`
--

CREATE TABLE `book_recommendations` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `book_id` varchar(36) NOT NULL,
  `reason_type` enum('genre_match','language_practice','new_release','popular','continuation_series') NOT NULL,
  `score` decimal(3,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `name_somali` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `description_somali` text DEFAULT NULL,
  `color` varchar(7) DEFAULT '#1E3A8A',
  `icon` varchar(50) DEFAULT 'book',
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `name_somali`, `description`, `description_somali`, `color`, `icon`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
('', 'Dark Romance', '', 'kuwa halista ah', NULL, '#1E3A8A', 'book', 1, 0, '2025-08-20 10:52:10', '2025-08-20 10:52:10'),
('cat-001', 'Fiction', 'Sheeko', 'Imaginative stories and novels', 'Sheekooyin khayaali ah iyo buugaag', '#1E3A8A', 'book', 1, 1, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-002', 'Non-Fiction', 'Sheeko-dhab', 'Real-world information and knowledge', 'Macluumaad dhab ah iyo aqoon', '#059669', 'school', 1, 2, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-003', 'Science Fiction', 'Saynis-Sheeko', 'Futuristic and scientific stories', 'Sheekooyin mustaqbalka iyo sayniska', '#7C3AED', 'rocket', 1, 3, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-004', 'Mystery', 'Sir', 'Suspenseful and detective stories', 'Sheekooyin xiiso leh iyo sirtir', '#DC2626', 'search', 1, 4, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-005', 'Romance', 'Jacayl', 'Love stories and relationships', 'Sheekooyin jacayl iyo xiriir', '#EC4899', 'favorite', 1, 5, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-006', 'Thriller', 'Xiiso', 'Exciting and suspenseful stories', 'Sheekooyin xiiso leh iyo xiiso', '#EA580C', 'flash_on', 1, 6, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-007', 'Horror', 'Cabsi', 'Scary and frightening stories', 'Sheekooyin cabsi iyo cabsi', '#1F2937', 'nightmare', 1, 7, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-008', 'Fantasy', 'Khayaal', 'Magical and supernatural stories', 'Sheekooyin sihri ah iyo caajib', '#059669', 'auto_fantasy', 1, 8, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-009', 'Adventure', 'Macaan', 'Action and exploration stories', 'Sheekooyin dhaqdhaqaaq iyo sahamin', '#0891B2', 'explore', 1, 9, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-010', 'Historical', 'Taariikhi', 'Stories from the past', 'Sheekooyin ka dhacay masaafurta', '#92400E', 'history', 1, 10, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-011', 'Biography', 'Taariikhi-nolol', 'Life stories of real people', 'Sheekooyin nolol ee dadka dhabta ah', '#7C2D12', 'person', 1, 11, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-012', 'Autobiography', 'Nolol-nolol', 'Self-written life stories', 'Sheekooyin nolol oo qoray qofka', '#581C87', 'edit', 1, 12, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-013', 'Self-Help', 'Caawimada-nafta', 'Personal development books', 'Buugaag horumarinta shakhsiyaadka', '#166534', 'psychology', 1, 13, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-014', 'Business', 'Ganacsi', 'Business and entrepreneurship', 'Ganacsi iyo horumarinta ganacsiga', '#1E40AF', 'business', 1, 14, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-015', 'Economics', 'Dhaqaale', 'Economic theory and practice', 'Nazariyada iyo dhaqanka dhaqaale', '#7C2D12', 'trending_up', 1, 15, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-016', 'Philosophy', 'Falsafad', 'Philosophical thoughts and ideas', 'Fikradaha falsafadeed', '#374151', 'lightbulb', 1, 16, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-017', 'Psychology', 'Nafsiga', 'Mental health and behavior', 'Caafimaadka maskaxda iyo dhaqanka', '#059669', 'psychology', 1, 17, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-018', 'Science', 'Saynis', 'Scientific knowledge and research', 'Aqoon saynis ah iyo cilmi-baaris', '#0891B2', 'science', 1, 18, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-019', 'Technology', 'Teknoolaji', 'Technology and innovation', 'Teknoolaji iyo horumarinta cusub', '#7C3AED', 'computer', 1, 19, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-020', 'Health', 'Caafimaad', 'Health and wellness', 'Caafimaadka iyo fayoobka', '#DC2626', 'health_and_safety', 1, 20, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-021', 'Fitness', 'Fayoob', 'Physical fitness and exercise', 'Fayoobka iyo jimicsiga', '#059669', 'fitness_center', 1, 21, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-022', 'Cooking', 'Karin', 'Food and cooking', 'Cunto iyo karin', '#EA580C', 'restaurant', 1, 22, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-023', 'Travel', 'Safarka', 'Travel and exploration', 'Safarka iyo sahaminta', '#0891B2', 'flight', 1, 23, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-024', 'Art', 'Farshaxan', 'Art and creativity', 'Farshaxan iyo hal-abuur', '#EC4899', 'palette', 1, 24, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-025', 'Music', 'Musik', 'Music and audio', 'Musik iyo cod', '#7C3AED', 'music_note', 1, 25, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-026', 'Poetry', 'Gabay', 'Poetry and verse', 'Gabay iyo sheeko', '#059669', 'format_quote', 1, 26, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-027', 'Drama', 'Masraxa', 'Drama and theater', 'Masraxa iyo masraxa', '#DC2626', 'theater_comedy', 1, 27, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-028', 'Comedy', 'Kaftan', 'Humor and comedy', 'Kaftan iyo kaftan', '#F59E0B', 'sentiment_satisfied', 1, 28, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-029', 'Education', 'Waxbarasho', 'Educational content', 'Nuxurka waxbarasho', '#1E40AF', 'school', 1, 29, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-030', 'Academic', 'Akademik', 'Academic and scholarly works', 'Shaqooyin akademik iyo cilmi', '#374151', 'academic', 1, 30, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-031', 'Children', 'Carruur', 'Books for children', 'Buugaag loogu talagalay carruurta', '#EC4899', 'child_care', 1, 31, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-032', 'Young Adult', 'Dhalinyaro', 'Books for young adults', 'Buugaag loogu talagalay dhalinyarada', '#7C3AED', 'teenager', 1, 32, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-033', 'Religious', 'Diini', 'Religious and spiritual content', 'Nuxurka diini iyo ruuxi', '#059669', 'church', 1, 33, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-034', 'Spiritual', 'Ruuxi', 'Spiritual and mindfulness', 'Ruuxi iyo fahanka', '#0891B2', 'self_improvement', 1, 34, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-035', 'Politics', 'Siyaasad', 'Political content', 'Nuxurka siyaasadeed', '#DC2626', 'gavel', 1, 35, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-036', 'Social Issues', 'Masalihul-buldan', 'Social problems and solutions', 'Dhibaaha iyo xalalka bulshada', '#7C2D12', 'groups', 1, 36, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-037', 'Environment', 'Deegaanka', 'Environmental topics', 'Mawduucyada deegaanka', '#059669', 'eco', 1, 37, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-038', 'Nature', 'Dabiici', 'Natural world and wildlife', 'Adduunka dabiici iyo xayawaan', '#0891B2', 'nature', 1, 38, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-039', 'Sports', 'Ciyaaraha', 'Sports and athletics', 'Ciyaaraha iyo ciyaaraha', '#EA580C', 'sports_soccer', 1, 39, '2025-08-18 15:45:47', '2025-08-18 15:45:47'),
('cat-040', 'Games', 'Ciyaar', 'Games and entertainment', 'Ciyaaraha iyo madadaalo', '#7C3AED', 'games', 1, 40, '2025-08-18 15:45:47', '2025-08-18 15:45:47');

-- --------------------------------------------------------

--
-- Table structure for table `reading_goals`
--

CREATE TABLE `reading_goals` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `daily_reading_minutes` int(11) NOT NULL DEFAULT 30,
  `monthly_book_goal` int(11) NOT NULL DEFAULT 4,
  `preferred_reading_time` time DEFAULT NULL,
  `reminder_enabled` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reading_sessions`
--

CREATE TABLE `reading_sessions` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `book_id` varchar(36) NOT NULL,
  `duration_minutes` int(11) NOT NULL,
  `words_read` int(11) DEFAULT NULL,
  `pages_read` int(11) DEFAULT NULL,
  `reading_speed_wpm` int(11) DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `ended_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reading_streaks`
--

CREATE TABLE `reading_streaks` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `current_streak` int(11) DEFAULT 0,
  `longest_streak` int(11) DEFAULT 0,
  `last_read_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `subscriptions`
--

CREATE TABLE `subscriptions` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `plan_type` enum('free','premium','lifetime') NOT NULL,
  `status` enum('active','inactive','cancelled','expired') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(3) DEFAULT 'USD',
  `payment_method` varchar(100) DEFAULT NULL,
  `payment_provider` varchar(50) DEFAULT NULL,
  `payment_provider_subscription_id` varchar(255) DEFAULT NULL,
  `starts_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subscriptions`
--

INSERT INTO `subscriptions` (`id`, `user_id`, `plan_type`, `status`, `amount`, `currency`, `payment_method`, `payment_provider`, `payment_provider_subscription_id`, `starts_at`, `expires_at`, `cancelled_at`, `created_at`, `updated_at`) VALUES
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 'free', 'active', 0.00, 'USD', NULL, NULL, NULL, '2025-08-17 14:51:06', NULL, NULL, '2025-08-17 14:51:06', '2025-08-17 14:51:06');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `language_preference` enum('en','so','ar') DEFAULT 'en',
  `theme_preference` enum('light','dark','sepia','night') DEFAULT 'light',
  `subscription_plan` enum('free','premium','lifetime') DEFAULT 'free',
  `subscription_status` enum('active','inactive','cancelled','expired') DEFAULT 'active',
  `subscription_expires_at` timestamp NULL DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `is_admin` tinyint(1) DEFAULT 0,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password_hash`, `first_name`, `last_name`, `display_name`, `avatar_url`, `language_preference`, `theme_preference`, `subscription_plan`, `subscription_status`, `subscription_expires_at`, `is_verified`, `is_active`, `is_admin`, `last_login_at`, `created_at`, `updated_at`) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'admin@teekoob.com', '$2a$12$WPbeJ9v4VvAFCigZIah1l.d2BsKX69ErLLoHGEeIk8RPHdzUXKVtm', 'Admin', 'User', 'Admin', NULL, 'en', 'light', 'lifetime', 'active', NULL, 1, 1, 1, '2025-08-22 08:32:39', '2025-08-17 14:51:06', '2025-08-22 08:32:39'),
('550e8400-e29b-41d4-a716-446655440002', 'user@teekoob.com', '$2b$10$example.hash.here', 'Test', 'User', 'TestUser', NULL, 'en', 'light', 'free', 'active', NULL, 1, 1, 0, NULL, '2025-08-17 14:51:06', '2025-08-17 14:51:06');

-- --------------------------------------------------------

--
-- Table structure for table `user_achievements`
--

CREATE TABLE `user_achievements` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `achievement_id` varchar(36) NOT NULL,
  `progress` decimal(5,2) DEFAULT 0.00,
  `unlocked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_library`
--

CREATE TABLE `user_library` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `book_id` varchar(36) NOT NULL,
  `status` enum('reading','completed','wishlist','archived') DEFAULT 'reading',
  `progress_percentage` decimal(5,2) DEFAULT 0.00,
  `current_position` varchar(100) DEFAULT NULL COMMENT 'Current page or timestamp',
  `bookmarks` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`bookmarks`)),
  `notes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`notes`)),
  `highlights` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`highlights`)),
  `reading_preferences` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`reading_preferences`)),
  `audio_preferences` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`audio_preferences`)),
  `is_downloaded` tinyint(1) DEFAULT 0,
  `downloaded_at` timestamp NULL DEFAULT NULL,
  `last_opened_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reading_speed_wpm` int(11) DEFAULT 0,
  `total_reading_time` int(11) DEFAULT 0,
  `last_reading_speed` int(11) DEFAULT NULL,
  `reading_streak_contribution` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_reading_stats`
-- (See below for the actual view)
--
CREATE TABLE `user_reading_stats` (
`user_id` varchar(36)
,`total_books` bigint(21)
,`completed_books` bigint(21)
,`total_reading_minutes` decimal(32,0)
,`avg_reading_speed` decimal(14,4)
,`languages_read` bigint(21)
,`current_streak` int(11)
,`longest_streak` int(11)
,`read_today` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure for view `user_reading_stats`
--
DROP TABLE IF EXISTS `user_reading_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_reading_stats`  AS SELECT `ul`.`user_id` AS `user_id`, count(distinct `ul`.`book_id`) AS `total_books`, count(distinct case when `ul`.`status` = 'completed' then `ul`.`book_id` end) AS `completed_books`, sum(`ul`.`total_reading_time`) AS `total_reading_minutes`, avg(`ul`.`reading_speed_wpm`) AS `avg_reading_speed`, count(distinct `b`.`language`) AS `languages_read`, max(`rs`.`current_streak`) AS `current_streak`, max(`rs`.`longest_streak`) AS `longest_streak`, count(distinct case when `rs`.`last_read_date` = curdate() then `rs`.`id` end) AS `read_today` FROM ((`user_library` `ul` join `books` `b` on(`ul`.`book_id` = `b`.`id`)) left join `reading_streaks` `rs` on(`ul`.`user_id` = `rs`.`user_id`)) GROUP BY `ul`.`user_id` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `achievements`
--
ALTER TABLE `achievements`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_language` (`language`),
  ADD KEY `idx_format` (`format`),
  ADD KEY `idx_is_featured` (`is_featured`),
  ADD KEY `idx_is_new_release` (`is_new_release`),
  ADD KEY `idx_is_premium` (`is_premium`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_books_language_format` (`language`,`format`),
  ADD KEY `idx_books_genre_language` (`language`);
ALTER TABLE `books` ADD FULLTEXT KEY `idx_search` (`title`,`title_somali`,`description`,`description_somali`);

--
-- Indexes for table `book_categories`
--
ALTER TABLE `book_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_book_category` (`book_id`,`category_id`),
  ADD KEY `idx_book_id` (`book_id`),
  ADD KEY `idx_category_id` (`category_id`);

--
-- Indexes for table `book_recommendations`
--
ALTER TABLE `book_recommendations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_book_rec` (`user_id`,`book_id`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_name` (`name`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_sort_order` (`sort_order`);

--
-- Indexes for table `reading_goals`
--
ALTER TABLE `reading_goals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_goals` (`user_id`);

--
-- Indexes for table `reading_sessions`
--
ALTER TABLE `reading_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_sessions` (`user_id`,`started_at`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `reading_streaks`
--
ALTER TABLE `reading_streaks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_streak` (`user_id`);

--
-- Indexes for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_plan_type` (`plan_type`),
  ADD KEY `idx_expires_at` (`expires_at`),
  ADD KEY `idx_subscriptions_user_status` (`user_id`,`status`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_subscription_status` (`subscription_status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `user_achievements`
--
ALTER TABLE `user_achievements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_achievement` (`user_id`,`achievement_id`),
  ADD KEY `achievement_id` (`achievement_id`);

--
-- Indexes for table `user_library`
--
ALTER TABLE `user_library`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_book` (`user_id`,`book_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_book_id` (`book_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_is_downloaded` (`is_downloaded`),
  ADD KEY `idx_last_opened` (`last_opened_at`),
  ADD KEY `idx_user_library_user_status` (`user_id`,`status`),
  ADD KEY `idx_reading_streak` (`user_id`,`reading_streak_contribution`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `book_categories`
--
ALTER TABLE `book_categories`
  ADD CONSTRAINT `book_categories_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `book_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `book_recommendations`
--
ALTER TABLE `book_recommendations`
  ADD CONSTRAINT `book_recommendations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `book_recommendations_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reading_goals`
--
ALTER TABLE `reading_goals`
  ADD CONSTRAINT `reading_goals_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reading_sessions`
--
ALTER TABLE `reading_sessions`
  ADD CONSTRAINT `reading_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reading_sessions_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reading_streaks`
--
ALTER TABLE `reading_streaks`
  ADD CONSTRAINT `reading_streaks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD CONSTRAINT `subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_achievements`
--
ALTER TABLE `user_achievements`
  ADD CONSTRAINT `user_achievements_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_achievements_ibfk_2` FOREIGN KEY (`achievement_id`) REFERENCES `achievements` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_library`
--
ALTER TABLE `user_library`
  ADD CONSTRAINT `user_library_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_library_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
