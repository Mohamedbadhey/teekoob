# Database Migration Instructions for Reviews Table

## Overview
The reviews table allows users to rate and comment on books and podcasts. Each review is linked to a specific book or podcast through the `item_id` and `item_type` fields.

## Running the Migration

### Option 1: Using Knex CLI (Recommended)
```bash
cd backend
npm run migrate
```

Or directly:
```bash
cd backend
npx knex migrate:latest
```

### Option 2: Manual SQL Execution
If you prefer to run the SQL manually, execute the following in your MySQL database:

```sql
CREATE TABLE `reviews` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `item_id` varchar(36) NOT NULL COMMENT 'book_id or podcast_id',
  `item_type` enum('book','podcast') NOT NULL,
  `rating` decimal(3,2) NOT NULL DEFAULT '0.00' COMMENT 'Rating from 0.00 to 5.00',
  `comment` text COMMENT 'Optional comment/review text',
  `is_approved` tinyint(1) DEFAULT '1' COMMENT 'For moderation',
  `is_edited` tinyint(1) DEFAULT '0' COMMENT 'Track if review was edited',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_item_review` (`user_id`,`item_id`,`item_type`),
  KEY `idx_reviews_user_id` (`user_id`),
  KEY `idx_reviews_item_id` (`item_id`),
  KEY `idx_reviews_item_type` (`item_type`),
  KEY `idx_reviews_item` (`item_id`,`item_type`),
  KEY `idx_reviews_rating` (`rating`),
  KEY `idx_reviews_created_at` (`created_at`),
  KEY `idx_reviews_is_approved` (`is_approved`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Verification

After running the migration, verify the table was created:

```sql
-- Check if table exists
SHOW TABLES LIKE 'reviews';

-- Check table structure
DESCRIBE reviews;

-- Check indexes
SHOW INDEX FROM reviews;
```

## How It Works

### Reviews Relationship
- Each review is linked to a **specific book or podcast** via:
  - `item_id`: The ID of the book or podcast
  - `item_type`: Either 'book' or 'podcast'
  
### Example Data
```sql
-- Review for a book
INSERT INTO reviews (id, user_id, item_id, item_type, rating, comment) 
VALUES ('rev-001', 'user-123', 'book-456', 'book', 4.5, 'Great book!');

-- Review for a podcast  
INSERT INTO reviews (id, user_id, item_id, item_type, rating, comment)
VALUES ('rev-002', 'user-123', 'podcast-789', 'podcast', 5.0, 'Amazing podcast!');
```

### API Endpoints
- `GET /api/v1/reviews/book/:bookId` - Get all reviews for a specific book
- `GET /api/v1/reviews/podcast/:podcastId` - Get all reviews for a specific podcast
- `POST /api/v1/reviews` - Create a review (requires itemId and itemType)
- `DELETE /api/v1/reviews/:reviewId` - Delete a review

## Important Notes

1. **One Review Per User Per Item**: The unique constraint ensures each user can only have one review per book/podcast (they can update it, but not create multiple)

2. **User Relationship**: Reviews are linked to users via foreign key, so if a user is deleted, their reviews are also deleted (CASCADE)

3. **Item Relationship**: The `item_id` can reference either a book or podcast, but the API validates that the item exists before allowing a review

4. **Rating Updates**: When a review is created/updated/deleted, the book or podcast's average rating and review count are automatically recalculated

