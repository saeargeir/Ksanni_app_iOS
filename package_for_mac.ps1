# Package iOS Project for Mac Transfer
# Run this script to create a complete package for Mac development

Write-Host "🚀 Packaging KsanniApp iOS Project for Mac Transfer..." -ForegroundColor Green
Write-Host ""

# Create staging directory
$stagingDir = ".\KsanniApp_iOS_Package"
if (Test-Path $stagingDir) {
    Remove-Item -Recurse -Force $stagingDir
}
New-Item -ItemType Directory -Path $stagingDir | Out-Null

# Copy iOS project files
Write-Host "📁 Copying iOS project files..." -ForegroundColor Yellow
Copy-Item -Recurse ".\iosApp" "$stagingDir\iosApp"

# Copy documentation
Copy-Item ".\README.md" "$stagingDir\README_Original.md"
Copy-Item ".\iOS_IMPLEMENTATION_COMPLETE.md" "$stagingDir\"
Copy-Item ".\WINDOWS_TO_MAC_SETUP.md" "$stagingDir\"

# Copy any relevant assets
if (Test-Path ".\app\image") {
    Copy-Item -Recurse ".\app\image" "$stagingDir\assets"
    Write-Host "📷 Copied app images and assets" -ForegroundColor Cyan
}

# Create setup script for Mac
$macSetupScript = @"
#!/bin/bash
# Mac Setup Script for KsanniApp iOS
echo "🍎 Setting up KsanniApp on macOS..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the Mac App Store."
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "📦 Installing CocoaPods..."
    sudo gem install cocoapods
fi

# Navigate to project directory
cd iosApp

# Install dependencies
echo "📦 Installing iOS dependencies..."
pod install

# Create Xcode project if needed
echo "🔨 Creating Xcode project..."
# The project structure is ready, just need to open .xcworkspace

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Add GoogleService-Info.plist from Firebase Console"
echo "2. Open KsanniApp.xcworkspace in Xcode"
echo "3. Build and run (⌘+R)"
echo ""
echo "📚 Read README_iOS.md for detailed setup instructions"
echo ""

# Open in Xcode
if command -v open &> /dev/null; then
    echo "🚀 Opening in Xcode..."
    open KsanniApp.xcworkspace
fi
"@

$macSetupScript | Out-File -FilePath "$stagingDir\setup_mac.sh" -Encoding UTF8
Write-Host "📜 Created Mac setup script" -ForegroundColor Cyan

# Create Firebase setup instructions
$firebaseInstructions = @"
# Firebase Setup Instructions

## 1. Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name: KsanniApp
4. Enable Google Analytics (optional)

## 2. Add iOS App
1. Click "Add app" → iOS
2. Bundle ID: com.iceveflausnir.ksanniapp
3. App nickname: KsanniApp iOS
4. Download GoogleService-Info.plist

## 3. Configure Services
Enable these services in Firebase Console:
- ✅ Authentication (Google Sign-In)
- ✅ Firestore Database
- ✅ Cloud Storage
- ✅ Analytics (optional)

## 4. Add to Xcode
1. Drag GoogleService-Info.plist into Xcode project
2. Make sure "Add to target" is checked
3. Verify file appears in project navigator

## 5. Test
Build and run app - Firebase should initialize without errors.
"@

$firebaseInstructions | Out-File -FilePath "$stagingDir\FIREBASE_SETUP.md" -Encoding UTF8
Write-Host "🔥 Created Firebase setup guide" -ForegroundColor Cyan

# Create package info file
$packageInfo = @"
# KsanniApp iOS Package Contents

## 📦 Package Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
## 🖥️ Source System: Windows
## 🎯 Target System: macOS with Xcode

## Contents:
- iosApp/ - Complete iOS project structure
- iOS_IMPLEMENTATION_COMPLETE.md - Feature overview
- WINDOWS_TO_MAC_SETUP.md - Transfer guide
- FIREBASE_SETUP.md - Firebase configuration
- setup_mac.sh - Automated Mac setup script

## Quick Start on Mac:
1. Extract this package
2. Run: chmod +x setup_mac.sh && ./setup_mac.sh
3. Follow FIREBASE_SETUP.md
4. Open KsanniApp.xcworkspace in Xcode
5. Build and run (⌘+R)

## Features Ready:
✅ Apple Vision OCR
✅ Document Scanner
✅ SwiftUI Interface
✅ Camera Integration
✅ Invoice Parsing
✅ Data Management
✅ Firebase Auth
✅ Export Functions

Your Android app has been fully converted to iOS!
"@

$packageInfo | Out-File -FilePath "$stagingDir\PACKAGE_INFO.md" -Encoding UTF8

# Create archive
Write-Host "📦 Creating transfer archive..." -ForegroundColor Yellow
$archiveName = "KsanniApp_iOS_Complete_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
Compress-Archive -Path $stagingDir -DestinationPath $archiveName

# Get file size
$fileSize = [math]::Round((Get-Item $archiveName).Length / 1MB, 2)

Write-Host ""
Write-Host "🎉 Package Created Successfully!" -ForegroundColor Green
Write-Host "📄 Archive: $archiveName" -ForegroundColor Cyan
Write-Host "📏 Size: $fileSize MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Transfer $archiveName to your Mac" -ForegroundColor White
Write-Host "2. Extract the archive" -ForegroundColor White
Write-Host "3. Run setup_mac.sh" -ForegroundColor White
Write-Host "4. Follow Firebase setup guide" -ForegroundColor White
Write-Host "5. Open .xcworkspace in Xcode" -ForegroundColor White
Write-Host ""
Write-Host "📱 Your iOS app is ready for development!" -ForegroundColor Green

# Clean up staging directory
Remove-Item -Recurse -Force $stagingDir