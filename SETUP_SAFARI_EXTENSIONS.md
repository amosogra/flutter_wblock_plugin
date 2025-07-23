# Safari Extensions Setup Guide

This guide provides detailed instructions for setting up the Safari extensions required for the Flutter wBlock Plugin.

## Overview

The wBlock ad blocker uses three Safari extensions:

- **2 Content Blocker Extensions** - For network-level blocking and CSS injection
- **1 Safari Web Extension** - For JavaScript execution and scriptlet injection

## Prerequisites

Before starting, ensure you have:

- macOS 10.15 or later
- Xcode 12 or later
- Safari 14 or later
- The Flutter wBlock Plugin source code

## Architecture

```
Safari Extensions:
├── wBlock-Filters (Content Blocker)
│   └── Handles standard network blocking rules
├── wBlock-Advance (Content Blocker)
│   └── Handles advanced rules and YouTube CSS
└── wBlock-Scripts (Safari Web Extension)
    └── Handles JavaScript injection and scriptlets
```

## Automatic Setup (Using Script)

### 1. Run the Setup Script

From your project root directory:

```bash
cd /path/to/flutter_wblock_plugin
chmod +x ./scripts/setup_safari_extensions.sh
./scripts/setup_safari_extensions.sh
```

The script will:

- Verify all required source files exist
- Create extension directory structures
- Generate Info.plist files for each extension
- Create entitlement files
- Copy/link necessary files

### 2. Verify Installation

The script automatically verifies that all files are in place. You should see:

- ✓ All required source files found
- ✓ Created wBlock-Filters extension
- ✓ Created wBlock-Advance extension
- ✓ Created wBlock-Scripts extension
- ✓ Found 60+ scriptlets

## Manual Setup in Xcode

After running the setup script, you need to add the extensions to your Xcode project:

### 1. Open Your macOS App Project

Open your Flutter macOS app in Xcode (usually `macos/Runner.xcworkspace`).

### 2. Add Content Blocker Extensions

For each content blocker (wBlock-Filters and wBlock-Advance):

1. **Create New Target**

   - File → New → Target
   - Select "Safari Extension"
   - Product Name: `wBlock-Filters` (or `wBlock-Advance`)
   - Bundle Identifier: `syferlab.wBlock.wBlock-Filters` (or `syferlab.wBlock.wBlock-Advance`)
   - Language: Swift
   - Click "Finish"

2. **Configure the Extension**

   - Select the extension target in project navigator
   - Go to "Signing & Capabilities"
   - Add "App Groups" capability
   - Add group: `group.syferlab.wBlock`

3. **Replace Default Files**

   - Delete the auto-generated Swift files
   - Copy `ContentBlockerRequestHandler.swift` from:
     ```
     macos/Classes/ContentBlockers/ContentBlockerRequestHandler.swift
     ```
   - Add it to the extension target

4. **Update Info.plist**
   - Replace the extension's Info.plist with the one created by the script:
     ```
     macos/SafariExtensions/wBlock-Filters/Info.plist
     ```

### 3. Add Safari Web Extension

1. **Create New Target**

   - File → New → Target
   - Select "Safari Web Extension"
   - Product Name: `wBlock-Scripts`
   - Bundle Identifier: `syferlab.wBlock.wBlock-Scripts`
   - Language: Swift
   - Click "Finish"

2. **Configure the Extension**

   - Select the extension target in project navigator
   - Go to "Signing & Capabilities"
   - Add "App Groups" capability
   - Add group: `group.syferlab.wBlock`

3. **Replace Default Files**

   - Delete the auto-generated Resources folder
   - Copy the entire Resources folder from:
     ```
     macos/Classes/SafariWebExtension/Resources/
     ```
   - Ensure it includes:
     - `manifest.json`
     - `src/background.js`
     - `src/content.js`
     - `src/extendedCss/extended-css.js`
     - `web_accessible_resources/scriptlets/` (60+ files)
     - `popup/` folder

4. **Update SafariExtensionHandler**

   - Replace the auto-generated handler with:
     ```
     macos/Classes/SafariWebExtension/SafariExtensionHandler.swift
     ```

5. **Update Info.plist**
   - Replace with the one created by the script:
     ```
     macos/SafariExtensions/wBlock-Scripts/Info.plist
     ```

### 4. Configure Build Settings

For all three extensions:

1. **Deployment Target**

   - Set to macOS 10.15 or your minimum supported version

2. **Build Settings**

   - Ensure "Swift Language Version" matches your main app
   - Set "Enable Bitcode" to No

3. **Entitlements**
   - Use the appropriate entitlements file from:
     ```
     macos/SafariExtensions/ContentBlocker.entitlements (for content blockers)
     macos/SafariExtensions/WebExtension.entitlements (for web extension)
     ```

## Testing the Extensions

### 1. Build and Run

1. Select your main app scheme in Xcode
2. Build and run (⌘R)
3. The app should launch with all extensions embedded

### 2. Enable in Safari

1. Open Safari Preferences
2. Go to the Extensions tab
3. Enable all three wBlock extensions:
   - wBlock Filters
   - wBlock Advance
   - wBlock Scripts

### 3. Verify Functionality

1. **Check Console Logs**

   - Open Safari Web Inspector
   - Look for "[wBlock Scripts]" messages

2. **Test Network Blocking**

   - Visit a site with ads
   - Check if network requests are blocked

3. **Test YouTube Ad Blocking**
   - Visit YouTube
   - Play a video
   - Verify ads are blocked and scriptlets are working

## Troubleshooting

### Common Issues

1. **"Extension not found in Safari"**

   - Ensure extensions are properly embedded in the app
   - Check bundle identifiers match exactly
   - Verify Info.plist files are correct

2. **"Native messaging not working"**

   - Check the native app ID in background.js:
     ```javascript
     const NATIVE_APP_ID = "syferlab.wBlock.wBlock-Scripts";
     ```
   - Verify entitlements include the mach-lookup exception

3. **"Scriptlets not loading"**

   - Ensure all scriptlet files are included in the web extension
   - Check web_accessible_resources in manifest.json
   - Verify registry.json is present

4. **"Content blockers not updating"**
   - Check shared container access (app groups)
   - Verify JSON files are being written to the container
   - Manually reload content blockers in Safari

### Debug Commands

Check if extensions are properly signed:

```bash
codesign -dv --verbose=4 /path/to/YourApp.app/Contents/PlugIns/wBlock-Scripts.appex
```

Verify app group container:

```bash
ls ~/Library/Group\ Containers/group.syferlab.wBlock/
```

## File Structure Reference

After setup, your extension structure should look like:

```
macos/SafariExtensions/
├── wBlock-Filters/
│   ├── Info.plist
│   └── ContentBlockerRequestHandler.swift (linked)
├── wBlock-Advance/
│   ├── Info.plist
│   └── ContentBlockerRequestHandler.swift (linked)
├── wBlock-Scripts/
│   ├── Info.plist
│   ├── SafariExtensionHandler.swift (linked)
│   └── Resources/
│       ├── manifest.json
│       ├── src/
│       │   ├── background.js
│       │   ├── content.js
│       │   └── extendedCss/
│       ├── popup/
│       └── web_accessible_resources/
├── ContentBlocker.entitlements
└── WebExtension.entitlements
```

## Additional Resources

- [Safari Web Extensions Documentation](https://developer.apple.com/documentation/safariservices/safari_web_extensions)
- [Content Blocker Documentation](https://developer.apple.com/documentation/safariservices/creating_a_content_blocker)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

## Support

If you encounter issues not covered in this guide:

1. Check the project's GitHub issues
2. Review Safari's developer console for errors
3. Ensure all paths and bundle identifiers are correct
4. Verify your development certificates include Safari extension capabilities
