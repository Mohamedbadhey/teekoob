# Registration Flow Fix

## Problem
The registration flow was trying to create users with `password_hash = NULL` during email verification, but the database schema required `password_hash` to be NOT NULL. This caused the error:
```
Column 'password_hash' cannot be null
```

## Solution
Made `password_hash` nullable in the database to support the two-step registration flow:
1. **Step 1**: User enters email → receives verification code → user record created with `password_hash = NULL`
2. **Step 2**: User verifies code → enters password → `password_hash` is set and registration is complete

## Changes Made

### 1. Database Migration
Created `backend/migrations/020_make_password_hash_nullable.js` to make the `password_hash` column nullable.

### 2. Code Updates
- **Login Route** (`backend/src/routes/auth.js`): Added check to prevent login for users with NULL `password_hash` (incomplete registrations)
- **Password Change Route** (`backend/src/routes/users.js`): Added NULL check for safety
- **Account Deletion Route** (`backend/src/routes/users.js`): Added NULL check for safety

## How to Apply the Fix

### Step 1: Run the Migration
```bash
cd backend
npm run migrate
```

Or if using Knex directly:
```bash
cd backend
npx knex migrate:latest
```

### Step 2: Verify the Migration
Check that the migration ran successfully:
```bash
npx knex migrate:status
```

You should see `020_make_password_hash_nullable.js` listed as completed.

### Step 3: Test the Registration Flow
1. Try registering a new user with email verification
2. The user should be created successfully with NULL password
3. After verifying the code, the password should be set
4. User should be able to login after completing registration

## Registration Flow (Current)

1. **POST `/api/v1/auth/send-registration-code`**
   - User provides: `email`, `firstName`, `lastName`, `preferredLanguage`
   - Backend creates user with `password_hash = NULL`
   - Sends verification code via email
   - Returns success message

2. **POST `/api/v1/auth/verify-registration-code`**
   - User provides: `email`, `code`
   - Backend verifies code is valid and not expired
   - Returns success if valid

3. **POST `/api/v1/auth/complete-registration`**
   - User provides: `email`, `code`, `password`
   - Backend verifies code again
   - Hashes password and sets `password_hash`
   - Sets `is_active = true` and `is_verified = true`
   - Clears verification code
   - Returns JWT token for immediate login

## Security Notes

- Users with `password_hash = NULL` cannot login (checked in login route)
- Users with `password_hash = NULL` cannot change password (checked in password change route)
- Only users who have completed registration (have `password_hash`) can authenticate
- Verification codes expire after the configured time (default: 10 minutes)

## Rollback (if needed)

If you need to revert this change:
```bash
cd backend
npx knex migrate:rollback
```

**Note**: Rollback will fail if there are any users with NULL `password_hash` in the database. You would need to either:
1. Delete incomplete registrations first, OR
2. Set a temporary password for them before rolling back

