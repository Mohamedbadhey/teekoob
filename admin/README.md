# 📚 Teekoob Admin Panel

A modern, feature-rich admin panel for the Teekoob multilingual eBook and audiobook platform, built with React.js and Material-UI.

## ✨ Features

### 🎯 Core Management
- **Dashboard Overview** - Real-time analytics and key metrics
- **Book Management** - Add, edit, delete, and manage books with file uploads
- **User Management** - Monitor users, manage subscriptions, and control access
- **Category Management** - Organize content with multilingual categories
- **Content Moderation** - Review and manage flagged content

### 📊 Analytics & Insights
- **User Growth Charts** - Visualize user acquisition trends
- **Book Performance Metrics** - Track popular content and ratings
- **Revenue Analytics** - Monitor subscriptions and financial metrics
- **Content Distribution** - Language and format breakdowns
- **Custom Time Ranges** - Flexible period selection for analysis

### 🔧 System Administration
- **Feature Flags** - Toggle platform features on/off
- **System Limits** - Configure upload limits and user restrictions
- **Security Settings** - Manage authentication and verification requirements
- **Notification Preferences** - Control system-wide notification settings
- **Backup & Restore** - System backup management

### 📱 Modern UI/UX
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Material Design 3** - Modern, accessible interface
- **Dark/Light Themes** - User preference support
- **Real-time Updates** - Live data with React Query
- **Drag & Drop** - Intuitive file uploads

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Teekoob backend running on port 3000

### Installation

1. **Clone and navigate to admin directory**
```bash
cd admin
```

2. **Install dependencies**
```bash
npm install
```

3. **Start development server**
```bash
npm start
```

4. **Open in browser**
```
http://localhost:3001
```

### Build for Production
```bash
npm run build
```

## 🏗 Architecture

### Tech Stack
- **Frontend**: React 18 + TypeScript
- **UI Framework**: Material-UI (MUI) v5
- **State Management**: Redux Toolkit
- **Data Fetching**: TanStack React Query
- **Routing**: React Router v6
- **Build Tool**: Vite
- **Charts**: Recharts

### Project Structure
```
admin/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── Layout/         # Main layout components
│   │   └── Common/         # Shared components
│   ├── pages/              # Page components
│   │   ├── Auth/           # Authentication pages
│   │   ├── Dashboard/      # Dashboard and analytics
│   │   ├── Books/          # Book management
│   │   ├── Users/          # User management
│   │   ├── Categories/     # Category management
│   │   ├── Analytics/      # Detailed analytics
│   │   └── Settings/       # System settings
│   ├── services/           # API services
│   ├── store/              # Redux store and slices
│   └── types/              # TypeScript type definitions
├── public/                 # Static assets
└── package.json            # Dependencies and scripts
```

## 🔐 Authentication

The admin panel uses JWT-based authentication:

1. **Login** - Admin credentials required
2. **Token Storage** - Secure localStorage with automatic refresh
3. **Route Protection** - All admin routes require authentication
4. **Role-based Access** - Admin privileges required for all operations

## 📚 Book Management

### Adding Books
1. Navigate to **Books** → **Add New Book**
2. Fill in book details (English & Somali)
3. Upload cover image, eBook file, and audio file
4. Set pricing and features
5. Save and publish

### Book Features
- **Multilingual Support** - English, Somali, Arabic
- **Multiple Formats** - eBook, Audiobook, or Both
- **File Management** - Drag & drop uploads
- **Bulk Operations** - Mass update/delete
- **Export Options** - CSV and Excel formats

## 👥 User Management

### User Operations
- **View Profiles** - Complete user information
- **Status Management** - Activate/deactivate users
- **Subscription Control** - Manage user plans
- **Library Access** - Monitor user reading activity
- **Export Data** - Download user information

### User Analytics
- **Growth Trends** - User acquisition over time
- **Subscription Metrics** - Plan distribution and revenue
- **Activity Tracking** - Login patterns and engagement

## 📊 Analytics Dashboard

### Key Metrics
- **Total Users** - Registered user count
- **Total Books** - Published content count
- **Active Subscriptions** - Premium user count
- **Monthly Revenue** - Financial performance

### Charts & Visualizations
- **User Growth** - Line charts with time selection
- **Content Distribution** - Pie charts for languages/formats
- **Performance Metrics** - Bar charts for top books
- **Revenue Analytics** - Financial trend analysis

## ⚙️ System Settings

### Feature Flags
- User registration toggle
- Social login options
- Offline mode support
- Multi-language features
- Push notifications
- Analytics tracking

### Security Configuration
- Email verification requirements
- Phone verification options
- Two-factor authentication
- Session timeout settings
- Login attempt limits

### System Limits
- Maximum file upload sizes
- Books per user limits
- Offline download limits
- Daily upload restrictions

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the admin directory:

```env
VITE_API_URL=http://localhost:3000/api/v1
VITE_APP_NAME=Teekoob Admin
VITE_APP_VERSION=1.0.0
```

### API Configuration
The admin panel connects to the Teekoob backend API:

- **Base URL**: Configurable via environment variables
- **Authentication**: JWT token-based
- **Endpoints**: RESTful API with admin-specific routes
- **File Uploads**: Multipart form data support

## 🚀 Deployment

### Production Build
```bash
npm run build
```

### Docker Deployment
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3001
CMD ["npm", "start"]
```

### Environment Setup
- Configure API endpoints for production
- Set up SSL certificates
- Configure reverse proxy (nginx/Apache)
- Set up monitoring and logging

## 🧪 Development

### Available Scripts
- `npm start` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - TypeScript type checking

### Code Style
- **ESLint** - Code quality and consistency
- **Prettier** - Code formatting
- **TypeScript** - Type safety and IntelliSense
- **Material-UI** - Component design system

### Testing
- **Unit Tests** - Component and utility testing
- **Integration Tests** - API and state management
- **E2E Tests** - User workflow testing

## 🔒 Security Features

- **JWT Authentication** - Secure token-based auth
- **Route Protection** - Admin-only access
- **Input Validation** - Form and API validation
- **XSS Protection** - Content security policies
- **CSRF Protection** - Cross-site request forgery prevention

## 📱 Responsive Design

The admin panel is fully responsive and works on:

- **Desktop** - Full feature set with side navigation
- **Tablet** - Optimized layout for medium screens
- **Mobile** - Touch-friendly interface with bottom navigation

## 🌐 Internationalization

- **Multi-language Support** - English, Somali, Arabic
- **RTL Support** - Right-to-left language layouts
- **Localized Content** - Language-specific book management
- **Cultural Adaptation** - Region-specific features

## 🔄 API Integration

### Backend Endpoints
- `/api/v1/admin/books` - Book management
- `/api/v1/admin/users` - User management
- `/api/v1/admin/analytics` - Analytics data
- `/api/v1/admin/settings` - System configuration

### Data Flow
1. **React Query** - Data fetching and caching
2. **Redux Store** - Global state management
3. **API Services** - HTTP client with interceptors
4. **Real-time Updates** - Automatic data refresh

## 📈 Performance

- **Code Splitting** - Lazy-loaded routes and components
- **Image Optimization** - Compressed and responsive images
- **Caching Strategy** - React Query caching and invalidation
- **Bundle Optimization** - Tree shaking and minification

## 🐛 Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Check backend server status
   - Verify API URL configuration
   - Check network connectivity

2. **Authentication Errors**
   - Clear browser localStorage
   - Check JWT token validity
   - Verify admin credentials

3. **File Upload Issues**
   - Check file size limits
   - Verify file type restrictions
   - Ensure proper permissions

### Debug Mode
Enable debug logging in development:

```typescript
// In src/services/authAPI.ts
const DEBUG = import.meta.env.DEV
if (DEBUG) console.log('API Request:', config)
```

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

### Code Standards
- Follow TypeScript best practices
- Use Material-UI components consistently
- Implement proper error handling
- Add comprehensive documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Documentation**: Check this README and inline code comments
- **Issues**: Report bugs via GitHub issues
- **Discussions**: Use GitHub discussions for questions
- **Email**: Contact the development team

---

**Built with ❤️ for the Teekoob platform**

*Empowering multilingual literacy through technology*
