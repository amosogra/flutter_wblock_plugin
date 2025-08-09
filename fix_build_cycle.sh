#!/bin/bash

# Fix build cycle issue in Xcode project

echo "🔧 Fixing Xcode build cycle issue..."
echo ""

cd /Users/amos/Documents/GitHub/flutter_wblock_plugin/example/ios

# Clean derived data and build folder
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build/
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner -configuration Debug

# Reinstall pods to ensure clean state
echo ""
echo "📦 Reinstalling pods..."
pod deintegrate
pod install

echo ""
echo "🔨 Attempting build with disabled thin binary script..."

# Try building with explicit settings to avoid the cycle
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    CODE_SIGNING_ALLOWED=NO \
    VALIDATE_WORKSPACE=NO \
    build

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Opening Xcode to fix build phases manually..."
    echo ""
    
    open Runner.xcworkspace
    
    echo "📝 MANUAL FIX INSTRUCTIONS:"
    echo ""
    echo "1. Select 'Runner' target"
    echo "2. Go to 'Build Phases' tab"
    echo "3. Find the 'Thin Binary' script phase"
    echo "4. Either:"
    echo "   a) DELETE the 'Thin Binary' script phase (if not needed)"
    echo "   OR"
    echo "   b) Move it to AFTER 'Embed App Extensions'"
    echo ""
    echo "5. Ensure 'Embed App Extensions' is AFTER 'Compile Sources'"
    echo ""
    echo "6. The correct order should be:"
    echo "   - Dependencies"
    echo "   - Compile Sources"
    echo "   - Link Binary With Libraries"
    echo "   - Copy Bundle Resources"
    echo "   - Embed Pods Frameworks"
    echo "   - Embed App Extensions"
    echo "   - Thin Binary (if needed)"
    echo "   - Run Script phases"
    echo ""
    echo "7. Clean: Product > Clean Build Folder (Cmd+Shift+K)"
    echo "8. Build: Product > Build (Cmd+B)"
else
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "You can now run: flutter run"
fi
