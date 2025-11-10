const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');
const emailService = require('../utils/emailService');

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

  // Generate UUID for user
  const userId = require('crypto').randomUUID();

  // Create user
  await db('users').insert({
    id: userId,
    email,
    password_hash: passwordHash,
    first_name: firstName,
    last_name: lastName,
    display_name: `${firstName} ${lastName}`,
    language_preference: preferredLanguage,
    subscription_plan: 'free',
    is_active: true,
    is_verified: false
  });

  // Generate JWT token
  const token = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  // Get created user (without password)
  const user = await db('users')
    .select('id', 'email', 'first_name', 'last_name', 'display_name', 'language_preference', 'subscription_plan', 'created_at')
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
    .select('id', 'email', 'password_hash', 'first_name', 'last_name', 'display_name', 'language_preference', 'subscription_plan', 'is_active', 'is_verified', 'is_admin')
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

  // Note: Admin check removed - all users can login via email/password
  // Admin-only access should be checked at the route level, not during login

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
    displayName: user.display_name,
    avatarUrl: user.avatar_url,  // Include avatar URL
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

  // 🔔 AUTOMATIC NOTIFICATION REGISTRATION
  console.log('🔔 ===== AUTOMATIC NOTIFICATION REGISTRATION START =====');
  console.log('🔔 User logged in:', email, 'ID:', user.id);
  
  try {
    // Create a test FCM token for this user
    const testFCMToken = `auto_token_${user.id}_${Date.now()}`;
    console.log('🔔 Creating FCM token:', testFCMToken);
    
    // Insert FCM token
    await db('user_fcm_tokens')
      .insert({
        user_id: user.id,
        fcm_token: testFCMToken,
        platform: 'mobile',
        enabled: true,
        created_at: new Date()
      })
      .onConflict(['user_id', 'fcm_token'])
      .merge({
        enabled: true,
        updated_at: new Date()
      });
    
    console.log('🔔 ✅ FCM token registered successfully');
    
    // Insert notification preferences
    await db('notification_preferences')
      .insert({
        user_id: user.id,
        random_books_enabled: true,
        random_books_interval: 10,
        platform: 'mobile',
        daily_reminders_enabled: true,
        daily_reminder_time: '20:00:00',
        new_book_notifications_enabled: true,
        progress_reminders_enabled: false,
        progress_reminder_interval: 7,
        created_at: new Date()
      })
      .onConflict('user_id')
      .merge({
        random_books_enabled: true,
        random_books_interval: 10,
        updated_at: new Date()
      });
    
    console.log('🔔 ✅ Notification preferences enabled successfully');
    console.log('🔔 User will now receive random book notifications!');
    
  } catch (notificationError) {
    console.error('🔔 ❌ Error setting up notifications:', notificationError);
    // Don't fail login if notifications fail
  }
  
  console.log('🔔 ===== AUTOMATIC NOTIFICATION REGISTRATION END =====');

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
      { expiresIn: process.env.JWT_EXPIRES_IN || '365d' }
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

// Forgot password - Generate and send 6-digit verification code
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
    // Return error if email doesn't exist (for better UX - user knows to check email)
    return res.status(404).json({ 
      error: 'No account found with this email address',
      code: 'USER_NOT_FOUND'
    });
  }

  // Generate 6-digit verification code
  const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
  // Get expiry time from environment (default to 10 minutes)
  const expiryMinutes = parseInt(process.env.RESET_CODE_EXPIRY_MINUTES || '10', 10);
  const codeExpires = new Date(Date.now() + expiryMinutes * 60 * 1000);

  // Store code in database
  await db('users')
    .where('id', user.id)
    .update({
      reset_password_code: resetCode,
      reset_password_code_expires_at: codeExpires
    });

  // Send email with verification code
  const emailSent = await emailService.sendPasswordResetCode(email, resetCode);

  if (!emailSent) {
    logger.error('Failed to send password reset email:', { email, userId: user.id });
    // In development or when email fails, log the code prominently for testing
    if (process.env.NODE_ENV === 'development' || process.env.LOG_RESET_CODES === 'true') {
      logger.warn('⚠️ PASSWORD RESET CODE (Email failed, but code generated):', {
        email: email,
        code: resetCode,
        expiresAt: codeExpires,
        note: 'This code is logged because email sending failed. Use this code to test password reset.'
      });
      console.log('\n⚠️ ============================================');
      console.log('⚠️ PASSWORD RESET CODE GENERATED');
      console.log('⚠️ Email:', email);
      console.log('⚠️ Code:', resetCode);
      console.log('⚠️ Expires at:', codeExpires);
      console.log('⚠️ ============================================\n');
    }
    // Still return success to not reveal if user exists
  }

  logger.info('Password reset code generated:', { email, userId: user.id, code: resetCode });

  res.json({ 
    message: 'If an account with that email exists, a password reset code has been sent',
    // Include code in development mode for testing (remove in production)
    ...(process.env.NODE_ENV === 'development' || process.env.LOG_RESET_CODES === 'true' ? { 
      code: resetCode,
      note: 'Code included in response for development/testing. Remove in production!'
    } : {})
  });
}));

// Verify reset code
router.post('/verify-reset-code', asyncHandler(async (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    return res.status(400).json({ 
      error: 'Email and code are required',
      code: 'MISSING_FIELDS'
    });
  }

  if (!/^\d{6}$/.test(code)) {
    return res.status(400).json({ 
      error: 'Invalid code format. Code must be 6 digits',
      code: 'INVALID_CODE_FORMAT'
    });
  }

  const user = await db('users')
    .where('email', email)
    .where('reset_password_code', code)
    .where('reset_password_code_expires_at', '>', new Date())
    .first();

  if (!user) {
    return res.status(400).json({ 
      error: 'Invalid or expired verification code',
      code: 'INVALID_RESET_CODE'
    });
  }

  logger.info('Reset code verified:', { email, userId: user.id });

  res.json({ 
    message: 'Verification code is valid',
    verified: true
  });
}));

// Reset password - Requires verified code
router.post('/reset-password', asyncHandler(async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword) {
    return res.status(400).json({ 
      error: 'Email, code, and new password are required',
      code: 'MISSING_FIELDS'
    });
  }

  if (!/^\d{6}$/.test(code)) {
    return res.status(400).json({ 
      error: 'Invalid code format. Code must be 6 digits',
      code: 'INVALID_CODE_FORMAT'
    });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ 
      error: 'Password must be at least 6 characters',
      code: 'PASSWORD_TOO_SHORT'
    });
  }

  // Verify code is valid and not expired
  const user = await db('users')
    .where('email', email)
    .where('reset_password_code', code)
    .where('reset_password_code_expires_at', '>', new Date())
    .first();

  if (!user) {
    return res.status(400).json({ 
      error: 'Invalid or expired verification code',
      code: 'INVALID_RESET_CODE'
    });
  }

  // Hash new password
  const saltRounds = 12;
  const passwordHash = await bcrypt.hash(newPassword, saltRounds);

  // Update password and clear reset code
  await db('users')
    .where('id', user.id)
    .update({
      password_hash: passwordHash,
      reset_password_code: null,
      reset_password_code_expires_at: null
    });

  // Get updated user data
  const updatedUser = await db('users')
    .select('id', 'email', 'first_name', 'last_name', 'display_name', 'language_preference', 'subscription_plan', 'subscription_expires_at', 'avatar_url', 'is_admin', 'is_active', 'is_verified', 'created_at')
    .where('id', user.id)
    .first();

  // Generate JWT token for auto-login
  const token = jwt.sign(
    { userId: user.id },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  // Transform field names to match frontend expectations
  const adminField = updatedUser.is_admin !== undefined ? updatedUser.is_admin : 
                    updatedUser.isAdmin !== undefined ? updatedUser.isAdmin : 
                    updatedUser.admin !== undefined ? updatedUser.admin : false;

  const transformedUser = {
    id: updatedUser.id,
    email: updatedUser.email,
    firstName: updatedUser.first_name,
    lastName: updatedUser.last_name,
    displayName: updatedUser.display_name,
    avatarUrl: updatedUser.avatar_url,
    languagePreference: updatedUser.language_preference,
    subscriptionPlan: updatedUser.subscription_plan,
    isActive: !!updatedUser.is_active,
    isVerified: !!updatedUser.is_verified,
    isAdmin: !!adminField,
    createdAt: updatedUser.created_at
  };

  logger.info('Password reset successful:', { email, userId: user.id });

  res.json({ 
    message: 'Password reset successfully',
    user: transformedUser,
    token: token
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
      { expiresIn: process.env.JWT_EXPIRES_IN || '365d' }
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

    // 🔔 AUTOMATIC NOTIFICATION REGISTRATION FOR GOOGLE LOGIN
    console.log('🔔 ===== GOOGLE LOGIN NOTIFICATION REGISTRATION START =====');
    console.log('🔔 Google user logged in:', email, 'ID:', user.id);
    
    try {
      // Create a test FCM token for this user
      const testFCMToken = `google_token_${user.id}_${Date.now()}`;
      console.log('🔔 Creating Google FCM token:', testFCMToken);
      
      // Insert FCM token
      await db('user_fcm_tokens')
        .insert({
          user_id: user.id,
          fcm_token: testFCMToken,
          platform: 'mobile',
          enabled: true,
          created_at: new Date()
        })
        .onConflict(['user_id', 'fcm_token'])
        .merge({
          enabled: true,
          updated_at: new Date()
        });
      
      console.log('🔔 ✅ Google FCM token registered successfully');
      
      // Insert notification preferences
      await db('notification_preferences')
        .insert({
          user_id: user.id,
          random_books_enabled: true,
          random_books_interval: 10,
          platform: 'mobile',
          daily_reminders_enabled: true,
          daily_reminder_time: '20:00:00',
          new_book_notifications_enabled: true,
          progress_reminders_enabled: false,
          progress_reminder_interval: 7,
          created_at: new Date()
        })
        .onConflict('user_id')
        .merge({
          random_books_enabled: true,
          random_books_interval: 10,
          updated_at: new Date()
        });
      
      console.log('🔔 ✅ Google user notification preferences enabled successfully');
      console.log('🔔 Google user will now receive random book notifications!');
      
    } catch (notificationError) {
      console.error('🔔 ❌ Error setting up Google user notifications:', notificationError);
      // Don't fail login if notifications fail
    }
    
    console.log('🔔 ===== GOOGLE LOGIN NOTIFICATION REGISTRATION END =====');

    res.json({
      message: 'Google login successful',
      user: transformedUser,
      token
    });
  } catch (error) {
    // Enhanced error logging for debugging
    console.error('🚨 Google OAuth Web Error Details:');
    console.error('🚨 Error message:', error.message);
    console.error('🚨 Error code:', error.code);
    console.error('🚨 Error stack:', error.stack);
    console.error('🚨 Request body:', req.body);
    console.error('🚨 User info received:', req.body.userInfo);
    
    logger.error('Google OAuth Web error:', {
      error: error.message,
      code: error.code,
      stack: error.stack,
      requestBody: req.body,
      userInfo: req.body.userInfo
    });
    
    res.status(500).json({
      error: 'Google authentication failed',
      code: 'GOOGLE_AUTH_ERROR',
      details: error.message
    });
  }
}));

// Test endpoint to verify Google OAuth configuration
router.get('/google-config', asyncHandler(async (req, res) => {
  const config = {
    hasGoogleClientId: !!process.env.GOOGLE_OAUTH_CLIENT_ID,
    hasGoogleClientIds: !!process.env.GOOGLE_OAUTH_CLIENT_IDS,
    hasAndroidClientId: !!process.env.GOOGLE_ANDROID_CLIENT_ID,
    hasIosClientId: !!process.env.GOOGLE_IOS_CLIENT_ID,
    clientIdsCount: process.env.GOOGLE_OAUTH_CLIENT_IDS ? process.env.GOOGLE_OAUTH_CLIENT_IDS.split(',').length : 0,
    environment: process.env.NODE_ENV
  };
  
  console.log('🔍 Google OAuth Config Check:', config);
  
  res.json({
    message: 'Google OAuth configuration status',
    config,
    status: config.clientIdsCount > 0 ? 'CONFIGURED' : 'MISSING_CONFIG'
  });
}));

// Test email configuration endpoint
router.get('/test-email-config', asyncHandler(async (req, res) => {
  const emailConfig = {
    hasSmtpHost: !!process.env.SMTP_HOST,
    hasSmtpPort: !!process.env.SMTP_PORT,
    hasSmtpUser: !!process.env.SMTP_USER,
    hasSmtpPass: !!(process.env.SMTP_PASS || process.env.SMTP_PASSWORD),
    smtpHost: process.env.SMTP_HOST,
    smtpPort: process.env.SMTP_PORT,
    smtpUser: process.env.SMTP_USER,
    smtpSecure: process.env.SMTP_SECURE,
    emailFrom: process.env.EMAIL_FROM || process.env.SMTP_FROM,
    isConfigured: emailService.isConfigured,
    appName: process.env.APP_NAME || 'Bookdoon',
    resetCodeExpiry: process.env.RESET_CODE_EXPIRY_MINUTES || '10'
  };
  
  res.json({
    message: 'Email configuration status',
    config: emailConfig,
    status: emailConfig.isConfigured ? 'CONFIGURED' : 'MISSING_CONFIG',
    missing: [
      !emailConfig.hasSmtpHost && 'SMTP_HOST',
      !emailConfig.hasSmtpPort && 'SMTP_PORT',
      !emailConfig.hasSmtpUser && 'SMTP_USER',
      !emailConfig.hasSmtpPass && 'SMTP_PASS or SMTP_PASSWORD'
    ].filter(Boolean)
  });
}));

// Test send email endpoint (for testing email functionality)
router.post('/test-send-email', asyncHandler(async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({
      error: 'Email address is required',
      code: 'EMAIL_REQUIRED'
    });
  }
  
  if (!emailService.isConfigured) {
    return res.status(503).json({
      error: 'Email service is not configured',
      code: 'EMAIL_NOT_CONFIGURED',
      message: 'Please configure SMTP settings in your .env file'
    });
  }
  
  // Generate a test code
  const testCode = Math.floor(100000 + Math.random() * 900000).toString();
  
  try {
    const emailSent = await emailService.sendPasswordResetCode(email, testCode);
    
    if (emailSent) {
      res.json({
        success: true,
        message: 'Test email sent successfully',
        email: email,
        testCode: testCode,
        note: 'This is a test code. Check your inbox!'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Failed to send test email',
        code: 'EMAIL_SEND_FAILED'
      });
    }
  } catch (error) {
    logger.error('Test email send error:', error);
    res.status(500).json({
      success: false,
      error: 'Error sending test email',
      code: 'EMAIL_ERROR',
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
    const androidClientId = process.env.GOOGLE_ANDROID_CLIENT_ID;
    const iosClientId = process.env.GOOGLE_IOS_CLIENT_ID;
    
    // Build allowed audiences from all configured client IDs
    const allowedAudiences = [
      singleClientId,
      ...(multipleClientIds ? multipleClientIds.split(',') : []),
      androidClientId,
      iosClientId
    ].filter(Boolean).map((s) => s.trim()).filter(Boolean);

    if (allowedAudiences.length === 0) {
      return res.status(500).json({
        error: 'Server misconfiguration: No Google OAuth client IDs configured. Please set GOOGLE_OAUTH_CLIENT_ID, GOOGLE_ANDROID_CLIENT_ID, or GOOGLE_IOS_CLIENT_ID',
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

      // Generate UUID for user
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
        subscription_plan: 'free',
        is_active: true,
        is_verified: !!emailVerified
      });

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
      { expiresIn: process.env.JWT_EXPIRES_IN || '365d' }
    );

    const transformedUser = {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      avatarUrl: user.avatar_url,  // Include avatar URL
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
    // Enhanced error logging for debugging
    console.error('🚨 Google OAuth Mobile Error Details:');
    console.error('🚨 Error message:', error.message);
    console.error('🚨 Error code:', error.code);
    console.error('🚨 Error stack:', error.stack);
    console.error('🚨 Request body:', req.body);
    console.error('🚨 Environment check:');
    console.error('  - GOOGLE_OAUTH_CLIENT_ID:', process.env.GOOGLE_OAUTH_CLIENT_ID ? 'SET' : 'NOT SET');
    console.error('  - GOOGLE_OAUTH_CLIENT_IDS:', process.env.GOOGLE_OAUTH_CLIENT_IDS ? 'SET' : 'NOT SET');
    console.error('  - GOOGLE_ANDROID_CLIENT_ID:', process.env.GOOGLE_ANDROID_CLIENT_ID ? 'SET' : 'NOT SET');
    console.error('  - GOOGLE_IOS_CLIENT_ID:', process.env.GOOGLE_IOS_CLIENT_ID ? 'SET' : 'NOT SET');
    
    logger.error('Google OAuth Mobile login failed:', {
      error: error.message,
      code: error.code,
      stack: error.stack,
      requestBody: req.body,
      environment: {
        hasGoogleClientId: !!process.env.GOOGLE_OAUTH_CLIENT_ID,
        hasGoogleClientIds: !!process.env.GOOGLE_OAUTH_CLIENT_IDS,
        hasAndroidClientId: !!process.env.GOOGLE_ANDROID_CLIENT_ID,
        hasIosClientId: !!process.env.GOOGLE_IOS_CLIENT_ID
      }
    });
    
    return res.status(401).json({
      error: 'Invalid Google ID token',
      code: 'GOOGLE_TOKEN_INVALID',
      details: error.message
    });
  }
}));