# 📱 Loan Tracker - Smart Finance Manager

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-green?style=for-the-badge)](https://flutter.dev)

**Loan Tracker** is a premium, high-performance financial management application built with Flutter. It is designed to provide users with a sophisticated, elegant, and private way to track loans, manage amortizations, and visualize their journey toward financial freedom.

Designed with **iOS-first aesthetics**, the app features a stunning Glassmorphism UI, smooth animations, and a secure local-first architecture.

---

## ✨ Key Features

- **🚀 Elegant Onboarding**: A seamless, animated introduction to the app's core value propositions.
- **📊 Advanced Analytics**: High-quality charts (using `fl_chart`) to visualize debt reduction and payment progress.
- **📑 PDF Reports**: Professional amortization schedules and loan summaries exported as high-quality PDFs.
- **🛡️ Biometric Security**: Secure your financial data with FaceID or Fingerprint authentication.
- **🌗 Full Dark Mode**: A meticulously crafted dark theme that looks stunning on OLED screens.
- **💰 Multi-Currency Support**: Default to USD ($) with global configuration options.
- **📱 Native Performance**: Smooth 60fps animations and haptic feedback for a premium feel.
- **🔒 Privacy First**: All data is stored locally on the device (SQLite/SharedPreferences). No cloud tracking.

---

## 🎨 UI & Design Principles

The application follows modern design trends:
- **Glassmorphism**: Translucent cards and blurred backgrounds for depth.
- **Dynamic Gradients**: Color-coded loan categories for quick identification.
- **Haptic Feedback**: Meaningful vibrations for every interaction.
- **Modern Typography**: Using Google Fonts (Inter) for maximum readability.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **Icons**: [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- **Animations**: [Flutter Staggered Animations](https://pub.dev/packages/flutter_staggered_animations)
- **Reports**: [Printing & PDF](https://pub.dev/packages/pdf)

---

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sadiq990/loantracker.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Generate Assets (Icons/Splash):**
   ```bash
   dart run flutter_launcher_icons:main
   dart run flutter_native_splash:create
   ```
4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📄 License & Credits

- **Made by**: Fibontech
- **License**: MIT

---
*Built with ❤️ for a better financial future.*
