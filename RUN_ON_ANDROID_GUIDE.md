# 📱 Running Teekoob on Android - Quick Guide

## ⚠️ Why Not Web?

Push notifications **don't work properly on web browsers** - they use a completely different mechanism. The `firebase_messaging_web` package also has compatibility issues with the current Flutter version.

**Solution:** Run on Android or iOS for testing notifications! ✅

---

## 🚀 Quick Start - Run on Android

### Option 1: Physical Android Device (Recommended)

1. **Enable Developer Mode on your phone:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - You'll see "You are now a developer!"

2. **Enable USB Debugging:**
   - Go to Settings → Developer Options
   - Turn on "USB Debugging"

3. **Connect phone to computer via USB**

4. **Run the app:**
```bash
cd mobile
flutter devices  # Should show your device
flutter run      # Will automatically deploy to connected device
```

---

### Option 2: Android Emulator

1. **Open Android Studio**

2. **Open Device Manager:**
   - Tools → Device Manager (or AVD Manager)

3. **Create/Start an emulator:**
   - Click "Create Device" if you don't have one
   - Choose a device (e.g., Pixel 5)
   - Choose system image (Android 11+ recommended)
   - Click "Finish" and start the emulator

4. **Run the app:**
```bash
cd mobile
flutter devices  # Should show emulator
flutter run
```

---

## 📋 Step-by-Step Testing

### 1. Check Connected Devices
```bash
cd C:\Users\hp\Documents\teekoob\mobile
flutter devices
```

**Expected output:**
```
4 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 11 (API 30)
Chrome (web)                 • chrome        • web-javascript • Google Chrome 120.0.0.0
Windows (desktop)            • windows       • windows-x64    • Microsoft Windows 10
Edge (web)                   • edge          • web-javascript • Microsoft Edge 120.0.0.0
```

### 2. Run on Android
```bash
# If you have one Android device/emulator:
flutter run

# If you have multiple devices, specify which one:
flutter run -d emulator-5554   # For emulator
flutter run -d DEVICE_ID        # For physical device
```

### 3. Watch for Firebase Initialization
In your terminal, look for:
```
🔔 Initializing Firebase Notification Service...
🔔 ✅ Firebase Core initialized
🔔 ✅ FCM Token obtained: eAbcd1234567890...
🔔 ✅ Local notifications initialized
🔔 ✅ Firebase Notification Service initialized successfully
```

### 4. Login to App

After login, check for:
```
🔔 FCM Token: eAbcd1234567890...
🔔 ✅ FCM token registered with backend
🔔 ✅ Random book notifications enabled
```

### 5. Test Notifications

**In the app:**
1. Go to Settings → Notification Settings
2. Tap "Test Random Book Notification"
3. **Should see notification appear!** ✅

### 6. Test Background Notifications

1. **Close the app completely** (swipe away from recent apps)
2. **Wait 1 minute** (you changed cron to 1 minute)
3. **Notification should appear even though app is closed!** 🎉

---

## 🐛 Troubleshooting

### Issue: "No devices found"

**For Physical Device:**
```bash
# Check if device is detected
adb devices

# If shows "unauthorized":
# - On your phone, approve the USB debugging popup
# - Run again
```

**For Emulator:**
- Make sure Android Studio's Device Manager shows emulator as running
- Try: `flutter doctor` to check for issues

---

### Issue: "Gradle build failed"

```bash
cd mobile/android
./gradlew clean

cd ../..
flutter clean
flutter pub get
flutter run
```

---

### Issue: "Google Play Services not available"

**Solution:** Use an emulator image with Google Play:
- In Android Studio Device Manager
- When creating emulator, choose system image with the "Play Store" icon
- Not "AOSP" images

---

## ✅ Success Checklist

After running on Android:

- [ ] App launches successfully
- [ ] Firebase initializes (check logs)
- [ ] FCM token is generated
- [ ] Can login successfully
- [ ] Token is sent to backend
- [ ] Test notification works
- [ ] **Close app completely**
- [ ] **Wait 1 minute**
- [ ] **Notification appears!** 🎉

---

## 🎯 Expected Results on Android

### Logs in Terminal:
```
I/flutter (12345): 🔔 Initializing Firebase Notification Service...
I/flutter (12345): 🔔 ✅ Firebase Core initialized
I/flutter (12345): 🔔 Notification permissions: AuthorizationStatus.authorized
I/flutter (12345): 🔔 ✅ FCM Token obtained: eAbcd1234567890...
I/flutter (12345): 🔔 ✅ Local notifications initialized
I/flutter (12345): 🔔 ✅ Firebase Notification Service initialized successfully
```

### After Login:
```
I/flutter (12345): 🔔 ✅ FCM token registered with backend
I/flutter (12345): 🔔 ✅ Random book notifications enabled
```

### After Test Notification:
```
I/flutter (12345): 🔔 Foreground message received: Test Book Alert!
```

### Backend Logs (Every 1 Minute):
```
🔔 Running scheduled random book notification...
🔔 Found 1 users with notifications enabled
🔔 Selected random book: [Book Title] (ID: [id])
🔔 📤 SENDING ENHANCED FIREBASE MESSAGE...
🔔 ✅ SUCCESS: Random book notification sent
```

---

## 🎉 What You Should See

### On Your Device:

1. **Notification in system tray** with:
   - Book emoji 📚
   - "Featured Book Alert!" (or Somali equivalent)
   - Book title
   - Author name
   - Book description

2. **Even when app is closed:**
   - Every 1 minute, a new notification
   - Proves background notifications work!

3. **Tap notification:**
   - App opens
   - Ready for navigation to book (if implemented)

---

## 📝 Quick Command Reference

```bash
# Check devices
flutter devices

# Run on Android
flutter run

# Run on specific device
flutter run -d emulator-5554

# Clean build
flutter clean

# Check setup
flutter doctor

# View logs
flutter logs

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart (while app is running)
# Press 'R' in terminal
```

---

## 🚫 Do NOT Use Web for Notification Testing

Web browsers have:
- ❌ Different notification API
- ❌ Compatibility issues with firebase_messaging_web
- ❌ Different permission model
- ❌ No background push notifications like mobile

**Always test notifications on Android/iOS!**

---

**Ready to test?** Just run:

```bash
cd C:\Users\hp\Documents\teekoob\mobile
flutter run
```

The app will deploy to your connected Android device/emulator and notifications will work! 🎉

