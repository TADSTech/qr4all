# QR4All - QR Code Generator & Scanner

QR4All is a powerful cross-platform **Flutter application** for generating and scanning QR codes with support for **mobile (Android/iOS) and web**. Featuring advanced customization, multiple data types, and seamless sharing capabilities.

## 🚀 Features

### 🔹 QR Code Generation
- **10+ Supported Data Types:**
  - Text, URLs, Email, Phone, SMS
  - WiFi, Contact, Location, Event, Cryptocurrency
- **Advanced Customization:**
  - Custom QR and background colors
  - Adjustable quiet zone and error correction
  - Toggle app-specific tagging
- **Export Options:**
  - Share via native sharing
  - Download as PNG (mobile/web)

### 🔹 QR Code Scanning
- **Real-time Camera Scanning**
- **Image Upload Support**
- **Smart QR Tag Handling** (QR4ALL:type:data format)
- **Action Execution** (open URLs, send SMS, etc.)
- **Scan History** with copy/delete functionality

### 🔹 Cross-Platform
- **Mobile:** Android & iOS
- **Web:** Full PWA support
- **Responsive UI** for all screen sizes

## 🎨 New in v2.0
- **Theming System** with 36+ color schemes
- **Dark/Light Mode** with system adaptation
- **Enhanced UI/UX** with Material 3 design
- **Improved Performance** for web and mobile
- **Better Error Handling** and user feedback

## 📸 Screenshots

| Generate QR Code | Scan QR Code | Theme Settings |
|-----------------|--------------|----------------|
| ![Generate](screenshots/generate.png) | ![Scan](screenshots/scan.png) | ![Theme](screenshots/theme.png) |

## 🛠 Installation & Development

### Prerequisites
- Flutter 3.10+
- Dart 2.18+
- Android Studio/Xcode (for mobile builds)

```sh
# Clone repository
git clone https://github.com/TADSTech/qr4all.git
cd qr4all

# Install dependencies
flutter pub get

# Run development version
flutter run -d chrome  # For web
flutter run            # For connected device
```

## 📦 Key Dependencies
- `flex_color_scheme` - Advanced theming
- `mobile_scanner` - Camera scanning
- `qr_flutter` - QR generation
- `share_plus` - Cross-platform sharing
- `provider` - State management
- `url_launcher` - Opening URLs/SMS

## 🌟 Upcoming Features
- [ ] QR code history export
- [ ] Batch QR generation
- [ ] Custom logo overlay
- [ ] Enhanced web camera support

## 🤝 Contributing
We welcome contributions! Please follow our guidelines:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📜 License
MIT License - See [LICENSE](LICENSE) for details.

## 💌 Contact
For support or questions:
- Email: motrenewed@gmail.com
- GitHub: [TADSTech](https://github.com/TADSTech)