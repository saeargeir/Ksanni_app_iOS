# iOS Setup Guide for KsanniApp

## Prerequisites

### Required Tools
1. **macOS** - iOS development requires macOS
2. **Xcode 14.0+** - Download from Mac App Store
3. **iOS 14.0+** - Minimum deployment target
4. **CocoaPods** - Dependency manager

### Installation Steps

1. **Install Xcode Command Line Tools:**
```bash
xcode-select --install
```

2. **Install CocoaPods:**
```bash
sudo gem install cocoapods
```

## Project Setup

### 1. Initialize iOS Project

1. Open Xcode
2. Create new iOS App project:
   - **Product Name:** KsanniApp
   - **Bundle Identifier:** io.github.saeargeir.ksanniapp
   - **Language:** Swift
   - **Interface:** SwiftUI
   - **Minimum Deployment:** iOS 14.0

### 2. Install Dependencies

Navigate to project directory and run:

```bash
cd iosApp
pod install
```

Always open `KsanniApp.xcworkspace` (not .xcodeproj) after installing pods.

### 3. Firebase Setup

1. Create Firebase project at https://console.firebase.google.com/
2. Add iOS app with bundle ID: `io.github.saeargeir.ksanniapp`
3. Download `GoogleService-Info.plist`
4. Add file to Xcode project root

### 4. Configure App Capabilities

In Xcode project settings, enable:
- **Camera** usage
- **Photo Library** access
- **Firebase Authentication**
- **Sign in with Apple** (optional)

## Project Structure

```
iosApp/
├── KsanniApp/
│   ├── KsanniApp.swift          # App entry point
│   ├── ContentView.swift        # Main UI
│   ├── Info.plist              # App configuration
│   ├── GoogleService-Info.plist # Firebase config
│   ├── Models/
│   │   └── DataModels.swift     # Data structures
│   ├── Views/
│   │   ├── ContentView.swift    # Main interface
│   │   ├── CameraViews.swift    # Camera components
│   │   ├── InvoiceListView.swift # Invoice management
│   │   └── OtherViews.swift     # Settings, stats, export
│   ├── OCR/
│   │   └── OCRManager.swift     # Text recognition
│   ├── Parser/
│   │   └── InvoiceParser.swift  # Invoice parsing logic
│   └── Managers/
│       └── Managers.swift       # Business logic managers
├── Podfile                      # Dependencies
└── KsanniApp.xcworkspace       # Xcode workspace
```

## Key Features Implemented

### 1. OCR (Optical Character Recognition)
- **Apple Vision Framework** - Primary OCR engine
- **Document Scanner** - iOS 13+ native scanner
- **Image preprocessing** - Enhanced accuracy
- **Multi-language support** - Icelandic and English

### 2. Invoice Parsing
- **International parser** - Multi-currency support
- **VAT extraction** - Automatic tax calculation
- **Smart categorization** - Auto-categorizes invoices
- **Date/amount recognition** - Intelligent parsing

### 3. User Interface
- **SwiftUI** - Modern declarative UI
- **Tab-based navigation** - 5 main sections
- **Dark/Light theme** - System theme support
- **Responsive design** - iPhone and iPad compatible

### 4. Data Management
- **Local storage** - UserDefaults (Core Data ready)
- **Export functionality** - CSV, Excel, PDF
- **Search and filtering** - Advanced invoice filtering
- **Statistics** - Spending analytics

### 5. Authentication (Firebase)
- **Google Sign-In** - OAuth authentication
- **User profiles** - Account management
- **Cloud sync ready** - Firebase integration

## iOS-Specific Implementations

### Camera Integration
```swift
// Native iOS camera with AVFoundation
struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        return picker
    }
}
```

### OCR with Vision Framework
```swift
// Apple's Vision framework for text recognition
let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
    // Process recognized text
}
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en-US", "is-IS"]
```

### Document Scanner (iOS 13+)
```swift
// Native document scanning with VisionKit
let scannerViewController = VNDocumentCameraViewController()
scannerViewController.delegate = coordinator
present(scannerViewController, animated: true)
```

## Build and Run

### Debug Build
1. Open `KsanniApp.xcworkspace` in Xcode
2. Select target device or simulator
3. Press Cmd+R to build and run

### Release Build
1. Select "Any iOS Device (arm64)" 
2. Product → Archive
3. Follow App Store distribution process

## Deployment

### App Store Connect
1. Create app record in App Store Connect
2. Archive and upload build
3. Complete App Store review process

### TestFlight (Beta Testing)
1. Upload build to App Store Connect
2. Enable TestFlight
3. Invite beta testers

## Key Differences from Android

| Feature | Android (Kotlin) | iOS (Swift) |
|---------|------------------|-------------|
| OCR | ML Kit | Apple Vision |
| Camera | CameraX | AVFoundation |
| UI | Jetpack Compose | SwiftUI |
| Storage | Room Database | Core Data |
| Auth | Firebase Auth | Firebase Auth |
| Navigation | Navigation Component | NavigationView |
| Theming | Material Design | iOS Design System |

## Performance Optimizations

1. **Lazy loading** - SwiftUI lazy views
2. **Image optimization** - Compressed image processing
3. **Background processing** - OCR on background queue
4. **Memory management** - ARC automatic cleanup
5. **Core Data** - Efficient data persistence (when implemented)

## Next Steps

1. **Core Data Integration** - Replace UserDefaults with Core Data
2. **CloudKit Sync** - iCloud synchronization
3. **Widgets** - iOS 14+ home screen widgets
4. **Apple Pay** - Payment integration
5. **Siri Shortcuts** - Voice commands
6. **Apple Watch** - Companion app

## Troubleshooting

### Common Issues

1. **Pod install fails:**
   ```bash
   sudo gem install cocoapods
   pod repo update
   pod install
   ```

2. **Firebase not working:**
   - Verify `GoogleService-Info.plist` is in project
   - Check bundle identifier matches Firebase configuration

3. **Camera not working:**
   - Verify camera permission in Info.plist
   - Test on physical device (not simulator)

4. **OCR accuracy issues:**
   - Ensure good lighting and image quality
   - Test with preprocessed images
   - Check language settings

### Support

- **Email:** iceveflausnir@gmail.com
- **GitHub:** https://github.com/saeargeir/Ksanni_app_iOS
- **Issues:** Use GitHub Issues for bug reports

---

**Made with ❤️ in Iceland 🇮🇸**

*This iOS version maintains feature parity with the Android version while leveraging iOS-specific capabilities for enhanced user experience.*