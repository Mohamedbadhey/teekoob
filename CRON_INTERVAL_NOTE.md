# ⏱️ Notification Cron Interval Changed

## 🎯 Change Made

**File:** `backend/src/routes/notifications.js`

**Before:**
```javascript
// Schedule random book notifications every 1 hour
cron.schedule('0 * * * *', async () => { ... });
```

**After:**
```javascript
// Schedule random book notifications every 1 minute (for testing)
cron.schedule('* * * * *', async () => { ... });
```

---

## 📊 Cron Schedule Explanation

### Current Setting: `'* * * * *'`
- **Runs:** Every 1 minute
- **Purpose:** Testing and immediate feedback
- **Example:** 10:00, 10:01, 10:02, 10:03...

### Cron Syntax
```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

---

## ⚠️ Important Notes

### For Testing (Current Setting)
- ✅ **Every 1 minute:** Great for testing
- ✅ Immediate feedback
- ✅ Easy to verify notifications work
- ⚠️ **Not recommended for production** (too frequent)

### For Production (Recommended)
Change back to one of these:

#### Every 10 Minutes:
```javascript
cron.schedule('*/10 * * * *', async () => { ... });
```

#### Every Hour:
```javascript
cron.schedule('0 * * * *', async () => { ... });
```

#### Every 3 Hours:
```javascript
cron.schedule('0 */3 * * *', async () => { ... });
```

#### Twice Daily (9 AM and 5 PM):
```javascript
cron.schedule('0 9,17 * * *', async () => { ... });
```

---

## 🧪 Testing with 1-Minute Interval

### What to Expect:

1. **Start Backend:**
```bash
cd backend
npm start
```

2. **Check Logs Every Minute:**
```
🔔 Running scheduled random book notification...
🔔 Found X users with notifications enabled
🔔 Selected random book: [Book Title]
🔔 ✅ SUCCESS: Random book notification sent
```

3. **Mobile Device:**
- Will receive notification every minute (if notifications enabled)
- Even when app is closed
- Can be overwhelming for testing!

---

## 📱 How to Test

1. **Login to mobile app**
2. **Enable notifications** in Settings
3. **Close the app completely**
4. **Wait 1 minute**
5. **Check for notification** ✅

---

## 🔄 To Change Back for Production

Edit `backend/src/routes/notifications.js` line 54:

```javascript
// For every 10 minutes:
cron.schedule('*/10 * * * *', async () => {

// For every hour:
cron.schedule('0 * * * *', async () => {

// For every 3 hours:
cron.schedule('0 */3 * * *', async () => {
```

Then restart the backend:
```bash
# If using Railway, it will redeploy automatically on git push
# If running locally:
npm start
```

---

## ⚡ Quick Reference

| Interval | Cron Expression | Use Case |
|----------|----------------|----------|
| Every minute | `* * * * *` | Testing only |
| Every 5 minutes | `*/5 * * * *` | Aggressive testing |
| Every 10 minutes | `*/10 * * * *` | Development |
| Every 30 minutes | `*/30 * * * *` | Moderate production |
| Every hour | `0 * * * *` | Production (balanced) |
| Every 3 hours | `0 */3 * * *` | Production (conservative) |
| Daily at 9 AM | `0 9 * * *` | Production (daily digest) |

---

## 🎯 Recommended Production Setting

For a book recommendation app:

**Every 3-6 hours** is ideal:
```javascript
// Every 3 hours
cron.schedule('0 */3 * * *', async () => { ... });

// Or every 6 hours (4 times per day)
cron.schedule('0 */6 * * *', async () => { ... });
```

This provides:
- ✅ Regular engagement without being annoying
- ✅ 4-8 notifications per day per user
- ✅ Better user experience
- ✅ Lower server load

---

**Current Status:** ⏱️ Running every 1 minute for testing  
**Action Required:** Change to production interval before deploying  
**File to Edit:** `backend/src/routes/notifications.js` line 54

