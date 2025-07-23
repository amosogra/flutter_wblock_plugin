=== wBlock Flutter Plugin Safari Extension Setup ===

This document will guide you through setting up the Safari extensions needed for wBlock.

Prerequisites:

1. Xcode installed
2. Apple Developer account (for signing)
3. The flutter_wblock_plugin project

Steps to complete manually in Xcode:

1. Open example/macos/Runner.xcworkspace in Xcode

2. Add Safari Web Extension targets:

   - File > New > Target
   - Select 'Safari Extension' under macOS
   - Create 3 extensions:
     a) Name: 'wBlock Filters'
     Bundle ID: syferlab.wBlock.wBlock-Filters
     b) Name: 'wBlock Advance'
     Bundle ID: syferlab.wBlock.wBlock-Advance
     c) Name: 'wBlock Scripts'
     Bundle ID: syferlab.wBlock.wBlock-Scripts

3. For each extension:

   - Set deployment target to macOS 10.14
   - Enable App Sandbox
   - Add App Group: group.syferlab.wBlock

4. Configure Info.plist for each extension:

For wBlock Filters and wBlock Advance:
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
<key>SFSafariWebExtensionManifest</key>
<string>Resources/manifest.json</string>

5. Add entitlements for each extension:

   - com.apple.security.app-sandbox = YES
   - com.apple.security.application-groups = [group.syferlab.wBlock]

6. Copy ContentBlockerRequestHandler.swift to Filters extensions
7. Copy SafariExtensionHandler.swift to Scripts extension

8. Build and run the project

After setup, the app will be able to:

- Block ads using Safari Content Blocker API
- Inject scripts for YouTube ad blocking
- Update filters automatically

For more details, see [📋 Setup Guide](/SETUP_SAFARI_EXTENSIONS.md)
