# Firebase Cloud Messaging Setup Guide

## Overview
This guide will help you set up Firebase Cloud Messaging (FCM) for background notifications in the Teekoob app. FCM allows notifications to be sent even when the app is completely closed.

## Prerequisites
- Google account
- Firebase project
- Android Studio (for Android setup)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `teekoob-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.example.mobile`
3. Enter app nickname: `Teekoob Mobile`
4. Click "Register app"
5. Download `google-services.json` file
6. Replace the placeholder `google-services.json` in `mobile/android/app/` with your downloaded file

## Step 3: Configure Firebase Admin SDK (Backend)

1. In Firebase Console, go to Project Settings > Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Replace the service account configuration in `backend/src/services/notification_service.js`:

```javascript
const serviceAccount = {
  // Replace with your actual service account details
  type: "service_account",
  project_id: "your-project-id",
  private_key_id: "your-private-key-id",
  private_key: "-----BEGIN PRIVATE KEY-----\nyour-private-key\n-----END PRIVATE KEY-----\n",
  client_email: "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  client_id: "your-client-id",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project.iam.gserviceaccount.com"
};
```

## Step 4: Environment Variables (Backend)

Add these environment variables to your backend `.env` file:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour-private-key\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

## Step 5: Test Notifications

### Frontend Testing
1. Run the app: `flutter run`
2. Go to Settings > Notification Settings
3. Toggle "Random Book Notifications" ON
4. Tap "Test Random Book Notification"

### Backend Testing
1. Start the backend server: `npm start`
2. Check console logs for: "🔥 Random book notifications started - every 10 minutes"
3. Wait 10 minutes to see if notifications are sent

## How It Works

### Frontend (Mobile App)
- **FirebaseNotificationService**: Handles FCM token registration and message reception
- **Topic Subscription**: Users subscribe to 'random_books' topic
- **Background Handler**: Processes notifications when app is closed
- **Local Notifications**: Shows notifications in foreground

### Backend (Server)
- **NotificationService**: Sends notifications every 10 minutes using cron job
- **Firebase Admin SDK**: Authenticates with Firebase to send messages
- **Topic Messaging**: Sends to all users subscribed to 'random_books' topic
- **Random Book Selection**: Fetches random books from homepage collections

## Notification Flow

1. **Backend cron job** runs every 10 minutes
2. **Selects random book** from homepage collections
3. **Sends FCM message** to 'random_books' topic
4. **Firebase delivers** to all subscribed devices
5. **App receives notification** even when closed
6. **User sees notification** with book details

## Troubleshooting

### Common Issues

1. **Notifications not received**:
   - Check Firebase project configuration
   - Verify google-services.json is correct
   - Ensure app is subscribed to topic

2. **Backend errors**:
   - Verify service account credentials
   - Check Firebase Admin SDK initialization
   - Ensure cron job is running

3. **Build errors**:
   - Run `flutter clean && flutter pub get`
   - Check Android build.gradle configuration
   - Verify Google Services plugin

### Debug Steps

1. Check Firebase Console > Cloud Messaging for delivery reports
2. Monitor backend logs for cron job execution
3. Test with Firebase Console > Cloud Messaging > Send test message
4. Verify FCM token registration in app logs

## Security Notes

- Keep service account keys secure
- Use environment variables for sensitive data
- Implement proper user authentication
- Consider rate limiting for notifications

## Next Steps

1. Set up Firebase project
2. Configure service account
3. Test notifications
4. Deploy to production
5. Monitor notification delivery

For more information, visit [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
