# 📚 Teekoob API Documentation

## Overview

The Teekoob API provides endpoints for managing a multilingual eBook and audiobook platform. The API supports both Somali and English languages and handles authentication, book management, user libraries, and subscription management.

**Base URL**: `https://api.teekoob.com/api/v1`
**Authentication**: JWT Bearer Token

## Authentication

### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "firstName": "John",
  "lastName": "Doe",
  "preferredLanguage": "english"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "preferred_language": "english",
    "subscription_plan": "free",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "token": "jwt_token_here"
}
```

### Login User
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "preferred_language": "english",
    "subscription_plan": "free"
  },
  "token": "jwt_token_here"
}
```

## Books

### Get All Books
```http
GET /books?page=1&limit=20&language=english&genre=fiction&search=title
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `language` (optional): Filter by language (somali, english, bilingual)
- `genre` (optional): Filter by genre
- `format` (optional): Filter by format (ebook, audiobook, both)
- `search` (optional): Search in title, author, description
- `featured` (optional): Show featured books only
- `newReleases` (optional): Show new releases only
- `popular` (optional): Show popular books only
- `free` (optional): Show free books only

**Response:**
```json
{
  "books": [
    {
      "id": "uuid",
      "title": "Book Title",
      "title_somali": "Cinwaanka Buugga",
      "author": "Author Name",
      "cover_image_url": "https://...",
      "language": "bilingual",
      "format": "both",
      "genre": "fiction",
      "rating": 4.5,
      "is_free": false,
      "price": 19.99
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### Get Book by ID
```http
GET /books/{id}
```

**Response:**
```json
{
  "book": {
    "id": "uuid",
    "title": "Book Title",
    "title_somali": "Cinwaanka Buugga",
    "description": "Book description",
    "description_somali": "Sharaxaada buugga",
    "author": "Author Name",
    "narrator": "Narrator Name",
    "language": "bilingual",
    "format": "both",
    "genre": "fiction",
    "page_count": 300,
    "duration_minutes": 360,
    "rating": 4.5,
    "is_free": false,
    "price": 19.99,
    "cover_image_url": "https://...",
    "ebook_file_url": "https://...",
    "audio_file_url": "https://..."
  }
}
```

### Get Book Content
```http
GET /books/{id}/content?format=ebook
```

**Query Parameters:**
- `format`: Content format (ebook, audiobook)

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "contentUrl": "https://...",
  "format": "ebook",
  "book": {
    "id": "uuid",
    "title": "Book Title",
    "language": "bilingual",
    "format": "both"
  }
}
```

## User Library

### Get User Library
```http
GET /library?status=reading&format=ebook&language=english
```

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `status` (optional): Filter by status (reading, completed, wishlist, archived)
- `format` (optional): Filter by format
- `language` (optional): Filter by language
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:**
```json
{
  "books": [
    {
      "id": "uuid",
      "title": "Book Title",
      "author": "Author Name",
      "cover_image_url": "https://...",
      "status": "reading",
      "current_page": 45,
      "progress_percentage": 15.0,
      "is_downloaded": false
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 25,
    "totalPages": 2
  }
}
```

### Add Book to Library
```http
POST /library
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "bookId": "uuid",
  "status": "reading"
}
```

### Update Reading Progress
```http
PUT /library/{bookId}/progress
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "currentPage": 50,
  "progressPercentage": 16.7
}
```

## Subscriptions

### Get Subscription Plans
```http
GET /payments/plans
```

**Response:**
```json
{
  "plans": [
    {
      "id": "free",
      "name": "Free",
      "nameSomali": "Bilaash",
      "price": 0,
      "currency": "USD",
      "features": [
        "Access to free books",
        "Basic reading features"
      ]
    },
    {
      "id": "premium_monthly",
      "name": "Premium Monthly",
      "nameSomali": "Premium Bilaha",
      "price": 9.99,
      "currency": "USD",
      "billingCycle": "monthly",
      "features": [
        "Access to all books",
        "Unlimited offline downloads"
      ]
    }
  ]
}
```

### Create Subscription
```http
POST /payments/create-subscription
```

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "planId": "premium_monthly",
  "paymentMethodId": "pm_..."
}
```

## Admin Endpoints

### Create Book
```http
POST /admin/books
```

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Request Body (multipart/form-data):**
```
title: Book Title
titleSomali: Cinwaanka Buugga
description: Book description
author: Author Name
language: bilingual
format: both
genre: fiction
coverImage: [file]
ebookFile: [file]
audioFile: [file]
```

### Get Analytics Overview
```http
GET /admin/analytics/overview?period=30
```

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Response:**
```json
{
  "overview": {
    "totalUsers": 1250,
    "newUsers": 45,
    "totalBooks": 89,
    "activeSubscriptions": 234,
    "revenue": 2345.67
  },
  "popularBooks": [
    {
      "id": "uuid",
      "title": "Popular Book",
      "rating": 4.8,
      "rating_count": 156
    }
  ]
}
```

## Error Handling

All API endpoints return consistent error responses:

```json
{
  "error": "Error message description",
  "code": "ERROR_CODE"
}
```

**Common Error Codes:**
- `TOKEN_MISSING`: Authentication token required
- `TOKEN_INVALID`: Invalid or expired token
- `USER_NOT_FOUND`: User not found
- `BOOK_NOT_FOUND`: Book not found
- `SUBSCRIPTION_REQUIRED`: Premium subscription required
- `VALIDATION_FAILED`: Request validation failed

**HTTP Status Codes:**
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `429`: Too Many Requests
- `500`: Internal Server Error

## Rate Limiting

The API implements rate limiting:
- **Limit**: 100 requests per 15 minutes per IP
- **Headers**: Rate limit information included in response headers

## File Upload Limits

- **Cover Images**: 5MB max
- **eBook Files**: 100MB max
- **Audio Files**: 100MB max
- **Supported Formats**: JPEG, PNG, WebP, EPUB, PDF, MP3

## Localization

The API supports multiple languages:
- **English**: Default language
- **Somali**: Native language support
- **Bilingual**: Content in both languages

Language preference can be set in user profile and affects:
- Book titles and descriptions
- Error messages
- UI text (when implemented)

## Webhooks

### Stripe Webhook
```http
POST /payments/webhook/stripe
```

**Headers:**
```
Stripe-Signature: {signature}
```

**Events Handled:**
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`

## Testing

### Test Environment
- **Base URL**: `https://test-api.teekoob.com/api/v1`
- **Test Database**: Separate test database with sample data
- **Mock Payments**: Test payment methods available

### Sample Data
The API includes sample books and users for testing:
- 8 sample books in various genres and languages
- Test user accounts
- Sample subscription plans

## SDKs and Libraries

### JavaScript/TypeScript
```bash
npm install teekoob-sdk
```

### Python
```bash
pip install teekoob-python
```

### Flutter/Dart
```yaml
dependencies:
  teekoob_flutter: ^1.0.0
```

## Support

For API support and questions:
- **Email**: api-support@teekoob.com
- **Documentation**: https://docs.teekoob.com
- **Status Page**: https://status.teekoob.com
- **Community**: https://community.teekoob.com
