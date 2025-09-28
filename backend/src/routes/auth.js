const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateRegistration = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('firstName').trim().isLength({ min: 2 }).withMessage('First name is required'),
  body('lastName').trim().isLength({ min: 2 }).withMessage('Last name is required'),
  body('preferredLanguage').isIn(['so', 'en', 'ar']).optional()
];

const validateLogin = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required')
];

// Register new user
router.post('/register', validateRegistration, asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array()
    });
  }

  const { email, password, firstName, lastName, preferredLanguage = 'en' } = req.body;

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
  const passwordHash = await bcrypt.hash(password, saltRounds);

  // Create user
  const [userId] = await db('users').insert({
    email,
    password_hash: passwordHash,
    first_name: firstName,
    last_name: lastName,
    language_preference: preferredLanguage,
    subscription_plan: 'free',
    is_active: true,
    is_verified: false
  }).returning('id');

  // Generate JWT token
  const token = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  // Get created user (without password)
  const user = await db('users')
    .select('id', 'email', 'first_name', 'last_name', 'language_preference', 'subscription_plan', 'created_at')
    .where('id', userId)
    .first();

  logger.info('New user registered:', { email, userId });

  res.status(201).json({
    message: 'User registered successfully',
    user,
    token
  });
}));

// Login user
router.post('/login', validateLogin, asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array()
    });
  }

  const { email, password } = req.body;

  // Find user
  console.log('🔍 Backend login - Querying for email:', email);
  // First, let's see all available fields
  const allFields = await db('users').first();
  console.log('🔍 Backend login - All available fields in users table:', Object.keys(allFields || {}));
  
  const user = await db('users')
    .select('id', 'email', 'password_hash', 'first_name', 'last_name', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin')
    .where('email', email)
    .first();
  console.log('🔍 Backend login - Raw query result:', user);
  console.log('🔍 Backend login - Available fields in user object:', Object.keys(user || {}));
  console.log('🔍 Backend login - is_admin value:', user?.is_admin);
  console.log('🔍 Backend login - is_admin type:', typeof user?.is_admin);

  if (!user) {
    return res.status(401).json({ 
      error: 'Invalid credentials',
      code: 'INVALID_CREDENTIALS'
    });
  }

  if (!user.is_active) {
    return res.status(401).json({ 
      error: 'Account is deactivated',
      code: 'ACCOUNT_DEACTIVATED'
    });
  }

  // Check if user is admin (only admin users can access admin panel)
  if (!user.is_admin) {
    return res.status(403).json({ 
      error: 'Access denied. Only admin users can access the admin panel.',
      code: 'ADMIN_ACCESS_REQUIRED'
    });
  }

  // Check password
  const isValidPassword = await bcrypt.compare(password, user.password_hash);
  if (!isValidPassword) {
    return res.status(401).json({ 
      error: 'Invalid credentials',
      code: 'INVALID_CREDENTIALS'
    });
  }

  // Update last login
  await db('users')
    .where('id', user.id)
    .update({ last_login_at: new Date() });

  // Generate JWT token
  const token = jwt.sign(
    { userId: user.id },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  // Remove password from response
  delete user.password_hash;

  // Transform field names to match frontend expectations
  // Check for different possible admin field names
  const adminField = user.is_admin !== undefined ? user.is_admin : 
                    user.isAdmin !== undefined ? user.isAdmin : 
                    user.admin !== undefined ? user.admin : false;
  
  console.log('🔍 Backend login - Admin field check:', {
    'user.is_admin': user.is_admin,
    'user.isAdmin': user.isAdmin,
    'user.admin': user.admin,
    'final adminField': adminField
  });
  
  const transformedUser = {
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    languagePreference: user.language_preference,
    subscriptionPlan: user.subscription_plan,
    isActive: !!user.is_active,
    isVerified: !!user.is_verified,
    isAdmin: !!adminField,
    createdAt: user.created_at
  };

  // Debug logging
  console.log('🔍 Backend login - Raw user from DB:', user);
  console.log('🔍 Backend login - is_admin from DB:', user.is_admin);
  console.log('🔍 Backend login - Transformed user:', transformedUser);
  console.log('🔍 Backend login - isAdmin in response:', transformedUser.isAdmin);

  logger.info('User logged in:', { email, userId: user.id });

  res.json({
    message: 'Login successful',
    user: transformedUser,
    token
  });
}));

// Get current user profile (protected by JWT)
router.get('/me', asyncHandler(async (req, res) => {
  // Get user ID from JWT token in Authorization header
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ 
      error: 'Authorization token required',
      code: 'TOKEN_REQUIRED'
    });
  }

  try {
    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    const user = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'language_preference', 'subscription_plan', 'subscription_expires_at', 'avatar_url', 'is_admin', 'is_active', 'is_verified', 'created_at')
      .where('id', userId)
      .first();

    if (!user) {
      return res.status(404).json({ 
        error: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }

    if (!user.is_active) {
      return res.status(401).json({ 
        error: 'Account is deactivated',
        code: 'ACCOUNT_DEACTIVATED'
      });
    }

    // Transform field names to match frontend expectations
    const transformedUser = {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      languagePreference: user.language_preference,
      subscriptionPlan: user.subscription_plan,
      subscriptionExpiresAt: user.subscription_expires_at,
      avatarUrl: user.avatar_url,
      isAdmin: !!user.is_admin,
      isActive: !!user.is_active,
      isVerified: !!user.is_verified,
      createdAt: user.created_at
    };

    res.json({ user: transformedUser });
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Invalid token',
        code: 'TOKEN_INVALID'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Token expired',
        code: 'TOKEN_EXPIRED'
      });
    }

    logger.error('Error in /me endpoint:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      code: 'SERVER_ERROR'
    });
  }
}));

// Refresh token
router.post('/refresh', asyncHandler(async (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ 
      error: 'Token is required',
      code: 'TOKEN_REQUIRED'
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user still exists
    const user = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'language_preference', 'subscription_plan')
      .where('id', decoded.userId)
      .first();

    if (!user) {
      return res.status(401).json({ 
        error: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }

    // Generate new token
    const newToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      message: 'Token refreshed successfully',
      user,
      token: newToken
    });
  } catch (error) {
    return res.status(401).json({ 
      error: 'Invalid token',
      code: 'TOKEN_INVALID'
    });
  }
}));

// Forgot password
router.post('/forgot-password', asyncHandler(async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ 
      error: 'Email is required',
      code: 'EMAIL_REQUIRED'
    });
  }

  const user = await db('users').where('email', email).first();
  if (!user) {
    // Don't reveal if user exists or not
    return res.json({ 
      message: 'If an account with that email exists, a password reset link has been sent'
    });
  }

  // Generate reset token (in production, send email)
  const resetToken = require('crypto').randomBytes(32).toString('hex');
  const resetExpires = new Date(Date.now() + 3600000); // 1 hour

  await db('users')
    .where('id', user.id)
    .update({
      reset_password_token: resetToken,
      reset_password_expires_at: resetExpires
    });

  // TODO: Send email with reset link
  logger.info('Password reset requested:', { email, userId: user.id });

  res.json({ 
    message: 'If an account with that email exists, a password reset link has been sent'
  });
}));

// Reset password
router.post('/reset-password', asyncHandler(async (req, res) => {
  const { token, newPassword } = req.body;

  if (!token || !newPassword) {
    return res.status(400).json({ 
      error: 'Token and new password are required',
      code: 'MISSING_FIELDS'
    });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ 
      error: 'Password must be at least 6 characters',
      code: 'PASSWORD_TOO_SHORT'
    });
  }

  const user = await db('users')
    .where('reset_password_token', token)
    .where('reset_password_expires_at', '>', new Date())
    .first();

  if (!user) {
    return res.status(400).json({ 
      error: 'Invalid or expired reset token',
      code: 'INVALID_RESET_TOKEN'
    });
  }

  // Hash new password
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(newPassword, saltRounds);

  // Update password and clear reset token
  await db('users')
    .where('id', user.id)
    .update({
      password_hash: passwordHash,
      reset_password_token: null,
      reset_password_expires_at: null
    });

  logger.info('Password reset successful:', { userId: user.id });

  res.json({ 
    message: 'Password reset successfully'
  });
}));

// Google OAuth for Web (using access token instead of ID token)
router.post('/google-web', asyncHandler(async (req, res) => {
  const { accessToken, userInfo } = req.body;

  if (!accessToken || !userInfo) {
    return res.status(400).json({
      error: 'Access token and user info are required',
      code: 'GOOGLE_ACCESS_TOKEN_REQUIRED'
    });
  }

  try {
    // Use the user info directly from the frontend (already verified)
    console.log('🔍 Google OAuth Web - Received userInfo:', userInfo);
    
    const email = userInfo.email;
    const firstName = userInfo.given_name || userInfo.name?.split(' ')[0] || 'User';
    const lastName = userInfo.family_name || userInfo.name?.split(' ').slice(1).join(' ') || 'Google';
    const avatarUrl = userInfo.picture || null;
    const emailVerified = userInfo.verified_email || false;
    
    console.log('🔍 Google OAuth Web - Parsed data:', { email, firstName, lastName, avatarUrl, emailVerified });

    if (!email) {
      return res.status(400).json({
        error: 'Google user info did not include an email',
        code: 'GOOGLE_EMAIL_MISSING'
      });
    }

    // Find or create user
    let user = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'avatar_url', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin', 'created_at')
      .where('email', email)
      .first();

    if (!user) {
      // Create a placeholder password hash for social login users
      const bcrypt = require('bcryptjs');
      const saltRounds = 12;
      const randomSecret = require('crypto').randomBytes(32).toString('hex');
      const passwordHash = await bcrypt.hash(`google-web:${email}:${randomSecret}`, saltRounds);

      // Generate a UUID for the new user
      const userId = require('crypto').randomUUID();
      
      await db('users').insert({
        id: userId,
        email,
        password_hash: passwordHash,
        first_name: firstName,
        last_name: lastName,
        display_name: `${firstName} ${lastName}`,
        avatar_url: avatarUrl,
        language_preference: 'en',
        theme_preference: 'light',
        subscription_plan: 'free',
        subscription_status: 'active',
        subscription_expires_at: null,
        is_active: true,
        is_verified: !!emailVerified,
        is_admin: false,
        last_login_at: new Date(),
        created_at: new Date(),
        updated_at: new Date()
      });

      user = await db('users')
        .select('id', 'email', 'first_name', 'last_name', 'avatar_url', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin', 'created_at')
        .where('id', userId)
        .first();
      logger.info('New user created via Google OAuth Web:', { email, userId });
    } else {
      // Update login timestamp and avatar if missing
      await db('users')
        .where('id', user.id)
        .update({
          last_login_at: new Date(),
          avatar_url: user.avatar_url || avatarUrl,
          is_verified: user.is_verified || !!emailVerified
        });
    }

    // Issue JWT
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const transformedUser = {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      avatarUrl: user.avatar_url,  // Include avatar URL
      languagePreference: user.language_preference,
      subscriptionPlan: user.subscription_plan,
      isActive: !!user.is_active,  // Convert to boolean
      isVerified: !!user.is_verified,  // Convert to boolean
      isAdmin: !!user.is_admin,  // Convert to boolean
      createdAt: user.created_at
    };

    logger.info('User logged in via Google OAuth Web:', { email, userId: user.id });

    res.json({
      message: 'Google login successful',
      user: transformedUser,
      token
    });
  } catch (error) {
    console.error('🚨 Google OAuth Web error details:', error);
    console.error('🚨 Error message:', error.message);
    console.error('🚨 Error stack:', error.stack);
    
    logger.error('Google OAuth Web error:', error);
    res.status(500).json({
      error: 'Google authentication failed',
      code: 'GOOGLE_AUTH_ERROR',
      details: error.message
    });
  }
}));

module.exports = router;
 
// Google OAuth: verify ID token and issue JWT
router.post('/google', asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({
      error: 'Google ID token is required',
      code: 'GOOGLE_ID_TOKEN_REQUIRED'
    });
  }

  try {
    const { OAuth2Client } = require('google-auth-library');
    const singleClientId = process.env.GOOGLE_OAUTH_CLIENT_ID;
    const multipleClientIds = process.env.GOOGLE_OAUTH_CLIENT_IDS;
    const allowedAudiences = (multipleClientIds
      ? multipleClientIds.split(',')
      : [singleClientId].filter(Boolean)).map((s) => s.trim()).filter(Boolean);

    if (allowedAudiences.length === 0) {
      return res.status(500).json({
        error: 'Server misconfiguration: GOOGLE_OAUTH_CLIENT_ID(S) missing',
        code: 'SERVER_MISCONFIGURED'
      });
    }

    // Try verifying against any allowed audience
    const oauthClient = new OAuth2Client();
    let ticket;
    let lastError;
    for (const aud of allowedAudiences) {
      try {
        ticket = await oauthClient.verifyIdToken({ idToken, audience: aud });
        break;
      } catch (err) {
        lastError = err;
      }
    }
    if (!ticket) {
      logger.warn('Google token verification failed for all audiences');
      throw lastError || new Error('Unable to verify Google token');
    }
    const payload = ticket.getPayload();

    const email = payload?.email;
    const emailVerified = payload?.email_verified;
    const firstName = payload?.given_name || 'User';
    const lastName = payload?.family_name || 'Google';
    const avatarUrl = payload?.picture || null;
    const googleSub = payload?.sub; // Google user ID

    if (!email) {
      return res.status(400).json({
        error: 'Google token did not include an email',
        code: 'GOOGLE_EMAIL_MISSING'
      });
    }

    // Find or create user
    let user = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'avatar_url', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin', 'created_at')
      .where('email', email)
      .first();

    if (!user) {
      // Create a placeholder password hash for social login users
      const bcrypt = require('bcryptjs');
      const saltRounds = 12;
      const randomSecret = require('crypto').randomBytes(32).toString('hex');
      const passwordHash = await bcrypt.hash(`google:${googleSub}:${randomSecret}`, saltRounds);

      const [userId] = await db('users').insert({
        email,
        password_hash: passwordHash,
        first_name: firstName,
        last_name: lastName,
        avatar_url: avatarUrl,
        language_preference: 'en',
        subscription_plan: 'free',
        is_active: true,
        is_verified: !!emailVerified
      }).returning('id');

      user = await db('users')
        .select('id', 'email', 'first_name', 'last_name', 'avatar_url', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin', 'created_at')
        .where('id', userId)
        .first();
      logger.info('New user created via Google OAuth:', { email, userId });
    } else {
      // Update login timestamp and avatar if missing
      await db('users')
        .where('id', user.id)
        .update({
          last_login_at: new Date(),
          avatar_url: user.avatar_url || avatarUrl,
          is_verified: user.is_verified || !!emailVerified
        });
    }

    // Issue JWT
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const transformedUser = {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      languagePreference: user.language_preference,
      subscriptionPlan: user.subscription_plan,
      isActive: !!user.is_active,
      isVerified: !!user.is_verified,
      isAdmin: !!user.is_admin,
      createdAt: user.created_at
    };

    return res.json({
      message: 'Login successful',
      user: transformedUser,
      token
    });
  } catch (error) {
    logger.error('Google OAuth login failed:', error);
    return res.status(401).json({
      error: 'Invalid Google ID token',
      code: 'GOOGLE_TOKEN_INVALID'
    });
  }
}));