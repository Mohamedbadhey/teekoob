const admin = require('firebase-admin');
const cron = require('node-cron');
const axios = require('axios');

class NotificationService {
  constructor() {
    this.isInitialized = false;
    this.notificationJob = null;
  }

  async initialize() {
    if (this.isInitialized) return;

    try {
      // Initialize Firebase Admin SDK
      if (!admin.apps.length) {
        // Firebase service account configuration
        const serviceAccount = {
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID || "loginproject-e428a",
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL || "firebase-adminsdk-xjo7a@loginproject-e428a.iam.gserviceaccount.com",
          client_id: process.env.FIREBASE_CLIENT_ID || "111518350729660009698",
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://oauth2.googleapis.com/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
          client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xjo7a%40loginproject-e428a.iam.gserviceaccount.com"
        };

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: 'loginproject-e428a'
        });
      }

      this.isInitialized = true;
      console.log('🔥 Firebase Admin SDK initialized');
    } catch (error) {
      console.error('❌ Error initializing Firebase Admin SDK:', error);
    }
  }

  async startRandomBookNotifications() {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      // Schedule notification every 10 minutes
      this.notificationJob = cron.schedule('*/10 * * * *', async () => {
        await this.sendRandomBookNotification();
      }, {
        scheduled: true,
        timezone: "UTC"
      });

      console.log('🔥 Random book notifications scheduled every 10 minutes');
    } catch (error) {
      console.error('❌ Error starting random book notifications:', error);
    }
  }

  async stopRandomBookNotifications() {
    if (this.notificationJob) {
      this.notificationJob.destroy();
      this.notificationJob = null;
      console.log('🔥 Random book notifications stopped');
    }
  }

  async sendRandomBookNotification() {
    try {
      // Get random book from database
      const randomBook = await this.getRandomBook();
      if (!randomBook) {
        console.log('📚 No books available for notification');
        return;
      }

      // Create notification message
      const message = {
        notification: {
          title: '📚 Featured Book Alert!',
          body: `${randomBook.title}\n\n${randomBook.description || 'Discover this amazing book from our homepage collections!'}`
        },
        data: {
          book_id: randomBook.id.toString(),
          book_title: randomBook.title,
          type: 'random_book'
        },
        topic: 'random_books'
      };

      // Send notification to all subscribers
      const response = await admin.messaging().send(message);
      console.log('🔥 Random book notification sent:', response);

    } catch (error) {
      console.error('❌ Error sending random book notification:', error);
    }
  }

  async getRandomBook() {
    try {
      // This would typically query your database
      // For now, we'll simulate getting a random book
      const books = [
        {
          id: 1,
          title: "The Great Adventure",
          description: "An epic tale of courage and discovery"
        },
        {
          id: 2,
          title: "Mystery of the Lost City",
          description: "A thrilling mystery that will keep you guessing"
        },
        {
          id: 3,
          title: "Science and Wonder",
          description: "Explore the fascinating world of science"
        }
      ];

      const randomIndex = Math.floor(Math.random() * books.length);
      return books[randomIndex];
    } catch (error) {
      console.error('❌ Error getting random book:', error);
      return null;
    }
  }

  async sendNotificationToUser(userId, notification) {
    try {
      // Get user's FCM token from database
      const userToken = await this.getUserFCMToken(userId);
      if (!userToken) {
        console.log('❌ No FCM token found for user:', userId);
        return;
      }

      const message = {
        notification: notification,
        token: userToken
      };

      const response = await admin.messaging().send(message);
      console.log('🔥 Notification sent to user:', userId, response);
      return response;
    } catch (error) {
      console.error('❌ Error sending notification to user:', error);
    }
  }

  async getUserFCMToken(userId) {
    try {
      // This would typically query your database for the user's FCM token
      // For now, return null as we don't have user tokens stored
      return null;
    } catch (error) {
      console.error('❌ Error getting user FCM token:', error);
      return null;
    }
  }

  async sendTestNotification() {
    try {
      const message = {
        notification: {
          title: '📚 Test Notification',
          body: 'This is a test notification from Teekoob!'
        },
        topic: 'random_books'
      };

      const response = await admin.messaging().send(message);
      console.log('🔥 Test notification sent:', response);
      return response;
    } catch (error) {
      console.error('❌ Error sending test notification:', error);
    }
  }
}

module.exports = new NotificationService();
