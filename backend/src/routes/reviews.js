const express = require('express');
const { body, param, query } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticateToken } = require('../middleware/auth');
const logger = require('../utils/logger');
const crypto = require('crypto');

const router = express.Router();

// Get reviews for a specific item (book or podcast)
router.get('/:itemType/:itemId', [
  param('itemType').isIn(['book', 'podcast']),
  param('itemId').notEmpty(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
], asyncHandler(async (req, res) => {
  const { itemType, itemId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const offset = (page - 1) * limit;

  try {
    // First verify the item exists
    let itemExists = false;
    if (itemType === 'book') {
      const book = await db('books').where('id', itemId).first();
      itemExists = !!book;
    } else if (itemType === 'podcast') {
      const podcast = await db('podcasts').where('id', itemId).first();
      itemExists = !!podcast;
    }

    if (!itemExists) {
      return res.status(404).json({
        error: `${itemType} not found`,
        code: 'ITEM_NOT_FOUND'
      });
    }

    // Get reviews with user information for this specific item
    const reviews = await db('reviews')
      .select(
        'reviews.*',
        'users.first_name as user_first_name',
        'users.last_name as user_last_name',
        'users.display_name as user_name',
        'users.avatar_url as user_avatar_url'
      )
      .leftJoin('users', 'reviews.user_id', 'users.id')
      .where({
        'reviews.item_id': itemId,
        'reviews.item_type': itemType,
        'reviews.is_approved': true
      })
      .orderBy('reviews.created_at', 'desc')
      .limit(limit)
      .offset(offset);

    // Get total count
    const countResult = await db('reviews')
      .where({
        'item_id': itemId,
        'item_type': itemType,
        'is_approved': true
      })
      .count('* as count')
      .first();

    const total = countResult ? parseInt(countResult.count) : 0;

    // Calculate average rating
    const avgRatingResult = await db('reviews')
      .where({
        'item_id': itemId,
        'item_type': itemType,
        'is_approved': true
      })
      .avg('rating as avg_rating')
      .first();

    const avgRating = avgRatingResult?.avg_rating 
      ? parseFloat(avgRatingResult.avg_rating) 
      : 0;

    res.json({
      reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      averageRating: avgRating,
      itemId,
      itemType
    });
  } catch (error) {
    logger.error('Error fetching reviews:', error);
    throw error;
  }
}));

// Create or update a review
router.post('/', authenticateToken, [
  body('itemId').notEmpty(),
  body('itemType').isIn(['book', 'podcast']),
  body('rating').isFloat({ min: 0, max: 5 }),
  body('comment').optional().isString().isLength({ max: 5000 }),
], asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { itemId, itemType, rating, comment } = req.body;

  // Validate that the item (book or podcast) exists
  let itemExists = false;
  if (itemType === 'book') {
    const book = await db('books').where('id', itemId).first();
    itemExists = !!book;
  } else if (itemType === 'podcast') {
    const podcast = await db('podcasts').where('id', itemId).first();
    itemExists = !!podcast;
  }

  if (!itemExists) {
    return res.status(404).json({
      error: `${itemType} not found`,
      code: 'ITEM_NOT_FOUND'
    });
  }

  try {
    // Check if user already has a review for this item
    const existingReview = await db('reviews')
      .where({
        user_id: userId,
        item_id: itemId,
        item_type: itemType
      })
      .first();

    let reviewId;
    let isNewReview = false;

    if (existingReview) {
      // Update existing review
      reviewId = existingReview.id;
      await db('reviews')
        .where('id', reviewId)
        .update({
          rating,
          comment: comment || null,
          is_edited: true,
          updated_at: db.fn.now()
        });
    } else {
      // Create new review
      reviewId = crypto.randomUUID();
      isNewReview = true;
      await db('reviews').insert({
        id: reviewId,
        user_id: userId,
        item_id: itemId,
        item_type: itemType,
        rating,
        comment: comment || null,
        is_approved: true,
        is_edited: false,
        created_at: db.fn.now(),
        updated_at: db.fn.now()
      });
    }

    // Update item rating and review count
    const avgRatingResult = await db('reviews')
      .where({
        item_id: itemId,
        item_type: itemType,
        is_approved: true
      })
      .avg('rating as avg_rating')
      .first();

    const avgRating = avgRatingResult?.avg_rating 
      ? parseFloat(avgRatingResult.avg_rating) 
      : 0;

    const reviewCountResult = await db('reviews')
      .where({
        item_id: itemId,
        item_type: itemType,
        is_approved: true
      })
      .count('* as count')
      .first();

    const reviewCount = reviewCountResult ? parseInt(reviewCountResult.count) : 0;

    // Update book or podcast table
    if (itemType === 'book') {
      await db('books')
        .where('id', itemId)
        .update({
          rating: avgRating,
          review_count: reviewCount,
          updated_at: db.fn.now()
        });
    } else if (itemType === 'podcast') {
      await db('podcasts')
        .where('id', itemId)
        .update({
          rating: avgRating,
          review_count: reviewCount,
          updated_at: db.fn.now()
        });
    }

    // Get the created/updated review with user info
    const review = await db('reviews')
      .select(
        'reviews.*',
        'users.first_name as user_first_name',
        'users.last_name as user_last_name',
        'users.display_name as user_name',
        'users.avatar_url as user_avatar_url'
      )
      .leftJoin('users', 'reviews.user_id', 'users.id')
      .where('reviews.id', reviewId)
      .first();

    res.status(isNewReview ? 201 : 200).json({
      review,
      message: isNewReview ? 'Review created successfully' : 'Review updated successfully'
    });
  } catch (error) {
    logger.error('Error creating/updating review:', error);
    throw error;
  }
}));

// Delete a review
router.delete('/:reviewId', authenticateToken, asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { reviewId } = req.params;

  try {
    // Get review to find item info
    const review = await db('reviews')
      .where({ id: reviewId, user_id: userId })
      .first();

    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }

    // Delete the review
    await db('reviews')
      .where({ id: reviewId, user_id: userId })
      .delete();

    // Update item rating and review count
    const avgRatingResult = await db('reviews')
      .where({
        item_id: review.item_id,
        item_type: review.item_type,
        is_approved: true
      })
      .avg('rating as avg_rating')
      .first();

    const avgRating = avgRatingResult?.avg_rating 
      ? parseFloat(avgRatingResult.avg_rating) 
      : 0;

    const reviewCountResult = await db('reviews')
      .where({
        item_id: review.item_id,
        item_type: review.item_type,
        is_approved: true
      })
      .count('* as count')
      .first();

    const reviewCount = reviewCountResult ? parseInt(reviewCountResult.count) : 0;

    // Update book or podcast table
    if (review.item_type === 'book') {
      await db('books')
        .where('id', review.item_id)
        .update({
          rating: avgRating,
          review_count: reviewCount,
          updated_at: db.fn.now()
        });
    } else if (review.item_type === 'podcast') {
      await db('podcasts')
        .where('id', review.item_id)
        .update({
          rating: avgRating,
          review_count: reviewCount,
          updated_at: db.fn.now()
        });
    }

    res.json({ message: 'Review deleted successfully' });
  } catch (error) {
    logger.error('Error deleting review:', error);
    throw error;
  }
}));

// Get user's review for a specific item
router.get('/user/:itemType/:itemId', authenticateToken, asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { itemType, itemId } = req.params;

  try {
    const review = await db('reviews')
      .select(
        'reviews.*',
        'users.first_name as user_first_name',
        'users.last_name as user_last_name',
        'users.display_name as user_name',
        'users.avatar_url as user_avatar_url'
      )
      .leftJoin('users', 'reviews.user_id', 'users.id')
      .where({
        'reviews.user_id': userId,
        'reviews.item_id': itemId,
        'reviews.item_type': itemType
      })
      .first();

    if (review) {
      res.json({ review });
    } else {
      res.json({ review: null });
    }
  } catch (error) {
    logger.error('Error fetching user review:', error);
    throw error;
  }
}));

module.exports = router;

