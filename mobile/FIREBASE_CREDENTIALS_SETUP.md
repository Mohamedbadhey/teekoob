# 🔥 Firebase Service Account Setup Guide

## Step 1: Download Service Account Key

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `loginproject-e428a`
3. **Click the gear icon** (⚙️) → **Project Settings**
4. **Go to "Service Accounts" tab**
5. **Click "Generate new private key"**
6. **Click "Generate key"** in the confirmation dialog
7. **Download the JSON file** (it will be named something like `loginproject-e428a-firebase-adminsdk-xxxxx.json`)

## Step 2: Extract Credentials from JSON File

Open the downloaded JSON file and copy these values:

```json
{
  "type": "service_account",
  "project_id": "loginproject-e428a",
  "private_key_id": "COPY_THIS_VALUE",
  "private_key": "COPY_THIS_VALUE",
  "client_email": "firebase-adminsdk-xjo7a@loginproject-e428a.iam.gserviceaccount.com",
  "client_id": "111518350729660009698",
  ...
}
```

## Step 3: Update Backend Environment File

Create a `.env` file in the `backend` folder (copy from `env.example`) and update these values:

```env
# Firebase Configuration for loginproject-e428a
FIREBASE_PROJECT_ID=loginproject-e428a
FIREBASE_PRIVATE_KEY_ID=your-private-key-id-from-json-file
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour-actual-private-key-from-json-file\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xjo7a@loginproject-e428a.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=111518350729660009698
```

## Step 4: Test the Setup

1. **Start the backend server**:
   ```bash
   cd backend
   npm start
   ```

2. **Look for these logs**:
   ```
   🔥 Firebase Admin SDK initialized
   🔥 Random book notifications started - every 10 minutes
   ```

3. **Run the mobile app**:
   ```bash
   cd mobile
   flutter run
   ```

4. **Test notifications**:
   - Go to Settings → Notification Settings
   - Toggle "Random Book Notifications" ON
   - Tap "Test Random Book Notification"

## Step 5: Verify Background Notifications

1. **Close the app completely** (swipe away from recent apps)
2. **Wait 10 minutes** for the cron job to run
3. **Check if you receive a notification** with a random book

## Troubleshooting

### If notifications don't work:

1. **Check Firebase Console** → Cloud Messaging for delivery reports
2. **Check backend logs** for cron job execution
3. **Verify FCM token** registration in app logs
4. **Test with Firebase Console** → Cloud Messaging → Send test message

### Common Issues:

- **Wrong package name**: Make sure `com.example.mobile` matches your app
- **Missing permissions**: Check notification permissions in device settings
- **Invalid credentials**: Verify all Firebase environment variables are correct
- **Network issues**: Ensure device has internet connection

## Security Notes

- ⚠️ **Never commit** the `.env` file to version control
- ⚠️ **Keep service account keys** secure
- ⚠️ **Use environment variables** for sensitive data
- ⚠️ **Implement proper user authentication**

## Next Steps

Once everything is working:
1. Deploy to production
2. Monitor notification delivery
3. Add user preferences for notification timing
4. Implement notification analytics
