# Flutter wBlock Plugin

A Flutter plugin that brings the power of wBlock - the next-generation ad blocker for Safari - to Flutter applications on macOS. This plugin provides a complete Flutter implementation of the wBlock Safari ad blocker API, including advanced YouTube ad blocking through script injection.

## Features

- 🛡️ **Safari Content Blocker Integration** - Native integration with Safari's content blocking API
- 📋 **Filter List Management** - Load, update, and manage multiple ad-blocking filter lists
- 🎨 **Native macOS UI** - Pixel-perfect recreation of the original SwiftUI interface
- 🔄 **Auto-Update Support** - Background updates for filter lists
- 📊 **Real-time Statistics** - Track enabled filters and active rules
- ⚡ **High Performance** - Optimized for minimal memory usage (~40MB idle)
- 🎯 **Custom Filters** - Add and manage custom filter lists
- ⌨️ **Keyboard Shortcuts** - Full keyboard shortcut support

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

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_wblock_plugin: ^0.2.0
```

## Platform Configuration

### macOS

1. Set the minimum macOS deployment target to 10.14 or higher in your `macos/Podfile`:

```ruby
platform :osx, '10.14'
```

2. Add the required entitlements to your macOS app:

Create or modify `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.syferlab.wBlock</string>
    </array>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

3. Configure Safari Extensions (if building the full app with extensions):

You'll need to create Safari Web Extension targets for the content blockers. To do that in your example app [Click here for Safari Extension setup instructions](SETUP_SAFARI_EXTENSIONS.md)
[📋 Setup Guide](SETUP_SAFARI_EXTENSIONS.md)

## Quick Links
- [Setup Guide](SETUP_SAFARI_EXTENSIONS.md)
- [Architecture](ARCHITECTURE.md)
- [Architecture Diagram](ARCHITECTURE_DIAGRAM.md)

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilterListManager(),
      child: MaterialApp(
        home: WBlockScreen(),
      ),
    );
  }
}

class WBlockScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filterManager = context.watch<FilterListManager>();

    return Scaffold(
      appBar: AppBar(title: Text('wBlock')),
      body: Column(
        children: [
          // Stats Banner
          FilterStats(
            enabledLists: filterManager.filterLists.where((f) => f.isSelected).length,
            totalRules: filterManager.ruleCounts.values.fold(0, (a, b) => a + b),
          ),

          // Filter Lists
          Expanded(
            child: ListView.builder(
              itemCount: filterManager.filterLists.length,
              itemBuilder: (context, index) {
                final filter = filterManager.filterLists[index];
                return ListTile(
                  title: Text(filter.name),
                  subtitle: Text(filter.description),
                  trailing: Switch(
                    value: filter.isSelected,
                    onChanged: (_) => filterManager.toggleFilterListSelection(filter.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => filterManager.applyChanges(),
        child: Icon(Icons.save),
      ),
    );
  }
}
```

### Advanced Features

#### Adding Custom Filters

```dart
final customFilter = FilterList(
  name: 'My Custom Filter',
  url: 'https://example.com/filter.txt',
  category: FilterListCategory.custom,
  isSelected: true,
  description: 'My custom ad-blocking rules',
);

await filterManager.addCustomFilterList(customFilter);
```

#### Checking for Updates

```dart
await filterManager.checkForUpdates();

if (filterManager.availableUpdates.isNotEmpty) {
  // Show update dialog
  await filterManager.updateSelectedFilters(filterManager.availableUpdates);
}
```

## Default Filter Lists

The plugin includes the following pre-configured filter lists:

### Ads

- AdGuard Base Filter
- AdGuard Mobile Ads Filter
- EasyList

### Privacy

- AdGuard Tracking Protection Filter
- EasyPrivacy

### Security

- Online Malicious URL Blocklist
- Phishing URL Blocklist

### Annoyances

- AdGuard Annoyances Filter
- AdGuard Cookie Notices Filter
- EasyList Cookie List
- Fanboy's Annoyance List

### And many more...

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

## Native Integration

The plugin uses platform channels to communicate with native macOS code:

- **Method Channel**: For invoking native methods
- **Event Channel**: For progress updates during filter operations

The native implementation handles:

- Safari Content Blocker API integration
- Safari Extension API integration
- Filter list downloading and conversion
- App group shared storage
- Background updates

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

#### 4. Keyboard Shortcuts

The plugin supports the following keyboard shortcuts:

- `⌘R` - Check for Updates
- `⌘S` - Apply Changes
- `⌘N` - Add Custom Filter
- `⌘⇧L` - Show Logs
- `⌘,` - Show Settings
- `⌘⌥R` - Reset to Default
- `⌘⇧F` - Toggle Only Enabled Filters
- `⌘⇧K` - Show Keyboard Shortcuts

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

To enable full functionality, you need to create Safari Web Extension targets for the content blockers in the example app:

1. **wBlock Filters**: Standard blocking rules
2. **wBlock Advance**: Advanced rules and overflow
3. **wBlock Scripts**: JavaScript injection for YouTube

To do that in your example app [Click here for Safari Extension setup instructions](SETUP_SAFARI_EXTENSIONS.md)
[📋 Setup Guide](SETUP_SAFARI_EXTENSIONS.md)

## Performance

- Memory usage: ~40MB idle
- Rule compilation: < 1 second for 150,000 rules
- Update checking: Parallel HTTP HEAD requests
- File operations: Concurrent with actor isolation

### Testing

```bash
flutter test
```

## Platform Requirements

- macOS 10.14 (Mojave) or higher
- Flutter 3.0.0 or higher
- Xcode 14.0 or higher

## License

This project is licensed under the GPLv3 License - see the LICENSE file for details.

## Acknowledgments

- Original wBlock project by [0xCUB3](https://github.com/0xCUB3/wBlock)
- AdGuard for filter lists
- EasyList maintainers

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please use the [GitHub issue tracker](https://github.com/amosogra/flutter_wblock_plugin/issues).
