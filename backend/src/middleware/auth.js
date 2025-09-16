const jwt = require('jsonwebtoken');
const db = require('../config/database');
const logger = require('../utils/logger');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ 
        error: 'Access token required',
        code: 'TOKEN_MISSING'
      });
    }

    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user still exists and is active
    const user = await db('users')
      .select('id', 'email', 'first_name', 'last_name', 'subscription_plan', 'subscription_expires_at', 'is_active', 'is_admin')
      .where('id', decoded.userId)
      .first();

    if (!user) {
      return res.status(401).json({ 
        error: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }

    if (!user.is_active) {
      return res.status(401).json({ 
        error: 'User account is deactivated',
        code: 'USER_DEACTIVATED'
      });
    }

    // Check subscription status
    if (user.subscription_plan !== 'free' && user.subscription_expires_at) {
      if (new Date() > new Date(user.subscription_expires_at)) {
        // Subscription expired, but user can still access free content
        user.subscription_plan = 'free';
      }
    }

    // Add user info to request
    req.user = user;
    req.userId = user.id;
    
    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    
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

    return res.status(500).json({ 
      error: 'Authentication failed',
      code: 'AUTH_ERROR'
    });
  }
};

// Optional authentication - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await db('users')
        .select('id', 'email', 'first_name', 'last_name', 'subscription_plan', 'subscription_expires_at', 'is_active', 'is_admin')
        .where('id', decoded.userId)
        .first();

      if (user && user.is_active) {
        req.user = user;
        req.userId = user.id;
      }
    }
    
    next();
  } catch (error) {
    // Continue without authentication
    next();
  }
};

// Admin authentication
const requireAdmin = async (req, res, next) => {
  try {
    // Check if user exists in request (set by authenticateToken)
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    // Check if user is admin using the is_admin field already available in req.user
    if (!req.user.is_admin) {
      return res.status(403).json({ 
        error: 'Admin access required. Only admin users can access this resource.',
        code: 'ADMIN_REQUIRED'
      });
    }

    next();
  } catch (error) {
    logger.error('Admin authentication error:', error);
    return res.status(500).json({ 
      error: 'Admin authentication failed',
      code: 'ADMIN_AUTH_ERROR'
    });
  }
};

module.exports = {
  authenticateToken,
  optionalAuth,
  requireAdmin
};
