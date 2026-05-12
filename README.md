# 🍚 AI Ration Mitra

A comprehensive Flutter application for managing public ration distribution with AI-powered support and real-time tracking.

## ✨ Features

- **Multi-Role Access**: Citizen, FPS Dealer, and Admin dashboards
- **AI Assistant**: Gemini AI-powered support for user queries
- **Ration Management**: Track entitlements, bookings, and distribution
- **Real-time Notifications**: Push notifications for updates
- **Family Management**: Manage family members and beneficiaries
- **Grievance System**: Submit and track complaints
- **FPS Locator**: Find nearby Fair Price Shops
- **Analytics**: Admin dashboard with statistics and insights
- **Multi-Language Support**: Localization support

## 🛠 Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Authentication, Cloud Messaging)
- **AI Integration**: Google Gemini API
- **State Management**: Provider
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux

## 📱 Screenshots

- **Citizen Dashboard**: View entitlements and upcoming distributions
- **FPS Dealer**: Manage stock, beneficiaries, and distributions
- **Admin Panel**: Analytics, notifications, and stock management
- **AI Chat**: Get instant help from AI assistant

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Firebase account
- Google Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MOHAMMED-FAIZAN-KHAN/ai_ration_mitra-main--1-.git
   cd ai_ration_mitra-main
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Set up environment variables**
   - Create `.env` file with Gemini API key

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── core/                  # Core utilities & constants
├── models/                # Data models
├── screens/               # UI screens
│   ├── admin/
│   ├── citizen/
│   ├── fps_dealer/
│   ├── auth/
│   └── chat/
├── services/              # Business logic & APIs
├── providers/             # State management
├── widgets/               # Reusable widgets
└── navigation/            # Navigation setup
```

## 🔐 Security

- Sensitive files are excluded from git (see `.gitignore`)
- Firebase credentials not committed
- API keys managed via environment variables

## 📝 License

This project is licensed under the MIT License.

## 👤 Author

**Mohammed Faizan Khan**

---

**Happy Distribution! 🎉**
