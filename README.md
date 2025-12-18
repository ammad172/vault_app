# 🔐 VaultLock - Secure Password Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20|%20Android-lightgrey.svg)](https://flutter.dev/)

**VaultLock** is a premium, cross-platform password manager built with Flutter, featuring military-grade encryption, biometric authentication, and seamless cloud backup.

## ✨ Features

### 🔒 **Security First**
- **Military-Grade Encryption**: AES-256 encryption for vault data
- **PBKDF2 Password Hashing**: 600,000 iterations (OWASP 2024 standard)
- **Biometric Authentication**: Touch ID, Face ID, fingerprint support
- **Auto-Lock**: Configurable session timeout (1-60 minutes)
- **Rate Limiting**: Protection against brute force attacks
- **Zero-Knowledge**: Your data never leaves your device unencrypted

### 💎 **Premium Features**
- **Password Generator**: Create cryptographically secure passwords
  - Random passwords (8-64 characters)
  - Passphrase generation for memorability
  - Real-time strength indicator
  - Configurable character sets
- **Smart Organization**: Categories, search, and filtering
- **Cloud Backup**: Optional Google Drive sync
- **Cross-Platform**: iOS, Android, Web, macOS, Windows, Linux

### 🎨 **Modern Design**
- Material Design 3 with dynamic colors
- Dark mode support
- Smooth animations and transitions
- Intuitive, clean interface
- Google Fonts (Inter) for premium typography

## 📱 Screenshots

*Coming soon - Add screenshots here*

## 🚀 Getting Started

### Prerequisites
- Flutter 3.10.4 or higher
- Dart SDK 3.10.4 or higher
- iOS 12.0+ / Android 5.0+ (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/vault_app.git
   cd vault_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Development mode
   flutter run

   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release
```

## 🏗️ Architecture

VaultLock follows a clean, service-oriented architecture:

```
lib/
├── models/          # Data models (VaultEntry)
├── services/        # Business logic layer
│   ├── backup_service.dart
│   ├── password_generator_service.dart
│   ├── secure_storage_service.dart
│   ├── session_manager.dart
│   └── vault_service.dart
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

### Key Technologies
- **State Management**: Riverpod + Hive listeners
- **Local Storage**: Hive (encrypted)
- **Secure Storage**: flutter_secure_storage (Keychain/Keystore)
- **Cloud Backup**: Google Drive API
- **Cryptography**: pointycastle (PBKDF2), crypto
- **Authentication**: local_auth, google_sign_in, sign_in_with_apple

## 🔐 Security

### Encryption Details
- **Algorithm**: AES-256-CBC
- **Key Derivation**: PBKDF2-HMAC-SHA256
- **Iterations**: 600,000 (OWASP recommendation)
- **Salt**: Randomly generated 128-bit salt per user
- **Storage**: Platform secure storage (iOS Keychain, Android Keystore)

### Security Features
- **No cloud storage** of unencrypted data
- **Client-side encryption** before any cloud backup
- **Automatic clipboard clearing** (30 seconds)
- **Session timeout** with auto-lock
- **Failed attempt tracking** and lockout
- **No analytics or telemetry**

### Threat Model
VaultLock protects against:
- ✅ Device compromise (encrypted at rest)
- ✅ Cloud backup interception (encrypted before upload)
- ✅ Brute force attacks (PBKDF2 + rate limiting)
- ✅ Shoulder surfing (password masking, auto-lock)

Does NOT protect against:
- ❌ Keyloggers on your device
- ❌ Compromised operating system
- ❌ Forgotten master password (irrecoverable)

## 💰 Monetization

**Subscription Model:**
- **Monthly**: $3.00/month
- **Annual**: $30.00/year (save 17%)

**Premium Features:**
- Unlimited vault entries
- Cloud backup & sync
- Priority support
- Early access to new features

## 📄 Privacy

VaultLock is privacy-first:
- **No registration required** (works completely offline)
- **No analytics or tracking**
- **No ads**
- **Open source** (MIT License)

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for full details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Known Issues

- Flutter must be in PATH to run `flutter pub get`
- First build may take longer due to dependency resolution

## 📮 Support

- **Email**: support@vaultlock.app
- **Website**: https://vaultlock.app
- **Issues**: https://github.com/yourusername/vault_app/issues

## 🗺️ Roadmap

- [ ] Password health audit
- [ ] Breach monitoring integration
- [ ] Browser extensions (Chrome, Firefox, Safari)
- [ ] File attachments support
- [ ] Family sharing plans
- [ ] Hardware key support (YubiKey)
- [ ] Self-hosted sync option

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- OWASP for security recommendations

---

**Made with ❤️ and Flutter**

*Secure your digital life with VaultLock*
