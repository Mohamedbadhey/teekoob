const express = require('express');
const { query, param } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { optionalAuth } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Test database connection
router.get('/test', asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Testing database connection...');
    const result = await db.raw('SELECT 1 as test');
    console.log('✅ Database test result:', result);
    res.json({
      success: true,
      message: 'Database connection working',
      result: result[0]
    });
  } catch (error) {
    console.error('❌ Database test failed:', error);
    res.status(500).json({
      success: false,
      error: 'Database connection failed',
      details: error.message
    });
  }
}));

// Test books table
router.get('/count', asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Testing books table...');
    const count = await db('books').count('* as count').first();
    console.log('✅ Books count result:', count);
    res.json({
      success: true,
      message: 'Books table accessible',
      count: count.count
    });
  } catch (error) {
    console.error('❌ Books table test failed:', error);
    res.status(500).json({
      success: false,
      error: 'Books table query failed',
      details: error.message
    });
  }
}));

// Test specific book endpoint
router.get('/test/:id', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Testing book endpoint for ID:', id);
    
    const book = await db('books').where('id', id).first();
    
    if (!book) {
      return res.json({
        success: false,
        message: 'Book not found',
        id: id
      });
    }
    
    res.json({
      success: true,
      message: 'Book found',
      id: book.id,
      title: book.title,
      authors: book.authors,
      hasEbookContent: !!book.ebook_content,
      ebookContentLength: book.ebook_content ? book.ebook_content.length : 0
    });
  } catch (error) {
    console.error('💥 Error in test book endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Test failed',
      details: error.message
    });
  }
}));

// Get all unique genres/categories
router.get('/categories', asyncHandler(async (req, res) => {
  try {
    // First try to get from the new categories table
    const categories = await db('categories')
      .where('is_active', true)
      .orderBy('sort_order', 'asc')
      .orderBy('name', 'asc')
      .select('*');
    
    if (categories.length > 0) {
      // Get book count for each category
      const categoriesWithCounts = await Promise.all(
        categories.map(async (category) => {
          const bookCount = await db('book_categories')
            .where('category_id', category.id)
            .count('* as count')
            .first();
          
          return {
            ...category,
            book_count: parseInt(bookCount.count)
          };
        })
      );
      
      res.json({
        success: true,
        categories: categoriesWithCounts,
        total: categoriesWithCounts.length
      });
    } else {
      // No categories found - return empty array
      res.json({
        success: true,
        categories: [],
        total: 0
      });
    }
  } catch (error) {
    logger.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch categories'
    });
  }
}));

// Get books by language
router.get('/language/:language', asyncHandler(async (req, res) => {
  try {
    const { language } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    // Validate language code
    const validLanguages = ['en', 'so', 'ar'];
    if (!validLanguages.includes(language)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid language code. Supported languages: en, so, ar'
      });
    }

    // Get books by language
    const books = await db('books')
      .where('language', language)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 'cover_image_url',
        'audio_url', 'ebook_url', 'sample_url', 'duration', 'page_count',
        'rating', 'review_count', 'is_featured', 'is_new_release', 'is_premium',
        'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);

    // Get total count
    const totalCount = await db('books')
      .where('language', language)
      .count('* as count')
      .first();

    const total = totalCount.count;
    const totalPages = Math.ceil(total / limit);

    // Process books
    const processedBooks = books.map(book => ({
      ...book,
      authors: book.authors || '',
      authorsSomali: book.authors_somali || '',
      isFeatured: Boolean(book.isFeatured),
      isNewRelease: Boolean(book.isNewRelease),
      isPremium: Boolean(book.isPremium),
    }));

    res.json({
      success: true,
      language: language,
      books: processedBooks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    logger.error('Error fetching books by language:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch books by language'
    });
  }
}));

// Get all books with pagination and filters
router.get('/', asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Books endpoint called with query:', req.query);
    const { page = 1, limit = 20, search, category, categories, author, language, format, year, sortBy = 'created_at', sortOrder = 'desc' } = req.query;
    const offset = (page - 1) * limit;
    console.log('📊 Books endpoint params:', { page, limit, offset, search, category, categories, author, language, format, year, sortBy, sortOrder });

    let query = db('books')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 'cover_image_url',
        'audio_url', 'ebook_content', 'sample_url', 'duration', 'page_count',
        'rating', 'review_count', 'is_featured', 'is_new_release', 'is_premium',
        'metadata', 'created_at', 'updated_at'
      );

    // Apply search filter
    if (search) {
      query = query.where(function() {
        this.where('title', 'like', `%${search}%`)
          .orWhere('title_somali', 'like', `%${search}%`)
          .orWhere('description', 'like', `%${search}%`)
          .orWhere('description_somali', 'like', `%${search}%`)
          .orWhere('authors', 'like', `%${search}%`)
          .orWhere('authors_somali', 'like', `%${search}%`);
      });
    }

    // Apply category filter (support both single category and multiple categories)
    const categoryIds = [];
    if (category) {
      categoryIds.push(category);
    }
    if (categories) {
      // Handle comma-separated categories or array
      const categoriesArray = Array.isArray(categories) ? categories : categories.split(',');
      categoryIds.push(...categoriesArray);
    }
    
    if (categoryIds.length > 0) {
      // Remove duplicates
      const uniqueCategoryIds = [...new Set(categoryIds)];
      console.log('📊 Filtering by categories:', uniqueCategoryIds);
      
      query = query.whereExists(function() {
        this.select('*')
          .from('book_categories')
          .whereRaw('book_categories.book_id = books.id')
          .whereIn('book_categories.category_id', uniqueCategoryIds);
      });
    }

    // Apply author filter
    if (author) {
      query = query.where('authors', 'like', `%${author}%`);
    }

    // Apply language filter
    if (language) {
      query = query.where('language', language);
    }

    // Apply format filter
    if (format) {
      query = query.where('format', format);
    }

    // Apply year filter
    if (year) {
      const yearInt = parseInt(year);
      if (!isNaN(yearInt)) {
        query = query.whereRaw('YEAR(created_at) = ?', [yearInt]);
      }
    }

    // Get total count - create a separate count query to avoid SQL mode issues
    console.log('📊 Getting total count...');
    let countQuery = db('books');
    
    // Apply the same filters to the count query
    if (search) {
      countQuery = countQuery.where(function() {
        this.where('title', 'like', `%${search}%`)
          .orWhere('title_somali', 'like', `%${search}%`)
          .orWhere('description', 'like', `%${search}%`)
          .orWhere('description_somali', 'like', `%${search}%`)
          .orWhere('authors', 'like', `%${search}%`)
          .orWhere('authors_somali', 'like', `%${search}%`);
      });
    }
    // Apply category filter to count query
    if (categoryIds.length > 0) {
      countQuery = countQuery.whereExists(function() {
        this.select('*')
          .from('book_categories')
          .whereRaw('book_categories.book_id = books.id')
          .whereIn('book_categories.category_id', uniqueCategoryIds);
      });
    }
    if (author) {
      countQuery = countQuery.where('authors', 'like', `%${author}%`);
    }
    if (language) {
      countQuery = countQuery.where('language', language);
    }
    if (format) {
      countQuery = countQuery.where('format', format);
    }
    if (year) {
      const yearInt = parseInt(year);
      if (!isNaN(yearInt)) {
        countQuery = countQuery.whereRaw('YEAR(created_at) = ?', [yearInt]);
      }
    }
    
    const totalCount = await countQuery.count('* as count').first();
    console.log('📊 Total count result:', totalCount);
    const total = totalCount.count;
    const totalPages = Math.ceil(total / limit);
    console.log('📊 Total:', total, 'Total pages:', totalPages);

    // Apply sorting and pagination
    console.log('📚 Getting books with sorting and pagination...');
    console.log('🔄 Sorting by:', sortBy, 'Order:', sortOrder);
    
    // Validate sortBy parameter to prevent SQL injection
    const allowedSortFields = ['created_at', 'updated_at', 'title', 'rating', 'review_count', 'page_count', 'duration'];
    const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'created_at';
    const validSortOrder = ['asc', 'desc'].includes(sortOrder.toLowerCase()) ? sortOrder.toLowerCase() : 'desc';
    
    console.log('✅ Using validated sort:', validSortBy, validSortOrder);
    
    const books = await query
      .orderBy(validSortBy, validSortOrder)
      .limit(parseInt(limit))
      .offset(offset);
    console.log('📚 Retrieved books:', books.length);

    // Process books to handle JSON fields and fetch categories
    const processedBooks = await Promise.all(books.map(async (book) => {
      // Fetch categories for this book
      const categories = await db('book_categories')
        .join('categories', 'book_categories.category_id', 'categories.id')
        .where('book_categories.book_id', book.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: book.id,
        title: book.title,
        titleSomali: book.title_somali,
        description: book.description,
        descriptionSomali: book.description_somali,
        authors: book.authors || '',
        authorsSomali: book.authors_somali || '',
        language: book.language,
        format: book.format,
        coverImageUrl: book.cover_image_url,
        audioUrl: book.audio_url,
        ebookContent: book.ebook_content,  // Changed from ebookUrl to ebookContent
        sampleUrl: book.sample_url,
        duration: book.duration,
        pageCount: book.page_count,
        rating: book.rating,
        reviewCount: book.review_count,
        isFeatured: Boolean(book.is_featured),
        isNewRelease: Boolean(book.is_new_release),
        isPremium: Boolean(book.is_premium),
        metadata: book.metadata,
        createdAt: book.created_at,
        updatedAt: book.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      books: processedBooks,
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    console.error('💥 Error in books endpoint:', error);
    console.error('💥 Error stack:', error.stack);
    logger.error('Error fetching books:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch books',
      details: error.message
    });
  }
}));

// Get book by ID
router.get('/:id', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Book by ID endpoint called with ID:', id);
    
    const book = await db('books')
      .where('id', id)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 'cover_image_url',
        'audio_url', 'ebook_content', 'sample_url', 'duration', 'page_count',
        'rating', 'review_count', 'is_featured', 'is_new_release', 'is_premium',
        'metadata', 'created_at', 'updated_at'
      )
      .first();

    if (!book) {
      console.log('❌ Book not found for ID:', id);
      return res.status(404).json({
        success: false,
        error: 'Book not found'
      });
    }

    console.log('✅ Book found:', {
      id: book.id,
      title: book.title,
      authors: book.authors,
      ebookContent: book.ebook_content ? `${book.ebook_content.length} chars` : 'null'
    });

    // Get categories for this book
    const categories = await db('book_categories')
      .join('categories', 'book_categories.category_id', 'categories.id')
      .where('book_categories.book_id', id)
      .where('categories.is_active', true)
      .select('categories.id', 'categories.name', 'categories.name_somali')
      .orderBy('categories.sort_order', 'asc');

    // Process book data
    const processedBook = {
      ...book,
      authors: book.authors || '',
      authorsSomali: book.authors_somali || '',
      categories: categories.map(cat => cat.id),
      categoryNames: categories.map(cat => cat.name),
      categoryNamesSomali: categories.map(cat => cat.name_somali),
      ebookContent: book.ebook_content,  // Changed from ebookUrl to ebookContent
      isFeatured: Boolean(book.is_featured),
      isNewRelease: Boolean(book.is_new_release),
      isPremium: Boolean(book.is_premium),
      createdAt: book.created_at,
      updatedAt: book.updated_at,
    };

    console.log('📤 Sending processed book data:', {
      id: processedBook.id,
      title: processedBook.title,
      authors: processedBook.authors,
      ebookContent: processedBook.ebookContent ? `${processedBook.ebookContent.length} chars` : 'null'
    });

    // Return the book data directly (not wrapped in success object)
    res.json(processedBook);
  } catch (error) {
    console.error('💥 Error in book by ID endpoint:', error);
    console.error('💥 Error stack:', error.stack);
    logger.error('Error fetching book:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch book',
      details: error.message
    });
  }
}));

// Update a book
router.put('/:id', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    // Check if book exists
    const existingBook = await db('books').where('id', id).first();
    if (!existingBook) {
      return res.status(404).json({
        success: false,
        error: 'Book not found'
      });
    }

    // Handle file uploads
    const files = req.files;
    if (files) {
      if (files['coverImage'] && files['coverImage'][0]) {
        updateData.cover_image_url = files['coverImage'][0].path;
      }
      if (files['audioFile'] && files['audioFile'][0]) {
        updateData.audio_url = files['audioFile'][0].path;
      }
      if (files['sampleFile'] && files['sampleFile'][0]) {
        updateData.sample_url = files['sampleFile'][0].path;
      }
    }

    // Update the book
    await db('books')
      .where('id', id)
      .update({
        ...updateData,
        updated_at: new Date()
      });

    // Get the updated book
    const updatedBook = await db('books').where('id', id).first();
    
    // Get categories for this book
    const categories = await db('book_categories')
      .join('categories', 'book_categories.category_id', 'categories.id')
      .where('book_categories.book_id', id)
      .where('categories.is_active', true)
      .select('categories.id', 'categories.name', 'categories.name_somali')
      .orderBy('categories.sort_order', 'asc');
    
    // Process the book data
    const processedBook = {
      id: updatedBook.id,
      title: updatedBook.title,
      titleSomali: updatedBook.title_somali,
      description: updatedBook.description,
      descriptionSomali: updatedBook.description_somali,
      authors: updatedBook.authors || '',
      authorsSomali: updatedBook.authors_somali || '',
      categories: categories.map(cat => cat.id),
      categoryNames: categories.map(cat => cat.name),
      categoryNamesSomali: categories.map(cat => cat.name_somali),
      language: updatedBook.language,
      format: updatedBook.format,
      coverImageUrl: updatedBook.cover_image_url,
      audioUrl: updatedBook.audio_url,
      ebookContent: updatedBook.ebook_content,  // Changed from ebookUrl to ebookContent
      sampleUrl: updatedBook.sample_url,
      duration: updatedBook.duration,
      pageCount: updatedBook.page_count,
      rating: updatedBook.rating,
      reviewCount: updatedBook.review_count,
      isFeatured: Boolean(updatedBook.is_featured),
      isNewRelease: Boolean(updatedBook.is_new_release),
      isPremium: Boolean(updatedBook.is_premium),
      metadata: updatedBook.metadata,
      createdAt: updatedBook.created_at,
      updatedAt: updatedBook.updated_at,
    };

    res.json({
      success: true,
      message: 'Book updated successfully',
      book: processedBook
    });
  } catch (error) {
    logger.error('Error updating book:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update book'
    });
  }
}));

// Get book content (protected by subscription)
router.get('/:id/content', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { format = 'ebook' } = req.query;
  
  // This route should be protected by auth middleware
  // For now, we'll require user ID in query params
  const { userId } = req.query;
  
  if (!userId) {
    return res.status(401).json({ 
      error: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }
  
  // Get user and book
  const [user, book] = await Promise.all([
    db('users').select('subscription_plan', 'subscription_expires_at').where('id', userId).first(),
    db('books').where('id', id).where('status', 'published').first()
  ]);
  
  if (!user) {
    return res.status(401).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  // Check subscription access
  if (!book.is_free && user.subscription_plan === 'free') {
    return res.status(403).json({ 
      error: 'Premium subscription required',
      code: 'SUBSCRIPTION_REQUIRED'
    });
  }
  
  // Check if subscription is expired
  if (user.subscription_expires_at && new Date() > new Date(user.subscription_expires_at)) {
    if (!book.is_free) {
      return res.status(403).json({ 
        error: 'Subscription expired',
        code: 'SUBSCRIPTION_EXPIRED'
      });
    }
  }
  
  // Get content URL based on format
  let contentUrl;
  if (format === 'audiobook' && book.audio_file_url) {
    contentUrl = book.audio_file_url;
  } else if (format === 'ebook' && book.ebook_file_url) {
    contentUrl = book.ebook_file_url;
  } else {
    return res.status(400).json({ 
      error: 'Requested format not available',
      code: 'FORMAT_NOT_AVAILABLE'
    });
  }
  
  // Update user library if not exists
  await db('user_library')
    .insert({
      user_id: userId,
      book_id: id,
      status: 'reading',
      started_reading_at: new Date()
    })
    .onConflict(['user_id', 'book_id'])
    .ignore();
  
  res.json({
    contentUrl,
    format,
    book: {
      id: book.id,
      title: book.title,
      title_somali: book.title_somali,
      author: book.author,
      narrator: book.narrator,
      language: book.language,
      format: book.format,
      duration_minutes: book.duration_minutes,
      page_count: book.page_count
    }
  });
}));

// Get book sample
router.get('/:id/sample', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { format = 'ebook' } = req.query;
  
  const book = await db('books')
    .where('id', id)
    .where('status', 'published')
    .select('id', 'title', 'sample_text_url', 'sample_audio_url')
    .first();
  
  if (!book) {
    return res.status(404).json({ 
      error: 'Book not found',
      code: 'BOOK_NOT_FOUND'
    });
  }
  
  let sampleUrl;
  if (format === 'audiobook' && book.sample_audio_url) {
    sampleUrl = book.sample_audio_url;
  } else if (format === 'ebook' && book.sample_text_url) {
    sampleUrl = book.sample_text_url;
  } else {
    return res.status(400).json({ 
      error: 'Sample not available for requested format',
      code: 'SAMPLE_NOT_AVAILABLE'
    });
  }
  
  res.json({
    sampleUrl,
    format,
    book: {
      id: book.id,
      title: book.title
    }
  });
}));

// Get book recommendations
router.get('/:id/recommendations', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 5 } = req.query;

    // Get current book details
    const currentBook = await db('books')
      .where('id', id)
      .select('id', 'language', 'authors')
      .first();

    if (!currentBook) {
      return res.status(404).json({
        success: false,
        error: 'Book not found'
      });
    }

    // Get recommendations based on language and authors
    let recommendationsQuery = db('books')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 'cover_image_url',
        'audio_url', 'ebook_url', 'sample_url', 'duration', 'page_count',
        'rating', 'review_count', 'is_featured', 'is_new_release', 'is_premium',
        'metadata', 'created_at', 'updated_at'
      )
      .where('id', '!=', id)
      .where('language', currentBook.language);

    // If current book has authors, also filter by similar authors
    if (currentBook.authors) {
      // Authors are now stored as simple strings, so we can do a LIKE search
      recommendationsQuery = recommendationsQuery.where('authors', 'like', `%${currentBook.authors}%`);
    }

    const recommendations = await recommendationsQuery
      .orderBy('rating', 'desc')
      .orderBy('review_count', 'desc')
      .limit(parseInt(limit));

    // Process recommendations
    const processedRecommendations = recommendations.map(book => ({
      ...book,
      authors: book.authors || '',
      authorsSomali: book.authors_somali || '',
      isFeatured: Boolean(book.is_featured),
      isNewRelease: Boolean(book.is_new_release),
      isPremium: Boolean(book.is_premium),
      createdAt: book.created_at,
      updatedAt: book.updated_at,
    }));

    res.json({
      success: true,
      recommendations: processedRecommendations,
      total: processedRecommendations.length
    });
  } catch (error) {
    logger.error('Error fetching recommendations:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch recommendations'
    });
  }
}));


// Get languages
router.get('/languages/list', asyncHandler(async (req, res) => {
  const languages = await db('books')
    .distinct('language')
    .orderBy('language');
  
  res.json({ languages });
}));

// Get featured books
router.get('/featured/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Featured books endpoint called with limit:', limit);
    
    const featuredBooks = await db('books')
      .where('is_featured', true)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 
        'cover_image_url', 'audio_url', 'ebook_url', 'sample_url', 'duration', 
        'page_count', 'rating', 'review_count', 'is_featured', 'is_new_release', 
        'is_premium', 'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    // Process books to handle JSON fields and fetch categories
    const processedBooks = await Promise.all(featuredBooks.map(async (book) => {
      // Fetch categories for this book
      const categories = await db('book_categories')
        .join('categories', 'book_categories.category_id', 'categories.id')
        .where('book_categories.book_id', book.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: book.id,
        title: book.title,
        titleSomali: book.title_somali,
        description: book.description,
        descriptionSomali: book.description_somali,
        authors: book.authors || '',
        authorsSomali: book.authors_somali || '',
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
        language: book.language,
        format: book.format,
        coverImageUrl: book.cover_image_url,
        audioUrl: book.audio_url,
        ebookContent: book.ebook_content,
        sampleUrl: book.sample_url,
        duration: book.duration,
        pageCount: book.page_count,
        rating: book.rating,
        reviewCount: book.review_count,
        isFeatured: Boolean(book.is_featured),
        isNewRelease: Boolean(book.is_new_release),
        isPremium: Boolean(book.is_premium),
        metadata: book.metadata,
        createdAt: book.created_at,
        updatedAt: book.updated_at,
      };
    }));

    console.log('📤 Sending featured books:', {
      count: processedBooks.length,
      books: processedBooks.map(b => ({
        id: b.id,
        title: b.title,
        hasEbookContent: !!b.ebookContent,
        ebookContentLength: b.ebookContent ? b.ebookContent.length : 0
      }))
    });

    res.json({
      success: true,
      featuredBooks: processedBooks,
      total: processedBooks.length
    });
  } catch (error) {
    logger.error('Error fetching featured books:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch featured books'
    });
  }
}));

// Get new releases
router.get('/new-releases/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 New releases endpoint called with limit:', limit);
    
    const newReleases = await db('books')
      .where('is_new_release', true)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 
        'cover_image_url', 'audio_url', 'ebook_url', 'sample_url', 'duration', 
        'page_count', 'rating', 'review_count', 'is_featured', 'is_new_release', 
        'is_premium', 'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    // Process books to handle JSON fields and fetch categories
    const processedBooks = await Promise.all(newReleases.map(async (book) => {
      // Fetch categories for this book
      const categories = await db('book_categories')
        .join('categories', 'book_categories.category_id', 'categories.id')
        .where('book_categories.book_id', book.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: book.id,
        title: book.title,
        titleSomali: book.title_somali,
        description: book.description,
        descriptionSomali: book.description_somali,
        authors: book.authors || '',
        authorsSomali: book.authors_somali || '',
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
        language: book.language,
        format: book.format,
        coverImageUrl: book.cover_image_url,
        audioUrl: book.audio_url,
        ebookContent: book.ebook_content,
        sampleUrl: book.sample_url,
        duration: book.duration,
        pageCount: book.page_count,
        rating: book.rating,
        reviewCount: book.review_count,
        isFeatured: Boolean(book.is_featured),
        isNewRelease: Boolean(book.is_new_release),
        isPremium: Boolean(book.is_premium),
        metadata: book.metadata,
        createdAt: book.created_at,
        updatedAt: book.updated_at,
      };
    }));

    console.log('📤 Sending new releases:', {
      count: processedBooks.length,
      books: processedBooks.map(b => ({
        id: b.id,
        title: b.title,
        hasEbookContent: !!b.ebookContent,
        ebookContentLength: b.ebookContent ? b.ebookContent.length : 0
      }))
    });

    res.json({
      success: true,
      newReleases: processedBooks,
      total: processedBooks.length
    });
  } catch (error) {
    logger.error('Error fetching new releases:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch new releases'
    });
  }
}));

// Get recent books (sorted by creation date)
router.get('/recent/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Recent books endpoint called with limit:', limit);
    
    const recentBooks = await db('books')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 
        'cover_image_url', 'audio_url', 'ebook_content', 'sample_url', 'duration', 
        'page_count', 'rating', 'review_count', 'is_featured', 'is_new_release', 
        'is_premium', 'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc') // Most recent first
      .limit(parseInt(limit));

    console.log('📚 Database query returned', recentBooks.length, 'recent books');
    console.log('📖 Recent book titles:', recentBooks.map(b => b.title));
    console.log('📅 Recent book dates:', recentBooks.map(b => b.created_at));

    // Process books to handle JSON fields and fetch categories
    const processedBooks = await Promise.all(recentBooks.map(async (book) => {
      // Fetch categories for this book
      const categories = await db('book_categories')
        .join('categories', 'book_categories.category_id', 'categories.id')
        .where('book_categories.book_id', book.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: book.id,
        title: book.title,
        titleSomali: book.title_somali,
        description: book.description,
        descriptionSomali: book.description_somali,
        authors: book.authors || '',
        authorsSomali: book.authors_somali || '',
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
        language: book.language,
        format: book.format,
        coverImageUrl: book.cover_image_url,
        audioUrl: book.audio_url,
        ebookContent: book.ebook_content,
        sampleUrl: book.sample_url,
        duration: book.duration,
        pageCount: book.page_count,
        rating: book.rating,
        reviewCount: book.review_count,
        isFeatured: Boolean(book.is_featured),
        isNewRelease: Boolean(book.is_new_release),
        isPremium: Boolean(book.is_premium),
        metadata: book.metadata,
        createdAt: book.created_at,
        updatedAt: book.updated_at,
      };
    }));

    console.log('✅ Processed', processedBooks.length, 'recent books for response');
    console.log('📱 Sending response with', processedBooks.length, 'recent books');
    console.log('🔍 First recent book data:', processedBooks[0]);
    console.log('📅 First recent book created at:', processedBooks[0]?.createdAt);

    res.json({
      success: true,
      recentBooks: processedBooks,
      total: processedBooks.length
    });
  } catch (error) {
    console.error('💥 Error in recent books endpoint:', error);
    logger.error('Error fetching recent books:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch recent books'
    });
  }
}));

// Get random books for recommendations
router.get('/random/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Random books endpoint called with limit:', limit);
    
    // First, let's check how many books exist in the database
    const totalBooks = await db('books').count('* as count').first();
    console.log('📊 Total books in database:', totalBooks.count);
    
    // Get random books using ORDER BY RAND() for MySQL
    const randomBooks = await db('books')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'authors', 'authors_somali', 'language', 'format', 
        'cover_image_url', 'audio_url', 'ebook_url', 'sample_url', 'duration', 
        'page_count', 'rating', 'review_count', 'is_featured', 'is_new_release', 
        'is_premium', 'metadata', 'created_at', 'updated_at'
      )
      .orderByRaw('RAND()') // MySQL random ordering
      .limit(parseInt(limit));

    console.log('📚 Database query returned', randomBooks.length, 'books');
    console.log('📖 Book titles:', randomBooks.map(b => b.title));
    console.log('🔍 First book data:', randomBooks[0]);

    // Process books to handle JSON fields and fetch categories
    const processedBooks = await Promise.all(randomBooks.map(async (book) => {
      // Fetch categories for this book
      const categories = await db('book_categories')
        .join('categories', 'book_categories.category_id', 'categories.id')
        .where('book_categories.book_id', book.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: book.id,
        title: book.title,
        titleSomali: book.title_somali,
        description: book.description,
        descriptionSomali: book.description_somali,
        authors: book.authors || '',
        authorsSomali: book.authors_somali || '',
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
        language: book.language,
        format: book.format,
        coverImageUrl: book.cover_image_url,
        audioUrl: book.audio_url,
        ebookContent: book.ebook_content,  // Changed from ebookUrl to ebookContent
        sampleUrl: book.sample_url,
        duration: book.duration,
        pageCount: book.page_count,
        rating: book.rating,
        reviewCount: book.review_count,
        isFeatured: Boolean(book.is_featured),
        isNewRelease: Boolean(book.is_new_release),
        isPremium: Boolean(book.is_premium),
        metadata: book.metadata,
        createdAt: book.created_at,
        updatedAt: book.updated_at,
      };
    }));

    console.log('✅ Processed', processedBooks.length, 'books for response');
    console.log('📱 Sending response with', processedBooks.length, 'books');
    console.log('🔍 First processed book data:', processedBooks[0]);
    console.log('🖼️ First book coverImageUrl:', processedBooks[0]?.coverImageUrl);

    res.json({
      success: true,
      randomBooks: processedBooks,
      total: processedBooks.length
    });
  } catch (error) {
    console.error('💥 Error in random books endpoint:', error);
    logger.error('Error fetching random books:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch random books'
    });
  }
}));

module.exports = router;
