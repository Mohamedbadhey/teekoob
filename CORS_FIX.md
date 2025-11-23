# CORS Fix for Admin Panel Deployment

## Issue
The admin panel deployed at `https://bookdoon.kismayoict.com/` was getting blocked by CORS when trying to connect to the backend API at `https://teekoob-production.up.railway.app/api/v1`.

**Error Message:**
```
Access to XMLHttpRequest at 'https://teekoob-production.up.railway.app/api/v1/auth/login' 
from origin 'https://bookdoon.kismayoict.com' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Solution

The backend CORS configuration has been updated to allow requests from `kismayoict.com` domains.

### What Was Changed

Updated `backend/src/index.js` to include support for `kismayoict.com` domains in the CORS whitelist.

### Next Steps

1. **Deploy the Backend Update**
   - Push the updated `backend/src/index.js` to your repository
   - Railway will automatically redeploy your backend service
   - Wait for the deployment to complete (usually 2-5 minutes)

2. **Verify the Fix**
   - Once deployed, try logging into the admin panel again at `https://bookdoon.kismayoict.com/`
   - The CORS error should be resolved and login should work

3. **Alternative: Environment Variable Method**
   If you prefer to use environment variables instead (more flexible for multiple domains):
   - Go to Railway Dashboard → Your Backend Service → Variables
   - Add or update: `CORS_ORIGIN`
   - Value: `https://bookdoon.kismayoict.com`
   - For multiple domains: `https://bookdoon.kismayoict.com,https://another-domain.com`

## Current CORS Configuration

The backend now allows requests from:
- ✅ `localhost` (any port) - for development
- ✅ `.railway.app` domains - Railway default domains
- ✅ `kismayoict.com` domains - Admin panel domain
- ✅ Custom domains specified in `CORS_ORIGIN` environment variable

## Testing

After deployment, test the admin panel:
1. Visit: https://bookdoon.kismayoict.com/
2. Try to login with admin credentials
3. Check browser console - CORS errors should be gone
4. Verify API calls are working

---

**Note:** The code update allows all `kismayoict.com` subdomains. If you need stricter control, use the `CORS_ORIGIN` environment variable method instead.

