const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();
const path = require('path');

console.log('🚀 Starting Teekoob Backend...');
console.log('🔍 Environment variables loaded:');
console.log('  - NODE_ENV:', process.env.NODE_ENV);
console.log('  - PORT:', process.env.PORT);
console.log('  - DB_HOST:', process.env.DB_HOST);
console.log('  - DB_NAME:', process.env.DB_NAME);
console.log('🔍 Google OAuth Configuration:');
console.log('  - GOOGLE_OAUTH_CLIENT_ID:', process.env.GOOGLE_OAUTH_CLIENT_ID ? 'SET' : 'NOT SET');
console.log('  - GOOGLE_OAUTH_CLIENT_IDS:', process.env.GOOGLE_OAUTH_CLIENT_IDS ? 'SET' : 'NOT SET');
console.log('  - GOOGLE_ANDROID_CLIENT_ID:', process.env.GOOGLE_ANDROID_CLIENT_ID ? 'SET' : 'NOT SET');
console.log('  - GOOGLE_IOS_CLIENT_ID:', process.env.GOOGLE_IOS_CLIENT_ID ? 'SET' : 'NOT SET');
if (process.env.GOOGLE_OAUTH_CLIENT_IDS) {
  const clientIds = process.env.GOOGLE_OAUTH_CLIENT_IDS.split(',');
  console.log('  - Total client IDs configured:', clientIds.length);
  clientIds.forEach((id, index) => {
    console.log(`    ${index + 1}. ${id.trim()}`);
  });
}

try {
  console.log('📦 Loading routes...');
  const authRoutes = require('./routes/auth');
  console.log('✅ Auth routes loaded');
  
  const userRoutes = require('./routes/users');
  console.log('✅ User routes loaded');
  
  const bookRoutes = require('./routes/books');
  console.log('✅ Book routes loaded');
  
  const categoryRoutes = require('./routes/categories');
  console.log('✅ Category routes loaded');
  
  const libraryRoutes = require('./routes/library');
  console.log('✅ Library routes loaded');
  
  const paymentRoutes = require('./routes/payments');
  console.log('✅ Payment routes loaded');
  
  const adminRoutes = require('./routes/admin');
  console.log('✅ Admin routes loaded');
  
  const setupRoutes = require('./routes/setup');
  console.log('✅ Setup routes loaded');
  
  const notificationRoutes = require('./routes/notifications');
  console.log('✅ Notification routes loaded');
  
  console.log('📦 Loading middleware...');
  const { errorHandler } = require('./middleware/errorHandler');
  console.log('✅ Error handler loaded');
  
  const { authenticateToken, requireAdmin } = require('./middleware/auth');
  console.log('✅ Auth middleware loaded');
  
  const logger = require('./utils/logger');
  console.log('✅ Logger loaded');
  
  console.log('🚀 Creating Express app...');
  const app = express();
  const PORT = process.env.PORT || 3000;
  
  console.log('🔧 Setting up middleware...');
  // Rate limiting
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
  });
  
  // Middleware
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        frameAncestors: ["'self'", 'http://localhost:*'],
        frameSrc: ["'self'", 'http://localhost:*', 'blob:'],
        imgSrc: ["'self'", 'data:', 'blob:', 'http://localhost:*'],
        connectSrc: ["'self'", 'http://localhost:*', 'blob:'],
        objectSrc: ["'self'", 'blob:'],
        mediaSrc: ["'self'", 'blob:'],
        scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        workerSrc: ["'self'", 'blob:'],
      },
    },
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
  }));
  console.log('✅ Helmet middleware added with CSP configuration');
  
  app.use(cors({
    origin: function(origin, callback) {
      // Allow requests with no origin (like mobile apps or curl requests)
      if(!origin) return callback(null, true);
      
      // Allow localhost with any port (development)
      if(origin.startsWith('http://localhost:')) {
        return callback(null, true);
      }
      
      // Allow Railway domains
      if(origin.includes('.railway.app')) {
        return callback(null, true);
      }
      
      // Allow custom domains from environment
      const allowedOrigins = process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : [];
      if(allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      
      callback(new Error('Not allowed by CORS'));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Range'],
    exposedHeaders: ['Content-Range', 'Content-Length', 'Accept-Ranges'],
    credentials: true,
    maxAge: 86400, // Cache preflight requests for 24 hours
  }));
  console.log('✅ CORS middleware added with configuration');
  
  app.use(compression());
  console.log('✅ Compression middleware added');
  
  app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));
  console.log('✅ Morgan middleware added');
  
  app.use(limiter);
  console.log('✅ Rate limiter added');
  
  app.use(express.json({ limit: '50mb' }));
  console.log('✅ JSON parser added');
  
  app.use(express.urlencoded({ extended: true, limit: '50mb' }));
  console.log('✅ URL encoded parser added');
  
  // Serve static files from uploads directory (Railway persistent volume)
  const uploadsPath = process.env.RAILWAY_VOLUME_MOUNT_PATH || path.join(__dirname, '../uploads');
  console.log('🔍 Uploads directory path:', uploadsPath);
  console.log('🔍 __dirname:', __dirname);
  console.log('🔍 Full uploads path:', path.resolve(uploadsPath));
  
  // Check if directory exists, create if not
  const fs = require('fs');
  if (!fs.existsSync(uploadsPath)) {
    fs.mkdirSync(uploadsPath, { recursive: true });
    console.log('✅ Created uploads directory:', uploadsPath);
  } else {
    console.log('✅ Uploads directory exists');
  }
  
  app.use('/uploads', express.static(uploadsPath));
  console.log('✅ Static file serving for uploads directory added');
  
  // Backup route to serve upload files directly
  app.get('/uploads/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path.join(uploadsPath, filename);
    console.log('🔍 Serving file request:');
    console.log('  - Filename:', filename);
    console.log('  - Uploads path:', uploadsPath);
    console.log('  - Full file path:', filePath);
    console.log('  - File exists:', fs.existsSync(filePath));
    
    // List files in uploads directory
    try {
      const files = fs.readdirSync(uploadsPath);
      console.log('  - Files in uploads directory:', files);
    } catch (err) {
      console.log('  - Error reading uploads directory:', err.message);
    }
    
    res.sendFile(filePath, (err) => {
      if (err) {
        console.error('❌ Error serving file:', err);
        // Try to serve a default placeholder image for missing cover images
        if (filename.startsWith('coverImage-')) {
          console.log('🖼️ Attempting to serve default cover image for missing file:', filename);
          // You can add a default cover image here or return a 404
          res.status(404).json({ 
            error: 'Cover image not found',
            filename: filename,
            suggestion: 'Please re-upload the cover image'
          });
        } else {
          res.status(404).json({ 
            error: 'File not found',
            filename: filename
          });
        }
      }
    });
  });
  console.log('✅ Backup upload file route added');
  
  // Debug: List all registered routes
  console.log('🔍 All registered routes:');
  app._router.stack.forEach((middleware) => {
    if (middleware.route) {
      console.log('  -', middleware.route.path);
    } else if (middleware.name === 'router') {
      console.log('  - Router:', middleware.regexp);
    }
  });
  
  console.log('🌐 Setting up routes...');
  // Welcome route
  app.get('/', (req, res) => {
    res.status(200).json({ 
      message: 'Welcome to Teekoob API! 🚀',
      description: 'Multilingual eBook & Audiobook Platform',
      version: process.env.npm_package_version || '1.0.0',
      timestamp: new Date().toISOString(),
      endpoints: {
        health: '/health',
        auth: '/api/v1/auth',
        books: '/api/v1/books',
        library: '/api/v1/library',
        payments: '/api/v1/payments',
        admin: '/api/v1/admin'
      }
    });
  });
  console.log('✅ Welcome route added');
  
  // Health check
  app.get('/health', (req, res) => {
    res.status(200).json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0'
    });
  });
  console.log('✅ Health check route added');
  
  // API Routes
  app.use('/api/v1/auth', authRoutes);
  console.log('✅ Auth routes registered');
  
  app.use('/api/v1/setup', setupRoutes);
  console.log('✅ Setup routes registered');
  
  app.use('/api/v1/users', authenticateToken, userRoutes);
  console.log('✅ User routes registered');
  
  app.use('/api/v1/books', bookRoutes);
  console.log('✅ Book routes registered');
  
  app.use('/api/v1/categories', categoryRoutes);
  console.log('✅ Category routes registered');
  
  app.use('/api/v1/library', authenticateToken, libraryRoutes);
  console.log('✅ Library routes registered');
  
  app.use('/api/v1/payments', authenticateToken, paymentRoutes);
  console.log('✅ Payment routes registered');
  
  app.use('/api/v1/admin', authenticateToken, requireAdmin, adminRoutes);
  console.log('✅ Admin routes registered');
  
  // Test endpoints for notifications (no authentication required)
  app.get('/api/v1/notifications/test-db', async (req, res) => {
    try {
      console.log('🔔 Testing database connection...');
      await db.raw('SELECT 1');
      
      const userCount = await db('users').count('* as count').first();
      const bookCount = await db('books').count('* as count').first();
      const fcmCount = await db('user_fcm_tokens').count('* as count').first();
      const prefCount = await db('notification_preferences').count('* as count').first();
      
      res.json({
        success: true,
        message: 'Database connection successful',
        data: {
          users: userCount.count,
          books: bookCount.count,
          fcmTokens: fcmCount.count,
          notificationPreferences: prefCount.count
        }
      });
    } catch (error) {
      console.error('❌ Database test failed:', error);
      res.status(500).json({ 
        error: 'Database connection failed',
        details: error.message 
      });
    }
  });

  app.post('/api/v1/notifications/test-setup', async (req, res) => {
    try {
      console.log('🔔 Setting up test notification data...');
      
      // First, test database connection
      console.log('🔔 Testing database connection...');
      await db.raw('SELECT 1');
      console.log('🔔 ✅ Database connection successful');
      
      // Get the first user from the database
      console.log('🔔 Querying users table...');
      const users = await db('users').select('id', 'email', 'first_name', 'last_name', 'language_preference').limit(5);
      console.log('🔔 Found users:', users.length);
      
      if (users.length === 0) {
        console.log('🔔 ❌ No users found in database');
        return res.status(404).json({ 
          error: 'No users found in database',
          message: 'Please create a user account first'
        });
      }
      
      const user = users[0];
      console.log('🔔 Using user:', user.email);
      
      console.log('🔔 Found user:', user.email);
      
      // Create a test FCM token
      const testFCMToken = `test_token_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
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
      
      console.log('🔔 ✅ Test notification data created successfully');
      console.log('🔔 User:', user.email);
      console.log('🔔 FCM Token:', testFCMToken);
      console.log('🔔 Random books enabled: true');
      
      res.json({
        success: true,
        message: 'Test notification data created successfully',
        data: {
          user: {
            id: user.id,
            email: user.email,
            name: `${user.first_name} ${user.last_name}`,
            language: user.language_preference
          },
          fcmToken: testFCMToken,
          preferences: {
            randomBooksEnabled: true,
            interval: 10
          }
        }
      });
      
    } catch (error) {
      console.error('❌ Error setting up test notification data:', error);
      res.status(500).json({ error: 'Failed to setup test notification data' });
    }
  });

  app.post('/api/v1/notifications/test-notification', async (req, res) => {
    try {
      console.log('🔔 Manually triggering random book notifications...');
      
      // Call the sendRandomBookNotifications function directly
      const notificationRoutes = require('./routes/notifications');
      // We'll need to access the function from the routes file
      // For now, let's just trigger the cron job manually
      console.log('🔔 Triggering notification process...');
      
      // Get all users who have random book notifications enabled
      const result = await db('users as u')
        .select('u.id', 'u.email', 'u.first_name', 'u.last_name', 'u.language_preference',
                'nf.fcm_token', 'np.random_books_enabled', 'np.random_books_interval')
        .join('user_fcm_tokens as nf', 'u.id', 'nf.user_id')
        .join('notification_preferences as np', 'u.id', 'np.user_id')
        .where('nf.enabled', true)
        .andWhere('np.random_books_enabled', true);

      if (result.length === 0) {
        console.log('🔔 No users with random book notifications enabled');
        return res.json({
          success: false,
          message: 'No users with random book notifications enabled'
        });
      }

      console.log(`🔔 Found ${result.length} users with notifications enabled`);
      
      // Get random books
      const books = await db('books')
        .select('*')
        .where('is_featured', true)
        .orWhere('is_new_release', true)
        .orderByRaw('RAND()')
        .limit(3);

      if (books.length === 0) {
        console.log('🔔 No books available for notifications');
        return res.json({
          success: false,
          message: 'No books available for notifications'
        });
      }

      console.log(`🔔 Found ${books.length} books for notifications`);
      
      // Send notifications (simulate for now)
      console.log('🔔 Simulating notification sending...');
      for (const user of result) {
        console.log(`🔔 Would send notification to: ${user.email}`);
        console.log(`🔔 FCM Token: ${user.fcm_token}`);
        console.log(`🔔 Language: ${user.language_preference}`);
      }
      
      console.log('🔔 ✅ Notification process completed');
      
      res.json({
        success: true,
        message: 'Random book notifications triggered successfully'
      });
    } catch (error) {
      console.error('❌ Error triggering notifications:', error);
      res.status(500).json({ error: 'Failed to trigger notifications' });
    }
  });

  app.use('/api/v1/notifications', authenticateToken, notificationRoutes);
  console.log('✅ Notification routes registered');
  
  // 404 handler
  app.use('*', (req, res) => {
    res.status(404).json({ 
      error: 'Route not found',
      path: req.originalUrl 
    });
  });
  console.log('✅ 404 handler added');
  
  // Error handling middleware
  app.use(errorHandler);
  console.log('✅ Error handler middleware added');
  
  console.log('🚀 Starting server...');
  // Start server
  app.listen(PORT, () => {
    console.log(`🚀 Teekoob Backend Server running on port ${PORT}`);
    console.log(`📚 Environment: ${process.env.NODE_ENV}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    logger.info(`🚀 Teekoob Backend Server running on port ${PORT}`);
    logger.info(`📚 Environment: ${process.env.NODE_ENV}`);
    logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
  });
  
  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    logger.info('SIGTERM received, shutting down gracefully');
    process.exit(0);
  });
  
  process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    logger.info('SIGINT received, shutting down gracefully');
    process.exit(0);
  });
  
  module.exports = app;
  
} catch (error) {
  console.error('❌ Error during startup:', error);
  console.error('❌ Error stack:', error.stack);
  process.exit(1);
}
