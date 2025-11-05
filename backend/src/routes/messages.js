const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const db = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../middleware/asyncHandler');
const { body, validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * @route   POST /api/v1/messages
 * @desc    Admin sends a message to one or more users
 * @access  Admin only
 */
router.post(
  '/',
  authenticateToken,
  requireAdmin,
  [
    body('userIds').isArray().withMessage('userIds must be an array'),
    body('userIds.*').isUUID().withMessage('Each userId must be a valid UUID'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('title').isLength({ max: 255 }).withMessage('Title must be less than 255 characters'),
    body('message').trim().notEmpty().withMessage('Message is required'),
    body('message').isLength({ max: 5000 }).withMessage('Message must be less than 5000 characters'),
    body('actionUrl').optional().isURL().withMessage('actionUrl must be a valid URL'),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userIds, title, message, actionUrl } = req.body;
    const senderId = req.userId;

    // Verify all users exist
    const users = await db('users')
      .whereIn('id', userIds)
      .select('id');

    if (users.length !== userIds.length) {
      return res.status(400).json({
        error: 'One or more user IDs are invalid',
        code: 'INVALID_USER_IDS'
      });
    }

    // Create notifications for each user
    const notifications = userIds.map(userId => ({
      id: crypto.randomUUID(),
      user_id: userId,
      sender_id: senderId,
      title: title.trim(),
      message: message.trim(),
      type: 'admin_message',
      is_read: false,
      action_url: actionUrl || null,
      created_at: db.fn.now(),
    }));

    await db('notifications').insert(notifications);

    logger.info('Admin messages sent', {
      senderId,
      recipientCount: userIds.length,
      title: title.substring(0, 50),
    });

    res.status(201).json({
      message: `Messages sent to ${userIds.length} user(s)`,
      notificationsCreated: notifications.length,
    });
  })
);

/**
 * @route   POST /api/v1/messages/broadcast
 * @desc    Admin sends a message to all users
 * @access  Admin only
 */
router.post(
  '/broadcast',
  authenticateToken,
  requireAdmin,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('title').isLength({ max: 255 }).withMessage('Title must be less than 255 characters'),
    body('message').trim().notEmpty().withMessage('Message is required'),
    body('message').isLength({ max: 5000 }).withMessage('Message must be less than 5000 characters'),
    body('actionUrl').optional().isURL().withMessage('actionUrl must be a valid URL'),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { title, message, actionUrl } = req.body;
    const senderId = req.userId;

    // Get all user IDs
    const users = await db('users').select('id');
    const userIds = users.map(u => u.id);

    if (userIds.length === 0) {
      return res.status(404).json({
        error: 'No users found',
        code: 'NO_USERS'
      });
    }

    // Create notifications for all users
    const notifications = userIds.map(userId => ({
      id: crypto.randomUUID(),
      user_id: userId,
      sender_id: senderId,
      title: title.trim(),
      message: message.trim(),
      type: 'admin_message',
      is_read: false,
      action_url: actionUrl || null,
      created_at: db.fn.now(),
    }));

    // Insert in batches to avoid query size limits
    const batchSize = 100;
    for (let i = 0; i < notifications.length; i += batchSize) {
      const batch = notifications.slice(i, i + batchSize);
      await db('notifications').insert(batch);
    }

    logger.info('Broadcast message sent', {
      senderId,
      recipientCount: userIds.length,
      title: title.substring(0, 50),
    });

    res.status(201).json({
      message: `Broadcast message sent to ${userIds.length} user(s)`,
      notificationsCreated: notifications.length,
    });
  })
);

/**
 * @route   GET /api/v1/messages
 * @desc    Get user's notifications/messages
 * @access  Authenticated users
 */
router.get(
  '/',
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.userId;
    const { page = 1, limit = 20, unreadOnly = false } = req.query;

    const pageNum = parseInt(page, 10);
    const limitNum = parseInt(limit, 10);
    const offset = (pageNum - 1) * limitNum;

    // Build query
    let query = db('notifications')
      .where('user_id', userId)
      .orderBy('created_at', 'desc');

    if (unreadOnly === 'true') {
      query = query.where('is_read', false);
    }

    // Get total count
    const totalQuery = query.clone().count('* as count').first();
    const totalResult = await totalQuery;
    const total = totalResult.count;

    // Get notifications
    const notifications = await query
      .limit(limitNum)
      .offset(offset)
      .select(
        'id',
        'title',
        'message',
        'type',
        'is_read',
        'action_url as actionUrl',
        'created_at as createdAt',
        'read_at as readAt'
      );

    // Get unread count
    const unreadCount = await db('notifications')
      .where('user_id', userId)
      .where('is_read', false)
      .count('* as count')
      .first();

    res.json({
      notifications,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
      unreadCount: unreadCount.count,
    });
  })
);

/**
 * @route   GET /api/v1/messages/unread-count
 * @desc    Get user's unread notification count
 * @access  Authenticated users
 */
router.get(
  '/unread-count',
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.userId;

    const result = await db('notifications')
      .where('user_id', userId)
      .where('is_read', false)
      .count('* as count')
      .first();

    res.json({
      unreadCount: result.count || 0,
    });
  })
);

/**
 * @route   PUT /api/v1/messages/:id/read
 * @desc    Mark a notification as read
 * @access  Authenticated users
 */
router.put(
  '/:id/read',
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.userId;
    const notificationId = req.params.id;

    // Verify notification belongs to user
    const notification = await db('notifications')
      .where('id', notificationId)
      .where('user_id', userId)
      .first();

    if (!notification) {
      return res.status(404).json({
        error: 'Notification not found',
        code: 'NOTIFICATION_NOT_FOUND'
      });
    }

    // Mark as read
    await db('notifications')
      .where('id', notificationId)
      .update({
        is_read: true,
        read_at: db.fn.now(),
      });

    res.json({
      message: 'Notification marked as read',
    });
  })
);

/**
 * @route   PUT /api/v1/messages/read-all
 * @desc    Mark all user's notifications as read
 * @access  Authenticated users
 */
router.put(
  '/read-all',
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.userId;

    await db('notifications')
      .where('user_id', userId)
      .where('is_read', false)
      .update({
        is_read: true,
        read_at: db.fn.now(),
      });

    res.json({
      message: 'All notifications marked as read',
    });
  })
);

/**
 * @route   DELETE /api/v1/messages/:id
 * @desc    Delete a notification
 * @access  Authenticated users
 */
router.delete(
  '/:id',
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.userId;
    const notificationId = req.params.id;

    // Verify notification belongs to user
    const notification = await db('notifications')
      .where('id', notificationId)
      .where('user_id', userId)
      .first();

    if (!notification) {
      return res.status(404).json({
        error: 'Notification not found',
        code: 'NOTIFICATION_NOT_FOUND'
      });
    }

    await db('notifications')
      .where('id', notificationId)
      .delete();

    res.json({
      message: 'Notification deleted',
    });
  })
);

module.exports = router;

