const express = require('express');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Get all categories (public)
router.get('/', asyncHandler(async (req, res) => {
  try {
    const categories = await db('categories')
      .where('is_active', true)
      .orderBy('sort_order', 'asc')
      .orderBy('name', 'asc')
      .select('*');
    
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
  } catch (error) {
    logger.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch categories'
    });
  }
}));

// Get all categories (admin only)
router.get('/admin', authenticateToken, requireAdmin, asyncHandler(async (req, res) => {
  try {
    const categories = await db('categories')
      .orderBy('sort_order', 'asc')
      .orderBy('name', 'asc')
      .select('*');
    
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
  } catch (error) {
    logger.error('Error fetching admin categories:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch categories'
    });
  }
}));

// Create new category (admin only)
router.post('/', authenticateToken, requireAdmin, [
  body('name').trim().isLength({ min: 1, max: 100 }).withMessage('Name is required and must be less than 100 characters'),
  body('name_somali').trim().isLength({ min: 1, max: 100 }).withMessage('Somali name is required'),
  body('description').optional().trim(),
  body('description_somali').optional().trim(),
  body('color').optional().matches(/^#[0-9A-F]{6}$/i).withMessage('Color must be a valid hex color'),
  body('icon').optional().trim(),
  body('sort_order').optional().isInt({ min: 0 }).withMessage('Sort order must be a positive integer')
], asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }

  const { name, name_somali, description, description_somali, color, icon, sort_order } = req.body;
  
  // Check if category name already exists
  const existingCategory = await db('categories')
    .where('name', name)
    .first();
  
  if (existingCategory) {
    return res.status(400).json({
      success: false,
      error: 'Category with this name already exists'
    });
  }

  const categoryId = crypto.randomUUID();
  const newCategory = {
    id: categoryId,
    name,
    name_somali,
    description: description || null,
    description_somali: description_somali || null,
    color: color || '#1E3A8A',
    icon: icon || 'book',
    sort_order: sort_order || 0,
    is_active: true,
    created_at: new Date(),
    updated_at: new Date()
  };

  await db('categories').insert(newCategory);
  
  logger.info(`Category created: ${name} by admin ${req.user.id}`);
  
  res.status(201).json({
    success: true,
    category: newCategory,
    message: 'Category created successfully'
  });
}));

// Update category (admin only)
router.put('/:id', authenticateToken, requireAdmin, [
  body('name').optional().trim().isLength({ min: 1, max: 100 }),
  body('name_somali').optional().trim().isLength({ min: 1, max: 100 }),
  body('description').optional().trim(),
  body('description_somali').optional().trim(),
  body('color').optional().matches(/^#[0-9A-F]{6}$/i),
  body('icon').optional().trim(),
  body('sort_order').optional().isInt({ min: 0 }),
  body('is_active').optional().isBoolean()
], asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }

  const { id } = req.params;
  const updateData = req.body;
  updateData.updated_at = new Date();

  // Check if category exists
  const existingCategory = await db('categories')
    .where('id', id)
    .first();
  
  if (!existingCategory) {
    return res.status(404).json({
      success: false,
      error: 'Category not found'
    });
  }

  // If updating name, check for duplicates
  if (updateData.name && updateData.name !== existingCategory.name) {
    const duplicateCategory = await db('categories')
      .where('name', updateData.name)
      .whereNot('id', id)
      .first();
    
    if (duplicateCategory) {
      return res.status(400).json({
        success: false,
        error: 'Category with this name already exists'
      });
    }
  }

  await db('categories')
    .where('id', id)
    .update(updateData);
  
  const updatedCategory = await db('categories')
    .where('id', id)
    .first();
  
  logger.info(`Category updated: ${updatedCategory.name} by admin ${req.user.id}`);
  
  res.json({
    success: true,
    category: updatedCategory,
    message: 'Category updated successfully'
  });
}));

// Delete category (admin only)
router.delete('/:id', authenticateToken, requireAdmin, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check if category exists
  const existingCategory = await db('categories')
    .where('id', id)
    .first();
  
  if (!existingCategory) {
    return res.status(404).json({
      success: false,
      error: 'Category not found'
    });
  }

  // Check if category is used by any books
  const booksUsingCategory = await db('book_categories')
    .where('category_id', id)
    .first();
  
  if (booksUsingCategory) {
    return res.status(400).json({
      success: false,
      error: 'Cannot delete category that is assigned to books'
    });
  }

  await db('categories')
    .where('id', id)
    .delete();
  
  logger.info(`Category deleted: ${existingCategory.name} by admin ${req.user.id}`);
  
  res.json({
    success: true,
    message: 'Category deleted successfully'
  });
}));

// Get books by category
router.get('/:id/books', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    // Check if category exists
    const category = await db('categories')
      .where('id', id)
      .where('is_active', true)
      .first();
    
    if (!category) {
      return res.status(404).json({
        success: false,
        error: 'Category not found'
      });
    }

    // Get books in this category
    const books = await db('books')
      .join('book_categories', 'books.id', 'book_categories.book_id')
      .where('book_categories.category_id', id)
      .select(
        'books.*',
        db.raw('JSON_UNQUOTE(books.authors) as authors'),
        db.raw('JSON_UNQUOTE(books.authors_somali) as authors_somali'),
        db.raw('updated_at AS updatedAt')
      )
      .orderBy('books.created_at', 'desc')
      .limit(limit)
      .offset(offset);

    // Get total count
    const totalCount = await db('books')
      .join('book_categories', 'books.id', 'book_categories.book_id')
      .where('book_categories.category_id', id)
      .count('* as count')
      .first();

    const total = totalCount.count;
    const totalPages = Math.ceil(total / limit);

    // Process books
    const processedBooks = books.map(book => ({
      ...book,
      authors: book.authors || '',
      authorsSomali: book.authors_somali || '',
      categories: [category.id],
      categoryNames: [category.name],
      isFeatured: Boolean(book.isFeatured),
      isNewRelease: Boolean(book.isNewRelease),
      isPremium: Boolean(book.isPremium),
    }));

    res.json({
      success: true,
      category: category,
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
    logger.error('Error fetching books by category:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch books by category'
    });
  }
}));

module.exports = router;
