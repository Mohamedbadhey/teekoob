const express = require('express');
const { body, param, query } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

// Get user's library
router.get('/', asyncHandler(async (req, res) => {
  const { status, format, language, page = 1, limit = 20 } = req.query;
  const userId = req.userId;
  
  const offset = (page - 1) * limit;
  
  // Build query
  let query = db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId)
    .where('b.status', 'published');
  
  // Apply filters
  if (status) {
    query = query.where('ul.status', status);
  }
  
  if (format) {
    query = query.where('b.format', format);
  }
  
  if (language) {
    query = query.where('b.language', language);
  }
  
  // Get total count for pagination - create a separate count query to avoid SQL mode issues
  let countQuery = db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId);
  
  // Apply the same filters to the count query
  if (status) {
    countQuery = countQuery.where('ul.status', status);
  }
  if (language) {
    countQuery = countQuery.where('b.language', language);
  }
  
  const totalCount = await countQuery.count('* as count').first();
  
  // Get books with user progress
  const books = await query
    .select(
      'b.id', 'b.title', 'b.title_somali', 'b.author', 'b.narrator',
      'b.cover_image_url', 'b.language', 'b.format',
      'b.duration_minutes', 'b.page_count', 'b.is_free', 'b.price',
      'ul.status', 'ul.current_page', 'ul.current_audio_position',
      'ul.progress_percentage', 'ul.is_downloaded', 'ul.last_read_at',
      'ul.last_listened_at', 'ul.started_reading_at', 'ul.completed_at'
    )
    .orderBy('ul.last_read_at', 'desc')
    .orderBy('ul.last_listened_at', 'desc')
    .limit(limit)
    .offset(offset);
  
  res.json({
    books,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount.count,
      totalPages: Math.ceil(totalCount.count / limit)
    }
  });
}));

// Add book to library
router.post('/', asyncHandler(async (req, res) => {
  const { bookId, status = 'reading' } = req.body;
  const userId = req.userId;
  
  if (!bookId) {
    return res.status(400).json({ 
      error: 'Book ID is required',
      code: 'BOOK_ID_REQUIRED'
    });
  }
  
  // Check if book exists and is published
  const book = await db('books')
    .where('id', bookId)
    .where('status', 'published')
    .first();
  
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  // Check if already in library
  const existingEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (existingEntry) {
    return res.status(400).json({ 
      error: 'Book already in library',
      code: 'BOOK_ALREADY_EXISTS'
    });
  }
  
  // Add to library
  const [libraryId] = await db('user_library').insert({
    user_id: userId,
    book_id: bookId,
    status,
    started_reading_at: new Date(),
    last_read_at: new Date()
  }).returning('id');
  
  logger.info('Book added to library:', { userId, bookId, libraryId });
  
  res.status(201).json({
    message: 'Book added to library successfully',
    libraryId
  });
}));

// Update reading progress
router.put('/:bookId/progress', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const { currentPage, currentAudioPosition, progressPercentage } = req.body;
  const userId = req.userId;
  
  // Validate input
  if (currentPage && (currentPage < 1 || currentPage > 10000)) {
    return res.status(400).json({ 
      error: 'Invalid page number',
      code: 'INVALID_PAGE'
    });
  }
  
  if (currentAudioPosition && currentAudioPosition < 0) {
    return res.status(400).json({ 
      error: 'Invalid audio position',
      code: 'INVALID_AUDIO_POSITION'
    });
  }
  
  if (progressPercentage && (progressPercentage < 0 || progressPercentage > 100)) {
    return res.status(400).json({ 
      error: 'Invalid progress percentage',
      code: 'INVALID_PROGRESS'
    });
  }
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Update progress
  const updateData = {
    updated_at: new Date()
  };
  
  if (currentPage !== undefined) {
    updateData.current_page = currentPage;
    updateData.last_read_at = new Date();
  }
  
  if (currentAudioPosition !== undefined) {
    updateData.current_audio_position = currentAudioPosition;
    updateData.last_listened_at = new Date();
  }
  
  if (progressPercentage !== undefined) {
    updateData.progress_percentage = progressPercentage;
    
    // Mark as completed if progress is 100%
    if (progressPercentage >= 100) {
      updateData.status = 'completed';
      updateData.completed_at = new Date();
    }
  }
  
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update(updateData);
  
  logger.info('Reading progress updated:', { userId, bookId, updateData });
  
  res.json({
    message: 'Progress updated successfully'
  });
}));

// Update book status
router.put('/:bookId/status', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const { status } = req.body;
  const userId = req.userId;
  
  if (!status || !['reading', 'completed', 'wishlist', 'archived'].includes(status)) {
    return res.status(400).json({ 
      error: 'Valid status is required',
      code: 'INVALID_STATUS'
    });
  }
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Update status
  const updateData = {
    status,
    updated_at: new Date()
  };
  
  if (status === 'completed') {
    updateData.completed_at = new Date();
  } else if (status === 'reading') {
    updateData.started_reading_at = new Date();
  }
  
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update(updateData);
  
  logger.info('Book status updated:', { userId, bookId, status });
  
  res.json({
    message: 'Status updated successfully'
  });
}));

// Add bookmark
router.post('/:bookId/bookmarks', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const { page, audioPosition, note, highlight } = req.body;
  const userId = req.userId;
  
  if (!page && !audioPosition) {
    return res.status(400).json({ 
      error: 'Page or audio position is required',
      code: 'POSITION_REQUIRED'
    });
  }
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Get existing bookmarks
  const bookmarks = libraryEntry.bookmarks || [];
  
  // Add new bookmark
  const newBookmark = {
    id: Date.now().toString(),
    page,
    audioPosition,
    note,
    highlight,
    createdAt: new Date().toISOString()
  };
  
  bookmarks.push(newBookmark);
  
  // Update bookmarks in database
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update({
      bookmarks: JSON.stringify(bookmarks),
      updated_at: new Date()
    });
  
  logger.info('Bookmark added:', { userId, bookId, bookmarkId: newBookmark.id });
  
  res.status(201).json({
    message: 'Bookmark added successfully',
    bookmark: newBookmark
  });
}));

// Get bookmarks for a book
router.get('/:bookId/bookmarks', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const userId = req.userId;
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .select('bookmarks')
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  const bookmarks = libraryEntry.bookmarks || [];
  
  res.json({ bookmarks });
}));

// Remove bookmark
router.delete('/:bookId/bookmarks/:bookmarkId', asyncHandler(async (req, res) => {
  const { bookId, bookmarkId } = req.params;
  const userId = req.userId;
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Get existing bookmarks
  const bookmarks = libraryEntry.bookmarks || [];
  const bookmarkIndex = bookmarks.findIndex(b => b.id === bookmarkId);
  
  if (bookmarkIndex === -1) {
    return res.status(404).json({ 
      error: 'Bookmark not found',
      code: 'BOOKMARK_NOT_FOUND'
    });
  }
  
  // Remove bookmark
  bookmarks.splice(bookmarkIndex, 1);
  
  // Update bookmarks in database
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update({
      bookmarks: JSON.stringify(bookmarks),
      updated_at: new Date()
    });
  
  logger.info('Bookmark removed:', { userId, bookId, bookmarkId });
  
  res.json({
    message: 'Bookmark removed successfully'
  });
}));

// Update reading preferences
router.put('/:bookId/preferences', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const { fontSize, fontFamily, theme, lineHeight, margin } = req.body;
  const userId = req.userId;
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Get existing preferences
  const preferences = libraryEntry.reading_preferences || {};
  
  // Update preferences
  if (fontSize !== undefined) preferences.fontSize = fontSize;
  if (fontFamily !== undefined) preferences.fontFamily = fontFamily;
  if (theme !== undefined) preferences.theme = theme;
  if (lineHeight !== undefined) preferences.lineHeight = lineHeight;
  if (margin !== undefined) preferences.margin = margin;
  
  // Update preferences in database
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update({
      reading_preferences: JSON.stringify(preferences),
      updated_at: new Date()
    });
  
  logger.info('Reading preferences updated:', { userId, bookId, preferences });
  
  res.json({
    message: 'Preferences updated successfully',
    preferences
  });
}));

// Mark book as downloaded
router.put('/:bookId/download', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const { downloadPath } = req.body;
  const userId = req.userId;
  
  if (!downloadPath) {
    return res.status(400).json({ 
      error: 'Download path is required',
      code: 'DOWNLOAD_PATH_REQUIRED'
    });
  }
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Update download status
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .update({
      is_downloaded: true,
      download_path: downloadPath,
      downloaded_at: new Date(),
      updated_at: new Date()
    });
  
  logger.info('Book marked as downloaded:', { userId, bookId, downloadPath });
  
  res.json({
    message: 'Book marked as downloaded successfully'
  });
}));

// Remove book from library
router.delete('/:bookId', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const userId = req.userId;
  
  // Check if book is in user's library
  const libraryEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (!libraryEntry) {
    return res.status(404).json({ 
      error: 'Book not found in library',
      code: 'BOOK_NOT_IN_LIBRARY'
    });
  }
  
  // Remove from library
  await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .del();
  
  logger.info('Book removed from library:', { userId, bookId });
  
  res.json({
    message: 'Book removed from library successfully'
  });
}));

// Toggle favorite status
router.put('/favorite', asyncHandler(async (req, res) => {
  const { userId, bookId, isFavorite } = req.body;
  const authenticatedUserId = req.userId;
  
  // Validate input
  if (!userId || !bookId || typeof isFavorite !== 'boolean') {
    return res.status(400).json({ 
      error: 'userId, bookId, and isFavorite are required',
      code: 'INVALID_INPUT'
    });
  }
  
  // Check if the authenticated user matches the requested userId
  if (authenticatedUserId !== userId) {
    return res.status(403).json({ 
      error: 'Access denied',
      code: 'ACCESS_DENIED'
    });
  }
  
  // Check if book exists and is published
  const book = await db('books')
    .where('id', bookId)
    .where('status', 'published')
    .first();
  
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  // Check if book is already in library
  const existingEntry = await db('user_library')
    .where('user_id', userId)
    .where('book_id', bookId)
    .first();
  
  if (existingEntry) {
    // Update existing entry
    await db('user_library')
      .where('user_id', userId)
      .where('book_id', bookId)
      .update({
        is_favorite: isFavorite,
        updated_at: new Date()
      });
    
    logger.info('Favorite status updated:', { userId, bookId, isFavorite });
    
    res.json({
      message: 'Favorite status updated successfully',
      isFavorite
    });
  } else {
    // Create new library entry as favorite
    const [libraryId] = await db('user_library').insert({
      user_id: userId,
      book_id: bookId,
      status: 'wishlist', // Default status for favorite-only items
      is_favorite: isFavorite,
      started_reading_at: new Date(),
      last_read_at: new Date(),
      created_at: new Date(),
      updated_at: new Date()
    }).returning('id');
    
    logger.info('Book added to library as favorite:', { userId, bookId, libraryId, isFavorite });
    
    res.status(201).json({
      message: 'Book added to library as favorite successfully',
      libraryId,
      isFavorite
    });
  }
}));

// Get reading statistics
router.get('/stats/overview', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  // Get library statistics
  const stats = await db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId)
    .select(
      db.raw('COUNT(*) as total_books'),
      db.raw('COUNT(CASE WHEN ul.status = \'reading\' THEN 1 END) as currently_reading'),
      db.raw('COUNT(CASE WHEN ul.status = \'completed\' THEN 1 END) as completed'),
      db.raw('COUNT(CASE WHEN ul.status = \'wishlist\' THEN 1 END) as wishlist'),
      db.raw('COUNT(CASE WHEN ul.is_downloaded = true THEN 1 END) as downloaded'),
      db.raw('COUNT(CASE WHEN ul.is_favorite = true THEN 1 END) as favorites'),
      db.raw('AVG(ul.progress_percentage) as avg_progress'),
      db.raw('SUM(CASE WHEN b.format = \'audiobook\' THEN b.duration_minutes ELSE 0 END) as total_audio_minutes'),
      db.raw('SUM(CASE WHEN b.format = \'ebook\' THEN b.page_count ELSE 0 END) as total_pages')
    )
    .first();
  
  // Get recent activity
  const recentActivity = await db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId)
    .whereNotNull('ul.last_read_at')
    .orWhereNotNull('ul.last_listened_at')
    .select(
      'b.id', 'b.title', 'b.cover_image_url', 'b.format',
      'ul.last_read_at', 'ul.last_listened_at', 'ul.progress_percentage'
    )
    .orderBy(db.raw('GREATEST(ul.last_read_at, ul.last_listened_at)'), 'desc')
    .limit(5);
  
  res.json({
    stats,
    recentActivity
  });
}));

module.exports = router;
