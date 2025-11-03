# Reviews and Comments System Documentation

## Overview
The reviews system allows users to rate (0-5 stars) and comment on books and podcasts. Each book and podcast has its own separate review section, and all reviews are properly linked to specific items in the database.

## Database Structure

### Reviews Table
The `reviews` table links reviews to specific books or podcasts:

```sql
CREATE TABLE `reviews` (
  `id` varchar(36) PRIMARY KEY,
  `user_id` varchar(36) NOT NULL,           -- Links to users table
  `item_id` varchar(36) NOT NULL,           -- Book ID or Podcast ID
  `item_type` enum('book','podcast') NOT NULL,  -- Specifies if it's a book or podcast
  `rating` decimal(3,2) NOT NULL DEFAULT 0.00,  -- Rating from 0.00 to 5.00
  `comment` text,                          -- Optional comment text
  `is_approved` tinyint(1) DEFAULT 1,      -- For moderation
  `is_edited` tinyint(1) DEFAULT 0,        -- Track edits
  `created_at` timestamp,
  `updated_at` timestamp,
  
  -- One review per user per item
  UNIQUE KEY (`user_id`, `item_id`, `item_type`),
  
  -- Foreign key to users
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);
```

### How Reviews Link to Books and Podcasts

1. **For Books**: 
   - `item_id` = book ID (from `books` table)
   - `item_type` = 'book'

2. **For Podcasts**:
   - `item_id` = podcast ID (from `podcasts` table)
   - `item_type` = 'podcast'

## API Endpoints

### Get Reviews for a Book
```
GET /api/v1/reviews/book/:bookId
```
Returns all reviews for a specific book ID.

### Get Reviews for a Podcast
```
GET /api/v1/reviews/podcast/:podcastId
```
Returns all reviews for a specific podcast ID.

### Create/Update Review
```
POST /api/v1/reviews
Body: {
  itemId: "book-id-or-podcast-id",
  itemType: "book" or "podcast",
  rating: 4.5,
  comment: "Great content!"
}
```
- Validates that the book/podcast exists before creating review
- Updates existing review if user already reviewed this item
- Automatically recalculates book/podcast average rating

### Delete Review
```
DELETE /api/v1/reviews/:reviewId
```
- Removes the review
- Recalculates book/podcast average rating

## Frontend Integration

### Book Detail Page
```dart
CommentSection(
  itemId: book.id,           // Specific book ID
  itemType: 'book',          // Identifies as book
  userId: currentUserId,
  currentRating: book.rating,
  reviewCount: book.reviewCount,
)
```

### Podcast Detail Page
```dart
CommentSection(
  itemId: podcast.id,       // Specific podcast ID
  itemType: 'podcast',       // Identifies as podcast
  userId: currentUserId,
  currentRating: podcast.rating,
  reviewCount: podcast.reviewCount,
)
```

## Data Flow

1. **User views book detail page** → Frontend loads `book.id`
2. **CommentSection widget** → Requests reviews for `itemId: book.id, itemType: 'book'`
3. **API endpoint** → Queries `reviews` table WHERE `item_id = book.id AND item_type = 'book'`
4. **Returns reviews** → Only reviews for that specific book
5. **User adds review** → Creates review with `item_id = book.id, item_type = 'book'`
6. **Book rating updated** → Average rating recalculated for that specific book

## Example Data

### Book Review
```json
{
  "id": "rev-001",
  "user_id": "user-123",
  "item_id": "aa106e4d-61da-43e0-b290-8d3066ca5148",  // Book ID from books table
  "item_type": "book",
  "rating": 4.5,
  "comment": "Excellent book!",
  "user_first_name": "Mohamed",
  "user_last_name": "Badhey",
  "user_avatar_url": "https://..."
}
```

### Podcast Review
```json
{
  "id": "rev-002",
  "user_id": "user-123",
  "item_id": "8d36a306-1ffb-40ac-a426-83f94bf1769a",  // Podcast ID from podcasts table
  "item_type": "podcast",
  "rating": 5.0,
  "comment": "Amazing podcast series!",
  "user_first_name": "Mohamed",
  "user_last_name": "Badhey",
  "user_avatar_url": "https://..."
}
```

## Key Features

✅ **Separate Review Sections**: Each book and podcast has its own isolated review section
✅ **Proper Relationships**: Reviews are linked via `item_id` + `item_type` to ensure correct association
✅ **User Information**: Reviews include user name, avatar, and other profile data from `users` table
✅ **One Review Per User**: Each user can only have one review per book/podcast (can update it)
✅ **Automatic Rating Calculation**: Book/podcast ratings are automatically updated when reviews are added/updated/deleted
✅ **Validation**: API validates that books/podcasts exist before allowing reviews

## Database Migration

To create the reviews table, run:
```bash
cd backend
npm run migrate
```

Or manually execute the SQL from `backend/migrations/016_create_reviews_table.js`

See `MIGRATION_INSTRUCTIONS.md` for detailed migration steps.

