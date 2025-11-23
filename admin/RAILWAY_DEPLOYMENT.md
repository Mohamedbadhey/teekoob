# Railway Deployment Guide for Admin Panel

## Prerequisites
- Railway account (https://railway.app)
- Backend API already deployed on Railway
- Git repository with admin panel code

## Step-by-Step Deployment

### 1. Prepare Your Code
Make sure your `admin/` directory has:
- ✅ `railway.json` - Railway configuration
- ✅ `package.json` - Dependencies and scripts
- ✅ `vite.config.ts` - Vite build configuration
- ✅ All source files in `src/`

### 2. Create New Railway Project/Service

#### Option A: New Project
1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"** (recommended) or **"Empty Project"**

#### Option B: Add to Existing Project
1. Open your existing Railway project (the one with your backend)
2. Click **"New"** → **"Service"**
3. Select **"GitHub Repo"** or **"Empty Service"**

### 3. Connect Repository
If deploying from GitHub:
1. Select your repository
2. Railway will detect the project structure
3. **Important**: Set the **Root Directory** to `admin` (not the project root)
   - Go to Settings → Source → Root Directory
   - Set to: `admin`

### 4. Configure Environment Variables

Go to your admin service → **Variables** tab and add:

```bash
# Required: Backend API URL
VITE_API_URL=https://your-backend-service.railway.app/api/v1

# Optional: App Configuration
VITE_APP_NAME=Teekoob Admin
VITE_APP_VERSION=1.0.0
```

**Important Notes:**
- Replace `your-backend-service.railway.app` with your actual backend Railway URL
- Vite requires environment variables to be prefixed with `VITE_`
- These variables are baked into the build at build time (not runtime)

### 5. Configure Build Settings

Railway should auto-detect the configuration from `railway.json`, but verify:

1. Go to **Settings** → **Build**
2. **Build Command**: `npm install && npm run build`
3. **Start Command**: `npx serve -s dist -l $PORT`
4. **Healthcheck Path**: `/`

### 6. Deploy

1. Railway will automatically start building when you:
   - Push to your connected branch, OR
   - Click **"Deploy"** in the Railway dashboard

2. Monitor the build logs:
   - Click on your service
   - Go to **"Deployments"** tab
   - Watch the build process

3. Once deployed, Railway will provide a URL like:
   - `https://your-admin-service.railway.app`

### 7. Verify Deployment

1. Visit your admin panel URL
2. You should see the login page
3. Try logging in with admin credentials
4. Check browser console for any errors

## Configuration Files

### railway.json
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npm run build"
  },
  "deploy": {
    "startCommand": "npx serve -s dist -l $PORT",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `VITE_API_URL` | Yes | Backend API base URL | `https://teekoob-backend.railway.app/api/v1` |
| `VITE_APP_NAME` | No | Application name | `Teekoob Admin` |
| `VITE_APP_VERSION` | No | App version | `1.0.0` |

## Troubleshooting

### Build Fails
- **Error: "Cannot find module"**
  - Check that all dependencies are in `package.json`
  - Run `npm install` locally to verify

- **Error: "Build command failed"**
  - Check build logs for specific errors
  - Verify `vite.config.ts` is correct
  - Ensure TypeScript compiles without errors

### App Doesn't Load
- **Blank page**
  - Check browser console for errors
  - Verify `VITE_API_URL` is set correctly
  - Check that build completed successfully

- **404 errors**
  - Verify `healthcheckPath` is set to `/`
  - Check that `serve` is serving from `dist/` directory
  - Ensure build output is in `dist/`

### API Connection Issues
- **CORS errors**
  - Verify backend CORS settings allow your admin domain
  - Check `VITE_API_URL` matches your backend URL

- **401 Unauthorized**
  - Check that backend is running
  - Verify API URL is correct
  - Check authentication token in browser localStorage

### Port Issues
- Railway automatically sets `$PORT` environment variable
- The `serve` command uses `$PORT` to listen on the correct port
- Don't hardcode port numbers

## Custom Domain (Optional)

1. Go to your service → **Settings** → **Networking**
2. Click **"Generate Domain"** or **"Custom Domain"**
3. Add your custom domain
4. Update DNS records as instructed

## Updating the Deployment

### Automatic (Recommended)
- Push changes to your connected GitHub branch
- Railway will automatically rebuild and redeploy

### Manual
1. Go to **Deployments** tab
2. Click **"Redeploy"** on the latest deployment
3. Or trigger a new deployment from **Settings** → **Source**

## Monitoring

- **Logs**: View real-time logs in Railway dashboard
- **Metrics**: Check CPU, Memory, and Network usage
- **Deployments**: Track deployment history and status

## Production Checklist

- [ ] Environment variables configured
- [ ] Backend API URL is correct
- [ ] Build completes successfully
- [ ] Admin panel loads correctly
- [ ] Login works
- [ ] API calls are successful
- [ ] Custom domain configured (if needed)
- [ ] SSL certificate is active (automatic with Railway)

## Support

If you encounter issues:
1. Check Railway build logs
2. Check browser console for errors
3. Verify environment variables
4. Test API connection separately
5. Check Railway status page: https://status.railway.app

