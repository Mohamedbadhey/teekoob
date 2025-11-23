# Railway Admin Panel - Quick Fix Guide

## Current Issue
Deployment is crashing because the start command is incorrect.

## Fix Steps

### 1. Update Start Command
In Railway Dashboard → Your Admin Service → Settings → Deploy:

**Change from:**
```
npm run start
```

**Change to:**
```
npx serve -s dist -l $PORT
```

### 2. Set Healthcheck Path
In Railway Dashboard → Your Admin Service → Settings → Deploy:

**Set Healthcheck Path to:**
```
/
```

### 3. Verify Build Command
In Railway Dashboard → Your Admin Service → Settings → Build:

**Should be:**
```
npm run build
```

### 4. Verify Root Directory
In Railway Dashboard → Your Admin Service → Settings → Source:

**Root directory should be:**
```
admin
```

### 5. Set Environment Variable
In Railway Dashboard → Your Admin Service → Variables:

**Add/Update:**
```
VITE_API_URL=https://your-backend-service.railway.app/api/v1
```

Replace `your-backend-service.railway.app` with your actual backend Railway URL.

## Complete Configuration Summary

### Build Settings
- **Builder**: NIXPACKS (Default)
- **Build Command**: `npm run build`
- **Root Directory**: `admin`

### Deploy Settings
- **Start Command**: `npx serve -s dist -l $PORT`
- **Healthcheck Path**: `/`
- **Port**: Railway will set `$PORT` automatically (usually 8080)

### Environment Variables
- `VITE_API_URL` = Your backend API URL (required)

## Why This Fixes It

- `npm run start` runs the Vite dev server (for development)
- `npx serve -s dist -l $PORT` serves the built static files (for production)
- The `-s` flag enables SPA routing (handles client-side routing)
- The `-l $PORT` listens on Railway's assigned port

## After Making Changes

1. Save the settings
2. Railway will automatically trigger a new deployment
3. Watch the deployment logs to ensure it builds successfully
4. Once deployed, visit your admin panel URL

## Verify Deployment

1. Check deployment logs for:
   - ✅ Build completes successfully
   - ✅ "Serving!" message from serve
   - ✅ No errors

2. Visit your admin panel URL
3. You should see the login page
4. Check browser console for any errors

## If Still Having Issues

1. Check deployment logs for specific errors
2. Verify `serve` package is in dependencies (it should be)
3. Ensure `dist` folder is created during build
4. Check that environment variables are set correctly

