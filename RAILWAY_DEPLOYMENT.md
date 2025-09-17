# 🚀 Railway Deployment Guide for Teekoob

This guide will help you deploy your Teekoob project (Backend + Admin Panel) to Railway.

## 📋 Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app)
2. **GitHub Repository**: Your project should be pushed to GitHub
3. **Database**: You'll need a MySQL database (Railway provides this)

## 🏗️ Project Structure for Railway

Your project will be deployed as **two separate services**:

1. **Backend Service** (`/backend` directory)
2. **Admin Panel Service** (`/admin` directory)

## 🚀 Step-by-Step Deployment

### Step 1: Create Railway Project

1. Go to [railway.app](https://railway.app) and sign in
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose your `teekoob` repository
5. Railway will detect your project structure

### Step 2: Deploy Backend Service

1. In your Railway project, click **"New Service"**
2. Select **"GitHub Repo"** and choose your repository
3. **Root Directory**: Set to `backend`
4. **Build Command**: `npm install`
5. **Start Command**: `npm start`

#### Backend Environment Variables

Add these environment variables in Railway dashboard:

```env
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database (Railway will provide these)
DB_HOST=your-railway-mysql-host
DB_PORT=3306
DB_NAME=railway
DB_USER=root
DB_PASSWORD=your-railway-mysql-password

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# CORS (Update with your Railway URLs)
CORS_ORIGIN=https://your-admin-service.railway.app

# AWS S3 (Optional - for file storage)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=teekoob-storage

# Stripe (Optional - for payments)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

# Firebase (Optional - for notifications)
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY_ID=your_firebase_private_key_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_CLIENT_ID=your_firebase_client_id
```

### Step 3: Deploy Admin Panel Service

1. In your Railway project, click **"New Service"** again
2. Select **"GitHub Repo"** and choose your repository
3. **Root Directory**: Set to `admin`
4. **Build Command**: `npm install && npm run build`
5. **Start Command**: `npx serve -s dist -l 3001`

#### Admin Environment Variables

```env
# API Configuration
VITE_API_BASE_URL=https://your-backend-service.railway.app/api/v1
VITE_APP_NAME=Teekoob Admin
VITE_APP_VERSION=1.0.0
```

### Step 4: Set Up MySQL Database

1. In Railway dashboard, click **"New Service"**
2. Select **"Database"** → **"MySQL"**
3. Railway will automatically create a MySQL database
4. Copy the connection details to your backend environment variables

### Step 5: Run Database Migrations

1. Go to your backend service in Railway
2. Click on **"Deployments"** tab
3. Click **"View Logs"** to see the deployment
4. You can run migrations manually by connecting to your service

## 🔧 Configuration Updates Needed

### Backend CORS Configuration

Update your backend CORS settings to allow your Railway admin panel:

```javascript
// In backend/src/index.js
app.use(cors({
  origin: [
    'http://localhost:3001', // Local development
    'https://your-admin-service.railway.app', // Railway admin URL
  ],
  credentials: true,
}));
```

### Admin API Configuration

Update your admin panel to use the Railway backend URL:

```typescript
// In admin/src/services/adminAPI.ts
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1';
```

## 🌐 Custom Domains (Optional)

1. In Railway dashboard, go to your service
2. Click **"Settings"** → **"Domains"**
3. Add your custom domain
4. Update CORS settings to include your custom domain

## 📊 Monitoring & Logs

- **Logs**: View real-time logs in Railway dashboard
- **Metrics**: Monitor CPU, memory, and network usage
- **Health Checks**: Railway automatically monitors your services

## 🔄 Auto-Deployments

Railway automatically deploys when you push to your main branch. To deploy:

1. Make changes to your code
2. Commit and push to GitHub
3. Railway will automatically build and deploy

## 🚨 Troubleshooting

### Common Issues:

1. **Build Failures**: Check the build logs in Railway dashboard
2. **Database Connection**: Verify environment variables are set correctly
3. **CORS Errors**: Update CORS settings to include Railway URLs
4. **File Uploads**: Consider using AWS S3 for file storage in production

### Useful Commands:

```bash
# Check Railway CLI (optional)
npm install -g @railway/cli
railway login
railway status
```

## 📝 Environment Variables Summary

### Backend Required:
- `NODE_ENV=production`
- `PORT=3000`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `JWT_SECRET`

### Admin Required:
- `VITE_API_BASE_URL`

### Optional (for full functionality):
- AWS S3 credentials
- Stripe keys
- Firebase credentials

## 🎉 Success!

Once deployed, you'll have:
- **Backend API**: `https://your-backend.railway.app`
- **Admin Panel**: `https://your-admin.railway.app`
- **Database**: Managed MySQL instance

Your Teekoob platform will be live and accessible worldwide! 🌍

## 📞 Support

- Railway Documentation: [docs.railway.app](https://docs.railway.app)
- Railway Discord: [discord.gg/railway](https://discord.gg/railway)
- Railway Status: [status.railway.app](https://status.railway.app)
