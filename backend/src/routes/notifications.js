const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const cron = require('node-cron');
const db = require('../config/database');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    // Try to use service account from environment variables first
    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID || 'teekoob',
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
      universe_domain: "googleapis.com"
    };

    // Check if we have the required environment variables
    if (serviceAccount.private_key && serviceAccount.client_email) {
      console.log('🔔 Initializing Firebase with environment variables...');
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id,
      });
      console.log('🔔 ✅ Firebase initialized with environment variables');
    } else {
      console.log('🔔 ⚠️ Firebase environment variables not found, trying application default...');
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: 'teekoob',
      });
      console.log('🔔 ✅ Firebase initialized with application default');
    }
  } catch (error) {
    console.error('🔔 ❌ Firebase initialization failed:', error);
    throw error;
  }
}

// Database connection is handled by the main database config

// Store for FCM tokens and notification preferences
const userTokens = new Map();
const notificationPreferences = new Map();

// Schedule random book notifications every 2 minutes
cron.schedule('*/2 * * * *', async () => {
  try {
    console.log('🔔 Running scheduled random book notification...');
    await sendRandomBookNotifications();
  } catch (error) {
    console.error('❌ Error in scheduled notification:', error);
  }
});

// Register FCM token
router.post('/register-token', async (req, res) => {
  try {
    const { fcmToken, platform, enabled } = req.body;
    const userId = req.user?.id;

    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    // Store token in database
    await db('user_fcm_tokens')
      .insert({
        user_id: userId,
        fcm_token: fcmToken,
        platform: platform || 'mobile',
        enabled: enabled !== false,
        created_at: new Date()
      })
      .onConflict(['user_id', 'fcm_token'])
      .merge({
        enabled: enabled !== false,
        updated_at: new Date()
      });

    // Store in memory for quick access
    if (userId) {
      userTokens.set(userId, fcmToken);
    }

    console.log(`🔔 FCM token registered for user ${userId}`);
    res.json({ success: true, message: 'FCM token registered successfully' });
  } catch (error) {
    console.error('❌ Error registering FCM token:', error);
    res.status(500).json({ error: 'Failed to register FCM token' });
  }
});

// Enable/disable random book notifications
router.post('/enable-random-books', async (req, res) => {
  try {
    const { enabled, interval, platform } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    // Store preference in database
    await db('notification_preferences')
      .insert({
        user_id: userId,
        random_books_enabled: enabled,
        random_books_interval: interval || 10,
        platform: platform || 'mobile',
        created_at: new Date()
      })
      .onConflict('user_id')
      .merge({
        random_books_enabled: enabled,
        random_books_interval: interval || 10,
        updated_at: new Date()
      });

    // Store in memory
    notificationPreferences.set(userId, {
      randomBooksEnabled: enabled,
      interval: interval || 10,
      platform: platform || 'mobile'
    });

    console.log(`🔔 Random book notifications ${enabled ? 'enabled' : 'disabled'} for user ${userId}`);
    res.json({ 
      success: true, 
      message: `Random book notifications ${enabled ? 'enabled' : 'disabled'}` 
    });
  } catch (error) {
    console.error('❌ Error updating notification preferences:', error);
    res.status(500).json({ error: 'Failed to update notification preferences' });
  }
});

// Disable random book notifications
router.post('/disable-random-books', async (req, res) => {
  try {
    const { enabled, platform } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    // Update preference in database
    await db('notification_preferences')
      .where('user_id', userId)
      .update({
        random_books_enabled: false,
        updated_at: new Date()
      });

    // Update in memory
    const preferences = notificationPreferences.get(userId);
    if (preferences) {
      preferences.randomBooksEnabled = false;
      notificationPreferences.set(userId, preferences);
    }

    console.log(`🔔 Random book notifications disabled for user ${userId}`);
    res.json({ success: true, message: 'Random book notifications disabled' });
  } catch (error) {
    console.error('❌ Error disabling notifications:', error);
    res.status(500).json({ error: 'Failed to disable notifications' });
  }
});

// Send test notification with real book
router.post('/send-test', async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const fcmToken = userTokens.get(userId);
    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token not found for user' });
    }

    // Get a random book from database for test
    const booksResult = await db('books')
      .select('id', 'title', 'title_somali', 'description', 'description_somali', 
              'cover_image_url', 'authors', 'authors_somali', 'genre', 'genre_somali',
              'is_featured', 'is_new_release', 'rating', 'review_count')
      .where(function() {
        this.where('is_featured', true)
            .orWhere('is_new_release', true)
            .orWhere('rating', '>=', 4.0);
      })
      .orderByRaw('RAND()')
      .limit(1);

    if (booksResult.length === 0) {
      // Fallback to any book
      const fallbackResult = await db('books')
        .select('id', 'title', 'title_somali', 'description', 'description_somali', 
                'cover_image_url', 'authors', 'authors_somali', 'genre', 'genre_somali',
                'is_featured', 'is_new_release', 'rating', 'review_count')
        .orderByRaw('RAND()')
        .limit(1);
      
      if (fallbackResult.length === 0) {
        return res.status(404).json({ error: 'No books available for test notification' });
      }
      
      booksResult.push(fallbackResult[0]);
    }

    const testBook = booksResult[0];
    console.log(`🔔 Test notification using book: ${testBook.title}`);

    // Get user's preferred language
    const userResult = await db('users')
      .select('language_preference')
      .where('id', userId)
      .first();
    const userLanguage = userResult?.language_preference || 'en';
    const isSomali = userLanguage === 'so';

    // Create notification content based on user language
    let title, body;
    if (isSomali) {
      title = '📚 Tijaabada Buug!';
      const bookTitle = testBook.title_somali || testBook.title;
      const description = testBook.description_somali || testBook.description || 'Buug xiiso leh oo ka mid ah kuwa bogga hore!';
      const author = testBook.authors_somali ? JSON.parse(testBook.authors_somali)[0] : 'Qoraaga';
      body = `${bookTitle}\n\n${author}\n\n${description}`;
    } else {
      title = '📚 Test Book Alert!';
      const bookTitle = testBook.title;
      const description = testBook.description || 'This is a test notification with a real book from Teekoob!';
      const author = testBook.authors ? JSON.parse(testBook.authors)[0] : 'Author';
      body = `${bookTitle}\n\n${author}\n\n${description}`;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        bookId: testBook.id.toString(),
        type: 'test',
        platform: 'mobile',
        bookTitle: testBook.title,
        bookTitleSomali: testBook.title_somali || testBook.title,
        coverImage: testBook.cover_image_url || '',
        isFeatured: testBook.is_featured ? 'true' : 'false',
        isNewRelease: testBook.is_new_release ? 'true' : 'false',
        rating: testBook.rating ? testBook.rating.toString() : '0',
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`🔔 Test notification sent successfully: ${response}`);
    console.log(`📖 Test book: ${testBook.title} by ${testBook.authors ? JSON.parse(testBook.authors)[0] : 'Unknown Author'}`);

    res.json({ 
      success: true, 
      message: 'Test notification sent successfully',
      book: {
        id: testBook.id,
        title: testBook.title,
        titleSomali: testBook.title_somali,
        author: testBook.authors ? JSON.parse(testBook.authors)[0] : 'Unknown Author',
        isFeatured: testBook.is_featured,
        isNewRelease: testBook.is_new_release,
        rating: testBook.rating
      }
    });
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({ error: 'Failed to send test notification' });
  }
});

// Get random book and send notifications
async function sendRandomBookNotifications() {
  try {
    console.log('🔔 ===== RANDOM BOOK NOTIFICATION PROCESS START =====');
    console.log('🔔 Starting random book notification process...');
    
    // Debug: Check what's in the database
    console.log('🔔 🔍 DEBUG: Checking database contents...');
    
    const userCount = await db('users').count('* as count').first();
    const fcmCount = await db('user_fcm_tokens').count('* as count').first();
    const prefCount = await db('notification_preferences').count('* as count').first();
    
    console.log('🔔 🔍 DEBUG: Database counts - Users:', userCount.count, 'FCM Tokens:', fcmCount.count, 'Preferences:', prefCount.count);
    
    // Debug: Show sample data
    const sampleUsers = await db('users').select('id', 'email', 'first_name').limit(3);
    const sampleFCM = await db('user_fcm_tokens').select('user_id', 'fcm_token', 'enabled').limit(3);
    const samplePrefs = await db('notification_preferences').select('user_id', 'random_books_enabled').limit(3);
    
    console.log('🔔 🔍 DEBUG: Sample users:', sampleUsers);
    console.log('🔔 🔍 DEBUG: Sample FCM tokens:', sampleFCM);
    console.log('🔔 🔍 DEBUG: Sample preferences:', samplePrefs);
    
    // Get all users who have random book notifications enabled
    console.log('🔔 🔍 DEBUG: Running notification query...');
    const result = await db('users as u')
      .select('u.id', 'u.email', 'u.first_name', 'u.last_name', 'u.language_preference',
              'nf.fcm_token', 'np.random_books_enabled', 'np.random_books_interval')
      .join('user_fcm_tokens as nf', 'u.id', 'nf.user_id')
      .join('notification_preferences as np', 'u.id', 'np.user_id')
      .where('nf.enabled', true)
      .andWhere('np.random_books_enabled', true);

    console.log('🔔 🔍 DEBUG: Query result length:', result.length);
    console.log('🔔 🔍 DEBUG: Query result:', result);

    if (result.length === 0) {
      console.log('🔔 ❌ No users with random book notifications enabled');
      console.log('🔔 🔍 DEBUG: This means either:');
      console.log('🔔 🔍 DEBUG: 1. No FCM tokens in user_fcm_tokens table');
      console.log('🔔 🔍 DEBUG: 2. No notification preferences in notification_preferences table');
      console.log('🔔 🔍 DEBUG: 3. FCM tokens are disabled (enabled = false)');
      console.log('🔔 🔍 DEBUG: 4. Random books are disabled (random_books_enabled = false)');
      return;
    }

    console.log(`🔔 ✅ Found ${result.length} users with notifications enabled`);

    // Get random books from database - prioritize featured and new releases
    const booksResult = await db('books')
      .select('id', 'title', 'title_somali', 'description', 'description_somali', 
              'cover_image_url', 'authors', 'authors_somali',
              'is_featured', 'is_new_release', 'rating', 'review_count')
      .where(function() {
        this.where('is_featured', true)
            .orWhere('is_new_release', true)
            .orWhere('rating', '>=', 4.0);
      })
      .orderByRaw('RAND()')
      .limit(20);

    if (booksResult.length === 0) {
      console.log('🔔 No featured books found, getting any random books...');
      // Fallback to any books if no featured books
      const fallbackResult = await db('books')
        .select('id', 'title', 'title_somali', 'description', 'description_somali', 
                'cover_image_url', 'authors', 'authors_somali',
                'is_featured', 'is_new_release', 'rating', 'review_count')
        .orderByRaw('RAND()')
        .limit(10);
      
      if (fallbackResult.length === 0) {
        console.log('🔔 No books available for notifications');
        return;
      }
      
      booksResult.push(...fallbackResult);
    }

    const randomBook = booksResult[Math.floor(Math.random() * booksResult.length)];
    console.log(`🔔 Selected random book: ${randomBook.title} (ID: ${randomBook.id})`);

    // Send notifications to all enabled users
    const promises = result.map(async (user) => {
      try {
        // Skip fake FCM tokens
        if (user.fcm_token.startsWith('auto_token_') || user.fcm_token.startsWith('test_token_')) {
          console.log(`🔔 ⚠️ Skipping fake FCM token for user ${user.email}: ${user.fcm_token}`);
          return;
        }

        // Validate FCM token format (should be base64-like string)
        if (user.fcm_token.length < 50 || !user.fcm_token.includes(':')) {
          console.log(`🔔 ⚠️ Skipping invalid FCM token format for user ${user.email}: ${user.fcm_token}`);
          return;
        }

        const isSomali = user.language_preference === 'so';
        
        // Create notification content based on user language
        let title, body;
        if (isSomali) {
          title = '📚 Buug Xiiso Leh!';
          const bookTitle = randomBook.title_somali || randomBook.title;
          const description = randomBook.description_somali || randomBook.description || 'Buug xiiso leh oo ka mid ah kuwa bogga hore!';
          const author = randomBook.authors_somali ? (typeof randomBook.authors_somali === 'string' && randomBook.authors_somali.startsWith('[') ? JSON.parse(randomBook.authors_somali)[0] : randomBook.authors_somali) : 'Qoraaga';
          body = `${bookTitle}\n\n${author}\n\n${description}`;
        } else {
          title = '📚 Featured Book Alert!';
          const bookTitle = randomBook.title;
          const description = randomBook.description || 'Discover this amazing book from our homepage collections!';
          const author = randomBook.authors ? (typeof randomBook.authors === 'string' && randomBook.authors.startsWith('[') ? JSON.parse(randomBook.authors)[0] : randomBook.authors) : 'Author';
          body = `${bookTitle}\n\n${author}\n\n${description}`;
        }

        const message = {
          notification: {
            title: title,
            body: body,
          },
          data: {
            bookId: randomBook.id.toString(),
            type: 'random_book',
            platform: 'mobile',
            bookTitle: randomBook.title,
            bookTitleSomali: randomBook.title_somali || randomBook.title,
            coverImage: randomBook.cover_image_url || '',
            isFeatured: randomBook.is_featured ? 'true' : 'false',
            isNewRelease: randomBook.is_new_release ? 'true' : 'false',
            rating: randomBook.rating ? randomBook.rating.toString() : '0',
          },
          token: user.fcm_token,
        };

        const response = await admin.messaging().send(message);
        console.log(`🔔 ✅ Random book notification sent to user ${user.email}: ${response}`);
        
        // Log the book details for debugging
        console.log(`📖 Book details: ${randomBook.title} by ${randomBook.authors ? JSON.parse(randomBook.authors)[0] : 'Unknown Author'}`);
        
      } catch (error) {
        console.error(`❌ Error sending notification to user ${user.email}:`, error);
        
        // If it's an invalid token error, disable the token
        if (error.code === 'messaging/invalid-argument' && error.message.includes('registration token')) {
          console.log(`🔔 🗑️ Disabling invalid FCM token for user ${user.email}`);
          try {
            await db('user_fcm_tokens')
              .where('user_id', user.id)
              .where('fcm_token', user.fcm_token)
              .update({ enabled: false, updated_at: new Date() });
            console.log(`🔔 ✅ Invalid FCM token disabled for user ${user.email}`);
          } catch (dbError) {
            console.error(`❌ Error disabling invalid FCM token:`, dbError);
          }
        }
      }
    });

    await Promise.all(promises);
    console.log(`🔔 Random book notifications sent to ${result.length} users`);
    
    // Log successful notification
    console.log(`✅ Successfully sent random book notification: "${randomBook.title}" to ${result.length} users`);
    
  } catch (error) {
    console.error('❌ Error in sendRandomBookNotifications:', error);
  }
}

// Get notification preferences
router.get('/preferences', async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const result = await db('notification_preferences')
      .select('*')
      .where('user_id', userId)
      .first();

    if (!result) {
      return res.json({
        randomBooksEnabled: false,
        interval: 10,
        platform: 'mobile'
      });
    }

    res.json(result);
  } catch (error) {
    console.error('❌ Error getting notification preferences:', error);
    res.status(500).json({ error: 'Failed to get notification preferences' });
  }
});

// Update notification preferences
router.put('/preferences', async (req, res) => {
  try {
    const { randomBooksEnabled, interval, platform } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    await db('notification_preferences')
      .insert({
        user_id: userId,
        random_books_enabled: randomBooksEnabled,
        random_books_interval: interval || 10,
        platform: platform || 'mobile',
        created_at: new Date()
      })
      .onConflict('user_id')
      .merge({
        random_books_enabled: randomBooksEnabled,
        random_books_interval: interval || 10,
        platform: platform || 'mobile',
        updated_at: new Date()
      });

    // Update in memory
    notificationPreferences.set(userId, {
      randomBooksEnabled,
      interval: interval || 10,
      platform: platform || 'mobile'
    });

    res.json({ success: true, message: 'Notification preferences updated' });
  } catch (error) {
    console.error('❌ Error updating notification preferences:', error);
    res.status(500).json({ error: 'Failed to update notification preferences' });
  }
});

// Test endpoint to create sample notification data (for testing only)
router.post('/test-setup', async (req, res) => {
  try {
    console.log('🔔 Setting up test notification data...');
    
    // Get the first user from the database
    const user = await db('users').select('id', 'email', 'first_name', 'last_name', 'language_preference').first();
    
    if (!user) {
      return res.status(404).json({ error: 'No users found in database' });
    }
    
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

// Test endpoint to manually trigger random book notifications
router.post('/test-notification', async (req, res) => {
  try {
    console.log('🔔 Manually triggering random book notifications...');
    await sendRandomBookNotifications();
    res.json({
      success: true,
      message: 'Random book notifications triggered successfully'
    });
  } catch (error) {
    console.error('❌ Error triggering notifications:', error);
    res.status(500).json({ error: 'Failed to trigger notifications' });
  }
});

// Cleanup endpoint to remove fake FCM tokens
router.post('/cleanup-fake-tokens', async (req, res) => {
  try {
    console.log('🔔 Cleaning up fake FCM tokens...');
    
    // Delete fake tokens
    const deletedCount = await db('user_fcm_tokens')
      .where('fcm_token', 'like', 'auto_token_%')
      .orWhere('fcm_token', 'like', 'test_token_%')
      .del();
    
    console.log(`🔔 ✅ Deleted ${deletedCount} fake FCM tokens`);
    
    res.json({
      success: true,
      message: `Cleaned up ${deletedCount} fake FCM tokens`,
      deletedCount: deletedCount
    });
  } catch (error) {
    console.error('❌ Error cleaning up fake tokens:', error);
    res.status(500).json({ error: 'Failed to cleanup fake tokens' });
  }
});

module.exports = router;
