#!/bin/bash

echo "🔧 Fixing wBlock Theme Issues..."
echo "================================"

cd /Users/amos/Documents/GitHub/flutter_wblock_plugin/example

echo "1️⃣  Stopping any running Flutter processes..."
killall Flutter 2>/dev/null || true
killall dart 2>/dev/null || true

echo "2️⃣  Cleaning all build artifacts..."
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf macos/Pods
rm -rf ios/Pods
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "3️⃣  Removing theme-related caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/
rm -rf ~/.pub-cache/hosted/pub.dev/macos_ui-*
rm -rf ~/Library/Developer/CoreSimulator/Caches/

echo "4️⃣  Reinstalling dependencies..."
flutter pub cache clean -f
flutter pub get

echo "5️⃣  Installing native dependencies..."
cd macos && pod install && cd ..
cd ios && pod install && cd ..

echo "6️⃣  Building macOS app with light theme..."
flutter run -d macos
# flutter build macos --release

# echo "✅ Build complete! Running the app..."
# open build/macos/Build/Products/Release/Syferlab Blocker.app

# echo ""
# echo "If the app still shows dark theme:"
# echo "1. Check if macOS is in Dark Mode (System Preferences > General)"
# echo "2. Try running: flutter run -d macos --release"
# echo "3. Check the debug output with: flutter run -d macos --verbose"
