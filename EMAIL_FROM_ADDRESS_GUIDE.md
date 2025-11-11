# 📧 Email "From" Address Configuration Guide

## ❌ What You CANNOT Use

You **cannot** use Gmail addresses as the "from" address in Resend:
- ❌ `mohamedbadhey@gmail.com`
- ❌ `yourname@gmail.com`
- ❌ Any `@gmail.com` address

**Reason:** Resend requires domain verification, and you can't verify Google's domain.

---

## ✅ What You CAN Use

### Option 1: Resend Test Domain (Immediate)
```
RESEND_FROM=onboarding@resend.dev
```
- ✅ Works immediately
- ✅ No domain verification needed
- ⚠️ May go to spam folder
- ⚠️ For testing only

### Option 2: Your Verified Domain (Production)
```
RESEND_FROM=no-reply@bookdoon.com
RESEND_FROM=support@bookdoon.com
RESEND_FROM=hello@bookdoon.com
```
- ✅ Professional appearance
- ✅ Better deliverability
- ✅ Requires domain verification
- ✅ Any email address on your verified domain works

---

## 📬 Recipient Address (To Address)

You **CAN** send emails **TO** any address:
- ✅ `mohamedbadhey@gmail.com` (recipient - this is fine!)
- ✅ `user@example.com`
- ✅ Any email address

The "to" address doesn't need verification.

---

## 🔧 Current Configuration

### In Railway Environment Variables:

**For Testing (Now):**
```env
RESEND_FROM=onboarding@resend.dev
```

**For Production (After Domain Verification):**
```env
RESEND_FROM=no-reply@bookdoon.com
```

---

## 📋 Quick Setup

1. **Go to Railway Dashboard**
2. **Select your backend service**
3. **Go to Variables tab**
4. **Add/Update:**
   ```
   RESEND_FROM=onboarding@resend.dev
   ```
5. **Redeploy service**

---

## 🎯 Summary

- **From Address:** Must be verified domain or `onboarding@resend.dev`
- **To Address:** Can be any email (including Gmail)
- **Your Gmail:** Can receive emails, but can't be used as sender
- **Quick Fix:** Use `onboarding@resend.dev` for now
- **Production:** Verify `bookdoon.com` and use `no-reply@bookdoon.com`

---

## 💡 Example

When user requests password reset:
- **From:** `onboarding@resend.dev` (or `no-reply@bookdoon.com` after verification)
- **To:** `mohamedbadhey@gmail.com` ✅ (This works!)
- **Subject:** "Password Reset Code - Bookdoon"
- **Content:** 6-digit code

The email will arrive at `mohamedbadhey@gmail.com` successfully!

