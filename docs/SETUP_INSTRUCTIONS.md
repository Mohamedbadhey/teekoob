# 🚀 Teekoob Setup Instructions

## Prerequisites

Before setting up Teekoob, ensure you have the following installed:

### Required Software
- **Node.js** 18.0.0 or higher
- **PostgreSQL** 13.0 or higher
- **Flutter** 3.10.0 or higher
- **Git** 2.30.0 or higher
- **Docker** (optional, for containerized setup)

### Development Tools
- **VS Code** or **IntelliJ IDEA**
- **Postman** or **Insomnia** (for API testing)
- **pgAdmin** or **DBeaver** (for database management)

## Backend Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/teekoob.git
cd teekoob
```

### 2. Install Backend Dependencies
```bash
cd backend
npm install
```

### 3. Environment Configuration
```bash
# Copy environment template
cp env.example .env

# Edit .env file with your configuration
nano .env
```

**Required Environment Variables:**
```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=teekoob
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_super_secret_jwt_key_here

# Server
PORT=3000
NODE_ENV=development
```

### 4. Database Setup
```bash
# Create PostgreSQL database
psql -U postgres
CREATE DATABASE teekoob;
CREATE USER teekoob_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE teekoob TO teekoob_user;
\q

# Run database migrations
npm run migrate

# Seed sample data
npm run seed
```

### 5. Start Backend Server
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

**Verify Setup:**
- Backend should be running on `http://localhost:3000`
- Health check: `http://localhost:3000/health`
- API docs: `http://localhost:3000/api/v1`

## Mobile App Setup

### 1. Install Flutter Dependencies
```bash
cd ../mobile
flutter pub get
```

### 2. Flutter Configuration
```bash
# Check Flutter installation
flutter doctor

# Get additional dependencies
flutter pub run build_runner build
```

### 3. Platform Setup

#### Android
```bash
# Ensure Android SDK is installed
flutter doctor --android-licenses

# Run on Android device/emulator
flutter run
```

#### iOS
```bash
# Install iOS dependencies
cd ios
pod install
cd ..

# Run on iOS simulator/device
flutter run
```

### 4. Environment Configuration
Create `mobile/lib/core/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const String appName = 'Teekoob';
  static const String appVersion = '1.0.0';
  
  // Add other configuration constants
}
```

## Database Schema

### Tables Overview
- **users**: User accounts and profiles
- **books**: Book metadata and content
- **user_library**: User's personal book collection
- **subscriptions**: Subscription plans and billing

### Sample Data
The database comes pre-populated with:
- 8 sample books in various genres
- Multiple languages (English, Somali, Bilingual)
- Different formats (eBook, Audiobook, Both)

## API Testing

### 1. Test Authentication
```bash
# Register a new user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "preferredLanguage": "english"
  }'
```

### 2. Test Book Endpoints
```bash
# Get all books
curl http://localhost:3000/api/v1/books

# Get book by ID
curl http://localhost:3000/api/v1/books/550e8400-e29b-41d4-a716-446655440001
```

### 3. Test with Authentication
```bash
# Login to get token
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}' \
  | jq -r '.token')

# Use token for authenticated requests
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/users/profile
```

## Development Workflow

### 1. Backend Development
```bash
cd backend

# Run tests
npm test

# Lint code
npm run lint

# Watch for changes
npm run dev
```

### 2. Database Changes
```bash
# Create new migration
npx knex migrate:make migration_name

# Run migrations
npm run migrate

# Rollback migrations
npx knex migrate:rollback
```

### 3. Mobile Development
```bash
cd mobile

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Build APK
flutter build apk
```

## Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check if port is in use
lsof -i :3000

# Kill process using port
kill -9 <PID>

# Check database connection
psql -U postgres -d teekoob -c "SELECT 1;"
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql

# Check connection
psql -U postgres -h localhost
```

#### Flutter Issues
```bash
# Clean Flutter
flutter clean

# Get packages again
flutter pub get

# Check Flutter installation
flutter doctor
```

#### Migration Errors
```bash
# Reset database
npx knex migrate:rollback --all

# Run migrations again
npm run migrate

# Check migration status
npx knex migrate:status
```

### Performance Issues

#### Database Performance
```bash
# Check slow queries
# Add to postgresql.conf:
log_statement = 'all'
log_min_duration_statement = 1000

# Restart PostgreSQL
sudo systemctl restart postgresql
```

#### API Performance
```bash
# Monitor API calls
npm run dev

# Check response times in browser dev tools
# Use Postman/Insomnia for load testing
```

## Production Deployment

### 1. Environment Variables
```env
NODE_ENV=production
PORT=3000
DB_HOST=your_production_db_host
DB_PASSWORD=your_production_db_password
JWT_SECRET=your_production_jwt_secret
```

### 2. Build Backend
```bash
cd backend
npm run build
npm start
```

### 3. Build Mobile App
```bash
cd mobile

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Monitoring and Logs

### 1. Application Logs
```bash
# Backend logs
tail -f backend/logs/combined.log
tail -f backend/logs/error.log

# Mobile logs (Android)
adb logcat | grep teekoob
```

### 2. Database Monitoring
```bash
# Check active connections
psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Check table sizes
psql -U postgres -d teekoob -c "
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

## Contributing

### 1. Code Style
- Follow ESLint rules for backend
- Follow Flutter lint rules for mobile
- Use conventional commit messages

### 2. Testing
```bash
# Backend tests
npm test

# Mobile tests
flutter test

# Integration tests
flutter test integration_test/
```

### 3. Pull Request Process
1. Create feature branch
2. Make changes
3. Add tests
4. Update documentation
5. Submit PR

## Support

### Getting Help
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: `/docs` folder
- **API Docs**: `/docs/API_DOCUMENTATION.md`

### Useful Commands
```bash
# Quick start (after initial setup)
cd backend && npm run dev &
cd mobile && flutter run

# Reset everything
cd backend && npm run migrate:rollback --all && npm run migrate && npm run seed
cd mobile && flutter clean && flutter pub get

# Check system status
docker ps
ps aux | grep node
flutter doctor
```

## Next Steps

After successful setup:

1. **Explore the API**: Test endpoints with Postman
2. **Run the mobile app**: Test on device/simulator
3. **Add features**: Implement new functionality
4. **Customize**: Modify themes, languages, features
5. **Deploy**: Set up production environment

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Node.js Documentation](https://nodejs.org/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)
- [Knex.js Documentation](https://knexjs.org/)
- [Bloc Pattern](https://bloclibrary.dev/)
