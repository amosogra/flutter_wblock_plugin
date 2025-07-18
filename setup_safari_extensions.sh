#!/bin/bash

# Setup script for wBlock Flutter Plugin Safari Extensions
# This script helps create the necessary Safari Web Extension targets

echo "=== wBlock Flutter Plugin Safari Extension Setup ==="
echo ""
echo "This script will guide you through setting up the Safari extensions needed for wBlock."
echo ""
echo "Prerequisites:"
echo "1. Xcode installed"
echo "2. Apple Developer account (for signing)"
echo "3. The flutter_wblock_plugin project"
echo ""
echo "Steps to complete manually in Xcode:"
echo ""
echo "1. Open example/macos/Runner.xcworkspace in Xcode"
echo ""
echo "2. Add Safari Web Extension targets:"
echo "   - File > New > Target"
echo "   - Select 'Safari Extension' under macOS"
echo "   - Create 3 extensions:"
echo "     a) Name: 'wBlock Filters'"
echo "        Bundle ID: syferlab.wBlock.wBlock-Filters"
echo "     b) Name: 'wBlock Filters 2'"
echo "        Bundle ID: syferlab.wBlock.wBlock-Filters-2"
echo "     c) Name: 'wBlock Scripts'"
echo "        Bundle ID: syferlab.wBlock.wBlock-Scripts"
echo ""
echo "3. For each extension:"
echo "   - Set deployment target to macOS 10.14"
echo "   - Enable App Sandbox"
echo "   - Add App Group: group.syferlab.wBlock"
echo ""
echo "4. Configure Info.plist for each extension:"
echo ""

cat << 'EOF'
For wBlock Filters and wBlock Filters 2:
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.Safari.content-blocker</string>
    <key>NSExtensionPrincipalClass</key>
    <string>ContentBlockerRequestHandler</string>
</dict>

For wBlock Scripts:
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.Safari.web-extension</string>
    <key>NSExtensionPrincipalClass</key>
    <string>SafariWebExtensionHandler</string>
</dict>
EOF

echo ""
echo "5. Add entitlements for each extension:"
echo "   - com.apple.security.app-sandbox = YES"
echo "   - com.apple.security.application-groups = [group.syferlab.wBlock]"
echo ""
echo "6. Copy ContentBlockerRequestHandler.swift to Filters extensions"
echo "7. Copy SafariExtensionHandler.swift to Scripts extension"
echo ""
echo "8. Build and run the project"
echo ""
echo "After setup, the app will be able to:"
echo "- Block ads using Safari Content Blocker API"
echo "- Inject scripts for YouTube ad blocking"
echo "- Update filters automatically"
echo ""
echo "For more details, see IMPLEMENTATION_COMPLETE.md"
