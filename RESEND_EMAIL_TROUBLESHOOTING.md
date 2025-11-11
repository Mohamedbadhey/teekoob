# 📧 Resend Email Troubleshooting Guide

## Problem
Logs show "Email sent via Resend" but emails are not actually being delivered.

## Common Causes & Solutions

### 1. **Domain Not Verified** ⚠️ MOST COMMON
**Issue:** Resend requires domain verification before sending emails.

**Solution:**
1. Go to [Resend Dashboard](https://resend.com/domains)
2. Add your domain (e.g., `bookdoon.com`)
3. Add the DNS records provided by Resend:
   - SPF record
   - DKIM record
   - DMARC record (optional but recommended)
4. Wait for verification (usually a few minutes)
5. Use verified domain in `RESEND_FROM` (e.g., `no-reply@bookdoon.com`)

**Check:** In Resend dashboard, domain status should show "Verified"

---

### 2. **Invalid "From" Address**
**Issue:** Using an unverified email address in the `from` field.

**Solution:**
- Use a verified domain email: `no-reply@yourdomain.com`
- Or use Resend's test domain: `onboarding@resend.dev` (only for testing)
- Check `RESEND_FROM` environment variable matches a verified domain

**Current Configuration:**
- `RESEND_FROM`: Check Railway environment variables
- `EMAIL_FROM`: Fallback if `RESEND_FROM` not set

---

### 3. **API Key Issues**
**Issue:** Invalid or restricted API key.

**Solution:**
1. Check `RESEND_API_KEY` in Railway environment variables
2. Verify API key in [Resend Dashboard](https://resend.com/api-keys)
3. Ensure API key has "Send Email" permissions
4. Regenerate API key if needed

**Test API Key:**
```bash
curl -X POST 'https://api.resend.com/emails' \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "onboarding@resend.dev",
    "to": "your-email@example.com",
    "subject": "Test Email",
    "html": "<p>Test</p>"
  }'
```

---

### 4. **Rate Limits**
**Issue:** Exceeded Resend's rate limits.

**Free Tier Limits:**
- 100 emails/day
- 3,000 emails/month

**Solution:**
- Check Resend dashboard for usage
- Upgrade plan if needed
- Implement email queuing for high volume

---

### 5. **Email Going to Spam**
**Issue:** Email is sent but goes to spam folder.

**Solution:**
- Verify domain with proper SPF, DKIM, DMARC records
- Use a professional "from" address
- Avoid spam trigger words in subject/content
- Warm up domain gradually (start with low volume)

---

## Enhanced Logging

The code now includes enhanced logging to help diagnose issues:

### What to Check in Logs:

1. **Full Resend Response:**
   ```
   📧 Resend API Response: { ... }
   ```
   - Check if `data.id` exists (email was queued)
   - Check for `error` field
   - Check `status` field

2. **Error Details:**
   ```
   ❌ Resend API Error Details: { ... }
   ```
   - Check `statusCode` (400, 401, 403, etc.)
   - Check `response.data` for specific error message
   - Common errors:
     - `401`: Invalid API key
     - `403`: Domain not verified
     - `422`: Invalid email format
     - `429`: Rate limit exceeded

3. **Warning Messages:**
   ```
   Resend API response missing email ID
   ```
   - Indicates response didn't include email ID
   - Email may not have been queued

---

## Testing Email Configuration

### 1. Use Test Endpoint
```bash
POST /api/v1/auth/test-send-email
Body: { "email": "your-email@example.com" }
```

This will:
- Test email configuration
- Send a test email
- Return detailed error information

### 2. Check Configuration Status
```bash
GET /api/v1/auth/test-email-config
```

Returns:
- Email service configuration status
- Missing environment variables
- Provider information

---

## Environment Variables Checklist

Ensure these are set in Railway:

```env
# Required
RESEND_API_KEY=re_xxxxxxxxxxxxx

# Recommended (use verified domain)
RESEND_FROM=no-reply@yourdomain.com

# Fallback
EMAIL_FROM=no-reply@yourdomain.com

# Optional
APP_NAME=Bookdoon
RESET_CODE_EXPIRY_MINUTES=10
```

---

## Step-by-Step Fix

1. **Check Resend Dashboard:**
   - [ ] Domain is verified
   - [ ] API key is valid
   - [ ] Rate limits not exceeded

2. **Check Railway Environment:**
   - [ ] `RESEND_API_KEY` is set
   - [ ] `RESEND_FROM` uses verified domain
   - [ ] No typos in environment variables

3. **Test Email Sending:**
   - [ ] Use test endpoint: `/api/v1/auth/test-send-email`
   - [ ] Check logs for full Resend response
   - [ ] Verify email ID is returned

4. **Check Email Delivery:**
   - [ ] Check spam folder
   - [ ] Check Resend dashboard for delivery status
   - [ ] Check bounce/complaint reports

---

## Quick Fix: Use Resend Test Domain

For immediate testing (not for production):

1. Set in Railway:
   ```env
   RESEND_FROM=onboarding@resend.dev
   ```

2. This works without domain verification
3. **Note:** Emails from `onboarding@resend.dev` may go to spam

---

## Production Setup

For production, you MUST:

1. ✅ Verify your domain in Resend
2. ✅ Add DNS records (SPF, DKIM, DMARC)
3. ✅ Use verified domain email: `no-reply@yourdomain.com`
4. ✅ Set `RESEND_FROM=no-reply@yourdomain.com`
5. ✅ Test email delivery
6. ✅ Monitor Resend dashboard for issues

---

## Next Steps After Fix

After fixing the configuration:

1. **Deploy updated code** (with enhanced logging)
2. **Test password reset** again
3. **Check logs** for full Resend response
4. **Verify email delivery** in inbox/spam
5. **Monitor Resend dashboard** for delivery status

---

## Additional Resources

- [Resend Documentation](https://resend.com/docs)
- [Resend Domain Verification](https://resend.com/docs/dashboard/domains/introduction)
- [Resend API Reference](https://resend.com/docs/api-reference/emails/send-email)

---

## Summary

**Most likely issue:** Domain not verified in Resend.

**Quick test:** Use `onboarding@resend.dev` as `RESEND_FROM` to test if API key works.

**Production fix:** Verify your domain and use verified domain email address.

