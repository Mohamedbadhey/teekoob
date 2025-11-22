const express = require('express');
const { body, param } = require('express-validator');
const multer = require('multer');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

const router = express.Router();

// Ensure uploads/avatars directory exists
const uploadsDir = process.env.RAILWAY_VOLUME_MOUNT_PATH || path.join(__dirname, '../../uploads');
const avatarsDir = path.join(uploadsDir, 'avatars');

// Create directories if they don't exist
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  logger.info('Created uploads directory:', uploadsDir);
}

if (!fs.existsSync(avatarsDir)) {
  fs.mkdirSync(avatarsDir, { recursive: true });
  logger.info('Created avatars directory:', avatarsDir);
}

// Configure multer for avatar uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, avatarsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'avatar-' + uniqueSuffix + '.' + file.originalname.split('.').pop());
  }
});

const upload = multer({ 
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 1
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, and WebP are allowed.'), false);
    }
  }
});

// Get user profile
router.get('/profile', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  const user = await db('users')
    .select(
      'id', 'email', 'first_name', 'last_name', 'display_name', 'avatar_url',
      'language_preference', 'subscription_plan', 'subscription_expires_at',
      'is_verified', 'created_at', 'last_login_at'
    )
    .where('id', userId)
    .first();
  
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  // Transform to camelCase to match frontend expectations
  const transformedUser = {
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    displayName: user.display_name,
    avatarUrl: user.avatar_url,
    languagePreference: user.language_preference,
    subscriptionPlan: user.subscription_plan,
    subscriptionExpiresAt: user.subscription_expires_at,
    isVerified: !!user.is_verified,
    createdAt: user.created_at,
    lastLoginAt: user.last_login_at
  };
  
  res.json({ user: transformedUser });
}));

// Update user profile
router.put('/profile', asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { firstName, lastName, preferredLanguage } = req.body;
  
  // Validate input
  if (firstName && firstName.trim().length < 2) {
    return res.status(400).json({ 
      error: 'First name must be at least 2 characters',
      code: 'INVALID_FIRST_NAME'
    });
  }
  
  if (lastName && lastName.trim().length < 2) {
    return res.status(400).json({ 
      error: 'Last name must be at least 2 characters',
      code: 'INVALID_LAST_NAME'
    });
  }
  
  if (preferredLanguage && !['so', 'en', 'ar'].includes(preferredLanguage)) {
    return res.status(400).json({ 
      error: 'Invalid preferred language',
      code: 'INVALID_LANGUAGE'
    });
  }
  
  // Validate user exists
  const currentUser = await db('users')
    .select('first_name', 'last_name')
    .where('id', userId)
    .first();
  
  if (!currentUser) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  const updateData = {};
  
  // Only update fields that are provided - don't preserve existing corrupted values
  if (firstName !== undefined && firstName !== null) {
    updateData.first_name = firstName.trim();
  }
  if (lastName !== undefined && lastName !== null) {
    updateData.last_name = lastName.trim();
  }
  
  // Update display_name based on the NEW values (not the corrupted existing ones)
  // Only update display_name if we're updating firstName or lastName
  if ((firstName !== undefined && firstName !== null) || (lastName !== undefined && lastName !== null)) {
    // Use the new values if provided, otherwise use existing values
    // This ensures display_name always reflects the actual first_name and last_name
    const finalFirstName = (firstName !== undefined && firstName !== null) 
      ? firstName.trim() 
      : (currentUser.first_name || '');
    const finalLastName = (lastName !== undefined && lastName !== null) 
      ? lastName.trim() 
      : (currentUser.last_name || '');
    
    // Build display_name from the final values
    // Remove any extra spaces and ensure clean formatting
    if (finalLastName && finalLastName.trim().length > 0) {
      updateData.display_name = `${finalFirstName.trim()} ${finalLastName.trim()}`.trim();
    } else if (finalFirstName && finalFirstName.trim().length > 0) {
      updateData.display_name = finalFirstName.trim();
    }
  }
  
  if (preferredLanguage) updateData.language_preference = preferredLanguage;
  
  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ 
      error: 'No fields to update',
      code: 'NO_FIELDS'
    });
  }
  
  updateData.updated_at = new Date();
  
  await db('users')
    .where('id', userId)
    .update(updateData);
  
  logger.info('User profile updated:', { userId, updateData });
  
  // Fetch and return updated user with camelCase fields
  const updatedUser = await db('users')
    .select(
      'id', 'email', 'first_name', 'last_name', 'display_name', 'avatar_url',
      'language_preference', 'subscription_plan', 'subscription_expires_at',
      'is_verified', 'created_at', 'last_login_at'
    )
    .where('id', userId)
    .first();
  
  // Transform to camelCase to match frontend expectations
  const transformedUser = {
    id: updatedUser.id,
    email: updatedUser.email,
    firstName: updatedUser.first_name,
    lastName: updatedUser.last_name,
    displayName: updatedUser.display_name,
    avatarUrl: updatedUser.avatar_url,
    languagePreference: updatedUser.language_preference,
    subscriptionPlan: updatedUser.subscription_plan,
    subscriptionExpiresAt: updatedUser.subscription_expires_at,
    isVerified: !!updatedUser.is_verified,
    createdAt: updatedUser.created_at,
    lastLoginAt: updatedUser.last_login_at
  };
  
  res.json({
    message: 'Profile updated successfully',
    user: transformedUser
  });
}));

// Upload avatar
router.put('/avatar', upload.single('avatar'), asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  if (!req.file) {
    return res.status(400).json({ 
      error: 'Avatar file is required',
      code: 'AVATAR_REQUIRED'
    });
  }
  
  try {
    // TODO: Upload to S3 and get URL
    // For now, store local path
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    
    // Update user avatar
    await db('users')
      .where('id', userId)
      .update({
        avatar_url: avatarUrl,
        updated_at: new Date()
      });
    
    logger.info('Avatar uploaded:', { userId, avatarUrl });
    
    // Fetch updated user to return with camelCase fields
    const updatedUser = await db('users')
      .select(
        'id', 'email', 'first_name', 'last_name', 'display_name', 'avatar_url',
        'language_preference', 'subscription_plan', 'subscription_expires_at',
        'is_verified', 'created_at', 'last_login_at'
      )
      .where('id', userId)
      .first();
    
    // Transform to camelCase to match frontend expectations
    const transformedUser = {
      id: updatedUser.id,
      email: updatedUser.email,
      firstName: updatedUser.first_name,
      lastName: updatedUser.last_name,
      displayName: updatedUser.display_name,
      avatarUrl: updatedUser.avatar_url,
      languagePreference: updatedUser.language_preference,
      subscriptionPlan: updatedUser.subscription_plan,
      subscriptionExpiresAt: updatedUser.subscription_expires_at,
      isVerified: !!updatedUser.is_verified,
      createdAt: updatedUser.created_at,
      lastLoginAt: updatedUser.last_login_at
    };
    
    res.json({
      message: 'Avatar uploaded successfully',
      avatarUrl,
      user: transformedUser
    });
    
  } catch (error) {
    logger.error('Avatar upload failed:', error);
    res.status(500).json({ 
      error: 'Failed to upload avatar',
      code: 'AVATAR_UPLOAD_FAILED',
      details: error.message
    });
  }
}));

// Change password
router.put('/password', asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { currentPassword, newPassword } = req.body;
  
  if (!currentPassword || !newPassword) {
    return res.status(400).json({ 
      error: 'Current password and new password are required',
      code: 'MISSING_FIELDS'
    });
  }
  
  if (newPassword.length < 6) {
    return res.status(400).json({ 
      error: 'New password must be at least 6 characters',
      code: 'PASSWORD_TOO_SHORT'
    });
  }
  
  // Get current user with password
  const user = await db('users')
    .select('password_hash')
    .where('id', userId)
    .first();
  
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  // Check if user has a password (should always be true for authenticated users)
  if (!user.password_hash) {
    return res.status(400).json({ 
      error: 'Registration incomplete. Please complete your registration first.',
      code: 'REGISTRATION_INCOMPLETE'
    });
  }
  
  // Verify current password
  const bcrypt = require('bcryptjs');
  const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
  
  if (!isValidPassword) {
    return res.status(400).json({ 
      error: 'Current password is incorrect',
      code: 'INVALID_CURRENT_PASSWORD'
    });
  }
  
  // Hash new password
  const saltRounds = 12;
  const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);
  
  // Update password
  await db('users')
    .where('id', userId)
    .update({
      password_hash: newPasswordHash,
      updated_at: new Date()
    });
  
  logger.info('Password changed:', { userId });
  
  res.json({
    message: 'Password changed successfully'
  });
}));

// Update reading preferences
router.put('/preferences', asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { 
    fontSize, 
    fontFamily, 
    theme, 
    lineHeight, 
    margin,
    autoPlay,
    playbackSpeed,
    sleepTimer
  } = req.body;
  
  // Validate input
  if (fontSize && (fontSize < 12 || fontSize > 32)) {
    return res.status(400).json({ 
      error: 'Font size must be between 12 and 32',
      code: 'INVALID_FONT_SIZE'
    });
  }
  
  if (theme && !['light', 'dark', 'sepia'].includes(theme)) {
    return res.status(400).json({ 
      error: 'Invalid theme',
      code: 'INVALID_THEME'
    });
  }
  
  if (playbackSpeed && (playbackSpeed < 0.5 || playbackSpeed > 2.0)) {
    return res.status(400).json({ 
      error: 'Playback speed must be between 0.5x and 2.0x',
      code: 'INVALID_PLAYBACK_SPEED'
    });
  }
  
  // Get current preferences
  const user = await db('users')
    .select('preferences')
    .where('id', userId)
    .first();
  
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  // Update preferences
  const currentPreferences = user.preferences || {};
  const updatedPreferences = {
    ...currentPreferences,
    ...(fontSize !== undefined && { fontSize }),
    ...(fontFamily !== undefined && { fontFamily }),
    ...(theme !== undefined && { theme }),
    ...(lineHeight !== undefined && { lineHeight }),
    ...(margin !== undefined && { margin }),
    ...(autoPlay !== undefined && { autoPlay }),
    ...(playbackSpeed !== undefined && { playbackSpeed }),
    ...(sleepTimer !== undefined && { sleepTimer })
  };
  
  // Update user preferences
  await db('users')
    .where('id', userId)
    .update({
      preferences: JSON.stringify(updatedPreferences),
      updated_at: new Date()
    });
  
  logger.info('User preferences updated:', { userId, preferences: updatedPreferences });
  
  res.json({
    message: 'Preferences updated successfully',
    preferences: updatedPreferences
  });
}));

// Get reading preferences
router.get('/preferences', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  const user = await db('users')
    .select('preferences')
    .where('id', userId)
    .first();
  
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  const preferences = user.preferences || {};
  
  res.json({ preferences });
}));

// Delete account
router.delete('/account', asyncHandler(async (req, res) => {
  const userId = req.userId;
  const { password } = req.body;
  
  if (!password) {
    return res.status(400).json({ 
      error: 'Password is required to delete account',
      code: 'PASSWORD_REQUIRED'
    });
  }
  
  // Verify password
  const user = await db('users')
    .select('password_hash')
    .where('id', userId)
    .first();
  
  if (!user) {
    return res.status(404).json({ 
      error: 'User not found',
      code: 'USER_NOT_FOUND'
    });
  }
  
  // Check if user has a password (should always be true for authenticated users)
  if (!user.password_hash) {
    return res.status(400).json({ 
      error: 'Registration incomplete. Please complete your registration first.',
      code: 'REGISTRATION_INCOMPLETE'
    });
  }
  
  const bcrypt = require('bcryptjs');
  const isValidPassword = await bcrypt.compare(password, user.password_hash);
  
  if (!isValidPassword) {
    return res.status(400).json({ 
      error: 'Password is incorrect',
      code: 'INVALID_PASSWORD'
    });
  }
  
  try {
    // Start transaction
    await db.transaction(async (trx) => {
      // Delete user library entries
      await trx('user_library').where('user_id', userId).del();
      
      // Delete subscriptions
      await trx('subscriptions').where('user_id', userId).del();
      
      // Delete user
      await trx('users').where('id', userId).del();
    });
    
    logger.info('User account deleted:', { userId });
    
    res.json({
      message: 'Account deleted successfully'
    });
    
  } catch (error) {
    logger.error('Account deletion failed:', error);
    res.status(500).json({ 
      error: 'Failed to delete account',
      code: 'ACCOUNT_DELETION_FAILED'
    });
  }
}));

// Get user statistics
router.get('/stats', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  // Get reading statistics
  const readingStats = await db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId)
    .select(
      db.raw('COUNT(*) as total_books'),
      db.raw('COUNT(CASE WHEN ul.status = \'reading\' THEN 1 END) as currently_reading'),
      db.raw('COUNT(CASE WHEN ul.status = \'completed\' THEN 1 END) as completed'),
      db.raw('COUNT(CASE WHEN ul.status = \'wishlist\' THEN 1 END) as wishlist'),
      db.raw('AVG(ul.progress_percentage) as avg_progress'),
      db.raw('SUM(CASE WHEN b.format = \'audiobook\' THEN b.duration_minutes ELSE 0 END) as total_audio_minutes'),
      db.raw('SUM(CASE WHEN b.format = \'ebook\' THEN b.page_count ELSE 0 END) as total_pages')
    )
    .first();
  
  // Get reading streak
  const readingStreak = await db.raw(`
    WITH daily_activity AS (
      SELECT 
        DATE(GREATEST(ul.last_read_at, ul.last_listened_at)) as activity_date
      FROM user_library ul
      WHERE ul.user_id = ? 
        AND (ul.last_read_at IS NOT NULL OR ul.last_listened_at IS NOT NULL)
      GROUP BY DATE(GREATEST(ul.last_read_at, ul.last_listened_at))
      ORDER BY activity_date DESC
    ),
    streak_calc AS (
      SELECT 
        activity_date,
        ROW_NUMBER() OVER (ORDER BY activity_date DESC) as rn,
        DATE(activity_date + (ROW_NUMBER() OVER (ORDER BY activity_date DESC) - 1) * INTERVAL '1 day') as expected_date
      FROM daily_activity
    )
    SELECT COUNT(*) as streak
    FROM streak_calc
    WHERE activity_date = expected_date
  `, [userId]);
  
  // Get favorite categories
  const favoriteCategories = await db('user_library as ul')
    .join('book_categories as bc', 'ul.book_id', 'bc.book_id')
    .join('categories as c', 'bc.category_id', 'c.id')
    .where('ul.user_id', userId)
    .where('ul.is_favorite', true)
    .select('c.id', 'c.name', 'c.name_somali')
    .count('* as count')
    .groupBy('c.id', 'c.name', 'c.name_somali')
    .orderBy('count', 'desc')
    .limit(5);
  
  // Get favorite languages
  const favoriteLanguages = await db('user_library as ul')
    .join('books as b', 'ul.book_id', 'b.id')
    .where('ul.user_id', userId)
    .select('b.language')
    .count('* as count')
    .groupBy('b.language')
    .orderBy('count', 'desc');
  
  res.json({
    readingStats,
    readingStreak: readingStreak.rows[0]?.streak || 0,
    favoriteCategories,
    favoriteLanguages
  });
}));

// Export user data
router.get('/export', asyncHandler(async (req, res) => {
  const userId = req.userId;
  
  // Get user data
  const [user, library, subscriptions] = await Promise.all([
    db('users').where('id', userId).first(),
    db('user_library as ul')
      .join('books as b', 'ul.book_id', 'b.id')
      .where('ul.user_id', userId)
      .select(
        'b.title', 'b.author', 'ul.status', 'ul.current_page',
        'ul.progress_percentage', 'ul.started_reading_at',
        'ul.completed_at', 'ul.bookmarks', 'ul.notes'
      ),
    db('subscriptions').where('user_id', userId).select('*')
  ]);
  
  const exportData = {
    user: {
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      preferredLanguage: user.language_preference,
      subscriptionPlan: user.subscription_plan,
      createdAt: user.created_at
    },
    library: library,
    subscriptions: subscriptions,
    exportedAt: new Date().toISOString()
  };
  
  res.json({
    message: 'Data exported successfully',
    data: exportData
  });
}));

module.exports = router;
