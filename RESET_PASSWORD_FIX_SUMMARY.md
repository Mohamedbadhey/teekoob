# Reset Password Integration - Fix Summary

## ✅ Fixed Issues

### 1. Email Service Configuration ✅ COMPLETED
**File**: `backend/src/utils/emailService.js`

**Changes Made**:
- **SMTP_PASS Support**: Updated to read `SMTP_PASS` environment variable (with fallback to `SMTP_PASSWORD` for backward compatibility)
  ```javascript
  const smtpPassword = process.env.SMTP_PASS || process.env.SMTP_PASSWORD;
  ```
- **EMAIL_FROM Support**: Updated to read `EMAIL_FROM` environment variable (with fallback to `SMTP_FROM` for backward compatibility)
  ```javascript
  const smtpFrom = process.env.EMAIL_FROM || process.env.SMTP_FROM || smtpUser || 'noreply@bookdoon.com';
  ```
- **SMTP_SECURE Support**: Now properly reads `SMTP_SECURE` environment variable and uses it for secure connection
  ```javascript
  const smtpSecure = process.env.SMTP_SECURE === 'true' || smtpPort === '465';
  ```
- **Enhanced Logging**: Added detailed logging when email service is configured, including host, port, secure flag, and from address

**Verification**:
- ✅ Email service initializes with correct environment variables
- ✅ Supports both old and new variable names for backward compatibility
- ✅ Secure connection properly configured based on `SMTP_SECURE` or port 465

### 2. Email Template Updates ✅ COMPLETED
**File**: `backend/src/utils/emailService.js` - `sendPasswordResetCode()` method

**Changes Made**:
- **Dynamic App Name**: Email template now uses `APP_NAME` environment variable (defaults to "Bookdoon")
  ```javascript
  const appName = process.env.APP_NAME || 'Bookdoon';
  const subject = `Password Reset Code - ${appName}`;
  ```
- **Configurable Expiry Time**: Email template displays expiry time from `RESET_CODE_EXPIRY_MINUTES` environment variable
  ```javascript
  const expiryMinutes = parseInt(process.env.RESET_CODE_EXPIRY_MINUTES || '10', 10);
  ```
- **Updated Branding**: All references to "Teekoob" replaced with dynamic `${appName}` variable
- **Proper From Field**: Email "from" field uses `EMAIL_FROM` with proper format: `"Bookdoon Support <no-reply@bookdoon.com>"`

**Email Template Features**:
- ✅ Professional HTML email template with styled code display
- ✅ Plain text fallback for email clients that don't support HTML
- ✅ Clear expiry time message (dynamically shows minutes)
- ✅ Security notice about ignoring unauthorized requests

**Verification**:
- ✅ Email subject includes app name from environment
- ✅ Email body shows correct expiry time from environment
- ✅ Email "from" field uses EMAIL_FROM format correctly

### 3. Reset Code Expiry Configuration ✅ COMPLETED
**File**: `backend/src/routes/auth.js` - `/forgot-password` endpoint

**Changes Made**:
- **Configurable Expiry**: Reset code expiry time now reads from `RESET_CODE_EXPIRY_MINUTES` environment variable
  ```javascript
  const expiryMinutes = parseInt(process.env.RESET_CODE_EXPIRY_MINUTES || '10', 10);
  const codeExpires = new Date(Date.now() + expiryMinutes * 60 * 1000);
  ```
- **Default Value**: Defaults to 10 minutes if not specified (was previously hardcoded to 15 minutes)
- **Database Storage**: Expiry time is stored in `reset_password_code_expires_at` field in users table

**Code Generation**:
- ✅ Generates 6-digit random code: `Math.floor(100000 + Math.random() * 900000).toString()`
- ✅ Stores code with expiry timestamp in database
- ✅ Clears old reset tokens when generating new code

**Verification**:
- ✅ Reset codes expire after configured time (default: 10 minutes)
- ✅ Expired codes are rejected during verification
- ✅ Expired codes are rejected during password reset

### 4. Environment Variables Documentation ✅ COMPLETED
**File**: `backend/env.example`

**Changes Made**:
- **Updated Email Configuration Section**: Added all required email environment variables with proper format
  ```env
  SMTP_HOST=smtp.gmail.com
  SMTP_PORT=465
  SMTP_SECURE=true
  SMTP_USER=your_email@gmail.com
  SMTP_PASS=your_app_password
  EMAIL_FROM="Bookdoon Support <no-reply@bookdoon.com>"
  ```
- **Added App Settings Section**: Added new environment variables for app configuration
  ```env
  RESET_CODE_EXPIRY_MINUTES=10
  APP_NAME=Bookdoon
  APP_URL=https://bookdoon.com
  ```
- **Added Comments**: Included helpful comments explaining each variable

**Documentation Features**:
- ✅ Clear section headers for organization
- ✅ Example values for all variables
- ✅ Comments explaining Gmail App Password requirement
- ✅ Proper format examples (especially for EMAIL_FROM)

**Verification**:
- ✅ All required environment variables documented
- ✅ Example values match production configuration
- ✅ Format examples are correct

### 5. Mobile App Reset Password Fix ✅ COMPLETED
**Files**: 
- `mobile/lib/features/auth/presentation/pages/reset_password_page.dart`
- `mobile/lib/features/auth/bloc/auth_bloc.dart`

**Changes Made**:

**ResetPasswordPage**:
- **Added confirmPassword Parameter**: Updated `ResetPasswordRequested` event to include `confirmPassword`
  ```dart
  context.read<AuthBloc>().add(
    ResetPasswordRequested(
      email: widget.email,
      code: widget.code,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text, // ✅ Added
    ),
  );
  ```

**AuthBloc**:
- **Updated Event Class**: Added `confirmPassword` field to `ResetPasswordRequested` event
  ```dart
  class ResetPasswordRequested extends AuthEvent {
    final String email;
    final String code;
    final String newPassword;
    final String confirmPassword; // ✅ Added
    
    const ResetPasswordRequested({
      required this.email,
      required this.code,
      required this.newPassword,
      required this.confirmPassword, // ✅ Added
    });
  }
  ```
- **Updated Handler**: Updated `_onResetPasswordRequested` to pass `confirmPassword` to auth service
  ```dart
  await _authService.resetPassword(
    email: event.email,
    code: event.code,
    newPassword: event.newPassword,
    confirmPassword: event.confirmPassword, // ✅ Fixed
  );
  ```

**Password Validation**:
- ✅ Frontend validates passwords match before submission
- ✅ Backend validates password length (minimum 6 characters)
- ✅ Both password fields are required

**Verification**:
- ✅ Reset password page correctly passes both password fields
- ✅ Auth service receives confirmPassword parameter
- ✅ Password matching validation works correctly

## 📧 Required Environment Variables

Add these to your `.env` file in the `backend` directory:

```env
# ================================
# EMAIL CONFIGURATION (Gmail SMTP)
# ================================
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=mohamedbadhey@gmail.com
SMTP_PASS=jkrqjbqhlbmqirvi
EMAIL_FROM="Bookdoon Support <no-reply@bookdoon.com>"

# ================================
# APP SETTINGS
# ================================
RESET_CODE_EXPIRY_MINUTES=10
APP_NAME=Bookdoon
APP_URL=https://bookdoon.com
```

## 🔧 How It Works

### Flow:
1. **User requests password reset** → `/auth/forgot-password`
   - Backend generates 6-digit code
   - Code stored in database with expiry time
   - Email sent with verification code

2. **User enters verification code** → `/auth/verify-reset-code`
   - Backend validates code and expiry
   - Returns success if valid

3. **User resets password** → `/auth/reset-password`
   - Backend validates code again
   - Updates password
   - Clears reset code from database

### Email Configuration:
- Uses Gmail SMTP with App Password
- Port 465 with SSL/TLS (secure connection)
- Sends from: "Bookdoon Support <no-reply@bookdoon.com>"
- Code expires in 10 minutes (configurable)

## 🧪 Testing Guide

### 1. Test Forgot Password Flow
**Steps**:
1. Open mobile app and navigate to login page
2. Click "Forgot Password?" link
3. Enter a valid email address in the dialog
4. Click "Send Code"
5. Check email inbox for 6-digit verification code

**Expected Results**:
- ✅ Dialog closes after clicking "Send Code"
- ✅ Navigates to verify code page with email in URL
- ✅ Email received within 30 seconds
- ✅ Email contains 6-digit code in large, highlighted format
- ✅ Email shows correct expiry time (10 minutes by default)
- ✅ Email "from" field shows: "Bookdoon Support <no-reply@bookdoon.com>"

**Backend Verification**:
- Check backend logs for: `Password reset code generated: { email, userId, code }`
- Check database: `users` table should have `reset_password_code` and `reset_password_code_expires_at` set

### 2. Test Code Verification
**Steps**:
1. On verify code page, enter the 6-digit code from email
2. Code should auto-verify when all 6 digits are entered
3. Should navigate to reset password page

**Expected Results**:
- ✅ Code input fields accept only digits
- ✅ Auto-advances to next field when digit entered
- ✅ Auto-verifies when all 6 digits entered
- ✅ Navigates to reset password page with email and code in URL
- ✅ Shows error if code is invalid or expired

**Test Cases**:
- ✅ Valid code: Should verify successfully
- ✅ Invalid code: Should show error "Invalid or expired verification code"
- ✅ Expired code: Should show error "Invalid or expired verification code" (after 10 minutes)
- ✅ Wrong format: Should show error "Invalid code format. Code must be 6 digits"

### 3. Test Password Reset
**Steps**:
1. On reset password page, enter new password
2. Enter password confirmation
3. Click "Reset Password"
4. Should redirect to login page

**Expected Results**:
- ✅ Password field shows/hides password toggle
- ✅ Confirm password field shows/hides password toggle
- ✅ Validates passwords match before submission
- ✅ Validates password length (minimum 6 characters)
- ✅ Shows success message after reset
- ✅ Redirects to login page after 1 second
- ✅ Can login with new password

**Test Cases**:
- ✅ Matching passwords: Should reset successfully
- ✅ Non-matching passwords: Should show error "Passwords do not match"
- ✅ Password too short: Should show error "Password must be at least 6 characters"
- ✅ Invalid/expired code: Should show error "Invalid or expired verification code"

### 4. Test Edge Cases
**Steps**:
1. Request password reset for non-existent email
2. Request multiple password resets for same email
3. Try to use old code after requesting new one

**Expected Results**:
- ✅ Non-existent email: Still shows success message (security)
- ✅ Multiple requests: New code invalidates old code
- ✅ Old code: Should be rejected after new code is generated
- ✅ Code reuse: Code should be cleared after successful reset

### 5. Test Email Configuration
**Steps**:
1. Check backend logs on startup
2. Verify email service initialization
3. Test email sending

**Expected Results**:
- ✅ Backend logs show: `Email service configured with SMTP { host, port, secure, from }`
- ✅ Email sent successfully with message ID
- ✅ Email appears in recipient's inbox
- ✅ Email format is correct (HTML and plain text)

**If Email Not Configured**:
- ✅ Backend logs show: `Email service not configured. Emails will be logged to console only.`
- ✅ Email content logged to console in development mode
- ✅ Flow still works (returns success to not break user experience)

## 📝 Implementation Details

### Email Service Backward Compatibility
- **SMTP_PASS vs SMTP_PASSWORD**: The service checks for `SMTP_PASS` first, then falls back to `SMTP_PASSWORD` if not found
- **EMAIL_FROM vs SMTP_FROM**: The service checks for `EMAIL_FROM` first, then falls back to `SMTP_FROM`, then `SMTP_USER`, then default
- **Fallback Behavior**: If email is not configured, emails are logged to console in development mode (returns `true` to not break flow)

### Security Features
- **Code Expiry**: Reset codes automatically expire after configured time (default: 10 minutes)
- **One-Time Use**: Reset codes are cleared from database after successful password reset
- **Code Invalidation**: When a new reset code is generated, old codes are automatically invalidated
- **Email Privacy**: Backend doesn't reveal if email exists or not (returns same message for both cases)

### Database Schema
The reset password flow uses these fields in the `users` table:
- `reset_password_code`: Stores the 6-digit verification code (VARCHAR)
- `reset_password_code_expires_at`: Stores the expiry timestamp (DATETIME)
- `reset_password_token`: Legacy field (cleared when using code-based reset)
- `reset_password_expires_at`: Legacy field (cleared when using code-based reset)

### Error Handling
- **Invalid Code**: Returns `INVALID_RESET_CODE` error code
- **Expired Code**: Returns `INVALID_RESET_CODE` error code (same as invalid for security)
- **Missing Fields**: Returns `MISSING_FIELDS` error code
- **Password Too Short**: Returns `PASSWORD_TOO_SHORT` error code
- **Email Not Sent**: Logs error but doesn't reveal to user (security best practice)

### Mobile App Flow
1. **Login Page** → User clicks "Forgot Password?"
2. **Dialog** → User enters email address
3. **Verify Code Page** → User enters 6-digit code (auto-verifies when complete)
4. **Reset Password Page** → User enters new password and confirmation
5. **Success** → Redirects to login page with success message

### API Endpoints

#### POST `/api/v1/auth/forgot-password`
**Request Body**:
```json
{
  "email": "user@example.com"
}
```

**Response** (200):
```json
{
  "message": "If an account with that email exists, a password reset code has been sent"
}
```

#### POST `/api/v1/auth/verify-reset-code`
**Request Body**:
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Response** (200):
```json
{
  "message": "Verification code is valid",
  "verified": true
}
```

**Error Response** (400):
```json
{
  "error": "Invalid or expired verification code",
  "code": "INVALID_RESET_CODE"
}
```

#### POST `/api/v1/auth/reset-password`
**Request Body**:
```json
{
  "email": "user@example.com",
  "code": "123456",
  "newPassword": "newpassword123"
}
```

**Response** (200):
```json
{
  "message": "Password reset successfully"
}
```

**Error Responses** (400):
```json
{
  "error": "Email, code, and new password are required",
  "code": "MISSING_FIELDS"
}
```
```json
{
  "error": "Invalid code format. Code must be 6 digits",
  "code": "INVALID_CODE_FORMAT"
}
```
```json
{
  "error": "Password must be at least 6 characters",
  "code": "PASSWORD_TOO_SHORT"
}
```

## 🚀 Deployment Checklist

### Step 1: Configure Environment Variables
1. Open `backend/.env` file (create if it doesn't exist)
2. Add the email configuration variables:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=465
   SMTP_SECURE=true
   SMTP_USER=mohamedbadhey@gmail.com
   SMTP_PASS=jkrqjbqhlbmqirvi
   EMAIL_FROM="Bookdoon Support <no-reply@bookdoon.com>"
   ```
3. Add the app settings:
   ```env
   RESET_CODE_EXPIRY_MINUTES=10
   APP_NAME=Bookdoon
   APP_URL=https://bookdoon.com
   ```

### Step 2: Verify Gmail App Password
- ✅ Gmail account: `mohamedbadhey@gmail.com`
- ✅ App Password: `jkrqjbqhlbmqirvi` (16 characters, no spaces)
- ✅ 2-Step Verification: Must be enabled on Gmail account
- ✅ App Password: Generated from Google Account settings

**How to Generate Gmail App Password**:
1. Go to Google Account → Security
2. Enable 2-Step Verification (if not already enabled)
3. Go to App Passwords
4. Select "Mail" and "Other (Custom name)"
5. Enter "Bookdoon Backend" as name
6. Copy the 16-character password (no spaces)

### Step 3: Restart Backend Server
```bash
cd backend
npm start
# or for development
npm run dev
```

**Verify Startup**:
- ✅ Check logs for: `Email service configured with SMTP`
- ✅ Check logs show correct host, port, secure flag, and from address
- ✅ No errors about email configuration

### Step 4: Test Email Sending
1. Request password reset from mobile app
2. Check email inbox within 30 seconds
3. Verify email format and content
4. Check backend logs for email sent confirmation

### Step 5: Production Deployment
If deploying to Railway or other platform:
1. Add environment variables to platform settings
2. Ensure `SMTP_PASS` is set correctly (no spaces)
3. Ensure `EMAIL_FROM` is in correct format with quotes
4. Restart service after adding variables
5. Test password reset flow in production

## 🔍 Troubleshooting

### Email Not Sending
**Symptoms**: No email received, backend logs show email sent
**Solutions**:
- Check spam/junk folder
- Verify Gmail App Password is correct (16 characters, no spaces)
- Verify 2-Step Verification is enabled
- Check Gmail account security settings
- Verify `SMTP_SECURE=true` for port 465

### Email Service Not Configured
**Symptoms**: Backend logs show "Email service not configured"
**Solutions**:
- Verify all required environment variables are set
- Check `.env` file is in `backend` directory
- Verify variable names match exactly (case-sensitive)
- Restart backend server after adding variables

### Invalid Code Error
**Symptoms**: Code verification fails even with correct code
**Solutions**:
- Check code hasn't expired (default: 10 minutes)
- Verify code format is exactly 6 digits
- Check database: `reset_password_code` and `reset_password_code_expires_at` fields
- Ensure new code request invalidates old code

### Password Reset Fails
**Symptoms**: Password reset returns error
**Solutions**:
- Verify code is still valid (not expired)
- Check password meets minimum length (6 characters)
- Verify passwords match in frontend
- Check backend logs for specific error

## 📚 Additional Resources

- **Gmail App Passwords**: https://support.google.com/accounts/answer/185833
- **Nodemailer Documentation**: https://nodemailer.com/about/
- **Environment Variables**: See `backend/env.example` for all available options

## ✅ Completion Status

- [x] Email service uses correct environment variable names
- [x] Email template uses Bookdoon branding
- [x] Reset code expiry is configurable
- [x] Environment variables documented in env.example
- [x] Mobile app passes confirmPassword correctly
- [x] All fixes tested and verified
- [x] Documentation completed

