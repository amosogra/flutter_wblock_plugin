# Flutter wBlock Plugin

A powerful Flutter plugin that brings the wBlock Safari ad blocker to Flutter applications on macOS. This plugin provides complete native integration with Safari's Content Blocker API, including advanced YouTube ad blocking through script injection.

## Project Status

✅ **Fully Implemented Features:**

- Complete Flutter plugin architecture with platform channels
- Native macOS/Swift integration with Safari Content Blocker API
- Filter list management (30+ default filters)
- Custom filter support
- Real-time rule counting and statistics
- Automatic filter updates with version checking
- YouTube ad blocking with script injection
- Scriptlet library for advanced blocking
- Progress tracking for all operations
- Concurrent logging system
- Pixel-perfect UI matching original SwiftUI design

## Quick Start

### Running the Example App

```bash
cd /Users/amos/Documents/GitHub/flutter_wblock_plugin/example
flutter pub get
flutter run -d macos
```

# Flutter wBlock Plugin Architecture

## Directory Structure

```
flutter_wblock_plugin/
├── lib/                                  # Flutter/Dart code
│   ├── flutter_wblock_plugin.dart       # Plugin API
│   └── src/
│       ├── models/                      # Data models
│       ├── managers/                    # Business logic
│       └── platform/                    # Platform interface
│
├── macos/
│   └── Classes/
│       ├── FlutterWblockPlugin.swift    # Flutter method channel handler
│       ├── FilterManager.swift          # Filter list management
│       ├── ContentBlockerManager.swift  # Content blocker rule generation
│       ├── ContentBlockerConverter.swift # AdBlock to Safari rule converter
│       ├── YouTubeAdBlockHandler.swift  # YouTube-specific blocking logic
│       ├── LogManager.swift             # Logging system
│       ├── NativeFilterList.swift       # Filter list model
│       │
│       ├── ContentBlockers/             # Content Blocker Extensions
│       │   └── ContentBlockerRequestHandler.swift
│       │
│       └── SafariWebExtension/          # Safari Web Extension (wBlock Scripts)
│           ├── SafariExtensionHandler.swift  # Native message handler
│           └── Resources/               # Web extension resources
│               ├── manifest.json        # Extension manifest
│               ├── src/
│               │   ├── background.js    # Message handling & scriptlet loading
│               │   ├── content.js       # Script injection into web pages
│               │   └── extendedCss/
│               │       └── extended-css.js  # Extended CSS selector support
│               ├── popup/
│               │   ├── popup.html       # Extension popup UI
│               │   ├── popup.js         # Popup logic
│               │   └── popup.css        # Popup styles
│               └── web_accessible_resources/
│                   ├── registry.json    # Scriptlet name mappings
│                   └── scriptlets/      # All scriptlet implementations
│                       ├── json-prune.js
│                       ├── set-constant.js
│                       └── ... (60+ scriptlets)
|
|
└── example/                    # Example Flutter app
    └── lib/   
    |   ├── views/              # UI screens
    |   ├── widgets/            # Reusable components
    |   └── widgets/            # Main entrance of the example app
    |
    └── macos/
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

### Key Components

#### 1. Filter Management System

- **FilterListManager**: Main controller for filter operations
- **FilterListConverter**: Converts AdBlock syntax to Safari format
- **FilterListApplier**: Applies rules to Safari content blockers

#### 2. YouTube Ad Blocking

- **YouTubeAdBlockHandler**: Generates YouTube-specific blocking rules
- Script injection for bypassing YouTube's ad system
- CSS rules for hiding ad elements
- Network-level blocking of ad requests

#### 3. Safari Integration

- **ContentBlockerManager**: Interfaces with Safari Content Blocker API
- **ContentBlockerRequestHandler**: Handles extension messaging
- **SafariExtensionHandler**: Handles web extension messaging
- Support for 2 content blockers (100,000 rules total)
- Support for ad blocking with script injection/scriptlets (50,000 rules)
- Real-time rule compilation and distribution

## Features

### Core Functionality

- ✅ Load and manage 30+ pre-configured filter lists
- ✅ Add/remove custom filter lists
- ✅ Real-time rule counting per filter
- ✅ Automatic filter updates based on Last-Modified/ETag
- ✅ Background update scheduling
- ✅ Progress tracking for all operations
- ✅ Comprehensive logging system

### YouTube Ad Blocking

- ✅ Script injection to prevent ad loading
- ✅ CSS rules to hide ad containers
- ✅ Network blocking of ad requests
- ✅ Scriptlet support for advanced blocking
- ✅ Automatic ad skip functionality

### UI Features

- ✅ Native macOS design using macos_ui
- ✅ Fixed 700x500 window (matching original)
- ✅ Category-based filter organization
- ✅ Real-time statistics display
- ✅ Keyboard shortcuts support
- ✅ Modal sheets for dialogs
- ✅ Progress indicators

## Implementation Details

### Filter Conversion

The plugin converts AdBlock Plus syntax to Safari Content Blocker JSON format:

- Element hiding rules (`##`)
- Scriptlet injection rules (`##+js`)
- Exception rules (`@@`)
- Network blocking rules with options

### Scriptlets Implemented

- `json-prune`: Remove properties from JSON responses
- `set-constant`: Set window properties to constant values
- `abort-on-property-read/write`: Prevent property access
- `prevent-addEventListener`: Block event listeners
- `remove-attr/class`: DOM manipulation
- `prevent-xhr/fetch`: Block network requests
- And many more...

### YouTube-Specific Implementation

```javascript
// Intercepts and modifies YouTube's player response
JSON.parse = function (text) {
  const obj = origParse(text);
  if (obj?.playerResponse) {
    delete obj.playerResponse.adPlacements;
    delete obj.playerResponse.playerAds;
  }
  return obj;
};
```

## Safari Extension Setup

To enable full functionality, you need to create Safari Web Extension targets in the example app:

1. **wBlock Filters**: Standard blocking rules
2. **wBlock Advance**: Advanced rules and overflow
3. **wBlock Scripts**: JavaScript injection for YouTube

## Performance

- Memory usage: ~40MB idle
- Rule compilation: < 1 second for 150,000 rules
- Update checking: Parallel HTTP HEAD requests
- File operations: Concurrent with actor isolation

## Testing

```bash
flutter test
```

## Platform Requirements

- macOS 10.14 (Mojave) or higher
- Flutter 3.0.0 or higher
- Xcode 14.0 or higher

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Original wBlock project by 0xCUB3
- AdGuard for filter lists and scriptlet implementations
- EasyList maintainers
