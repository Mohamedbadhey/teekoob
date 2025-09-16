const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

// Check if setup is needed
router.get('/status', asyncHandler(async (req, res) => {
  try {
    const adminCount = await db('users').where('is_admin', true).count('* as count').first();
    const totalUsers = await db('users').count('* as count').first();
    
    res.json({
      needsSetup: adminCount.count === 0,
      adminUsers: adminCount.count,
      totalUsers: totalUsers.count
    });
  } catch (error) {
    logger.error('Error checking setup status:', error);
    res.status(500).json({ error: 'Failed to check setup status' });
  }
}));

// Create first admin user
router.post('/first-admin', asyncHandler(async (req, res) => {
  try {
    // Check if any admin users exist
    const adminCount = await db('users').where('is_admin', true).count('* as count').first();
    
    if (adminCount.count > 0) {
      return res.status(403).json({ 
        error: 'Admin users already exist. Use regular admin routes.',
        code: 'ADMIN_EXISTS'
      });
    }
    
    const { email, password, firstName, lastName } = req.body;
    
    // Validate required fields
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ 
        error: 'All fields are required',
        code: 'MISSING_FIELDS'
      });
    }
    
    // Check if user already exists
    const existingUser = await db('users').where('email', email).first();
    if (existingUser) {
      return res.status(400).json({ 
        error: 'User with this email already exists',
        code: 'USER_EXISTS'
      });
    }
    
    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    
    // Create admin user
    const [userId] = await db('users').insert({
      email,
      password_hash: hashedPassword,
      first_name: firstName,
      last_name: lastName,
      display_name: `${firstName} ${lastName}`,
      language_preference: 'en',
      theme_preference: 'light',
      subscription_plan: 'lifetime',
      subscription_status: 'active',
      is_verified: true,
      is_active: true,
      is_admin: true,
      created_at: new Date(),
      updated_at: new Date()
    });
    
    logger.info(`First admin user created: ${email}`);
    
    res.status(201).json({
      message: 'First admin user created successfully',
      userId,
      email
    });
  } catch (error) {
    logger.error('Error creating first admin:', error);
    res.status(500).json({ 
      error: 'Failed to create first admin user',
      details: error.message
    });
  }
}));

module.exports = router;
