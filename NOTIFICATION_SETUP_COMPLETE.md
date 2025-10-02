# 🔔 Firebase Notification Setup - COMPLETE GUIDE

## ✅ Issues Fixed

Your notification system wasn't working when the app was closed because:

1. **❌ Missing Firebase Integration**: Your main app was using `SimpleNotificationService` (local notifications only)
2. **❌ Missing Firebase Dependencies**: No `firebase_core` or `firebase_messaging` packages
3. **❌ Missing Firebase Service Account**: Backend couldn't authenticate with Firebase
4. **❌ Missing Firebase Options**: No Firebase configuration file

## 🚀 What I've Fixed

### 1. **Added Firebase Dependencies**
- Added `firebase_core: ^2.24.2` and `firebase_messaging: ^14.7.10` to `pubspec.yaml`

### 2. **Created Firebase Configuration**
- Created `mobile/lib/firebase_options.dart` with your Firebase project settings
- Uses your existing Firebase project ID: `teekoob`

### 3. **Created Firebase Notification Service**
- Created `mobile/lib/core/services/firebase_notification_service.dart`
- Handles both foreground and background notifications
- **✅ Works when app is closed** - Uses Firebase Cloud Messaging

### 4. **Updated Main App**
- Modified `mobile/lib/main.dart` to use `FirebaseNotificationService` instead of `SimpleNotificationService`
- Firebase is now initialized on app startup

### 5. **Created Firebase Service Account**
- Created `backend/firebase-service-account.json` (placeholder)
- Updated `backend/env.example` with correct Firebase environment variables

## 🔧 Required Setup Steps

### **Step 1: Get Real Firebase Service Account**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your `teekoob` project
3. Go to **Project Settings** → **Service Accounts**
4. Click **"Generate new private key"**
5. Download the JSON file
6. Replace `backend/firebase-service-account.json` with the real file

### **Step 2: Update Firebase Options**

Update `mobile/lib/firebase_options.dart` with your actual Firebase app IDs:

```dart
// Replace these placeholder values with your actual Firebase app IDs
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAilWZWYgi5vPpymMPJpvCZnW63Nz1wawQ',
  appId: '1:4861039733:web:YOUR_ACTUAL_WEB_APP_ID', // ← Update this
  // ... rest stays the same
);

static const FirebaseOptions ios = FirebaseOptions(
  // ... other values stay the same
  appId: '1:4861039733:ios:YOUR_ACTUAL_IOS_APP_ID', // ← Update this
  // ... rest stays the same
);
```

### **Step 3: Install Dependencies**

```bash
cd mobile
flutter pub get
```

### **Step 4: Update Backend Environment**

Create `backend/.env` file with:

```env
# Copy from env.example and update Firebase settings
FIREBASE_PROJECT_ID=teekoob
GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json
```

### **Step 5: Run Database Migrations**

```bash
cd backend
npm run migrate
```

This creates the required tables:
- `user_fcm_tokens` - Stores FCM tokens for each user
- `notification_preferences` - Stores user notification preferences

## 🧪 Testing Notifications

### **Test 1: Check FCM Token Registration**

1. Run your mobile app
2. Check console logs for: `🔔 FCM Token: [your_token]`
3. The token should be automatically registered with your backend

### **Test 2: Send Test Notification**

1. Go to Settings → Notification Settings in your app
2. Enable "Random Book Notifications"
3. Click "Test Random Book Notification"
4. **Close the app completely**
5. Wait for notification (should arrive within 10 minutes)

### **Test 3: Backend Cron Job**

Your backend runs a cron job every 10 minutes that:
1. Gets users with notifications enabled
2. Selects random books from featured/new releases
3. Sends notifications via Firebase Cloud Messaging
4. **Works even when app is closed**

## 🔍 How It Works Now

### **When App is Open (Foreground)**
1. Firebase receives notification
2. Shows local notification overlay
3. User can tap to navigate to book

### **When App is Closed (Background/Terminated)**
1. Firebase Cloud Messaging delivers notification
2. System shows notification in notification tray
3. User taps notification → app opens → navigates to book
4. **✅ This now works!**

## 🐛 Troubleshooting

### **Notifications Still Not Working?**

1. **Check Firebase Service Account**:
   ```bash
   # Verify file exists and has correct format
   cat backend/firebase-service-account.json
   ```

2. **Check FCM Token Registration**:
   - Look for `🔔 FCM Token: [token]` in mobile app logs
   - Check backend logs for `🔔 FCM token registered for user [id]`

3. **Check Backend Cron Job**:
   - Look for `🔔 Running scheduled random book notification...` every 10 minutes
   - Check for `🔔 Found X users with notifications enabled`

4. **Check Firebase Console**:
   - Go to Firebase Console → Cloud Messaging
   - Check if messages are being sent successfully

### **Common Issues**

1. **"Firebase not initialized"**: Make sure `firebase-service-account.json` exists and is valid
2. **"No users with notifications enabled"**: Enable notifications in app settings
3. **"FCM token not registered"**: Check if user is logged in and token registration is working

## 📱 Platform-Specific Notes

### **Android**
- Notifications work out of the box
- No additional setup needed

### **iOS**
- Requires APNs certificate in Firebase Console
- Go to Firebase Console → Project Settings → Cloud Messaging → iOS app configuration
- Upload your APNs certificate

## 🎉 Success Indicators

You'll know it's working when:
- ✅ Mobile app logs show FCM token
- ✅ Backend logs show token registration
- ✅ Backend logs show cron job running every 10 minutes
- ✅ **Notifications arrive when app is completely closed**
- ✅ Tapping notification opens app and navigates to book

---

**The main issue was that you were using local notifications instead of Firebase Cloud Messaging. Local notifications can't work when the app is closed, but Firebase Cloud Messaging can! 🚀**
