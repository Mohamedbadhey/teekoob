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
    .where('ul.user_id', userId);
  
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
  
  // Check if book exists
  const book = await db('books')
    .where('id', bookId)
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

// Toggle favorite status for books
router.put('/favorites/books/:bookId', asyncHandler(async (req, res) => {
  const { bookId } = req.params;
  const userId = req.userId;
  
  // Check if book exists
  const book = await db('books')
    .where('id', bookId)
    .first();
  
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  // Check if already favorited
  const existingFavorite = await db('user_favorites')
    .where('user_id', userId)
    .where('item_id', bookId)
    .where('item_type', 'book')
    .first();
  
  if (existingFavorite) {
    // Remove from favorites
    await db('user_favorites')
      .where('user_id', userId)
      .where('item_id', bookId)
      .where('item_type', 'book')
      .del();
    
    // Also update user_library if exists
    await db('user_library')
      .where('user_id', userId)
      .where('book_id', bookId)
      .update({
        is_favorite: false,
        updated_at: new Date()
      });
    
    logger.info('Book removed from favorites:', { userId, bookId });
    
    res.json({
      message: 'Book removed from favorites',
      isFavorite: false
    });
  } else {
    // Add to favorites
    const favoriteId = require('crypto').randomUUID();
    await db('user_favorites').insert({
      id: favoriteId,
      user_id: userId,
      item_id: bookId,
      item_type: 'book',
      created_at: new Date(),
      updated_at: new Date()
    });
    
    // Also update user_library if exists, or create entry
    const libraryEntry = await db('user_library')
      .where('user_id', userId)
      .where('book_id', bookId)
      .first();
    
    if (libraryEntry) {
      await db('user_library')
        .where('user_id', userId)
        .where('book_id', bookId)
        .update({
          is_favorite: true,
          updated_at: new Date()
        });
    } else {
      // Create library entry
      await db('user_library').insert({
        user_id: userId,
        book_id: bookId,
        status: 'wishlist',
        is_favorite: true,
        created_at: new Date(),
        updated_at: new Date()
      });
    }
    
    logger.info('Book added to favorites:', { userId, bookId, favoriteId });
    
    res.status(201).json({
      message: 'Book added to favorites',
      isFavorite: true
    });
  }
}));

// Toggle favorite status for podcasts
router.put('/favorites/podcasts/:podcastId', asyncHandler(async (req, res) => {
  const { podcastId } = req.params;
  const userId = req.userId;
  
  // Check if podcast exists
  const podcast = await db('podcasts')
    .where('id', podcastId)
    .first();
  
  if (!podcast) {
    return res.status(404).json({ 
      error: 'Podcast not found',
      code: 'PODCAST_NOT_FOUND'
    });
  }
  
  // Check if already favorited
  const existingFavorite = await db('user_favorites')
    .where('user_id', userId)
    .where('item_id', podcastId)
    .where('item_type', 'podcast')
    .first();
  
  if (existingFavorite) {
    // Remove from favorites
    await db('user_favorites')
      .where('user_id', userId)
      .where('item_id', podcastId)
      .where('item_type', 'podcast')
      .del();
    
    logger.info('Podcast removed from favorites:', { userId, podcastId });
    
    res.json({
      message: 'Podcast removed from favorites',
      isFavorite: false
    });
  } else {
    // Add to favorites
    const favoriteId = require('crypto').randomUUID();
    await db('user_favorites').insert({
      id: favoriteId,
      user_id: userId,
      item_id: podcastId,
      item_type: 'podcast',
      created_at: new Date(),
      updated_at: new Date()
    });
    
    logger.info('Podcast added to favorites:', { userId, podcastId, favoriteId });
    
    res.status(201).json({
      message: 'Podcast added to favorites',
      isFavorite: true
    });
  }
}));

// Get all favorites
router.get('/favorites', asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { type, page = 1, limit = 20 } = req.query;
  const offset = (page - 1) * limit;
  
  let query = db('user_favorites as uf')
    .where('uf.user_id', userId);
  
  // Filter by type if provided
  if (type && ['book', 'podcast'].includes(type)) {
    query = query.where('uf.item_type', type);
  }
  
  // Get total count
  const totalCount = await query.clone().count('* as count').first();
  
  // Get favorites with item details
  const favorites = await query
    .select('uf.*')
    .orderBy('uf.created_at', 'desc')
    .limit(limit)
    .offset(offset);
  
  // Get book details for book favorites
  const bookIds = favorites.filter(f => f.item_type === 'book').map(f => f.item_id);
  const books = bookIds.length > 0 
    ? await db('books')
        .whereIn('id', bookIds)
        .select('id', 'title', 'title_somali', 'authors', 'authors_somali', 'cover_image_url', 'language', 'format', 'is_free')
    : [];
  
  // Get podcast details for podcast favorites
  const podcastIds = favorites.filter(f => f.item_type === 'podcast').map(f => f.item_id);
  const podcasts = podcastIds.length > 0
    ? await db('podcasts')
        .whereIn('id', podcastIds)
        .select('id', 'title', 'title_somali', 'host', 'host_somali', 'cover_image_url', 'language', 'is_free')
    : [];
  
  // Combine favorites with item details
  const favoritesWithDetails = favorites.map(fav => {
    if (fav.item_type === 'book') {
      const book = books.find(b => b.id === fav.item_id);
      return {
        ...fav,
        item: book
      };
    } else {
      const podcast = podcasts.find(p => p.id === fav.item_id);
      return {
        ...fav,
        item: podcast
      };
    }
  }).filter(f => f.item != null); // Filter out items that don't exist anymore
  
  res.json({
    favorites: favoritesWithDetails,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount.count,
      totalPages: Math.ceil(totalCount.count / limit)
    }
  });
}));

// Check if book is favorited
router.get('/favorites/book/:itemId', asyncHandler(async (req, res) => {
  const { itemId } = req.params;
  const userId = req.userId;
  
  const favorite = await db('user_favorites')
    .where('user_id', userId)
    .where('item_id', itemId)
    .where('item_type', 'book')
    .first();
  
  res.json({
    isFavorite: !!favorite
  });
}));

// Check if podcast is favorited
router.get('/favorites/podcast/:itemId', asyncHandler(async (req, res) => {
  const { itemId } = req.params;
  const userId = req.userId;
  
  const favorite = await db('user_favorites')
    .where('user_id', userId)
    .where('item_id', itemId)
    .where('item_type', 'podcast')
    .first();
  
  res.json({
    isFavorite: !!favorite
  });
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
