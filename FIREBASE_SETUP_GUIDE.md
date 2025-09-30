# Firebase Cloud Messaging Setup Guide

## Overview
This guide will help you set up Firebase Cloud Messaging (FCM) for background notifications that work even when the app is completely closed.

## Prerequisites
- Google Cloud Console project (you already have this for Google Sign-In)
- Firebase project linked to your Google Cloud project

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Use the same project name as your Google Cloud project: `teekoob-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Firebase to Your App

### For Android:
1. In Firebase Console, click "Add app" → Android
2. Package name: `com.example.mobile` (or your actual package name)
3. App nickname: `Teekoob Mobile`
4. Download `google-services.json`
5. Place it in `mobile/android/app/google-services.json`

### For iOS:
1. In Firebase Console, click "Add app" → iOS
2. Bundle ID: `com.example.mobile` (or your actual bundle ID)
3. App nickname: `Teekoob iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `mobile/ios/Runner/GoogleService-Info.plist`

### For Web:
1. In Firebase Console, click "Add app" → Web
2. App nickname: `Teekoob Web`
3. Copy the Firebase configuration object

## Step 3: Update Firebase Configuration

Replace the placeholder values in `mobile/lib/firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'YOUR_ACTUAL_PROJECT_ID',
  authDomain: 'YOUR_ACTUAL_AUTH_DOMAIN',
  storageBucket: 'YOUR_ACTUAL_STORAGE_BUCKET',
);
```

## Step 4: Enable Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. Click "Get started"
3. This will enable FCM for your project

## Step 5: Set Up Backend Firebase Admin SDK

1. In Firebase Console, go to "Project Settings" → "Service Accounts"
2. Click "Generate new private key"
3. Download the JSON file
4. Add it to your backend as `backend/firebase-service-account.json`

## Step 6: Update Backend Environment Variables

Add these to your backend `.env` file:

```env
# Firebase Admin SDK
GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json
FIREBASE_PROJECT_ID=teekoob-app
```

## Step 7: Run Database Migrations

```bash
cd backend
npm run migrate
```

This will create the required tables:
- `user_fcm_tokens` - Stores FCM tokens for each user
- `notification_preferences` - Stores user notification preferences

## Step 8: Test the Setup

1. Build and run your mobile app
2. Sign in with Google
3. Go to Settings → Notification Settings
4. Enable "Random Book Notifications"
5. Click "Test Random Book Notification"

## How It Works

### Background Notifications Flow:
1. **App Registration**: When user opens the app, it registers FCM token with backend
2. **Backend Scheduling**: Backend runs a cron job every 10 minutes
3. **Random Book Selection**: Backend selects random books from homepage collections
4. **FCM Delivery**: Backend sends notifications via Firebase Cloud Messaging
5. **Device Delivery**: FCM delivers notifications even when app is closed

### Key Features:
- ✅ **Works when app is closed** - Uses Firebase Cloud Messaging
- ✅ **Random books from homepage** - Gets books from featured, new releases, etc.
- ✅ **Multilingual support** - Notifications in English/Somali based on user preference
- ✅ **User control** - Users can enable/disable notifications
- ✅ **Test functionality** - Users can test notifications

## Troubleshooting

### Common Issues:

1. **Notifications not working when app is closed**
   - Check Firebase configuration
   - Verify FCM token registration
   - Check backend cron job logs

2. **Build errors**
   - Ensure `google-services.json` is in correct location
   - Check Firebase dependencies in `pubspec.yaml`

3. **Backend errors**
   - Verify Firebase Admin SDK setup
   - Check database migrations ran successfully
   - Verify cron job is running

## Testing Commands

```bash
# Test mobile app build
cd mobile
flutter build apk --release

# Test backend
cd backend
npm start

# Check logs
tail -f logs/app.log
```

## Next Steps

1. Set up Firebase project
2. Add configuration files
3. Update `firebase_options.dart` with real values
4. Test notifications
5. Deploy to production

The system is now ready to send background notifications every 10 minutes with random books from your homepage collections!
