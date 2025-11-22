# 📚 Teekoob Project Structure Analysis

## Overview
Teekoob is a multilingual eBook and audiobook platform with three main components:
1. **Backend API** (Node.js/Express)
2. **Admin Panel** (React/TypeScript)
3. **Mobile App** (Flutter/Dart)

---

## 🏗️ Backend Structure (`backend/`)

### Technology Stack
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MySQL (via Knex.js ORM)
- **Authentication**: JWT (jsonwebtoken)
- **File Upload**: Multer
- **Logging**: Winston
- **Validation**: Express-validator, Joi
- **Security**: Helmet, CORS, Rate Limiting
- **Email**: Resend API
- **Payments**: Stripe
- **Notifications**: Firebase Admin SDK

### Directory Structure
```
backend/
├── src/
│   ├── index.js              # Main server entry point
│   ├── config/
│   │   └── database.js       # Knex database configuration
│   ├── middleware/
│   │   ├── auth.js           # JWT authentication middleware
│   │   └── errorHandler.js   # Centralized error handling
│   ├── routes/               # API route handlers
│   │   ├── auth.js           # Authentication endpoints
│   │   ├── users.js          # User management
│   │   ├── books.js          # Book CRUD operations
│   │   ├── categories.js     # Category management
│   │   ├── library.js        # User library operations
│   │   ├── payments.js       # Payment/subscription handling
│   │   ├── admin.js          # Admin-only endpoints
│   │   ├── setup.js          # First-time setup
│   │   ├── notifications.js  # Push notifications
│   │   ├── podcasts.js       # Podcast management
│   │   ├── reviews.js        # Book reviews
│   │   └── messages.js       # Admin messaging
│   └── utils/
│       ├── logger.js         # Winston logger setup
│       └── emailService.js   # Email sending service
├── migrations/               # Database schema migrations (21 files)
├── seeds/                   # Sample data seeding
├── uploads/                 # File storage (Railway volume)
└── logs/                    # Application logs
```

### Key API Endpoints

#### Authentication (`/api/v1/auth`)
- `POST /send-registration-code` - Send email verification code
- `POST /verify-registration-code` - Verify registration code
- `POST /complete-registration` - Complete registration with password
- `POST /login` - User login
- `POST /send-reset-code` - Send password reset code
- `POST /verify-reset-code` - Verify reset code
- `POST /reset-password` - Reset password
- `POST /google-auth` - Google OAuth authentication
- `GET /me` - Get current user

#### Books (`/api/v1/books`)
- `GET /books` - List books with filters (search, category, language, format)
- `GET /books/:id` - Get book details
- `GET /books/:id/content` - Get book content (eBook/Audiobook)
- `GET /books/categories` - Get book categories
- `GET /books/featured` - Get featured books
- `GET /books/new-releases` - Get new releases

#### Library (`/api/v1/library`) - Requires Auth
- `GET /library` - Get user's library
- `POST /library/:bookId` - Add book to library
- `PUT /library/:bookId/progress` - Update reading progress
- `GET /library/:bookId/bookmarks` - Get bookmarks
- `POST /library/:bookId/bookmarks` - Add bookmark
- `DELETE /library/:bookId/bookmarks/:bookmarkId` - Delete bookmark
- `GET /library/:bookId/notes` - Get notes
- `POST /library/:bookId/notes` - Add note
- `PUT /library/:bookId/favorite` - Toggle favorite

#### Admin (`/api/v1/admin`) - Requires Admin Auth
- **Books Management**:
  - `GET /admin/books` - List all books (admin view)
  - `POST /admin/books` - Create book
  - `PUT /admin/books/:id` - Update book
  - `DELETE /admin/books/:id` - Delete book
  - `PUT /admin/books/:id/status` - Update book status
  - `PUT /admin/books/bulk` - Bulk operations
  
- **User Management**:
  - `GET /admin/users` - List all users
  - `GET /admin/users/:id` - Get user details
  - `PUT /admin/users/:id/status` - Update user status
  - `GET /admin/users/analytics` - User analytics
  - `GET /admin/users/activity` - User activity logs
  - `GET /admin/users/segmentation` - User segmentation
  - `GET /admin/users/reports` - User reports
  
- **Analytics**:
  - `GET /admin/analytics/overview` - Dashboard overview
  - `GET /admin/analytics/user-growth` - User growth metrics
  - `GET /admin/analytics/book-performance` - Book performance
  - `GET /admin/analytics/subscriptions` - Subscription analytics
  - `GET /admin/analytics/advanced` - Advanced analytics
  
- **Podcasts**:
  - `GET /admin/podcasts` - List podcasts
  - `POST /admin/podcasts` - Create podcast
  - `PUT /admin/podcasts/:id` - Update podcast
  - `DELETE /admin/podcasts/:id` - Delete podcast
  - `GET /admin/podcasts/:id/episodes` - Get episodes
  - `POST /admin/podcasts/:id/episodes` - Create episode

- **Categories**:
  - `GET /categories/admin` - List categories
  - `POST /categories` - Create category
  - `PUT /categories/:id` - Update category
  - `DELETE /categories/:id` - Delete category

- **Messages/Notifications**:
  - `POST /messages` - Send message to users
  - `POST /messages/broadcast` - Broadcast message

### Database Schema (Key Tables)
- `users` - User accounts, authentication, preferences
- `books` - Book metadata, content URLs, ratings
- `categories` - Book/podcast categories
- `user_library` - User's book collection, progress
- `user_favorites` - User favorite books
- `subscriptions` - Subscription plans and billing
- `user_fcm_tokens` - Firebase Cloud Messaging tokens
- `notification_preferences` - User notification settings
- `notifications` - Notification history
- `podcasts` - Podcast metadata
- `podcast_parts` - Podcast episodes
- `reviews` - Book reviews and ratings
- `book_categories` - Many-to-many relationship

### Authentication Flow
1. Registration: Email → Verification Code → Complete Registration
2. Login: Email/Password → JWT Token
3. Protected Routes: JWT Token in Authorization header
4. Admin Routes: JWT Token + `isAdmin` check

### File Upload
- Uses Multer for file handling
- Supports: Images, Audio (MP3, M4A, etc.), PDF, EPUB
- Files stored in `uploads/` directory (Railway volume in production)
- Static file serving via `/uploads` endpoint

---

## 🎨 Admin Panel Structure (`admin/`)

### Technology Stack
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **UI Library**: Material-UI (MUI) v5
- **State Management**: Redux Toolkit
- **Data Fetching**: TanStack React Query
- **Routing**: React Router v6
- **Form Handling**: Formik + Yup
- **HTTP Client**: Axios
- **Charts**: Recharts, MUI X Charts

### Directory Structure
```
admin/
├── src/
│   ├── App.tsx              # Main app component with routing
│   ├── main.tsx             # Entry point
│   ├── index.css            # Global styles
│   ├── components/
│   │   ├── Layout/
│   │   │   ├── Layout.tsx   # Main layout wrapper
│   │   │   ├── Header.tsx   # Top navigation bar
│   │   │   └── Sidebar.tsx  # Side navigation menu
│   │   └── Common/
│   │       └── NotificationSystem.tsx
│   ├── pages/               # Page components
│   │   ├── Auth/
│   │   │   └── LoginPage.tsx
│   │   ├── Dashboard/
│   │   │   └── DashboardPage.tsx
│   │   ├── Books/
│   │   │   ├── BooksPage.tsx        # Book list with filters
│   │   │   └── BookFormPage.tsx     # Create/Edit book
│   │   ├── Podcasts/
│   │   │   ├── PodcastsPage.tsx
│   │   │   └── PodcastEpisodesPage.tsx
│   │   ├── Users/
│   │   │   ├── UserManagementPage.tsx
│   │   │   ├── UserDetailPage.tsx
│   │   │   ├── UserAnalyticsPage.tsx
│   │   │   ├── UserActivityPage.tsx
│   │   │   ├── UserSegmentationPage.tsx
│   │   │   └── UserReportsPage.tsx
│   │   ├── Categories/
│   │   │   └── CategoriesPage.tsx
│   │   ├── Analytics/
│   │   │   ├── AnalyticsPage.tsx
│   │   │   └── AdvancedAnalyticsPage.tsx
│   │   ├── Settings/
│   │   │   ├── SettingsPage.tsx
│   │   │   └── SystemSettingsPage.tsx
│   │   ├── Moderation/
│   │   │   └── ContentModerationPage.tsx
│   │   └── Messages/
│   │       └── SendMessagePage.tsx
│   ├── services/
│   │   ├── authAPI.ts       # Authentication API calls
│   │   └── adminAPI.ts      # Admin API calls (books, users, analytics)
│   └── store/
│       ├── index.ts         # Redux store configuration
│       └── slices/
│           ├── authSlice.ts # Authentication state
│           └── [other slices]
└── uploads/                  # Local uploads (dev)
```

### Key Features

#### Authentication
- Login page with email/password
- JWT token stored in localStorage
- Protected routes with admin check
- Auto-redirect to login if not authenticated

#### Book Management
- List all books with pagination, search, filters
- Create/Edit books with file uploads (cover, eBook, audiobook)
- Book status management (featured, new release, premium)
- Bulk operations

#### User Management
- List all users with filters
- User detail view with activity
- User analytics (growth, engagement, retention)
- User segmentation
- User activity logs
- User reports

#### Analytics Dashboard
- Overview metrics (users, books, revenue)
- User growth charts
- Book performance metrics
- Subscription analytics
- Advanced analytics

#### Podcast Management
- List podcasts
- Create/Edit podcasts
- Manage podcast episodes
- Episode upload and metadata

#### Category Management
- Create/Edit/Delete categories
- Multilingual category names

#### Messaging
- Send messages to specific users
- Broadcast messages to all users
- Notification management

### State Management
- **Redux Toolkit** for global state
- **Auth Slice**: User authentication state, token management
- **React Query**: Server state caching and synchronization

### API Integration
- Base URL configured in `authAPI.ts`
- Axios interceptors for token injection
- Error handling and retry logic
- Type-safe API calls with TypeScript

---

## 📱 Mobile App Structure (`mobile/`)

### Technology Stack
- **Framework**: Flutter 3.10+
- **Language**: Dart
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: Go Router
- **HTTP Client**: Dio + Retrofit
- **Local Storage**: Flutter Secure Storage, SQLite (sqflite)
- **Audio**: Just Audio, Audio Service
- **PDF/EPUB**: Syncfusion PDF, WebView for EPUB
- **Notifications**: Firebase Cloud Messaging
- **Localization**: Flutter Intl (English/Somali)
- **UI**: Material Design 3

### Directory Structure
```
mobile/
├── lib/
│   ├── main.dart            # App entry point, BLoC providers
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart      # API base URLs
│   │   │   ├── app_router.dart      # Go Router configuration
│   │   │   └── app_theme.dart       # Theme configuration
│   │   ├── models/                 # Data models
│   │   │   ├── book_model.dart
│   │   │   ├── user_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── podcast_model.dart
│   │   │   └── review_model.dart
│   │   ├── services/               # Core services
│   │   │   ├── localization_service.dart
│   │   │   ├── language_service.dart
│   │   │   ├── theme_service.dart
│   │   │   ├── network_service.dart
│   │   │   ├── download_service.dart
│   │   │   ├── firebase_notification_service.dart
│   │   │   ├── global_audio_player_service.dart
│   │   │   └── teekoob_audio_handler.dart
│   │   ├── bloc/                   # Global BLoCs
│   │   │   ├── notification_bloc.dart
│   │   │   └── theme_bloc.dart
│   │   └── presentation/
│   │       ├── app_scaffold.dart
│   │       └── widgets/
│   │           ├── floating_audio_player.dart
│   │           └── [other widgets]
│   └── features/                    # Feature modules
│       ├── auth/
│       │   ├── bloc/
│       │   │   └── auth_bloc.dart
│       │   ├── services/
│       │   │   └── auth_service.dart
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── splash_page.dart
│       │       │   ├── login_page.dart
│       │       │   ├── register_page.dart
│       │       │   ├── verify_registration_code_page.dart
│       │       │   ├── complete_registration_page.dart
│       │       │   ├── reset_password_page.dart
│       │       │   └── verify_reset_code_page.dart
│       │       └── widgets/
│       │           └── password_field.dart
│       ├── books/
│       │   ├── bloc/
│       │   │   └── books_bloc.dart
│       │   ├── services/
│       │   │   └── books_service.dart
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── books_page.dart
│       │       │   ├── all_books_page.dart
│       │       │   ├── book_detail_page.dart
│       │       │   ├── book_read_page.dart
│       │       │   └── book_audio_player_page.dart
│       │       └── widgets/
│       │           ├── book_card.dart
│       │           ├── book_filters.dart
│       │           └── search_bar.dart
│       ├── library/
│       │   ├── bloc/
│       │   │   └── library_bloc.dart
│       │   ├── services/
│       │   │   └── library_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── library_page.dart
│       ├── player/
│       │   ├── bloc/
│       │   │   └── audio_player_bloc.dart
│       │   ├── services/
│       │   │   ├── audio_player_service.dart
│       │   │   └── audio_state_manager.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── audio_player_page.dart
│       ├── reader/
│       │   ├── bloc/
│       │   │   └── reader_bloc.dart
│       │   ├── services/
│       │   │   └── reader_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── reader_page.dart
│       ├── podcasts/
│       │   ├── bloc/
│       │   │   └── podcasts_bloc.dart
│       │   ├── services/
│       │   │   └── podcasts_service.dart
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── podcast_detail_page.dart
│       │       │   └── podcast_episode_page.dart
│       │       └── widgets/
│       │           ├── podcast_card.dart
│       │           └── podcast_episode_card.dart
│       ├── subscription/
│       │   ├── bloc/
│       │   │   └── subscription_bloc.dart
│       │   ├── services/
│       │   │   └── subscription_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── subscription_page.dart
│       ├── settings/
│       │   ├── bloc/
│       │   │   └── settings_bloc.dart
│       │   ├── services/
│       │   │   └── settings_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           ├── settings_page.dart
│       │           └── notification_settings_page.dart
│       ├── profile/
│       │   ├── services/
│       │   │   └── profile_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── edit_profile_page.dart
│       ├── notifications/
│       │   ├── services/
│       │   │   └── notifications_service.dart
│       │   └── presentation/
│       │       └── pages/
│       │           └── notifications_page.dart
│       └── reviews/
│           ├── services/
│           │   └── reviews_service.dart
│           └── presentation/
│               └── widgets/
│                   ├── rating_widget.dart
│                   ├── comment_section.dart
│                   └── comment_card.dart
├── assets/
│   ├── images/
│   ├── icons/
│   ├── animations/
│   ├── audio/
│   └── fonts/
└── android/ & ios/          # Platform-specific code
```

### Key Features

#### Authentication Flow
1. **Splash Screen** → Check auth state
2. **Login/Register** → Email verification code
3. **Verify Code** → Complete registration
4. **JWT Token** stored in secure storage
5. **Auto-login** on app restart

#### Book Features
- Browse books with filters (category, language, format)
- Search books
- Book detail page with description, reviews
- Read eBook (PDF/EPUB) with progress tracking
- Play audiobook with background audio support
- Add to library
- Mark as favorite
- Bookmarking and notes

#### Library
- View all books in library
- Reading progress tracking
- Bookmarks and notes
- Favorites list
- Offline access (downloaded books)

#### Audio Player
- Background audio playback
- System media controls
- Playback speed control
- Sleep timer
- Progress tracking
- Queue management

#### Reader
- PDF/EPUB reading
- Text size adjustment
- Theme options (light/dark/sepia/night)
- Reading progress sync
- Bookmarks
- Notes

#### Podcasts
- Browse podcasts
- Listen to episodes
- Episode management

#### Subscriptions
- View subscription plans (Free, Premium, Lifetime)
- Upgrade/downgrade
- Payment integration (Stripe)

#### Settings
- Language selection (English/Somali)
- Theme selection
- Notification preferences
- Account management
- Profile editing

#### Notifications
- Firebase Cloud Messaging integration
- Push notifications for new books, updates
- In-app notification center
- Notification preferences

### State Management (BLoC Pattern)
Each feature has:
- **BLoC**: Business logic and state management
- **Service**: API calls and data operations
- **Presentation**: UI pages and widgets

### Navigation
- **Go Router** for declarative routing
- Deep linking support
- Navigation guards for authentication
- Route-based state management

### Localization
- English and Somali language support
- Dynamic language switching
- Localized content from backend

---

## 🔄 Data Flow

### Backend → Admin Panel
1. Admin logs in → JWT token stored
2. API calls with token in Authorization header
3. Redux/React Query manages state
4. MUI components render data

### Backend → Mobile App
1. User authenticates → JWT token in secure storage
2. Dio interceptors add token to requests
3. BLoC handles state and business logic
4. Flutter widgets render UI

### Common API Patterns
- **Pagination**: `page` and `limit` query parameters
- **Filtering**: Query parameters (search, category, language, etc.)
- **Error Handling**: Standardized error responses
- **File Uploads**: Multipart form data
- **Authentication**: JWT Bearer tokens

---

## 🗄️ Database Architecture

### Core Tables
- **users**: User accounts, authentication, preferences
- **books**: Book metadata, content URLs
- **categories**: Book/podcast categories
- **book_categories**: Many-to-many relationship
- **user_library**: User's book collection, reading progress
- **user_favorites**: Favorite books
- **subscriptions**: Subscription plans and billing
- **reviews**: Book reviews and ratings
- **podcasts**: Podcast metadata
- **podcast_parts**: Podcast episodes
- **notifications**: Notification history
- **user_fcm_tokens**: FCM tokens for push notifications
- **notification_preferences**: User notification settings

### Relationships
- Users → Library (One-to-Many)
- Books → Categories (Many-to-Many)
- Users → Reviews (One-to-Many)
- Books → Reviews (One-to-Many)
- Podcasts → Episodes (One-to-Many)

---

## 🔐 Security Features

### Backend
- JWT authentication with expiration
- Password hashing with bcrypt
- Rate limiting (100 requests per 15 minutes)
- Helmet.js security headers
- CORS configuration
- Input validation (express-validator, Joi)
- SQL injection prevention (Knex parameterized queries)

### Admin Panel
- Protected routes with authentication check
- Admin role verification
- Token refresh mechanism
- Secure token storage (localStorage)

### Mobile App
- Secure token storage (flutter_secure_storage)
- Certificate pinning (optional)
- Encrypted offline storage
- Biometric authentication (optional)

---

## 📦 Deployment

### Backend
- **Platform**: Railway (or similar)
- **Database**: MySQL (Railway managed)
- **File Storage**: Railway persistent volume
- **Environment Variables**: Railway secrets

### Admin Panel
- **Platform**: Railway or Vercel
- **Build**: Vite production build
- **Static Hosting**: Served via Railway/Vercel

### Mobile App
- **Android**: Google Play Store
- **iOS**: Apple App Store
- **Build**: Flutter build commands
- **Firebase**: For notifications and analytics

---

## 🚀 Development Workflow

### Backend
```bash
cd backend
npm install
npm run dev        # Development with nodemon
npm start          # Production
npm run migrate    # Run migrations
npm run seed       # Seed database
```

### Admin Panel
```bash
cd admin
npm install
npm start          # Development server (Vite)
npm run build      # Production build
npm run preview    # Preview production build
```

### Mobile App
```bash
cd mobile
flutter pub get
flutter run        # Run on connected device
flutter build apk  # Build Android APK
flutter build ios  # Build iOS app
```

---

## 📝 Key Configuration Files

### Backend
- `package.json` - Dependencies and scripts
- `knexfile.js` - Database configuration
- `.env` - Environment variables
- `railway.json` - Railway deployment config

### Admin
- `package.json` - Dependencies and scripts
- `vite.config.ts` - Vite build configuration
- `tsconfig.json` - TypeScript configuration
- `.env.production.example` - Production env template

### Mobile
- `pubspec.yaml` - Flutter dependencies
- `lib/core/config/app_config.dart` - API configuration
- `android/` & `ios/` - Platform-specific configs

---

## 🔗 Integration Points

1. **Backend ↔ Admin**: REST API with JWT authentication
2. **Backend ↔ Mobile**: REST API with JWT authentication
3. **Firebase**: Push notifications for mobile app
4. **Stripe**: Payment processing for subscriptions
5. **Resend**: Email service for verification codes
6. **AWS S3** (optional): File storage for books/audio

---

## 📊 Current Status

### ✅ Completed
- User authentication (email verification flow)
- Book management (CRUD operations)
- User library with progress tracking
- Admin panel with full content management
- Mobile app with reading/listening capabilities
- Push notifications
- Multilingual support (English/Somali)
- Podcast support
- Reviews and ratings

### 🔄 In Progress / Planned
- Offline mode enhancements
- Advanced analytics
- Payment gateway integration
- Social features
- AI recommendations

---

This structure provides a comprehensive overview of the Teekoob project architecture, making it easier to understand the codebase and navigate between components.

