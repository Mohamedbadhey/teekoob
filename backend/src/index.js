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
