# 🧪 Firebase Notifications - Complete Testing Guide

## 📋 Pre-Testing Checklist

### Environment Setup
- [ ] Flutter SDK installed (3.10.0+)
- [ ] Android Studio / Xcode configured
- [ ] Real device or emulator with Google Play Services
- [ ] Backend server running (Railway or local)
- [ ] Database tables created

### Files Verification
```bash
# Verify all critical files exist:
ls mobile/pubspec.yaml                                    # ✅ Must exist
ls mobile/android/app/google-services.json                # ✅ Must exist
ls mobile/lib/core/services/firebase_notification_service_io.dart  # ✅ Must exist
ls backend/firebase-service-account.json                  # ✅ Must exist
```

---

## 🚀 Step-by-Step Testing

### Phase 1: Build & Deploy

#### Step 1.1: Install Mobile Dependencies
```bash
cd mobile
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in mobile...
Resolving dependencies...
+ firebase_messaging 14.7.10
Got dependencies!
```

#### Step 1.2: Clean Build
```bash
flutter clean
```

#### Step 1.3: Build for Android
```bash
# Debug build
flutter build apk --debug

# OR run directly
flutter run
```

**Expected Output:**
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

**⚠️ If build fails:**
- Check error messages for missing dependencies
- Verify `google-services.json` is in correct location
- Run `cd android && ./gradlew clean`

---

### Phase 2: Mobile App Testing

#### Test 2.1: Firebase Initialization

**Action:** Launch the app

**Check Logs For:**
```
🔔 Initializing Firebase Notification Service...
🔔 ✅ Firebase Core initialized
🔔 Notification permissions: AuthorizationStatus.authorized
🔔 ✅ FCM Token obtained: [first 20 chars]...
🔔 ✅ Local notifications initialized
🔔 ✅ Firebase Notification Service initialized successfully
```

**✅ Pass Criteria:** All Firebase initialization logs appear
**❌ Fail:** Missing logs or error messages

---

#### Test 2.2: User Login & Token Registration

**Action:** Login with a user account

**Check Logs For:**
```
🔔 FCM Token: eAbcd1234567890...
🔔 ✅ FCM token registered with backend
🔔 ✅ Random book notifications enabled
```

**Backend Logs Should Show:**
```
🔔 FCM token registered for user [user_id]
```

**Database Verification:**
```sql
-- Check token was stored
SELECT * FROM user_fcm_tokens WHERE user_id = [your_user_id];

-- Should return:
-- | user_id | fcm_token | platform | enabled | created_at |
-- |---------|-----------|----------|---------|------------|
-- | 1       | eAbcd...  | mobile   | 1       | 2025-11-08 |
```

**✅ Pass Criteria:** Token appears in database
**❌ Fail:** No token in database

---

#### Test 2.3: Notification Permissions

**Action:** 
1. Go to Settings → Notification Settings
2. Check permission status

**Expected:** 
- Notifications toggle is available
- Permission status shows "Enabled" or "Granted"

**✅ Pass Criteria:** Can enable/disable notifications
**❌ Fail:** Permission denied or toggle not working

---

#### Test 2.4: Test Notification (Foreground)

**Action:** 
1. Keep app open (foreground)
2. Go to Settings → Notification Settings
3. Tap "Test Random Book Notification"

**Expected:**
1. Local notification appears at top of screen
2. Shows book title and author
3. Notification is tappable

**Check Logs:**
```
🔔 ✅ Test notification sent
🔔 Foreground message received: [title]
```

**✅ Pass Criteria:** Notification appears in foreground
**❌ Fail:** No notification appears

---

#### Test 2.5: Test Notification (Background)

**Action:**
1. Send test notification from settings
2. **Immediately press Home button** (don't swipe app away)
3. Wait 5 seconds

**Expected:**
- Notification appears in system notification tray
- Shows book emoji 📚
- Title and author visible
- Notification can be expanded

**✅ Pass Criteria:** Notification appears in notification tray
**❌ Fail:** No notification in tray

---

#### Test 2.6: Test Notification (App Closed)

**Action:**
1. **Close app completely** (swipe away from recent apps)
2. Use backend API or Firebase Console to send test notification
3. Wait for notification

**Backend Test Endpoint:**
```bash
curl -X POST https://teekoob-production.up.railway.app/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected:**
- Notification appears even though app is closed
- System shows notification
- App is NOT running in background

**✅ Pass Criteria:** Notification received when app fully closed
**❌ Fail:** No notification when app closed

---

#### Test 2.7: Notification Tap Action

**Action:**
1. Receive a notification (from any test above)
2. Tap the notification

**Expected:**
- App opens (if closed)
- App comes to foreground (if background)
- Navigation to book details (if implemented)

**Check Logs:**
```
🔔 Notification tapped (background): [title]
🔔 onMessageOpenedApp: {bookId: 123, ...}
```

**✅ Pass Criteria:** App opens when notification is tapped
**❌ Fail:** Nothing happens on tap

---

### Phase 3: Backend Testing

#### Test 3.1: Backend Startup

**Action:** Start the backend server

```bash
cd backend
npm start
```

**Check Logs For:**
```
🔔 Initializing Firebase with environment variables...
🔔 ✅ Firebase initialized with environment variables
✅ Notification routes registered
```

**✅ Pass Criteria:** Firebase initializes without errors
**❌ Fail:** Firebase initialization errors

---

#### Test 3.2: Token Registration Endpoint

**Action:** Test token registration endpoint

```bash
curl -X POST https://teekoob-production.up.railway.app/api/v1/notifications/register-token \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "test_token_123",
    "platform": "mobile",
    "enabled": true
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "FCM token registered successfully"
}
```

**✅ Pass Criteria:** 200 status, success message
**❌ Fail:** 401/500 error

---

#### Test 3.3: Cron Job

**Action:** Wait for cron job to run (every 10 minutes)

**Backend Logs Should Show:**
```
🔔 ===== RANDOM BOOK NOTIFICATION PROCESS START =====
🔔 Starting random book notification process...
🔔 🧹 AUTO-CLEANUP: Deleted X fake FCM tokens
🔔 🔍 DEBUG: Database counts - Users: X, FCM Tokens: X, Preferences: X
🔔 Found X users with notifications enabled
🔔 Selected random book: [Book Title] (ID: [id])
🔔 📤 SENDING ENHANCED FIREBASE MESSAGE...
🔔 📤 To: user@example.com
🔔 📤 Token: eAbcd1234567890...
🔔 📤 Title: "📚 Featured Book Alert!"
🔔 📤 Book: "[Book Title]" by "[Author]"
🔔 ✅ SUCCESS: Random book notification sent to user user@example.com
```

**Mobile App:**
- Notification appears on device
- Even if app is completely closed

**✅ Pass Criteria:** Cron runs every 10 minutes, sends notifications
**❌ Fail:** No cron logs or no notifications sent

---

#### Test 3.4: Manual Trigger

**Action:** Manually trigger notification job

```bash
curl -X POST https://teekoob-production.up.railway.app/api/v1/admin/trigger-random-book-notifications \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Expected:**
- Backend processes immediately
- Notifications sent to all enabled users
- Success response

**✅ Pass Criteria:** Notifications sent immediately
**❌ Fail:** 500 error or no notifications

---

### Phase 4: End-to-End Integration Test

#### Test 4.1: Complete User Journey

**Steps:**
1. **Fresh Install**
   - Uninstall app completely
   - Reinstall from build

2. **First Launch**
   - App opens
   - Firebase initializes
   - Check logs for initialization

3. **User Registration/Login**
   - Create account or login
   - FCM token generated
   - Token sent to backend
   - Verify token in database

4. **Enable Notifications**
   - Go to Settings → Notifications
   - Enable "Random Book Notifications"
   - Verify in database: `random_books_enabled = 1`

5. **Test Notification**
   - Send test notification
   - Verify receipt in foreground

6. **Close App**
   - Close app completely
   - Swipe away from recent apps
   - Verify app is not running

7. **Wait for Cron**
   - Wait up to 10 minutes
   - Notification should arrive
   - Even though app is closed

8. **Tap Notification**
   - Tap the notification
   - App should open
   - Verify navigation (if implemented)

**✅ Pass Criteria:** All steps succeed
**❌ Fail:** Any step fails

---

## 🐛 Troubleshooting Guide

### Issue: No FCM Token Generated

**Symptoms:**
- Logs show "FCM token: null"
- No token in database

**Possible Causes:**
1. Firebase not initialized
2. Google Play Services not available
3. Permissions not granted

**Solutions:**
```bash
# 1. Verify Firebase configuration
cat mobile/android/app/google-services.json

# 2. Check if running on device with Google Play Services
# Use real device or Google Play emulator

# 3. Request permissions
# Settings → Apps → Teekoob → Permissions → Notifications → Allow
```

---

### Issue: Build Fails

**Symptoms:**
```
FAILURE: Build failed with an exception.
```

**Solutions:**
```bash
# 1. Clean everything
cd mobile
flutter clean
cd android
./gradlew clean
cd ../..

# 2. Update dependencies
flutter pub get

# 3. Rebuild
flutter build apk --debug
```

---

### Issue: Backend Not Sending Notifications

**Symptoms:**
- Backend logs show success
- But no notification on device

**Debug Steps:**

1. **Check FCM Token:**
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE user_id = [id];
```

2. **Test Token with Firebase Console:**
   - Go to Firebase Console
   - Cloud Messaging → Send test message
   - Paste FCM token
   - Send

3. **Check Backend Logs:**
```bash
# Look for errors:
grep "ERROR" backend/logs/combined.log
grep "❌" backend/logs/combined.log
```

---

### Issue: Notifications Only Work in Foreground

**Symptoms:**
- Foreground notifications work
- Background/closed notifications don't

**Causes:**
- Background handler not registered
- Battery optimization enabled (Android)

**Solutions:**

1. **Disable Battery Optimization:**
   - Settings → Apps → Teekoob
   - Battery → Unrestricted

2. **Check Background Handler:**
```dart
// In firebase_notification_service_io.dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 📊 Success Criteria Summary

| Test | Criteria | Status |
|------|----------|--------|
| Firebase Init | ✅ Initializes on app start | ⬜ |
| FCM Token | ✅ Generated and stored | ⬜ |
| Token Registration | ✅ Sent to backend | ⬜ |
| Database Storage | ✅ Token in `user_fcm_tokens` | ⬜ |
| Foreground Notification | ✅ Appears when app open | ⬜ |
| Background Notification | ✅ Appears when app in background | ⬜ |
| Closed Notification | ✅ Appears when app closed | ⬜ |
| Tap Action | ✅ Opens app | ⬜ |
| Backend Cron | ✅ Runs every 10 minutes | ⬜ |
| End-to-End | ✅ Complete flow works | ⬜ |

---

## 📝 Test Report Template

```
# Firebase Notifications Test Report

**Date:** [Date]
**Tester:** [Name]
**Environment:** [Android/iOS] [Version]
**Build:** [Debug/Release]

## Mobile Tests
- [ ] Firebase Initialization: [PASS/FAIL]
- [ ] FCM Token Generation: [PASS/FAIL]
- [ ] Token Registration: [PASS/FAIL]
- [ ] Foreground Notifications: [PASS/FAIL]
- [ ] Background Notifications: [PASS/FAIL]
- [ ] Closed App Notifications: [PASS/FAIL]
- [ ] Notification Tap: [PASS/FAIL]

## Backend Tests
- [ ] Firebase Init: [PASS/FAIL]
- [ ] Token Registration API: [PASS/FAIL]
- [ ] Cron Job: [PASS/FAIL]
- [ ] Manual Trigger: [PASS/FAIL]

## Issues Found
1. [Issue description]
2. [Issue description]

## Overall Status
[ ] All tests passed - Ready for production
[ ] Some tests failed - Needs fixes
[ ] Critical failures - Not ready

## Notes
[Additional notes]
```

---

**Testing Duration:** ~2-3 hours for complete testing
**Required:** Real device or emulator with Google Play Services
**Backend:** Must be running and accessible

