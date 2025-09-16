# 📖 Teekoob - Multilingual eBook & Audiobook Platform

A comprehensive digital library platform supporting multiple languages with seamless reading/listening sync, offline access, and subscription monetization.

## 🎯 Features

- **Multilingual Support**: Somali + English (expandable)
- **Dual Format**: eBook (EPUB/PDF) + Audiobook (MP3)
- **Cross-Platform**: iOS, Android, Web, Desktop
- **Offline Access**: Download books for offline reading/listening
- **Subscription Plans**: Free, Premium, Lifetime
- **Cloud Sync**: Seamless progress across devices

## 🏗 Project Structure

```
teekoob/
├── mobile/                 # Flutter mobile app
├── backend/                # Node.js backend API
├── web/                    # React web application
├── shared/                 # Shared types and utilities
├── docs/                   # Documentation
└── scripts/                # Build and deployment scripts
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Flutter 3.10+
- PostgreSQL
- Docker (optional)

### Backend Setup
```bash
cd backend
npm install
npm run dev
```

### Mobile App Setup
```bash
cd mobile
flutter pub get
flutter run
```

### Web App Setup
```bash
cd web
npm install
npm start
```

## 📱 Development Phases

1. **Phase 1**: Core System (Auth, Library, Reader, Player, Payments)
2. **Phase 2**: Offline Mode, Search, Sync
3. **Phase 3**: Community Features, AI, Gamification
4. **Phase 4**: Web + Desktop Expansion

## 🌟 Tech Stack

- **Frontend**: Flutter (Mobile), React (Web)
- **Backend**: Node.js + Express
- **Database**: PostgreSQL
- **Storage**: AWS S3
- **Payments**: Stripe, Google Play, Apple IAP
- **Notifications**: Firebase Cloud Messaging

## 📄 License

MIT License - see LICENSE file for details
