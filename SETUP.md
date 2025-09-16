# Teekoob Project Setup (Without Docker)

## Prerequisites

1. **MySQL Server** - Install MySQL 8.0 or later
2. **phpMyAdmin** - Your existing phpMyAdmin installation
3. **Node.js** - Version 18.0.0 or later
4. **Redis** - For caching (optional, can be installed locally)

## Database Setup

### 1. Create MySQL Database

Connect to your MySQL server using phpMyAdmin or MySQL command line:

```sql
-- Create database
CREATE DATABASE teekoob CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use the database
USE teekoob;

-- Run the initialization script
-- Copy and paste the contents of backend/init.sql
```

### 2. Database Connection Details

- **Host**: localhost
- **Port**: 3306
- **Database**: teekoob
- **Username**: root (or your MySQL username)
- **Password**: (your MySQL password)

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

Create a `.env` file in the backend directory:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=teekoob
DB_USER=root
DB_PASSWORD=your_mysql_password

# JWT
JWT_SECRET=teekoob_jwt_secret_key_development_2024
JWT_EXPIRES_IN=7d

# Redis (if using local Redis)
REDIS_URL=redis://localhost:6379

# Other services (configure as needed)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=teekoob-storage

STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY_ID=your_firebase_private_key_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_CLIENT_ID=your_firebase_client_id
```

### 3. Run Database Migrations

```bash
npm run migrate
```

### 4. Start the Backend

```bash
npm run dev
```

The backend will be available at: http://localhost:3000

## Mobile App Setup

### 1. Install Flutter Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Update API Configuration

In `mobile/lib/core/config/app_config.dart`, ensure the API base URL points to your local backend:

```dart
static const String apiBaseUrl = 'http://localhost:3000/api/v1';
```

### 3. Run the Mobile App

```bash
flutter run
```

## Connecting to phpMyAdmin

1. Open your phpMyAdmin in your browser
2. Add a new server connection:
   - **Server name**: Teekoob Local
   - **Host**: localhost
   - **Port**: 3306
   - **Username**: root (or your MySQL username)
   - **Password**: (your MySQL password)

3. Select the `teekoob` database to view and manage your data

## Troubleshooting

### Database Connection Issues

- Ensure MySQL service is running
- Check if the port 3306 is not blocked by firewall
- Verify username and password in your `.env` file

### Migration Issues

- Make sure the database exists before running migrations
- Check MySQL user permissions (CREATE, ALTER, INSERT, etc.)

### Port Conflicts

- If port 3000 is in use, change it in the `.env` file
- If port 3306 is in use, change MySQL port or update configuration

## Services Status

- **Backend API**: http://localhost:3000
- **Database**: localhost:3306
- **phpMyAdmin**: Your existing installation
- **Redis**: localhost:6379 (if installed locally)
