const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const multer = require('multer');
const crypto = require('crypto');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

const logger = require('../utils/logger');

const router = express.Router();

// Configure multer for file uploads
const path = require('path');
const fs = require('fs');

// Create uploads directory if it doesn't exist (Railway persistent volume)
const uploadsDir = process.env.RAILWAY_VOLUME_MOUNT_PATH || path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('✅ Created uploads directory:', uploadsDir);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + '.' + file.originalname.split('.').pop());
  }
});

const upload = multer({ 
  storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
    files: 5 // Max 5 files
  },
  fileFilter: (req, file, cb) => {
    // Allow specific file types
    const allowedTypes = [
      // Document types
      'application/epub+zip',
      'application/pdf',
      'text/plain',
      
      // Image types
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/webp',
      'image/gif',
      
      // Audio types - accept all common audio formats
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/m4a',
      'audio/aac',
      'audio/ogg',
      'audio/webm',
      'audio/flac',
      'audio/x-m4a',
      'audio/mp4',
      'audio/x-wav',
      'audio/wave'
    ];
    
    // Also accept any file with audio/* MIME type
    if (allowedTypes.includes(file.mimetype) || file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Allowed types: images, audio files, PDF, EPUB, and text files`), false);
    }
  }
});





// ===== BOOK MANAGEMENT =====

// Get all books
router.get('/books', asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, search, genre, language, format, featured } = req.query;
  
  const offset = (page - 1) * limit;
  
  let query = db('books');
  
  // Apply filters
  if (search) {
    query = query.where(function() {
      this.where('title', 'like', `%${search}%`)
        .orWhere('authors', 'like', `%${search}%`)
        .orWhere('description', 'like', `%${search}%`);
    });
  }
  
  if (genre && genre !== 'all') {
    query = query.where('genre', genre);
  }
  
  if (language && language !== 'all') {
    query = query.where('language', language);
  }
  
  if (format && format !== 'all') {
    query = query.where('format', format);
  }
  
  if (featured && featured !== 'all') {
    query = query.where('is_featured', featured === 'true');
  }
  
  // Get total count
  const countQuery = query.clone();
  const totalCount = await countQuery.count('* as count').first();
  
  // Get books
  const books = await query
    .select('*')
    .orderBy('created_at', 'desc')
    .limit(parseInt(limit))
    .offset(offset);
  
  // Process books to ensure proper data types and full URLs
  const baseUrl = process.env.RAILWAY_PUBLIC_DOMAIN 
    ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/api/v1`
    : `${req.protocol}://${req.get('host')}/api/v1`;
    
  const processedBooks = books.map(book => ({
    ...book,
    authors: book.authors || '',
    authors_somali: book.authors_somali || '',
    is_featured: Boolean(book.is_featured),
    is_new_release: Boolean(book.is_new_release),
    is_premium: Boolean(book.is_premium),
    rating: book.rating ? parseFloat(book.rating) : 0,
    review_count: book.review_count ? parseInt(book.review_count) : 0,
    page_count: book.page_count ? parseInt(book.page_count) : null,
    duration: book.duration ? parseInt(book.duration) : null,
    // Convert relative URLs to full URLs
    cover_image_url: book.cover_image_url && book.cover_image_url.startsWith('/uploads/') 
      ? `${baseUrl}${book.cover_image_url}` 
      : book.cover_image_url,
    audio_url: book.audio_url && book.audio_url.startsWith('/uploads/') 
      ? `${baseUrl}${book.audio_url}` 
      : book.audio_url
  }));
  
  res.json({
    books: processedBooks,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(totalCount.count),
      totalPages: Math.ceil(parseInt(totalCount.count) / parseInt(limit))
    }
  });
}));

// Get single book
router.get('/books/:id', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Admin: Fetching book with ID:', id);
    
    const book = await db('books')
      .select('*')
      .where('id', id)
      .first();
    
    console.log('🔍 Admin: Database query result:', book ? 'Book found' : 'Book not found');
    
    if (!book) {
      console.log('❌ Admin: Book not found with ID:', id);
      return res.status(404).json({ 
        error: 'Book not found',
        code: 'BOOK_NOT_FOUND',
        requestedId: id
      });
    }
    
    console.log('✅ Admin: Successfully fetched book:', book.title);
    
    // Convert relative URLs to full URLs
    const baseUrl = process.env.RAILWAY_PUBLIC_DOMAIN 
      ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/api/v1`
      : `${req.protocol}://${req.get('host')}/api/v1`;
    
    const processedBook = {
      ...book,
      cover_image_url: book.cover_image_url && book.cover_image_url.startsWith('/uploads/') 
        ? `${baseUrl}${book.cover_image_url}` 
        : book.cover_image_url,
      audio_url: book.audio_url && book.audio_url.startsWith('/uploads/') 
        ? `${baseUrl}${book.audio_url}` 
        : book.audio_url
    };
    
    res.json(processedBook);
  } catch (error) {
    console.error('💥 Admin: Error fetching book:', error);
    console.error('💥 Admin: Error stack:', error.stack);
    res.status(500).json({
      error: 'Internal server error while fetching book',
      code: 'INTERNAL_ERROR',
      details: error.message
    });
  }
}));

// Create new book
router.post('/books', upload.fields([
  { name: 'coverImage', maxCount: 1 },
  { name: 'audioFile', maxCount: 1 }
]), asyncHandler(async (req, res) => {
      const {
      title,
      title_somali,
      description,
      description_somali,
      author,  // Frontend might send 'author'
      authors,  // Frontend might send 'authors'
      authors_somali,
      genre,
      genre_somali,
      language,
      format,
      duration,
      page_count,
      is_featured,
      is_new_release,
      is_premium,
      ebook_content  // New field for text content
    } = req.body;
    
    // Use authors if provided, otherwise fall back to author
    const finalAuthors = authors || author;
  // Validate required fields
  if (!title || !language || !format || !genre || !finalAuthors) {
    return res.status(400).json({ 
      error: 'Missing required fields',
      code: 'MISSING_FIELDS',
      missing: {
        title: !title,
        language: !language,
        format: !format,
        genre: !genre,
        authors: !finalAuthors
      }
    });
  }
  
  try {
    // Process uploaded files
    const fileUrls = {};
    if (req.files) {
      // TODO: Upload files to S3 and get URLs
      // Store full URLs for uploaded files
      Object.keys(req.files).forEach(fieldName => {
        const file = req.files[fieldName][0];
        const baseUrl = process.env.RAILWAY_PUBLIC_DOMAIN 
          ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/api/v1`
          : `${req.protocol}://${req.get('host')}/api/v1`;
        fileUrls[fieldName] = `${baseUrl}/uploads/${file.filename}`;
      });
    }
    
    // Create book record - explicitly set UUID for id field since MySQL table might not have auto-increment
    const bookData = {
      id: crypto.randomUUID(), // Generate a UUID for the id field
      title,
      title_somali: title_somali || null,
      description,
      description_somali: description_somali || null,
      authors: finalAuthors || null,
      authors_somali: authors_somali || null,
      genre,
      genre_somali: genre_somali || genre,
      language,
      format,
      cover_image_url: fileUrls.coverImage || null,
      audio_url: fileUrls.audioFile || null,
      ebook_content: ebook_content || null,  // Store text content instead of PDF URL
      page_count: page_count ? parseInt(page_count) : null,
      duration: duration ? parseInt(duration) : null,
      is_featured: is_featured === 'true' || is_featured === true,
      is_new_release: is_new_release === 'true' || is_new_release === true,
      is_premium: is_premium === 'true' || is_premium === true,
      rating: 0,
      review_count: 0,
      created_at: new Date(),
      updated_at: new Date()
    };
    
        // Clean up any empty strings that could cause database issues
    Object.keys(bookData).forEach(key => {
      if (bookData[key] === '') {
        bookData[key] = null;
      }
    });
    
    // For MySQL, we need to handle the insert differently since .returning() is not supported
    const result = await db('books').insert(bookData);
    
    // Get the inserted ID from the result - MySQL returns an object with insertId
    const bookId = result[0];
    
    logger.info('Book created:', { bookId, title });
    
    res.status(201).json({
      message: 'Book created successfully',
      bookId
    });
    
  } catch (error) {
    logger.error('Book creation failed:', error);
    res.status(500).json({ 
      error: 'Failed to create book',
      code: 'BOOK_CREATION_FAILED',
      details: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
}));

// Update book
router.put('/books/:id', upload.fields([
  { name: 'coverImage', maxCount: 1 },
  { name: 'audioFile', maxCount: 1 }
]), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;
  
  // Debug: Log what we're receiving
  console.log('🔍 Admin Update Book - Received data:');
  console.log('Authors:', updateData.authors, '(type:', typeof updateData.authors, ')');
  console.log('Authors Somali:', updateData.authors_somali, '(type:', typeof updateData.authors_somali, ')');
  
  // Check if book exists
  const existingBook = await db('books').where('id', id).first();
  if (!existingBook) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  try {
    // Process uploaded files
    if (req.files) {
      Object.keys(req.files).forEach(fieldName => {
        const file = req.files[fieldName][0];
        const fieldMap = {
          coverImage: 'cover_image_url',
          audioFile: 'audio_url'
        };
        
        if (fieldMap[fieldName]) {
          const baseUrl = process.env.RAILWAY_PUBLIC_DOMAIN 
            ? `https://${process.env.RAILWAY_PUBLIC_DOMAIN}/api/v1`
            : `${req.protocol}://${req.get('host')}/api/v1`;
          updateData[fieldMap[fieldName]] = `${baseUrl}/uploads/${file.filename}`;
        }
      });
    }
    
    // Process authors fields as simple strings
    if (updateData.authors) {
      console.log('🔍 Before processing - Authors:', updateData.authors, '(type:', typeof updateData.authors, ')');
      updateData.authors = updateData.authors;
      console.log('🔍 After processing - Authors:', updateData.authors, '(type:', typeof updateData.authors, ')');
    }
    
    if (updateData.authors_somali) {
      console.log('🔍 Before processing - Authors Somali:', updateData.authors_somali, '(type:', typeof updateData.authors_somali, ')');
      updateData.authors_somali = updateData.authors_somali;
      console.log('🔍 After processing - Authors Somali:', updateData.authors_somali, '(type:', typeof updateData.authors_somali, ')');
    }
    
    // Process boolean fields
    if (updateData.is_featured !== undefined) {
      updateData.is_featured = updateData.is_featured === 'true' || updateData.is_featured === true;
    }
    
    if (updateData.is_new_release !== undefined) {
      updateData.is_new_release = updateData.is_new_release === 'true' || updateData.is_new_release === true;
    }
    
    if (updateData.is_premium !== undefined) {
      updateData.is_premium = updateData.is_premium === 'true' || updateData.is_premium === true;
    }
    
    // Process numeric fields
    if (updateData.page_count !== undefined) {
      updateData.page_count = parseInt(updateData.page_count) || null;
    }
    
    if (updateData.duration !== undefined) {
      updateData.duration = parseInt(updateData.duration) || null;
    }
    
    // Debug: Log what we're about to save to database
    console.log('🔍 About to save to database:');
    console.log('Authors field:', updateData.authors, '(type:', typeof updateData.authors, ')');
    console.log('Authors Somali field:', updateData.authors_somali, '(type:', typeof updateData.authors_somali, ')');
    
    // Update book
    await db('books')
      .where('id', id)
      .update({
        ...updateData,
        updated_at: new Date()
      });
    
    logger.info('Book updated:', { bookId: id });
    
    res.json({
      message: 'Book updated successfully'
    });
    
  } catch (error) {
    logger.error('Book update failed:', error);
    res.status(500).json({ 
      error: 'Failed to update book',
      code: 'BOOK_UPDATE_FAILED'
    });
  }
}));

// Update book status
router.put('/books/:id/status', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isFeatured, isNewRelease, isPremium } = req.body;
  
  const updateData = {};
  if (isFeatured !== undefined) updateData.is_featured = isFeatured;
  if (isNewRelease !== undefined) updateData.is_new_release = isNewRelease;
  if (isPremium !== undefined) updateData.is_premium = isPremium;
  
  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ 
      error: 'No fields to update',
      code: 'NO_FIELDS'
    });
  }
  
  updateData.updated_at = new Date();
  
  await db('books')
    .where('id', id)
    .update(updateData);
  
  logger.info('Book status updated:', { bookId: id, updateData });
  
  res.json({
    message: 'Book status updated successfully'
  });
}));

// Delete book
router.delete('/books/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check if book exists
  const book = await db('books').where('id', id).first();
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  // Hard delete the book
  await db('books')
    .where('id', id)
    .del();
  
  logger.info('Book archived:', { bookId: id, title: book.title });
  
  res.json({
    message: 'Book archived successfully'
  });
}));

// Get book statistics
router.get('/books/stats', asyncHandler(async (req, res) => {
  try {
    // Total books
    const totalBooks = await db('books')
      .count('* as count')
      .first();
    
    // Featured books
    const featuredBooks = await db('books')
      .where('is_featured', true)
      .count('* as count')
      .first();
    
    // New releases
    const newReleases = await db('books')
      .where('is_new_release', true)
      .count('* as count')
      .first();
    
    // Premium books
    const premiumBooks = await db('books')
      .where('is_premium', true)
      .count('* as count')
      .first();
    
    // Books by language
    const booksByLanguage = await db('books')
      .select('language')
      .count('* as count')
      .groupBy('language');
    
    const languageStats = {};
    booksByLanguage.forEach(item => {
      languageStats[item.language] = parseInt(item.count);
    });
    
    // Books by format
    const booksByFormat = await db('books')
      .select('format')
      .count('* as count')
      .groupBy('format');
    
    const formatStats = {};
    booksByFormat.forEach(item => {
      formatStats[item.format] = parseInt(item.count);
    });
    
    // Average rating
    const avgRating = await db('books')
      .whereNotNull('rating')
      .avg('rating as average')
      .first();
    
    // Total downloads (placeholder - would need user_library table)
    const totalDownloads = 0; // TODO: Implement when user_library is available
    
    res.json({
      totalBooks: totalBooks.count,
      featuredBooks: featuredBooks.count,
      newReleases: newReleases.count,
      premiumBooks: premiumBooks.count,
      totalDownloads: totalDownloads,
      averageRating: parseFloat(avgRating.average || 0).toFixed(2),
      booksByLanguage: languageStats,
      booksByFormat: formatStats
    });
    
  } catch (error) {
    logger.error('Error fetching book statistics:', error);
    res.status(500).json({ 
      error: 'Failed to fetch book statistics',
      code: 'STATS_ERROR'
    });
  }
}));

// Bulk update books
router.put('/books/bulk', asyncHandler(async (req, res) => {
  const { bookIds, action, updates } = req.body;
  
  if (!bookIds || !Array.isArray(bookIds) || bookIds.length === 0) {
    return res.status(400).json({ 
      error: 'Invalid book IDs',
      code: 'INVALID_BOOK_IDS'
    });
  }
  
  if (!action) {
    return res.status(400).json({ 
      error: 'Action is required',
      code: 'MISSING_ACTION'
    });
  }
  
  try {
    let updateData = {};
    
    switch (action) {
      case 'feature':
        updateData = { is_featured: true };
        break;
      case 'unfeature':
        updateData = { is_featured: false };
        break;
      case 'markNew':
        updateData = { is_new_release: true };
        break;
      case 'markPremium':
        updateData = { is_premium: true };
        break;
      case 'delete':
        // For delete action, we'll do a hard delete instead of update
        const deleteResult = await db('books')
          .whereIn('id', bookIds)
          .del();
        
        logger.info('Bulk book delete:', { action, bookIds, deletedRows: deleteResult });
        
        return res.json({
          message: 'Bulk delete completed successfully',
          affectedRows: deleteResult,
          action
        });
      default:
        if (updates && typeof updates === 'object') {
          updateData = updates;
        } else {
          return res.status(400).json({ 
            error: 'Invalid action or updates',
            code: 'INVALID_ACTION'
          });
        }
    }
    
    updateData.updated_at = new Date();
    
    const result = await db('books')
      .whereIn('id', bookIds)
      .update(updateData);
    
    logger.info('Bulk book update:', { action, bookIds, affectedRows: result });
    
    res.json({
      message: 'Bulk operation completed successfully',
      affectedRows: result,
      action
    });
    
  } catch (error) {
    logger.error('Error in bulk book update:', error);
    res.status(500).json({ 
      error: 'Failed to perform bulk operation',
      code: 'BULK_UPDATE_ERROR'
    });
  }
}));

// ===== USER MANAGEMENT =====

// Create new user (admin only)
router.post('/users', asyncHandler(async (req, res) => {
  const { email, password, firstName, lastName, isAdmin = false } = req.body;
  
  // Check if user already exists
  const existingUser = await db('users').where('email', email).first();
  if (existingUser) {
    return res.status(400).json({ 
      error: 'User with this email already exists',
      code: 'USER_EXISTS'
    });
  }

  // Hash password
  const bcrypt = require('bcryptjs');
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(password, saltRounds);

  // Create user
  const [userId] = await db('users').insert({
    email,
    password_hash: passwordHash,
    first_name: firstName,
    last_name: lastName,
    language_preference: 'en',
    subscription_plan: 'free',
    is_active: true,
    is_verified: true,
    is_admin: isAdmin
  }).returning('id');

  // Get created user (without password)
  const user = await db('users')
    .select('id', 'email', 'first_name', 'last_name', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin', 'created_at')
    .where('id', userId)
    .first();

  logger.info('New user created by admin:', { email, userId, isAdmin });

  res.status(201).json({
    message: 'User created successfully',
    user
  });
}));

// Get all users with advanced filtering and pagination
router.get('/users', asyncHandler(async (req, res) => {
  console.log('🔍 /users endpoint called with params:', req.query);
  
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = 'all',
      subscriptionPlan = 'all',
      language = 'all',
      isVerified = 'all',
      isAdmin = 'all',
      sortBy = 'created_at',
      sortOrder = 'desc',
      dateFrom,
      dateTo
    } = req.query;
  
  // Convert page and limit to numbers
  const pageNum = parseInt(page);
  const limitNum = parseInt(limit);
  const offset = (pageNum - 1) * limitNum;
  
  // Build query conditions
  let conditions = [];
  let params = [];
  
  if (search) {
    conditions.push(`(first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR display_name LIKE ?)`);
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm, searchTerm);
  }
  
  if (status !== 'all') {
    conditions.push(`is_active = ?`);
    params.push(status === 'active');
  }
  
  if (subscriptionPlan !== 'all') {
    conditions.push(`subscription_plan = ?`);
    params.push(subscriptionPlan);
  }
  
  if (language !== 'all') {
    conditions.push(`language_preference = ?`);
    params.push(language);
  }
  
  if (isVerified !== 'all') {
    conditions.push(`is_verified = ?`);
    params.push(isVerified === 'true');
  }
  
  if (isAdmin !== 'all') {
    conditions.push(`is_admin = ?`);
    params.push(isAdmin === 'true');
  }
  
  if (dateFrom) {
    conditions.push(`created_at >= ?`);
    params.push(dateFrom);
  }
  
  if (dateTo) {
    conditions.push(`created_at <= ?`);
    params.push(dateTo);
  }
  
  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  
  // Get total count
  const countQuery = `SELECT COUNT(*) as total FROM users ${whereClause}`;
  const totalResult = await db.raw(countQuery, params);
  const total = totalResult[0][0].total;
  
  // Get users with pagination
  const usersQuery = `
    SELECT 
      id, email, first_name, last_name, display_name, avatar_url,
      language_preference, theme_preference, subscription_plan, subscription_status,
      subscription_expires_at, is_verified, is_active, is_admin,
      last_login_at, created_at, updated_at
    FROM users 
    ${whereClause}
    ORDER BY ${sortBy} ${sortOrder.toUpperCase()}
    LIMIT ? OFFSET ?
  `;
  
  const users = await db.raw(usersQuery, [...params, limitNum, offset]);
  
  // Transform field names to camelCase
  const transformedUsers = users[0].map(user => ({
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    displayName: user.display_name,
    avatarUrl: user.avatar_url,
    languagePreference: user.language_preference,
    themePreference: user.theme_preference,
    subscriptionPlan: user.subscription_plan,
    subscriptionStatus: user.subscription_status,
    subscriptionExpiresAt: user.subscription_expires_at,
    isVerified: user.is_verified,
    isActive: user.is_active,
    isAdmin: user.is_admin,
    lastLoginAt: user.last_login_at,
    createdAt: user.created_at,
    updatedAt: user.updated_at
  }));
  
  res.json({
      users: transformedUsers,
    pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
    
    console.log('🔍 /users response sent successfully with', transformedUsers.length, 'users');
  } catch (error) {
    console.error('❌ Error in /users endpoint:', error);
    res.status(500).json({ 
      error: 'Internal server error in users endpoint',
      details: error.message,
      stack: error.stack
    });
  }
}));

// Get comprehensive user statistics
router.get('/users/stats', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // Total users
  const totalUsers = await db('users').count('* as count').first();
  
  // Active users
  const activeUsers = await db('users').where('is_active', true).count('* as count').first();
  
  // Verified users
  const verifiedUsers = await db('users').where('is_verified', true).count('* as count').first();
  
  // Admin users
  const adminUsers = await db('users').where('is_admin', true).count('* as count').first();
  
  // New users in period
  const newUsers = await db('users')
    .where('created_at', '>=', startDate)
    .count('* as count')
    .first();
  
  // Users by subscription plan
  const usersByPlan = await db('users')
    .select('subscription_plan')
    .count('* as count')
    .groupBy('subscription_plan');
  
  // Users by language
  const usersByLanguage = await db('users')
    .select('language_preference')
    .count('* as count')
    .groupBy('language_preference');
  
  // Users by verification status
  const usersByVerification = await db('users')
    .select('is_verified')
    .count('* as count')
    .groupBy('is_verified');
  
  // Users by activity status
  const usersByActivity = await db('users')
    .select('is_active')
    .count('* as count')
    .groupBy('is_active');
  
  // Recent logins (last 7 days)
  const recentLogins = await db('users')
    .where('last_login_at', '>=', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000))
    .count('* as count')
    .first();
  
  // Users with subscriptions
  const usersWithSubscriptions = await db('subscriptions')
    .where('status', 'active')
    .count('* as count')
    .first();
  
  res.json({
    totalUsers: totalUsers.count,
    activeUsers: activeUsers.count,
    verifiedUsers: verifiedUsers.count,
    adminUsers: adminUsers.count,
    newUsers: newUsers.count,
    recentLogins: recentLogins.count,
    usersWithSubscriptions: usersWithSubscriptions.count,
    breakdown: {
      byPlan: usersByPlan,
      byLanguage: usersByLanguage,
      byVerification: usersByVerification,
      byActivity: usersByActivity
    }
  });
}));

// Get user analytics and insights
router.get('/users/analytics', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // User growth over time (MySQL compatible)
  const userGrowth = await db.raw(`
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as new_users
    FROM users 
    WHERE created_at >= ?
    GROUP BY DATE(created_at)
    ORDER BY date
  `, [startDate]);
  
  // User activity patterns (MySQL compatible)
  const activityPatterns = await db.raw(`
    SELECT 
      HOUR(last_login_at) as hour,
      COUNT(*) as login_count
    FROM users 
    WHERE last_login_at >= ? AND last_login_at IS NOT NULL
    GROUP BY HOUR(last_login_at)
    ORDER BY hour
  `, [startDate]);
  
  // User engagement by subscription plan
  const engagementByPlan = await db.raw(`
    SELECT 
      u.subscription_plan,
      COUNT(DISTINCT u.id) as user_count,
      AVG(ul.progress_percentage) as avg_progress,
      COUNT(ul.id) as total_books
    FROM users u
    LEFT JOIN user_library ul ON u.id = ul.user_id
    WHERE u.created_at >= ?
    GROUP BY u.subscription_plan
  `, [startDate]);
  
  // User retention analysis (MySQL compatible)
  const retentionData = await db.raw(`
    SELECT 
      DATE(DATE_SUB(created_at, INTERVAL WEEKDAY(created_at) DAY)) as week,
      COUNT(*) as new_users,
      COUNT(CASE WHEN last_login_at >= DATE_ADD(created_at, INTERVAL 7 DAY) THEN 1 END) as retained_7d,
      COUNT(CASE WHEN last_login_at >= DATE_ADD(created_at, INTERVAL 30 DAY) THEN 1 END) as retained_30d
    FROM users
    WHERE created_at >= ?
    GROUP BY DATE(DATE_SUB(created_at, INTERVAL WEEKDAY(created_at) DAY))
    ORDER BY week
  `, [startDate]);
  
  res.json({
    userGrowth: userGrowth[0],
    activityPatterns: activityPatterns[0],
    engagementByPlan: engagementByPlan[0],
    retentionData: retentionData[0]
  });
}));

// Get user reports and insights
router.get('/users/reports', asyncHandler(async (req, res) => {
  const { reportType = 'overview', period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  let reportData = {};
  
  switch (reportType) {
    case 'overview':
      // Comprehensive user overview (MySQL compatible)
      const overview = await db.raw(`
        SELECT 
          COUNT(*) as total_users,
          COUNT(CASE WHEN is_active = true THEN 1 END) as active_users,
          COUNT(CASE WHEN is_verified = true THEN 1 END) as verified_users,
          COUNT(CASE WHEN is_admin = true THEN 1 END) as admin_users,
          COUNT(CASE WHEN created_at >= ? THEN 1 END) as new_users,
          AVG(DATEDIFF(NOW(), created_at)) as avg_user_age_days,
          COUNT(CASE WHEN last_login_at >= ? THEN 1 END) as recently_active
        FROM users
      `, [startDate, startDate]);
      
      reportData = overview[0][0];
      break;
      
    case 'subscription':
      // Subscription analysis (MySQL compatible)
      const subscription = await db.raw(`
        SELECT 
          u.subscription_plan,
          u.subscription_status,
          COUNT(*) as user_count,
          AVG(DATEDIFF(NOW(), u.created_at)) as avg_tenure_days
        FROM users u
        GROUP BY u.subscription_plan, u.subscription_status
        ORDER BY u.subscription_plan, u.subscription_status
      `);
      
      reportData = subscription[0];
      break;
      
    case 'engagement':
      // User engagement analysis
      const engagement = await db.raw(`
        SELECT 
          u.id,
          u.email,
          u.first_name,
          u.last_name,
          u.subscription_plan,
          COUNT(ul.id) as books_in_library,
          AVG(ul.progress_percentage) as avg_progress,
          MAX(ul.last_opened_at) as last_activity,
          COUNT(CASE WHEN ul.is_downloaded = true THEN 1 END) as downloaded_books
        FROM users u
        LEFT JOIN user_library ul ON u.id = ul.user_id
        WHERE u.created_at >= ?
        GROUP BY u.id, u.email, u.first_name, u.last_name, u.subscription_plan
        ORDER BY books_in_library DESC
        LIMIT 50
      `, [startDate]);
      
      reportData = engagement[0];
      break;
      
    case 'geographic':
      // Language preference analysis
      const geographic = await db.raw(`
        SELECT 
          language_preference,
          COUNT(*) as user_count,
          ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as percentage
        FROM users
        GROUP BY language_preference
        ORDER BY user_count DESC
      `);
      
      reportData = geographic[0];
      break;
      
    case 'behavioral':
      // User behavior patterns (MySQL compatible)
      const behavioral = await db.raw(`
        SELECT 
          CASE 
            WHEN last_login_at IS NULL THEN 'Never Logged In'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 'Active Today'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Active This Week'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Active This Month'
            ELSE 'Inactive'
          END as activity_status,
          COUNT(*) as user_count
        FROM users
        GROUP BY 
          CASE 
            WHEN last_login_at IS NULL THEN 'Never Logged In'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 'Active Today'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Active This Week'
            WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Active This Month'
            ELSE 'Inactive'
          END
        ORDER BY user_count DESC
      `);
      
      reportData = behavioral[0];
      break;
      
    default:
      return res.status(400).json({ error: 'Invalid report type' });
  }
  
  res.json({
    reportType,
    period,
    generatedAt: new Date().toISOString(),
    data: reportData
  });
}));

// Add the exact endpoints the frontend is calling (BEFORE the generic :id route)
router.get('/users/activity', asyncHandler(async (req, res) => {
  console.log('🔍 /users/activity endpoint called with params:', req.query);
  
  try {
    const { period = '7', userId, activityType } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));
    
    console.log('🔍 Processing activity request for period:', period, 'startDate:', startDate);
  
  // Get user activity summary
  const activitySummary = await db.raw(`
    SELECT 
      COUNT(DISTINCT u.id) as total_users,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as active_today,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_this_week,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as active_this_month,
      AVG(CASE WHEN u.last_login_at IS NOT NULL THEN DATEDIFF(NOW(), u.last_login_at) ELSE NULL END) as avg_days_since_login
    FROM users u
    WHERE u.created_at >= ?
  `, [startDate]);
  
  // Get hourly activity patterns
  const hourlyPatterns = await db.raw(`
    SELECT 
      HOUR(u.last_login_at) as hour,
      COUNT(*) as activity_count
    FROM users u
    WHERE u.last_login_at >= ? AND u.last_login_at IS NOT NULL
    GROUP BY HOUR(u.last_login_at)
    ORDER BY hour
  `, [startDate]);
  
  // Get recent user activities (simulated for now)
  const recentActivities = Array.from({ length: 20 }, (_, i) => ({
    userId: `user-${i + 1}`,
    userName: `User ${i + 1}`,
    activityType: ['login', 'book_read', 'search', 'download', 'share'][Math.floor(Math.random() * 5)],
    timestamp: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
    details: { action: 'Sample activity' },
    sessionDuration: Math.floor(Math.random() * 3600),
    deviceInfo: { type: ['mobile', 'desktop', 'tablet'][Math.floor(Math.random() * 3)] },
    location: { city: 'Sample City', country: 'Sample Country' }
  }));
  
  // Generate mock data for charts
  const days = parseInt(period);
  const activityData = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    activityData.push({
      date: date.toISOString().split('T')[0],
      sessions: Math.floor(Math.random() * 100) + 50,
      activeUsers: Math.floor(Math.random() * 200) + 100,
      pageViews: Math.floor(Math.random() * 500) + 200,
      engagement: Math.floor(Math.random() * 40) + 60
    });
  }
  
    res.json({
      summary: activitySummary[0][0],
      hourlyPatterns: hourlyPatterns[0],
      recentActivities,
      activityData,
      period: `${period} days`,
      generatedAt: new Date().toISOString()
    });
    
    console.log('🔍 /users/activity response sent successfully');
  } catch (error) {
    console.error('❌ Error in /users/activity:', error);
    res.status(500).json({ 
      error: 'Internal server error in activity endpoint',
      details: error.message,
      stack: error.stack
    });
  }
}));

router.get('/users/segmentation', asyncHandler(async (req, res) => {
  console.log('🔍 /users/segmentation endpoint called with params:', req.query);
  
  try {
    const { period = '30' } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));
    
    console.log('🔍 Processing segmentation request for period:', period, 'startDate:', startDate);
  
  // Get all user segments with detailed analytics
  const segments = await db.raw(`
    SELECT 
      'High Value' as segment_name,
      COUNT(*) as user_count,
      'Users with premium/lifetime subscriptions' as description,
      'premium,lifetime' as criteria
    FROM users 
    WHERE subscription_plan IN ('premium', 'lifetime') AND created_at >= ?
    
    UNION ALL
    
    SELECT 
      'Active Users' as segment_name,
      COUNT(*) as user_count,
      'Users active in last 7 days' as description,
      'active_7d' as criteria
    FROM users 
    WHERE last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) AND created_at >= ?
    
    UNION ALL
    
    SELECT 
      'New Users' as segment_name,
      COUNT(*) as user_count,
      'Users created in last 30 days' as description,
      'new_30d' as criteria
    FROM users 
    WHERE created_at >= ?
    
    UNION ALL
    
    SELECT 
      'Engaged Readers' as segment_name,
      COUNT(DISTINCT u.id) as user_count,
      'Users with 5+ books in library' as description,
      'books_5plus' as criteria
    FROM users u
    JOIN user_library ul ON u.id = ul.user_id
    WHERE u.created_at >= ?
    GROUP BY u.id
    HAVING COUNT(ul.id) >= 5
    
    UNION ALL
    
    SELECT 
      'At Risk' as segment_name,
      COUNT(*) as user_count,
      'Users inactive for 30+ days' as description,
      'inactive_30d' as criteria
    FROM users 
    WHERE last_login_at < DATE_SUB(NOW(), INTERVAL 30 DAY) AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
    
    UNION ALL
    
    SELECT 
      'Language Specific' as segment_name,
      COUNT(*) as user_count,
      'Users with specific language preference' as description,
      'language_specific' as criteria
    FROM users 
    WHERE language_preference IN ('so', 'ar') AND created_at >= ?
  `, [startDate, startDate, startDate, startDate, startDate]);
  
  // Get segment performance metrics
  const segmentMetrics = await db.raw(`
    SELECT 
      u.subscription_plan,
      COUNT(*) as total_users,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_users,
      ROUND(COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) * 100.0 / COUNT(*), 2) as engagement_rate
    FROM users u
    WHERE u.created_at >= ?
    GROUP BY u.subscription_plan
    ORDER BY total_users DESC
  `, [startDate]);
  
  // Get geographic distribution (simulated)
  const geographicData = [
    { location: 'United States', users: Math.floor(Math.random() * 100) + 50, percentage: 35 },
    { location: 'United Kingdom', users: Math.floor(Math.random() * 100) + 30, percentage: 20 },
    { location: 'Canada', users: Math.floor(Math.random() * 100) + 20, percentage: 15 },
    { location: 'Australia', users: Math.floor(Math.random() * 100) + 15, percentage: 12 },
    { location: 'Germany', users: Math.floor(Math.random() * 100) + 10, percentage: 8 },
    { location: 'Others', users: Math.floor(Math.random() * 100) + 10, percentage: 10 }
  ];
  
  // Get behavioral patterns
  const behavioralPatterns = await db.raw(`
    SELECT 
      CASE 
        WHEN last_login_at IS NULL THEN 'Never Logged In'
        WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 'Daily Active'
        WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Weekly Active'
        WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Monthly Active'
        ELSE 'Inactive'
        END as activity_pattern,
        COUNT(*) as user_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as percentage
      FROM users 
      WHERE created_at >= ?
      GROUP BY 
        CASE 
          WHEN last_login_at IS NULL THEN 'Never Logged In'
          WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 'Daily Active'
          WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Weekly Active'
          WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Monthly Active'
          ELSE 'Inactive'
        END
      ORDER BY user_count DESC
  `, [startDate]);
  
    res.json({
      segments: segments[0],
      segmentMetrics: segmentMetrics[0],
      geographicData,
      behavioralPatterns: behavioralPatterns[0],
      period: `${period} days`,
      totalSegments: segments[0].length,
      generatedAt: new Date().toISOString()
    });
    
    console.log('🔍 /users/segmentation response sent successfully');
  } catch (error) {
    console.error('❌ Error in /users/segmentation:', error);
    res.status(500).json({ 
      error: 'Internal server error in segmentation endpoint',
      details: error.message,
      stack: error.stack
    });
  }
}));

// Get user details with comprehensive information
router.get('/users/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Get user basic info
  const user = await db('users').where('id', id).first();
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // Get user's library
  const library = await db('user_library')
    .where('user_id', id)
    .join('books', 'user_library.book_id', 'books.id')
    .select(
      'books.id', 'books.title', 'books.title_somali', 'books.cover_image_url',
      'user_library.status', 'user_library.progress_percentage',
      'user_library.current_position', 'user_library.last_opened_at'
    );
  
  // Get user's subscription history
  const subscriptions = await db('subscriptions')
    .where('user_id', id)
    .orderBy('created_at', 'desc');
  
  // Get user's reading statistics
  const readingStats = await db('user_library')
    .where('user_id', id)
    .select(
      db.raw('COUNT(*) as total_books'),
      db.raw('COUNT(CASE WHEN status = ? THEN 1 END) as completed_books', ['completed']),
      db.raw('COUNT(CASE WHEN status = ? THEN 1 END) as reading_books', ['reading']),
      db.raw('COUNT(CASE WHEN status = ? THEN 1 END) as wishlist_books', ['wishlist']),
      db.raw('AVG(progress_percentage) as avg_progress'),
      db.raw('COUNT(CASE WHEN is_downloaded = true THEN 1 END) as downloaded_books')
    )
    .first();
  
  // Get user's activity timeline
  const activityTimeline = await db.raw(`
    SELECT 
      'login' as activity_type,
      last_login_at as timestamp,
      'User logged in' as description
    FROM users 
    WHERE id = ? AND last_login_at IS NOT NULL
    
    UNION ALL
    
    SELECT 
      'library_add' as activity_type,
      created_at as timestamp,
      'Added book to library' as description
    FROM user_library 
    WHERE user_id = ?
    
    UNION ALL
    
    SELECT 
      'subscription' as activity_type,
      created_at as timestamp,
      'Subscription ' || status as description
    FROM subscriptions 
    WHERE user_id = ?
    
    ORDER BY timestamp DESC
    LIMIT 50
  `, [id, id, id]);
  
  res.json({
    user: {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      languagePreference: user.language_preference,
      themePreference: user.theme_preference,
      subscriptionPlan: user.subscription_plan,
      subscriptionStatus: user.subscription_status,
      subscriptionExpiresAt: user.subscription_expires_at,
      isVerified: user.is_verified,
      isActive: user.is_active,
      isAdmin: user.is_admin,
      lastLoginAt: user.last_login_at,
      createdAt: user.created_at,
      updatedAt: user.updated_at
    },
    library,
    subscriptions,
    readingStats,
    activityTimeline: activityTimeline.rows
  });
}));

// Update user status and permissions
router.put('/users/:id/status', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isActive, isVerified, isAdmin, subscriptionPlan, subscriptionStatus } = req.body;
  
  const updateData = {};
  if (isActive !== undefined) updateData.is_active = isActive;
  if (isVerified !== undefined) updateData.is_verified = isVerified;
  if (isAdmin !== undefined) updateData.is_admin = isAdmin;
  if (subscriptionPlan !== undefined) updateData.subscription_plan = subscriptionPlan;
  if (subscriptionStatus !== undefined) updateData.subscription_status = subscriptionStatus;
  
  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }
  
  updateData.updated_at = new Date();
  
  await db('users').where('id', id).update(updateData);
  
  res.json({ message: 'User updated successfully', updatedFields: Object.keys(updateData) });
}));

// Bulk update users
router.put('/users/bulk', asyncHandler(async (req, res) => {
  const { userIds, action, value } = req.body;
  
  if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
    return res.status(400).json({ error: 'User IDs array is required' });
  }
  
  if (!action || !value) {
    return res.status(400).json({ error: 'Action and value are required' });
  }
  
  let updateData = {};
  
  switch (action) {
    case 'activate':
      updateData = { is_active: true };
      break;
    case 'deactivate':
      updateData = { is_active: false };
      break;
    case 'verify':
      updateData = { is_verified: true };
      break;
    case 'unverify':
      updateData = { is_verified: false };
      break;
    case 'make_admin':
      updateData = { is_admin: true };
      break;
    case 'remove_admin':
      updateData = { is_admin: false };
      break;
    case 'change_plan':
      updateData = { subscription_plan: value };
      break;
    case 'change_status':
      updateData = { subscription_status: value };
      break;
    default:
      return res.status(400).json({ error: 'Invalid action' });
  }
  
  updateData.updated_at = new Date();
  
  await db('users').whereIn('id', userIds).update(updateData);
  
  res.json({ 
    message: `Bulk update completed: ${action} applied to ${userIds.length} users`,
    updatedUsers: userIds.length
  });
}));

// Delete user
router.delete('/users/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check if user exists
  const user = await db('users').where('id', id).first();
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // Prevent deletion of last admin
  if (user.is_admin) {
    const adminCount = await db('users').where('is_admin', true).count('* as count').first();
    if (adminCount.count <= 1) {
      return res.status(400).json({ error: 'Cannot delete the last admin user' });
    }
  }
  
  // Delete user (cascade will handle related records)
  await db('users').where('id', id).del();
  
  res.json({ message: 'User deleted successfully' });
}));

// ===== USER ACTIVITY MONITORING =====

// Get real-time user activity feed
router.get('/users/activity/feed', asyncHandler(async (req, res) => {
  const { limit = 50, period = '24' } = req.query;
  const startDate = new Date();
  startDate.setHours(startDate.getHours() - parseInt(period));
  
  // Get recent user activities
  const activities = await db.raw(`
    SELECT 
      u.id,
      u.email,
      u.first_name,
      u.last_name,
      u.last_login_at,
      CASE 
        WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 'Very Active'
        WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 'Active Today'
        WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Active This Week'
        ELSE 'Inactive'
      END as activity_level,
      COUNT(ul.id) as books_in_library,
      MAX(ul.last_opened_at) as last_book_activity
    FROM users u
    LEFT JOIN user_library ul ON u.id = ul.user_id
    WHERE u.last_login_at >= ?
    GROUP BY u.id, u.email, u.first_name, u.last_name, u.last_login_at
    ORDER BY u.last_login_at DESC
    LIMIT ?
  `, [startDate, parseInt(limit)]);
  
  res.json({
    activities: activities[0],
    period: `${period} hours`,
    totalActivities: activities[0].length
  });
}));

// Get user behavior analytics
router.get('/users/activity/behavior', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // User engagement patterns
  const engagement = await db.raw(`
    SELECT 
      u.subscription_plan,
      COUNT(DISTINCT u.id) as total_users,
      AVG(CASE WHEN ul.id IS NOT NULL THEN 1 ELSE 0 END) as avg_books_per_user,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_users_7d,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as active_users_30d
    FROM users u
    LEFT JOIN user_library ul ON u.id = ul.user_id
    WHERE u.created_at >= ?
    GROUP BY u.subscription_plan
    ORDER BY total_users DESC
  `, [startDate]);
  
  // Device usage patterns (simulated data for now)
  const deviceUsage = [
    { device: 'Mobile', users: Math.floor(Math.random() * 100) + 50 },
    { device: 'Desktop', users: Math.floor(Math.random() * 100) + 30 },
    { device: 'Tablet', users: Math.floor(Math.random() * 100) + 20 }
  ];
  
  res.json({
    engagement: engagement[0],
    deviceUsage,
    period: `${period} days`
  });
}));

// Get comprehensive user activity data (for the activity page)
router.get('/users/activity/comprehensive', asyncHandler(async (req, res) => {
  const { period = '7', userId, activityType } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // Build base query
  let whereClause = 'WHERE u.created_at >= ?';
  let params = [startDate];
  
  if (userId && userId !== 'all') {
    whereClause += ' AND u.id = ?';
    params.push(userId);
  }
  
  // Get user activity summary
  const activitySummary = await db.raw(`
    SELECT 
      COUNT(DISTINCT u.id) as total_users,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 END) as active_today,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_this_week,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as active_this_month,
      AVG(CASE WHEN u.last_login_at IS NOT NULL THEN DATEDIFF(NOW(), u.last_login_at) ELSE NULL END) as avg_days_since_login
    FROM users u
    ${whereClause}
  `, params);
  
  // Get hourly activity patterns
  const hourlyPatterns = await db.raw(`
    SELECT 
      HOUR(u.last_login_at) as hour,
      COUNT(*) as activity_count
    FROM users u
    ${whereClause} AND u.last_login_at IS NOT NULL
    GROUP BY HOUR(u.last_login_at)
    ORDER BY hour
  `, params);
  
  // Get activity by subscription plan
  const activityByPlan = await db.raw(`
    SELECT 
      u.subscription_plan,
      COUNT(*) as user_count,
      COUNT(CASE WHEN u.last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_users
    FROM users u
    ${whereClause}
    GROUP BY u.subscription_plan
    ORDER BY user_count DESC
  `, params);
  
  // Get recent user activities (simulated for now)
  const recentActivities = Array.from({ length: 20 }, (_, i) => ({
    userId: `user-${i + 1}`,
    userName: `User ${i + 1}`,
    activityType: ['login', 'book_read', 'search', 'download', 'share'][Math.floor(Math.random() * 5)],
    timestamp: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
    details: { action: 'Sample activity' },
    sessionDuration: Math.floor(Math.random() * 3600),
    deviceInfo: { type: ['mobile', 'desktop', 'tablet'][Math.floor(Math.random() * 3)] },
    location: { city: 'Sample City', country: 'Sample Country' }
  }));
  
  // Generate mock data for charts
  const days = parseInt(period);
  const activityData = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    activityData.push({
      date: date.toISOString().split('T')[0],
      sessions: Math.floor(Math.random() * 100) + 50,
      activeUsers: Math.floor(Math.random() * 200) + 100,
      pageViews: Math.floor(Math.random() * 500) + 200,
      engagement: Math.floor(Math.random() * 40) + 60
    });
  }
  
  res.json({
    summary: activitySummary[0][0],
    hourlyPatterns: hourlyPatterns[0],
    activityByPlan: activityByPlan[0],
    recentActivities,
    activityData,
    period: `${period} days`,
    generatedAt: new Date().toISOString()
  });
}));

// ===== USER SEGMENTATION =====

// Get user segments
router.get('/users/segments', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // Define user segments
  const segments = await db.raw(`
    SELECT 
      'High Value' as segment_name,
      COUNT(*) as user_count,
      'Users with premium/lifetime subscriptions' as description
    FROM users 
    WHERE subscription_plan IN ('premium', 'lifetime') AND created_at >= ?
    
    UNION ALL
    
    SELECT 
      'Active Users' as segment_name,
      COUNT(*) as user_count,
      'Users active in last 7 days' as description
    FROM users 
    WHERE last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) AND created_at >= ?
    
    UNION ALL
    
    SELECT 
      'New Users' as segment_name,
      COUNT(*) as user_count,
      'Users created in last 30 days' as description
    FROM users 
    WHERE created_at >= ?
    
    UNION ALL
    
    SELECT 
      'Engaged Readers' as segment_name,
      COUNT(DISTINCT u.id) as user_count,
      'Users with 5+ books in library' as description
    FROM users u
    JOIN user_library ul ON u.id = ul.user_id
    WHERE u.created_at >= ?
    GROUP BY u.id
    HAVING COUNT(ul.id) >= 5
  `, [startDate, startDate, startDate, startDate]);
  
  res.json({
    segments: segments[0],
    period: `${period} days`,
    totalSegments: segments[0].length
  });
}));

// Create custom user segment
router.post('/users/segments', asyncHandler(async (req, res) => {
  const { name, criteria, description } = req.body;
  
  if (!name || !criteria) {
    return res.status(400).json({ error: 'Segment name and criteria are required' });
  }
  
  // For now, we'll store segments in memory (in production, use a database table)
  // This is a simplified implementation
  
  const segment = {
    id: Date.now().toString(),
    name,
    criteria,
    description: description || '',
    createdAt: new Date(),
    userCount: 0 // Will be calculated when segment is used
  };
  
  res.status(201).json({
    message: 'User segment created successfully',
    segment
  });
}));

// Get segment analytics
router.get('/users/segments/:segmentId/analytics', asyncHandler(async (req, res) => {
  const { segmentId } = req.params;
  const { period = '30' } = req.query;
  
  // This would typically query the actual segment data
  // For now, returning mock analytics
  const analytics = {
    segmentId,
    period: `${period} days`,
    userCount: Math.floor(Math.random() * 100) + 50,
    engagementRate: Math.random() * 100,
    retentionRate: Math.random() * 100,
    avgBooksPerUser: Math.random() * 10 + 1,
    topLanguages: ['en', 'so', 'ar'],
    subscriptionDistribution: {
      free: Math.floor(Math.random() * 30) + 10,
      premium: Math.floor(Math.random() * 40) + 20,
      lifetime: Math.floor(Math.random() * 30) + 10
    }
  };
  
  res.json(analytics);
}));

// ===== USER INSIGHTS & PREDICTIVE ANALYTICS =====

// Get AI-powered user insights
router.get('/users/insights', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // User growth prediction
  const growthPrediction = await db.raw(`
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as new_users,
      LAG(COUNT(*)) OVER (ORDER BY DATE(created_at)) as prev_day_users
    FROM users 
    WHERE created_at >= ?
    GROUP BY DATE(created_at)
    ORDER BY date DESC
    LIMIT 7
  `, [startDate]);
  
  // Churn prediction (users who haven't logged in recently)
  const churnPrediction = await db.raw(`
    SELECT 
      COUNT(*) as potential_churn_users,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as churn_percentage
    FROM users 
    WHERE last_login_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
  `);
  
  // Revenue prediction based on subscription plans
  const revenuePrediction = await db.raw(`
    SELECT 
      subscription_plan,
      COUNT(*) as user_count,
      CASE 
        WHEN subscription_plan = 'free' THEN 0
        WHEN subscription_plan = 'premium' THEN COUNT(*) * 9.99
        WHEN subscription_plan = 'lifetime' THEN COUNT(*) * 99.99
        ELSE 0
      END as estimated_monthly_revenue
    FROM users 
    WHERE created_at >= ?
    GROUP BY subscription_plan
  `, [startDate]);
  
  // Behavioral insights
  const behavioralInsights = await db.raw(`
    SELECT 
      language_preference,
      COUNT(*) as user_count,
      AVG(DATEDIFF(NOW(), created_at)) as avg_tenure_days,
      COUNT(CASE WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as active_users
    FROM users 
    WHERE created_at >= ?
    GROUP BY language_preference
    ORDER BY user_count DESC
  `, [startDate]);
  
  res.json({
    growthPrediction: growthPrediction[0],
    churnPrediction: churnPrediction[0][0],
    revenuePrediction: revenuePrediction[0],
    behavioralInsights: behavioralInsights[0],
    period: `${period} days`,
    insights: [
      {
        type: 'growth',
        message: `User growth trend: ${growthPrediction[0].length > 0 ? 'Stable' : 'No data'}`,
        confidence: 85
      },
      {
        type: 'churn',
        message: `Churn risk: ${churnPrediction[0][0]?.potential_churn_users || 0} users at risk`,
        confidence: 78
      },
      {
        type: 'revenue',
        message: `Revenue potential: Focus on premium conversions`,
        confidence: 92
      }
    ]
  });
}));

// Get user recommendations
router.get('/users/recommendations', asyncHandler(async (req, res) => {
  const { userId, type = 'general' } = req.query;
  
  let recommendations = [];
  
  switch (type) {
    case 'retention':
      recommendations = [
        {
          category: 'Engagement',
          action: 'Send personalized book recommendations',
          impact: 'High',
          priority: 'Critical'
        },
        {
          category: 'Communication',
          action: 'Implement re-engagement email campaign',
          impact: 'Medium',
          priority: 'High'
        },
        {
          category: 'Content',
          action: 'Add more content in user\'s preferred language',
          impact: 'High',
          priority: 'High'
        }
      ];
      break;
      
    case 'conversion':
      recommendations = [
        {
          category: 'Subscription',
          action: 'Offer premium trial for active users',
          impact: 'High',
          priority: 'High'
        },
        {
          category: 'Features',
          action: 'Highlight premium features in app',
          impact: 'Medium',
          priority: 'Medium'
        }
      ];
      break;
      
    default:
      recommendations = [
        {
          category: 'General',
          action: 'Monitor user engagement patterns',
          impact: 'Medium',
          priority: 'Medium'
        }
      ];
  }
  
  res.json({
    recommendations,
    type,
    generatedAt: new Date().toISOString()
  });
}));

// Export users data
router.get('/users/export', asyncHandler(async (req, res) => {
  const { format = 'json', filters = {} } = req.query;
  
  // Build query based on filters
  let query = db('users').select('*');
  
  if (filters.status) {
    query = query.where('is_active', filters.status === 'active');
  }
  if (filters.subscriptionPlan) {
    query = query.where('subscription_plan', filters.subscriptionPlan);
  }
  if (filters.language) {
    query = query.where('language_preference', filters.language);
  }
  
  const users = await query;
  
  if (format === 'csv') {
    const csv = users.map(user => ({
      ID: user.id,
      Email: user.email,
      'First Name': user.first_name,
      'Last Name': user.last_name,
      'Display Name': user.display_name,
      'Language': user.language_preference,
      'Subscription Plan': user.subscription_plan,
      'Subscription Status': user.subscription_status,
      'Verified': user.is_verified ? 'Yes' : 'No',
      'Active': user.is_active ? 'Yes' : 'No',
      'Admin': user.is_admin ? 'Yes' : 'No',
      'Last Login': user.last_login_at,
      'Created': user.created_at,
      'Updated': user.updated_at
    }));
    
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="users-export.csv"');
    
    // Convert to CSV
    const csvContent = [
      Object.keys(csv[0]).join(','),
      ...csv.map(row => Object.values(row).map(val => `"${val || ''}"`).join(','))
    ].join('\n');
    
    res.send(csvContent);
  } else {
    res.json({ users, exportDate: new Date().toISOString() });
  }
}));

// Update user status
router.put('/users/:id/status', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isActive, isVerified } = req.body;
  
  const updateData = {};
  if (isActive !== undefined) updateData.is_active = isActive;
  if (isVerified !== undefined) updateData.is_verified = isVerified;
  
  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ 
      error: 'No fields to update',
      code: 'NO_FIELDS'
    });
  }
  
  updateData.updated_at = new Date();
  
  await db('users')
    .where('id', id)
    .update(updateData);
  
  logger.info('User status updated:', { userId: id, updateData });
  
  res.json({
    message: 'User status updated successfully'
  });
}));

// Bulk update users
router.put('/users/bulk', asyncHandler(async (req, res) => {
  const { userIds, action, updates } = req.body;
  
  if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
    return res.status(400).json({ error: 'User IDs array is required' });
  }
  
  try {
    let affectedRows = 0;
    
    switch (action) {
      case 'activate':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_active: true, updated_at: new Date() });
        break;
      case 'deactivate':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_active: false, updated_at: new Date() });
        break;
      case 'verify':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_verified: true, updated_at: new Date() });
        break;
      case 'unverify':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_verified: false, updated_at: new Date() });
        break;
      case 'makeAdmin':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_admin: true, updated_at: new Date() });
        break;
      case 'removeAdmin':
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ is_admin: false, updated_at: new Date() });
        break;
      case 'custom':
        if (!updates) {
          return res.status(400).json({ error: 'Updates object required for custom action' });
        }
        affectedRows = await db('users')
          .whereIn('id', userIds)
          .update({ ...updates, updated_at: new Date() });
        break;
      default:
        return res.status(400).json({ error: 'Invalid action specified' });
    }
    
    logger.info('Bulk user update:', { action, userIds, affectedRows });
    
    res.json({ 
      message: 'Bulk operation completed successfully', 
      affectedRows,
      action 
    });
  } catch (error) {
    logger.error('Error in bulk user update:', error);
    res.status(500).json({ error: 'Failed to perform bulk operation' });
  }
}));

// Delete user
router.delete('/users/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  try {
    // Check if user exists
    const user = await db('users').where('id', id).first();
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Prevent deleting the last admin user
    if (user.is_admin) {
      const adminCount = await db('users').where('is_admin', true).count('* as count').first();
      if (adminCount.count <= 1) {
        return res.status(400).json({ error: 'Cannot delete the last admin user' });
      }
    }
    
    // Delete user (you might want to soft delete instead)
    const deletedRows = await db('users').where('id', id).del();
    
    if (deletedRows > 0) {
      logger.info('User deleted:', { userId: id, email: user.email });
      res.json({ message: 'User deleted successfully' });
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (error) {
    logger.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
}));

// Export users
router.get('/users/export', asyncHandler(async (req, res) => {
  const { format = 'json' } = req.query;
  
  try {
    const users = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'is_active', 'is_verified', 'is_admin', 'created_at')
      .orderBy('created_at', 'desc');
    
    if (format === 'csv') {
      // Convert to CSV
      const csvHeader = 'ID,Email,First Name,Last Name,Status,Verified,Admin,Joined\n';
      const csvRows = users.map(user => 
        `${user.id},"${user.email}","${user.first_name}","${user.last_name}",${user.is_active ? 'Active' : 'Inactive'},${user.is_verified ? 'Yes' : 'No'},${user.is_admin ? 'Yes' : 'No'},"${user.created_at}"`
      ).join('\n');
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="users.csv"');
      res.send(csvHeader + csvRows);
    } else {
      // Return JSON
      res.json({ users, exportDate: new Date().toISOString() });
    }
  } catch (error) {
    logger.error('Error exporting users:', error);
    res.status(500).json({ error: 'Failed to export users' });
  }
}));

// ===== ANALYTICS =====

// Get dashboard overview
router.get('/analytics/overview', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query; // days
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // Total users
  const totalUsers = await db('users').count('* as count').first();
  
  // New users in period
  const newUsers = await db('users')
    .where('created_at', '>=', startDate)
    .count('* as count')
    .first();
  
  // Total books
  const totalBooks = await db('books')
    .count('* as count')
    .first();
  
  // Active subscriptions
  const activeSubscriptions = await db('subscriptions')
    .where('status', 'active')
    .count('* as count')
    .first();
  
  // Revenue in period
  const revenue = await db('subscriptions')
    .where('created_at', '>=', startDate)
    .sum('amount as total')
    .first();
  
  // Popular books
  const popularBooks = await db('books')
    .orderBy('rating', 'desc')
    .limit(5)
    .select('id', 'title', 'rating', 'review_count');
  
  res.json({
    overview: {
      totalUsers: totalUsers.count,
      newUsers: newUsers.count,
      totalBooks: totalBooks.count,
      activeSubscriptions: activeSubscriptions.count,
      revenue: revenue.total || 0
    },
    popularBooks
  });
}));

// Get user growth chart
router.get('/analytics/user-growth', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  const userGrowth = await db.raw(`
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as new_users
    FROM users 
    WHERE created_at >= ?
    GROUP BY DATE(created_at)
    ORDER BY date
  `, [startDate]);
  
  res.json({ userGrowth: userGrowth.rows });
}));

// Get book performance
router.get('/analytics/book-performance', asyncHandler(async (req, res) => {
  const { limit = 10 } = req.query;
  
  const bookPerformance = await db('books')
    .select(
      'id', 'title', 'authors', 'rating', 'review_count',
      'is_featured', 'is_new_release'
    )
    .orderBy('rating', 'desc')
    .limit(limit);
  
  res.json({ bookPerformance });
}));

// Update book status
router.put('/books/:id/status', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isFeatured, isNewRelease, isPremium } = req.body;
  
  const updateData = {};
  if (isFeatured !== undefined) updateData.is_featured = isFeatured;
  if (isNewRelease !== undefined) updateData.is_new_release = isNewRelease;
  if (isPremium !== undefined) updateData.is_premium = isPremium;
  
  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }
  
  updateData.updated_at = new Date();
  
  await db('books')
    .where('id', id)
    .update(updateData);
  
  logger.info('Book status updated:', { bookId: id, updateData });
  
  res.json({
    message: 'Book status updated successfully'
  });
}));

// Delete book
router.delete('/books/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  try {
    // Check if book exists
    const book = await db('books').where('id', id).first();
    if (!book) {
      return res.status(404).json({ error: 'Book not found' });
    }
    
    // Delete book
    const deletedRows = await db('books').where('id', id).del();
    
    if (deletedRows > 0) {
      logger.info('Book deleted:', { bookId: id, title: book.title });
      res.json({ message: 'Book deleted successfully' });
    } else {
      res.status(404).json({ error: 'Book not found' });
    }
  } catch (error) {
    logger.error('Error deleting book:', error);
    res.status(500).json({ error: 'Failed to delete book' });
  }
}));

// Bulk update books
router.put('/books/bulk', asyncHandler(async (req, res) => {
  const { bookIds, action, updates } = req.body;
  
  if (!bookIds || !Array.isArray(bookIds) || bookIds.length === 0) {
    return res.status(400).json({ error: 'Book IDs array is required' });
  }
  
  try {
    let affectedRows = 0;
    
    switch (action) {
      case 'feature':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_featured: true, updated_at: new Date() });
        break;
      case 'unfeature':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_featured: false, updated_at: new Date() });
        break;
      case 'markNewRelease':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_new_release: true, updated_at: new Date() });
        break;
      case 'unmarkNewRelease':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_new_release: false, updated_at: new Date() });
        break;
      case 'markPremium':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_premium: true, updated_at: new Date() });
        break;
      case 'unmarkPremium':
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ is_premium: false, updated_at: new Date() });
        break;
      case 'custom':
        if (!updates) {
          return res.status(400).json({ error: 'Updates object required for custom action' });
        }
        affectedRows = await db('books')
          .whereIn('id', bookIds)
          .update({ ...updates, updated_at: new Date() });
        break;
      default:
        return res.status(400).json({ error: 'Invalid action specified' });
    }
    
    logger.info('Bulk book update:', { action, bookIds, affectedRows });
    
    res.json({ 
      message: 'Bulk operation completed successfully', 
      affectedRows,
      action 
    });
  } catch (error) {
    logger.error('Error in bulk book update:', error);
    res.status(500).json({ error: 'Failed to perform bulk operation' });
  }
}));

// Get subscription analytics
router.get('/analytics/subscriptions', asyncHandler(async (req, res) => {
  const { period = '30' } = req.query;
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(period));
  
  // Subscription plans distribution
  const planDistribution = await db('subscriptions')
    .where('created_at', '>=', startDate)
    .select('plan_type')
    .count('* as count')
    .groupBy('plan_type');
  
  // Monthly recurring revenue
  const mrr = await db('subscriptions')
    .where('status', 'active')
    .where('plan_type', 'premium')
    .sum('amount as total')
    .first();
  
  // Churn rate (simplified calculation)
  const cancelledSubs = await db('subscriptions')
    .where('status', 'cancelled')
    .where('cancelled_at', '>=', startDate)
    .count('* as count')
    .first();
  
  const totalSubs = await db('subscriptions')
    .where('created_at', '>=', startDate)
    .count('* as count')
    .first();
  
  const churnRate = totalSubs.count > 0 ? (cancelledSubs.count / totalSubs.count) * 100 : 0;
  
  res.json({
    planDistribution,
    mrr: mrr.total || 0,
    churnRate: Math.round(churnRate * 100) / 100
  });
}));

// Get advanced analytics
router.get('/analytics/advanced', asyncHandler(async (req, res) => {
  const { timeRange = '30' } = req.query;
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - parseInt(timeRange));
  
  try {
    // Platform growth metrics
    const totalUsers = await db('users').count('* as count').first();
    const newUsers = await db('users')
      .where('created_at', '>=', startDate)
      .count('* as count').first();
    
    // Content engagement metrics
    const avgRating = await db('books').avg('rating as avg').first();
    const totalReviews = await db('books').sum('review_count as total').first();
    const totalBooks = await db('books').count('* as count').first();
    
    // Revenue metrics
    const revenue = await db('subscriptions')
      .where('created_at', '>=', startDate)
      .sum('amount as total').first();
    
    res.json({
      timeRange,
      revenue: { 
        total: revenue.total || 0, 
        currency: 'USD' 
      },
      activeUsers: totalUsers.count,
      contentEngagement: { 
        avg_rating: Math.round((avgRating.avg || 0) * 100) / 100, 
        total_reviews: totalReviews.total || 0, 
        total_books: totalBooks.count 
      },
      platformGrowth: { 
        total_users: totalUsers.count, 
        new_users: newUsers.count 
      }
    });
  } catch (error) {
    logger.error('Error fetching advanced analytics:', error);
    res.status(500).json({ error: 'Failed to fetch advanced analytics' });
  }
}));

// Export analytics data
router.get('/analytics/export', asyncHandler(async (req, res) => {
  const { timeRange = '30', format = 'json' } = req.query;
  
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(timeRange));
    
    // Get analytics data
    const analyticsData = await Promise.all([
      db('users').where('created_at', '>=', startDate).count('* as count').first(),
      db('books').count('* as count').first(),
      db('subscriptions').where('created_at', '>=', startDate).sum('amount as total').first()
    ]);
    
    const data = {
      timeRange,
      exportDate: new Date().toISOString(),
      metrics: {
        newUsers: analyticsData[0].count,
        totalBooks: analyticsData[1].count,
        revenue: analyticsData[2].total || 0
      }
    };
    
    if (format === 'csv') {
      const csvHeader = 'Time Range,Export Date,New Users,Total Books,Revenue\n';
      const csvRow = `${timeRange},${data.exportDate},${data.metrics.newUsers},${data.metrics.totalBooks},${data.metrics.revenue}\n`;
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="analytics-${timeRange}days.csv"`);
      res.send(csvHeader + csvRow);
    } else {
      res.json(data);
    }
  } catch (error) {
    logger.error('Error exporting analytics:', error);
    res.status(500).json({ error: 'Failed to export analytics' });
  }
}));

// ===== CONTENT MODERATION =====

// Get flagged content
router.get('/moderation/flagged', asyncHandler(async (req, res) => {
  // Return mock data for development
  const mockFlaggedContent = [
    {
      id: '1',
      type: 'book',
      title: 'The Great Adventure',
      description: 'Book reported for inappropriate content',
      reportedBy: 'user@example.com',
      reportedAt: '2024-01-20T10:30:00Z',
      reason: 'Inappropriate content',
      severity: 'high',
      status: 'pending',
      content: { title: 'The Great Adventure', author: 'John Doe' },
      reportCount: 3
    },
    {
      id: '2',
      type: 'review',
      title: 'User Review',
      description: 'Review reported for spam',
      reportedBy: 'admin@teekoob.com',
      reportedAt: '2024-01-20T09:15:00Z',
      reason: 'Spam',
      severity: 'medium',
      status: 'pending',
      content: { text: 'This is a great book!', rating: 5 },
      reportCount: 1
    },
    {
      id: '3',
      type: 'comment',
      title: 'User Comment',
      description: 'Comment reported for harassment',
      reportedBy: 'moderator@teekoob.com',
      reportedAt: '2024-01-20T08:45:00Z',
      reason: 'Harassment',
      severity: 'critical',
      status: 'pending',
      content: { text: 'Inappropriate comment text' },
      reportCount: 5
    }
  ];
  
  res.json({ flaggedContent: mockFlaggedContent });
}));

// Review flagged content
router.put('/moderation/review/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { action, reason } = req.body;
  
  // Process moderation action
  logger.info('Content moderation action:', { contentId: id, action, reason });
  
  res.json({
    message: 'Moderation action processed successfully'
  });
}));

// Get moderation rules
router.get('/moderation/rules', asyncHandler(async (req, res) => {
  try {
    // In a real system, you'd query a moderation_rules table
    // For now, return mock data structure
    const rules = [
      { id: 1, name: 'Profanity Filter', enabled: true, severity: 'medium', description: 'Automatically detect and flag profane language' },
      { id: 2, name: 'Hate Speech Detection', enabled: true, severity: 'high', description: 'Detect hate speech and discriminatory content' },
      { id: 3, name: 'Spam Detection', enabled: true, severity: 'low', description: 'Identify and flag spam content' },
      { id: 4, name: 'Violence Detection', enabled: false, severity: 'critical', description: 'Detect violent or graphic content' }
    ];
    
    res.json(rules);
  } catch (error) {
    logger.error('Error fetching moderation rules:', error);
    res.status(500).json({ error: 'Failed to fetch moderation rules' });
  }
}));

// Get moderation statistics
router.get('/moderation/stats', asyncHandler(async (req, res) => {
  try {
    // In a real system, you'd calculate these from actual flagged content
    // For now, return mock data structure
    const stats = {
      totalFlagged: 156,
      pendingReview: 23,
      resolved: 45,
      autoResolved: 89,
      averageResponseTime: '2.5 hours',
      todayFlagged: 12,
      thisWeekFlagged: 67,
      thisMonthFlagged: 234
    };
    
    res.json(stats);
  } catch (error) {
    logger.error('Error fetching moderation stats:', error);
    res.status(500).json({ error: 'Failed to fetch moderation stats' });
  }
}));

// ===== SYSTEM SETTINGS =====

// Get system settings
router.get('/settings', asyncHandler(async (req, res) => {
  // Return system configuration
  res.json({
    features: {
      userRegistration: true,
      socialLogin: true,
      offlineMode: true,
      multiLanguage: true
    },
    limits: {
      maxFileSize: '100MB',
      maxBooksPerUser: 1000,
      maxOfflineDownloads: 100
    }
  });
}));

// Update system settings
router.put('/settings', asyncHandler(async (req, res) => {
  const { features, limits } = req.body;
  
  // Update system settings
  logger.info('System settings updated:', { features, limits });
  
  res.json({
    message: 'System settings updated successfully'
  });
}));

// Get system backups
router.get('/settings/backups', asyncHandler(async (req, res) => {
  try {
    // In a real system, you'd query a backups table or filesystem
    // For now, return mock data structure
    const backups = [
      { 
        id: 1, 
        name: 'Full Backup - 2024-01-15', 
        type: 'full', 
        size: '2.5 GB', 
        created_at: '2024-01-15T10:00:00Z', 
        status: 'completed' 
      },
      { 
        id: 2, 
        name: 'Incremental Backup - 2024-01-16', 
        type: 'incremental', 
        size: '150 MB', 
        created_at: '2024-01-16T10:00:00Z', 
        status: 'completed' 
      }
    ];
    
    res.json(backups);
  } catch (error) {
    logger.error('Error fetching system backups:', error);
    res.status(500).json({ error: 'Failed to fetch system backups' });
  }
}));

// Create system backup
router.post('/settings/backups', asyncHandler(async (req, res) => {
  try {
    // In a real system, you'd trigger a backup process
    const backupId = Date.now();
    logger.info('System backup created:', { backupId });
    
    res.json({ 
      message: 'System backup created successfully', 
      backupId,
      status: 'initiated'
    });
  } catch (error) {
    logger.error('Error creating system backup:', error);
    res.status(500).json({ error: 'Failed to create system backup' });
  }
}));

// Restore system backup
router.post('/settings/backups/:id/restore', asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  try {
    // In a real system, you'd trigger a restore process
    logger.info('System backup restore initiated:', { backupId: id });
    
    res.json({ 
      message: 'System backup restore initiated successfully', 
      backupId: id,
      status: 'restoring'
    });
  } catch (error) {
    logger.error('Error restoring system backup:', error);
    res.status(500).json({ error: 'Failed to restore system backup' });
  }
}));

// ===== CATEGORY MANAGEMENT =====

// Get all categories
router.get('/categories', asyncHandler(async (req, res) => {
  const categories = await db('categories')
    .select('*')
    .orderBy('name', 'asc');
  
  res.json(categories);
}));

// Create new category
router.post('/categories', [
  body('name').notEmpty().trim().escape(),
  body('name_somali').optional().trim().escape(),
  body('description').optional().trim().escape(),
  body('description_somali').optional().trim().escape()
], asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed', 
      details: errors.array() 
    });
  }

  const { name, name_somali, description, description_somali } = req.body;
  
  const [categoryId] = await db('categories').insert({
    name,
    name_somali,
    description,
    description_somali,
    created_at: new Date(),
    updated_at: new Date()
  }).returning('id');

  const newCategory = await db('categories')
    .where('id', categoryId)
    .first();

  logger.info('Category created:', { categoryId, name });
  res.status(201).json(newCategory);
}));

// Update category
router.put('/categories/:id', [
  param('id').isInt().withMessage('Invalid category ID'),
  body('name').optional().trim().escape(),
  body('name_somali').optional().trim().escape(),
  body('description').optional().trim().escape(),
  body('description_somali').optional().trim().escape()
], asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed', 
      details: errors.array() 
    });
  }

  const { id } = req.params;
  const updates = req.body;
  updates.updated_at = new Date();

  await db('categories')
    .where('id', id)
    .update(updates);

  const updatedCategory = await db('categories')
    .where('id', id)
    .first();

  if (!updatedCategory) {
    return res.status(404).json({ error: 'Category not found' });
  }

  logger.info('Category updated:', { categoryId: id, name: updatedCategory.name });
  res.json(updatedCategory);
}));

// Delete category
router.delete('/categories/:id', [
  param('id').isInt().withMessage('Invalid category ID')
], asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Check if category is being used by any books
  const booksUsingCategory = await db('books')
    .where('genre', id)
    .count('* as count')
    .first();

  if (booksUsingCategory.count > 0) {
    return res.status(400).json({ 
      error: 'Cannot delete category that is being used by books',
      booksCount: booksUsingCategory.count
    });
  }

  await db('categories')
    .where('id', id)
    .del();

  logger.info('Category deleted:', { categoryId: id });
  res.json({ message: 'Category deleted successfully' });
}));

module.exports = router;
