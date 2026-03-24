# Loan Tracker - Smart Finance Manager

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-green?style=for-the-badge)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

**Loan Tracker** is a premium, high-performance financial management application built with Flutter. It is designed to provide users with a sophisticated, elegant, and private way to track loans, manage amortizations, and visualize their journey toward financial freedom.

Designed with **iOS-first aesthetics**, the app features a stunning Glassmorphism UI, smooth animations, and a secure local-first architecture.

---

## Key Features

- **Advanced Analytics**: High-quality charts to visualize debt reduction and payment progress
- **Interest Saving Logic**: Smart calculations that reflect real-time interest savings when you make extra payments
- **Smart Amortization**: Rebuilt amortization engine with chronological 1:1 payment mapping
- **Payoff Strategies**: Toggle between *Reduce Term* and *Reduce Payment* strategies
- **PDF Reports**: Professional amortization schedules exported as high-quality PDFs
- **Biometric Security**: Secure your data with FaceID, TouchID, or PIN fallback
- **Full Dark Mode**: Meticulously crafted dark theme for OLED screens
- **Multi-Currency Support**: USD ($), EUR (€), GBP (£), and more
- **Native Performance**: Smooth 60fps animations with haptic feedback
- **Privacy First**: All data stored locally - no cloud tracking or external servers

---

## Screenshots

*The app features a stunning Glassmorphism UI with:*
- Dashboard with loan overview
- Detailed loan tracking with progress rings
- Amortization schedule visualization
- Payoff simulator for planning

---

## Tech Stack

| Component | Technology |
|----------|-----------|
| Framework | Flutter |
| State Management | Provider |
| Local Storage | SharedPreferences + Hive |
| Charts | fl_chart |
| Animations | flutter_staggered_animations |
| PDF Generation | pdf + printing |
| Biometrics | local_auth |

---

## Recent Updates & Quality Assurance

### ✅ Latest Release
- **Professional QA Testing**: Comprehensive testing across 11 categories completed
- **Bug Fix**: Fixed TextEditingController memory leak in Quick Payment feature
- **Enhanced Features**: 
  - Improved payment date matching algorithm (month-based, not index-based)
  - Payment status indicators in PDF exports (✓ checkmarks)
  - Extra payment impact preview (Reduce Term/Reduce Payment strategies)

### 📊 Quality Metrics
- **Test Coverage**: 11 comprehensive QA categories
- **Critical Issues**: 0 (1 found and fixed)
- **Code Quality**: All linting issues resolved
- **Performance**: Fast load times (<1s for 10 loans), optimized memory usage

For detailed test results, see [QA_TESTING_REPORT.md](QA_TESTING_REPORT.md)

---

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sadiq990/LoanCalculator.git
   cd LoanCalculator
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate App Icons:**
   ```bash
   dart run flutter_launcher_icons:main
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Building for Production

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
```

---

## Privacy & Security

- All financial data is stored **locally on your device**
- No data is transmitted to external servers
- Biometric authentication (FaceID/TouchID) supported
- PIN fallback for additional security
- No tracking, analytics, or advertising

---

## App Store Information

### Supported Platforms
- iOS 12.0+
- Android API 21+ (Android 5.0+)

### Categories
- Finance
- Productivity

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact & Support

- **Email**: support@loantracker.app
- **Privacy Policy**: Available in-app
- **Terms of Service**: Available in-app

---

*Built with ❤️ for a better financial future.*
