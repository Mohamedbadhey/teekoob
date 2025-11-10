# 🔐 Password Reset Flow Analysis

## Overview
The Teekoob platform uses a **6-digit verification code** system for password reset. This document explains the complete flow, when codes are sent, and how they're validated.

---

## 📋 Password Reset Flow

### **Step 1: User Requests Password Reset**
**Endpoint:** `POST /api/v1/auth/forgot-password`

**When Code is Sent:**
- ✅ Code is **immediately generated** when user requests password reset
- ✅ Code is **stored in database** before email is sent
- ✅ Email is sent **asynchronously** (code generation doesn't wait for email success)

**Code Generation:**
```javascript
// Location: backend/src/routes/auth.js (line 403)
const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
// Generates a random 6-digit code (100000-999999)
```

**Code Storage:**
```javascript
// Stored in users table:
reset_password_code: resetCode (6-digit string)
reset_password_code_expires_at: codeExpires (timestamp)
```

**Expiry Time:**
- Default: **10 minutes** (configurable via `RESET_CODE_EXPIRY_MINUTES` env variable)
- Calculated: `Date.now() + expiryMinutes * 60 * 1000`

**Email Sending:**
- Uses **Resend** email service (if `RESEND_API_KEY` is configured)
- If email fails, code is **still valid** and stored in database
- In development mode, code is **logged to console** for testing

---

### **Step 2: User Verifies Code**
**Endpoint:** `POST /api/v1/auth/verify-reset-code`

**Validation:**
- Checks if code matches user's email
- Checks if code hasn't expired (`reset_password_code_expires_at > now()`)
- Code must be exactly 6 digits

**Response:**
- ✅ `200 OK` if code is valid
- ❌ `400 Bad Request` if code is invalid or expired

---

### **Step 3: User Resets Password**
**Endpoint:** `POST /api/v1/auth/reset-password`

**Requirements:**
- Valid email
- Valid 6-digit code (not expired)
- New password (minimum 6 characters)

**Process:**
1. Verifies code again (same validation as step 2)
2. Hashes new password with bcrypt (12 rounds)
3. Updates user's password
4. **Clears reset code** from database (`reset_password_code = null`)
5. **Auto-logs in user** by returning JWT token

**Security:**
- Code is **single-use** (cleared after successful reset)
- Code **expires** after configured time (default 10 minutes)
- Old password is **not required** (code serves as authentication)

---

## 🔄 Code Generation Details

### **When Codes Are Generated:**
1. ✅ **Immediately** when `/forgot-password` endpoint is called
2. ✅ **Before** email is sent (code is stored first)
3. ✅ **Even if** email service is not configured
4. ✅ **Even if** email sending fails

### **Code Format:**
- **Type:** String (6 digits)
- **Range:** 100000 to 999999
- **Generation:** `Math.floor(100000 + Math.random() * 900000)`

### **Code Storage:**
- **Table:** `users`
- **Fields:**
  - `reset_password_code` (VARCHAR(6), nullable)
  - `reset_password_code_expires_at` (TIMESTAMP, nullable)

### **Code Expiry:**
- **Default:** 10 minutes
- **Configurable:** `RESET_CODE_EXPIRY_MINUTES` environment variable
- **Calculation:** `new Date(Date.now() + expiryMinutes * 60 * 1000)`

---

## 📧 Email Sending

### **Email Service:**
- **Provider:** Resend (via `resend` npm package)
- **Configuration:** Requires `RESEND_API_KEY` environment variable
- **From Address:** `RESEND_FROM` or `EMAIL_FROM` (defaults to `onboarding@resend.dev`)

### **Email Content:**
- **Subject:** "Password Reset Code - {AppName}"
- **Format:** HTML email with styled code display
- **Code Display:** Large, highlighted 6-digit code
- **Expiry Notice:** Shows expiry time (e.g., "expires in 10 minutes")

### **Email Failure Handling:**
- If email fails to send, code is **still generated and stored**
- In development mode (`NODE_ENV=development`), code is **logged to console**
- If `LOG_RESET_CODES=true`, code is included in API response (for testing)
- User still receives success message (security: doesn't reveal if email exists)

---

## 🔒 Security Features

### **Code Validation:**
1. ✅ Code must match exactly (case-sensitive)
2. ✅ Code must not be expired
3. ✅ Code must belong to the email address
4. ✅ Code format validation (6 digits only)

### **Code Expiry:**
- Codes expire after configured time (default 10 minutes)
- Expired codes cannot be used
- New code can be requested (replaces old code)

### **Single-Use Codes:**
- Code is **cleared** after successful password reset
- Cannot reuse the same code twice
- Each password reset requires a new code

### **Rate Limiting:**
- Express rate limiter applies to all endpoints
- Prevents brute force attacks
- Limits: 100 requests per 15 minutes per IP

---

## 📱 Mobile App Flow

### **Step 1: Forgot Password**
1. User enters email on login page
2. Taps "Forgot Password?"
3. App calls `POST /auth/forgot-password`
4. Navigates to verification code page

### **Step 2: Verify Code**
1. User enters 6-digit code (auto-advances between fields)
2. Code is verified automatically when all 6 digits are entered
3. App calls `POST /auth/verify-reset-code`
4. On success, navigates to reset password page

### **Step 3: Reset Password**
1. User enters new password and confirmation
2. App calls `POST /auth/reset-password`
3. On success, user is **auto-logged in** with returned JWT token
4. Navigates to home page

### **Resend Code:**
- User can tap "Resend Code" button
- Calls `/forgot-password` again
- **Generates new code** (replaces old one)
- Sends new email

---

## 🐛 Development & Testing

### **Development Mode:**
- Code is **logged to console** when generated
- Code is **included in API response** if `LOG_RESET_CODES=true`
- Email failures don't block code generation

### **Console Output (Development):**
```
⚠️ ============================================
⚠️ PASSWORD RESET CODE GENERATED
⚠️ Email: user@example.com
⚠️ Code: 123456
⚠️ Expires at: 2024-01-01T12:10:00.000Z
⚠️ ============================================
```

### **Test Endpoints:**
- `GET /api/v1/auth/test-email-config` - Check email configuration
- `POST /api/v1/auth/test-send-email` - Test email sending

---

## ⚙️ Configuration

### **Environment Variables:**

```env
# Email Service
RESEND_API_KEY=your_resend_api_key
RESEND_FROM=noreply@yourdomain.com
EMAIL_FROM=noreply@yourdomain.com  # Fallback

# Code Expiry (in minutes)
RESET_CODE_EXPIRY_MINUTES=10

# Development/Testing
LOG_RESET_CODES=true  # Include code in API response (for testing)
NODE_ENV=development  # Log codes to console
```

---

## 🔍 Database Schema

### **Users Table Fields:**
```sql
reset_password_code VARCHAR(6) NULL
reset_password_code_expires_at TIMESTAMP NULL
```

### **Migration:**
- Migration file: `018_add_reset_code_fields.js`
- Adds both fields to `users` table
- Fields are nullable (only set during password reset flow)

---

## 📊 Flow Diagram

```
User Request
    ↓
POST /forgot-password
    ↓
Generate 6-digit code
    ↓
Store code in database (with expiry)
    ↓
Send email with code (async)
    ↓
[User receives email]
    ↓
POST /verify-reset-code
    ↓
Validate code (format, expiry, match)
    ↓
[Code verified]
    ↓
POST /reset-password
    ↓
Verify code again
    ↓
Hash new password
    ↓
Update password
    ↓
Clear reset code
    ↓
Return JWT token (auto-login)
```

---

## ⚠️ Important Notes

1. **Code Generation is Immediate:** Code is generated and stored **before** email is sent
2. **Email Failure Doesn't Block:** If email fails, code is still valid (check console/logs in dev)
3. **Single Use:** Each code can only be used once
4. **Expiry:** Codes expire after configured time (default 10 minutes)
5. **Auto-Login:** After successful reset, user is automatically logged in
6. **Security:** Code is cleared from database after successful password reset

---

## 🐛 Common Issues

### **Issue: Code not received in email**
- **Check:** Email service configuration (`RESEND_API_KEY`)
- **Solution:** Check console logs for code (development mode)
- **Note:** Code is still generated even if email fails

### **Issue: Code expired**
- **Check:** `RESET_CODE_EXPIRY_MINUTES` setting
- **Solution:** Request new code (old one is replaced)

### **Issue: Invalid code error**
- **Check:** Code format (must be exactly 6 digits)
- **Check:** Code hasn't expired
- **Check:** Code matches the email address

---

## ✅ Summary

**When codes are sent:**
- ✅ Immediately when `/forgot-password` is called
- ✅ Before email is sent (code stored first)
- ✅ Even if email service fails
- ✅ New code replaces old one on resend

**Code characteristics:**
- 6-digit numeric code (100000-999999)
- Expires in 10 minutes (configurable)
- Single-use (cleared after reset)
- Stored in database with expiry timestamp

**Security:**
- Code validation (format, expiry, match)
- Rate limiting on endpoints
- Auto-clear after use
- Secure password hashing (bcrypt)

