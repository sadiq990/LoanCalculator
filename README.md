# Loan Tracker: Payoff Planner

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20(iPhone)%20%7C%20Android-green?style=for-the-badge)](https://flutter.dev)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local-blue?style=for-the-badge)](#privacy--security)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

**Loan Tracker** is an iOS-first, privacy-first loan tracker and payoff planner designed for the US and EU App Store. It is engineered with a strict local-only data architecture: no cloud accounts, no third-party tracking, and no external analytics.

---

## Key Features

- **Root Navigation Shell (Four Premium Tabs)**:
  - **Home (My Loans)**: Comprehensive dashboard with active debt balance, accrued interest tracking, loan lifecycle management, payment logging, and quick-payment sheets.
  - **Calculator Tab**: Bank-grade interactive loan simulation (inspired by ABB Bank / modern digital banks) with instant live recalculation, interactive sliders, quick-preset chips (amount, term, rate), monthly payment hero card, total interest, total repaid, and cent-rounding adjustment notes. Integrates a **"Your current loans"** overview strip linking active debts, and a **"Save as loan"** action that pre-fills the loan creation wizard.
  - **Statistics Tab**: Financial analytics, interactive payoff charts (`fl_chart`), debt breakdown, and payoff projections.
  - **Settings Tab**: Currency selection, theme mode, security & Face ID/PIN locks, data backup/restore, and CSV/PDF export.
- **Configurable Startup Tab ("Open app on")**: Choose whether the app launches on **Calculator**, **My Loans**, or **Last used** (persisted in preferences; fresh installs with no loans default to the Calculator tab).
- **Amortization Engine**: Accurate monthly amortization schedules with penny-perfect interest rounding, exact term cutoff handling (QA-02), support for long-term loans (up to 40+ years / 480–600 months), and zero-interest loans.
- **Accrued Interest vs. Principal Separation (F-06)**: Clear distinction between remaining principal debt balance and simple uncompounded accrued interest since the last payment period.
- **Payoff Strategies**: Simulate extra payments with **Reduce Term** (shorten loan duration) or **Reduce Payment** (lower monthly obligation) modes.
- **Data Backup & Restore (JSON)**: Full schema-versioned JSON backup export via iOS Share Sheet and file picker import with **Merge** or **Replace** conflict resolution.
- **CSV & PDF Export**: Export full amortization schedules to CSV for spreadsheet analysis or generate high-quality printable PDF reports.
- **Hardware-Backed Security**: 
  - Biometric authentication (Face ID / Touch ID) with PIN fallback.
  - Salted PBKDF2-HMAC-SHA256 PIN derivation stored securely in iOS Keychain via `flutter_secure_storage` (`first_unlock_this_device`).
  - Automatic Keychain cleanup on fresh reinstall preventing orphaned lockouts.
  - Progressive brute-force protection with escalating lockout delays (30s, 1m, 5m, 15m).
  - App Switcher Privacy Veil covering financial figures across both tabs whenever the app is inactive.
  - Auto-lock timeout options (Immediately, 1 minute, 5 minutes).
- **Locale-Aware Currency**: Automatically detects device locale currency symbol (with USD fallback) with full manual currency selection support.
- **Dark & Light Mode**: Premium modern glassmorphism design with OLED-optimized dark theme and full VoiceOver Semantics support.

---

## Architecture & Tech Stack

| Component | Technology / Implementation |
|-----------|-----------------------------|
| Framework | Flutter (Stable channel) |
| State Management | Provider |
| Primary Storage | Hive (encrypted/isolated box files with backup protection) |
| Secure Storage | iOS Keychain via `flutter_secure_storage` |
| Settings Storage | `shared_preferences` |
| Authentication | `local_auth` (Face ID / Touch ID) + `cryptography` (PBKDF2) |
| Data Export | `share_plus`, `file_picker`, `pdf`, `printing` |
| Charts | `fl_chart` |

---

## App Store & Apple Compliance

- **Bundle Identifier**: `com.loancalculator.app`
- **Minimum iOS Version**: iOS 14.0+ (Targeted Device Family: iPhone)
- **Encryption**: `ITSAppUsesNonExemptEncryption = false` declared in `Info.plist`.
- **Privacy Manifest**: `ios/Runner/PrivacyInfo.xcprivacy` declared in Xcode Copy Bundle Resources:
  - `NSPrivacyTracking = false`
  - Zero data collection categories (`NSPrivacyCollectedDataTypes` is empty).
  - Required reasons declared for `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`) and `NSPrivacyAccessedAPICategoryFileTimestamp` (`C617.1`).
- **Permissions**: `NSFaceIDUsageDescription` configured with user-facing explanation.
- **Disclaimers**: Financial informational disclaimer displayed in loan details, amortization views, PDF exports, and About screen.

> [!NOTE]
> Scheduled push notifications / reminders are deferred (`kRemindersEnabled = false`) for v1.0. Auxiliary platform directories (`windows`, `linux`, `macos`, `web`) are retained in the codebase for multi-platform tooling but excluded from mobile store distribution.

---

## Data Safety & Backup

All loan records and payment logs exist solely on the user's physical device:
1. **JSON Backup Export**: Generates a version-tagged backup (`LoanTracker-Backup-YYYY-MM-DD.json`) containing all loan data and user preferences. Sensitive Keychain secrets (PIN/salt) are never included in backups.
2. **JSON Backup Import**: Validates schema version (`schemaVersion: 1`), previews loan count and export date, and lets the user choose between **Merge** (upserts non-duplicate loans) or **Replace** (atomically replaces all records).
3. **Database Integrity Protection**: If a database box is unreadable on launch, a damaged-file backup (`loans.hive.bak`) is created rather than wiping user data.

---

## Getting Started

### Prerequisites
- Flutter 3.x SDK
- Xcode 15+ / CocoaPods (for iOS)
- Android Studio / SDK (for Android)

### Running Locally
```bash
# Get dependencies
flutter pub get

# Run tests (amortization, Hive roundtrip, PBKDF2 security, backup validation)
flutter test

# Run static analysis
flutter analyze

# Launch on connected iOS simulator or device
flutter run
```

### Release Build
```bash
# iOS IPA (requires distribution certificates / provisioning profiles)
flutter build ipa --release
```

---

## CI/CD Pipeline

The project includes `codemagic.yaml` configured for automated App Store Connect / TestFlight builds with:
- Apple App Store Connect API key authentication (`APP_STORE_CONNECT_KEY`)
- Automatic code signing and provisioning profile management
- Xcode archive and TestFlight deployment

---

## Financial Disclaimer

Loan Tracker is an independent financial calculation and organizational tool provided for educational and informational purposes only. It does not provide financial advice, loan origination, lending services, or credit counseling. Actual loan terms, interest calculations, and payoff dates may vary depending on lender compounding methods, fee structures, and loan contracts.

---

## 🇦🇿 Görülən İşlər və Layihə Yenilikləri

Bu layihədə App Store tələblərinə və istifadəçi istəklərinə uyğun olaraq aşağıdakı əsas dəyişikliklər və təkmilləşdirmələr edilmişdir:

### 1. Bundle ID və App Store Uyğunluğu
- Bütün layihə boyu (`project.pbxproj`, `codemagic.yaml`, sənədlər, testlər) standart placeholder-lar silindi və vahid rəsmi Bundle ID təyin edildi: `com.loancalculator.app` (və `com.loancalculator.app.RunnerTests`).
- Apple-ın ən son tələblərinə uyğun `PrivacyInfo.xcprivacy` manifest faylı əlavə edildi (`NSPrivacyTracking = false`, icazəli API kateqoriyaları `CA92.1` və `C617.1`).
- Şifrələmə bəyannaməsi (`ITSAppUsesNonExemptEncryption = false`) və Face ID icazə bildirişi (`NSFaceIDUsageDescription`) iOS konfiqurasiyasına daxil edildi.
- TestFlight və App Store avtomatlaşdırılmış quraşdırması üçün `codemagic.yaml` CI/CD boru xətti hazırlandı.

### 2. Təhlükəsizlik və Keychain Yenilənməsi
- **Təkrar Quraşdırma (Reinstall) Təmizliyi:** Tətbiq silinib yenidən yazıldıqda, köhnə Keychain-də qala biləcək PIN kodu, salt və kilid sayğaclarının aradan qaldırılması üçün `SecurePinService.cleanupOrphanedKeychainOnFreshInstall` mexanizmi quruldu.
- **Gücləndirilmiş Təhlükəsizlik:** PBKDF2-HMAC-SHA256 və salt ilə PIN şifrələməsi, Face ID / Touch ID biometriyası, pilləli gözləmə müddətləri olan brute-force qoruması (30 san, 1 dəq, 5 dəq, 15 dəq) və App Switcher örtüyü (Privacy Veil).

### 3. Amortizasiya və Dəqiq Yuvarlaqlaşdırma (QA-02)
- Ay sayı kredit müddətinə çatdıqda (`month >= termMonths`) qalıq borcun qəpiyinə qədər sıfırlanması təmin edildi.
- 40 illik (480 ay) və 50 illik (600 ay) kreditlərdə də cədvəlin heç vaxt müddətdən artıq sətir göstərməməsi və ödənişlərin cəminin əsas borc + faiz cəminə tam (1 qəpik dəqiqliyi ilə) bərabər olması təmin edildi.

### 4. Baza İdarəedicisi Sabitliyi (QA-03)
- `DatabaseHelper.close()` funksiyasında `_initialized = false` parametri `finally` blokuna keçirildi, bazanın təkrar və ya xətalı bağlanması zamanı singleton vəziyyətinin pozulması tam aradan qaldırıldı.

### 5. Faizlə Əsas Borcun Ayrılması (F-06)
- Qalıq borc (`remainingDebt`) semantikası yenilənərək yalnız **əsas borcu (Principal)** əks etdirir (faizlər əsas borcun üzərinə kapitallaşdırılmır).
- Son ödənişdən bu günə qədər hesablanmış sadə faiz üçün ayrıca `accruedInterest` sahəsi yaradıldı və həm əsas ekranda, həm də kredit detallarında ayrıca sətir kimi təqdim edildi.

### 6. İnteraktiv Kredit Kalkulyatoru Tabı (ABB Bank Tərzi)
- **4 Tablı Shell Arxitekturası:** Tətbiq alt naviqasiya paneli ilə 4 taba bölündü:
  1. **Ana Səhifə (Kreditlərim)**
  2. **Kalkulyator**
  3. **Statistika**
  4. **Tənzimləmələr**
- **İnteraktiv İkili Nəzarət:** Məbləğ, Faiz və Müddət üçün həm canlı slayderlər, həm sürətli seçim düymələri (Quick Chips: `$1 000` - `$100 000`), həm də sərbəst mətn sahələri əlavə edildi.
- **Böyük Məbləğ Dəstəyi (500.000+):** Əllə `500000` və ya Azərbaycan/Avropa standartında `500.000` yazıldıqda sistem xəta vermir, dərhal dəqiq aylıq ödənişi hesablayır və yeni kreditə ötürür.
- **Canlı Nəticələr Kartı:** Aylıq ödəniş, əlavə faiz məbləği, ümumi qaytarılacaq məbləğ, faiz nisbəti və son qəpik yuvarlaqlaşdırması qeydi ("Last payment: X").
- **Mövcud Kreditlərlə Əlaqə ("Your current loans"):** Əgər aktiv kreditlər varsa, ümumi aylıq ödəniş və qalıq əsas borc kartı görünür; həmçinin yeni kreditlə birlikdə ümumi aylıq yük ("Total monthly payments with this loan: current X + new Y = Z") dərhal göstərilir.
- **Kredit Kimi Yadda Saxla ("Save as loan"):** Kalkulyatorda hesablanmış məbləğ, faiz və müddət parametrləri bir toxunuşla yeni kredit əlavəetmə ekranına (`AddLoanScreen`) ötürülür.
- **Kross-Tab Sinxronizasiyası (Bug Fix):** Kalkulyatordan kredit yadda saxlandıqda `storage.revision` vasitəsilə dərhal Ana səhifəyə və Statistikaya ötürülür, heç bir manual yeniləməyə ehtiyac qalmır.
- **"Tətbiqi buradan başlat" Tənzimləməsi:** İstifadəçi tətbiqin açılışda Kalkulyator, Kreditlərim və ya Son istifadə edilən tab ilə açılmasını seçə bilər (borcu olmayan təzə istifadəçilərdə birbaşa Kalkulyator açılır).

### 7. Veb Uyğunluğu və Başlanğıc Crash Fix
- Flutter Web mühitində `Platform.localeName` çağırışının yaratdığı çöküş aradan qaldırıldı (`kIsWeb` yoxlamaları əlavə edildi).
- Tətbiq həm iOS/Android mobil cihazlarında, həm də brauzer üzərində (`localhost:8080`) problemsiz işləyir.

### 8. Kod Keyfiyyəti və Testlər
- `flutter analyze`: **0 xəta, 0 xəbərdarlıq (No issues found!)**
- `flutter test`: **275 / 275 testin hamısı 100% uğurla keçir** (Amortizasiya riyazi dəqiqlik testləri, 210-kombinasiyalı xüsusiyyət testləri, Hive baza testi, PBKDF2/Keychain təhlükəsizlik testləri və Kalkulyator widget inteqrasiya testləri daxil olmaqla).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
