# 🔧 Firebase Notification Fix - Complete Implementation Guide

## ✅ What Was Fixed

### 1. **Enabled firebase_messaging Package** ✅
- **File:** `mobile/pubspec.yaml` (line 108)
- **Change:** Uncommented `firebase_messaging: ^14.7.10`
- **Impact:** App can now receive push notifications

### 2. **Added Firebase Google Services Plugin** ✅
- **File:** `mobile/android/app/build.gradle.kts`
- **Change:** Added `id("com.google.gms.google-services")`
- **Impact:** Firebase services can initialize on Android

### 3. **Added Firebase Classpath** ✅
- **File:** `mobile/android/build.gradle.kts`
- **Change:** Added `classpath("com.google.gms:google-services:4.4.0")`
- **Impact:** Enables Firebase Google Services plugin

### 4. **Replaced Stub Firebase Notification Service** ✅
- **File:** `mobile/lib/core/services/firebase_notification_service_io.dart`
- **Change:** Implemented full Firebase Cloud Messaging functionality
- **Features:**
  - ✅ FCM token generation and storage
  - ✅ Background message handling
  - ✅ Foreground message handling
  - ✅ Notification tap handling
  - ✅ Token refresh handling
  - ✅ Backend token registration
  - ✅ Local notification display

### 5. **Updated Auth Service** ✅
- **File:** `mobile/lib/features/auth/services/auth_service.dart`
- **Change:** Added proper FCM token registration on login
- **Impact:** Tokens are sent to backend immediately after login

---

## 🚀 How to Test

### Step 1: Install Dependencies

```bash
cd mobile
flutter pub get
```

### Step 2: Clean and Rebuild

```bash
# Clean build artifacts
flutter clean

# For Android
flutter build apk --debug

# Or run directly
flutter run
```

### Step 3: Check Logs for FCM Token

After running the app, check the logs for:

```
🔔 Initializing Firebase Notification Service...
🔔 ✅ Firebase Core initialized
🔔 Notification permissions: AuthorizationStatus.authorized
🔔 ✅ FCM Token obtained: [first 20 chars]...
🔔 ✅ Local notifications initialized
🔔 ✅ Firebase Notification Service initialized successfully
```

### Step 4: Login to the App

When you log in, you should see:

```
🔔 ⚠️ No auth token, skipping backend registration
🔔 ✅ FCM token registered with backend
🔔 ✅ Random book notifications enabled
```

### Step 5: Check Backend

Check backend logs for:

```
🔔 FCM token registered for user [user_id]
```

### Step 6: Test Notification

1. Go to Settings → Notification Settings in the app
2. Click "Test Random Book Notification"
3. Close the app completely (swipe away from recent apps)
4. You should receive a notification within a few seconds

### Step 7: Test Automatic Notifications

1. Keep notifications enabled in app settings
2. Close the app completely
3. Wait 10 minutes
4. You should receive an automatic random book notification

---

## 🔍 Verification Checklist

### Mobile App
- [ ] App compiles without errors
- [ ] Firebase initializes successfully (check logs)
- [ ] FCM token is generated (check logs)
- [ ] Token is sent to backend on login (check logs)
- [ ] User can enable/disable notifications in settings
- [ ] Test notification works
- [ ] Notification appears when app is closed
- [ ] Tapping notification opens the app

### Backend
- [ ] Backend receives FCM token (check logs)
- [ ] Token is stored in `user_fcm_tokens` table
- [ ] Cron job runs every 10 minutes
- [ ] Notifications are sent to users with enabled notifications
- [ ] Firebase Cloud Messaging sends successfully

### Database
- [ ] Check `user_fcm_tokens` table has tokens:
  ```sql
  SELECT * FROM user_fcm_tokens;
  ```
- [ ] Check `notification_preferences` table:
  ```sql
  SELECT * FROM notification_preferences;
  ```

---

## 🐛 Troubleshooting

### Issue: "Firebase initialization failed"

**Possible Causes:**
- Missing `google-services.json` file
- Invalid Firebase configuration

**Solution:**
```bash
# Verify google-services.json exists
ls mobile/android/app/google-services.json

# Re-download from Firebase Console if needed
```

### Issue: "FCM token is null"

**Possible Causes:**
- Firebase not initialized
- Permissions not granted
- Device/emulator doesn't support Google Play Services

**Solution:**
- Check if running on a real device or emulator with Google Play Services
- Request permissions again
- Restart the app

### Issue: "Token not sent to backend"

**Possible Causes:**
- User not logged in
- Backend API not reachable
- Auth token expired

**Solution:**
```bash
# Check backend is running
curl https://teekoob-production.up.railway.app/health

# Check auth token is stored
# In app debug logs, look for:
🔔 ⚠️ No auth token, skipping backend registration
```

### Issue: "Notifications not appearing"

**Possible Causes:**
- Notifications disabled in system settings
- App in battery optimization (Android)
- Invalid FCM token

**Solution:**
1. Check system notification settings:
   - Android: Settings → Apps → Teekoob → Notifications
   - iOS: Settings → Notifications → Teekoob

2. Disable battery optimization (Android):
   - Settings → Battery → Battery optimization → Teekoob → Don't optimize

3. Check backend logs for sending errors

### Issue: "Cron job not running"

**Possible Causes:**
- Backend not running
- No users with notifications enabled
- Database connection issue

**Solution:**
```bash
# Check backend logs
# You should see every 10 minutes:
🔔 Running scheduled random book notification...

# Manually trigger notifications
curl -X POST https://teekoob-production.up.railway.app/api/v1/admin/trigger-random-book-notifications \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## 📊 Expected Behavior

### When User Logs In:
1. Firebase initializes (if not already)
2. FCM token is generated
3. Token is sent to backend via `/api/v1/notifications/register-token`
4. Backend stores token in `user_fcm_tokens` table
5. Random book notifications are enabled by default

### Every 10 Minutes (Backend Cron):
1. Backend queries users with notifications enabled
2. Selects a random featured/new/high-rated book
3. Sends notification via Firebase Cloud Messaging
4. Notification appears on user's device (even if app is closed)

### When Notification is Tapped:
1. App opens
2. `onMessageOpenedApp` stream emits notification data
3. App can navigate to the book (if implemented)

### When App is in Foreground:
1. Firebase message is received
2. Local notification is shown
3. `onMessage` stream emits notification data

---

## 🎯 Success Metrics

You'll know everything is working when:

1. ✅ Mobile app shows: `🔔 ✅ Firebase Notification Service initialized successfully`
2. ✅ After login: `🔔 ✅ FCM token registered with backend`
3. ✅ Backend shows: `🔔 FCM token registered for user [id]`
4. ✅ Every 10 minutes: Backend logs show notification sending
5. ✅ Notification appears when app is completely closed
6. ✅ Tapping notification opens the app
7. ✅ Database has FCM tokens stored

---

## 📝 Files Modified

1. `mobile/pubspec.yaml` - Enabled firebase_messaging
2. `mobile/android/app/build.gradle.kts` - Added Firebase plugin
3. `mobile/android/build.gradle.kts` - Added Firebase classpath
4. `mobile/lib/core/services/firebase_notification_service_io.dart` - Full implementation
5. `mobile/lib/features/auth/services/auth_service.dart` - Added token registration

---

## 🔐 Security Notes

- FCM tokens are stored securely using `flutter_secure_storage`
- Auth tokens are required for backend API calls
- Tokens are refreshed automatically on expiration
- Backend validates all notification requests

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

---

**Status:** ✅ Ready to test
**Date:** November 8, 2025
**Next Steps:** Run `flutter pub get` and rebuild the app

