# Using Your Existing Google Project for Firebase Cloud Messaging

## Your Project Details
- **Project ID**: `4861039733`
- **Web Client ID**: `4861039733-db4ode2aiqps85n3t116i4eabvjrnur7.apps.googleusercontent.com`
- **Android Client ID**: `4861039733-11kdgmdpdi7anir3bpl14orven45hlhq.apps.googleusercontent.com`
- **iOS Client ID**: `4861039733-hmccm6ifr07kcbk2al0a22f85f57svf8.apps.googleusercontent.com`

## Step 1: Import Your Existing Project to Firebase

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Import existing project**:
   - Click "Add project"
   - Select "Import Google Cloud project"
   - Find and select your project `4861039733`
   - Click "Continue"
   - Click "Create project"

## Step 2: Enable Cloud Messaging

1. In Firebase Console, go to **"Cloud Messaging"** in the left sidebar
2. Click **"Get started"** to enable FCM
3. This will enable Firebase Cloud Messaging for your existing project

## Step 3: Add Apps to Firebase

### For Android:
1. In Firebase Console, click **"Add app"** → **Android**
2. **Package name**: `com.example.mobile` (or your actual package name)
3. **App nickname**: `Teekoob Mobile`
4. Click **"Register app"**
5. Download `google-services.json`
6. Place it in `mobile/android/app/google-services.json`

### For iOS:
1. In Firebase Console, click **"Add app"** → **iOS**
2. **Bundle ID**: `com.example.mobile` (or your actual bundle ID)
3. **App nickname**: `Teekoob iOS`
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Place it in `mobile/ios/Runner/GoogleService-Info.plist`

### For Web:
1. In Firebase Console, click **"Add app"** → **Web**
2. **App nickname**: `Teekoob Web`
3. Click **"Register app"**
4. Copy the Firebase configuration

## Step 4: Get Firebase Configuration

After adding your apps, go to **Project Settings** → **General** tab:

### For Web App:
- **API Key**: Copy the `apiKey` value
- **App ID**: Copy the `appId` value

### For Android App:
- **API Key**: Copy the `apiKey` value  
- **App ID**: Copy the `appId` value

### For iOS App:
- **API Key**: Copy the `apiKey` value
- **App ID**: Copy the `appId` value

## Step 5: Update Firebase Configuration

Replace the placeholder values in `mobile/lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY_HERE', // From Firebase Console → Web App
  appId: 'YOUR_WEB_APP_ID_HERE', // From Firebase Console → Web App
  messagingSenderId: '4861039733',
  projectId: '4861039733',
  authDomain: '4861039733.firebaseapp.com',
  storageBucket: '4861039733.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY_HERE', // From Firebase Console → Android App
  appId: 'YOUR_ANDROID_APP_ID_HERE', // From Firebase Console → Android App
  messagingSenderId: '4861039733',
  projectId: '4861039733',
  storageBucket: '4861039733.appspot.com',
);
```

## Step 6: Set Up Service Account for Backend

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project**: `4861039733`
3. **Go to IAM & Admin** → **Service Accounts**
4. **Create Service Account**:
   - Name: `firebase-messaging-service`
   - Description: `Service account for Firebase Cloud Messaging`
   - Click **"Create and Continue"**
5. **Grant roles**:
   - Add role: `Firebase Admin SDK Administrator Service Agent`
   - Click **"Continue"**
6. **Create key**:
   - Click on the service account
   - Go to **"Keys"** tab
   - Click **"Add Key"** → **"Create new key"**
   - Choose **JSON** format
   - Download the JSON file
7. **Add to backend**:
   - Rename the file to `firebase-service-account.json`
   - Place it in `backend/firebase-service-account.json`

## Step 7: Update Backend Environment

Add to your backend `.env` file:

```env
# Firebase Admin SDK
GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json
FIREBASE_PROJECT_ID=4861039733
```

## Step 8: Run Database Migrations

```bash
cd backend
npm run migrate
```

## Step 9: Test the Setup

1. **Build and run your mobile app**
2. **Sign in with Google** (using your existing Google Sign-In)
3. **Go to Settings** → **Notification Settings**
4. **Enable "Random Book Notifications"**
5. **Click "Test Random Book Notification"**

## Benefits of Using Your Existing Project

✅ **No new project needed** - Uses your existing Google Cloud project
✅ **Same authentication** - Works with your existing Google Sign-In
✅ **Same billing** - No additional costs
✅ **Same management** - All services in one place
✅ **Seamless integration** - FCM works with your existing OAuth setup

## Troubleshooting

### If you get "Project not found" errors:
- Make sure you imported the correct project (`4861039733`)
- Verify the project ID in Firebase Console matches your Google Cloud project

### If notifications don't work:
- Check that Cloud Messaging is enabled in Firebase Console
- Verify the service account has the correct permissions
- Check backend logs for FCM errors

The system is now configured to use your existing Google project for Firebase Cloud Messaging! 🎉
