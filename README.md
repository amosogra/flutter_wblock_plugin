# Flutter wBlock Plugin

A Flutter plugin that brings the power of wBlock - the next-generation ad blocker for Safari - to Flutter applications on macOS. This plugin provides a complete Flutter implementation of the wBlock Safari ad blocker with native macOS integration.

## Features

- 🛡️ **Safari Content Blocker Integration** - Native integration with Safari's content blocking API
- 📋 **Filter List Management** - Load, update, and manage multiple ad-blocking filter lists
- 🎨 **Native macOS UI** - Pixel-perfect recreation of the original SwiftUI interface
- 🔄 **Auto-Update Support** - Background updates for filter lists
- 📊 **Real-time Statistics** - Track enabled filters and active rules
- ⚡ **High Performance** - Optimized for minimal memory usage (~40MB idle)
- 🎯 **Custom Filters** - Add and manage custom filter lists
- ⌨️ **Keyboard Shortcuts** - Full keyboard shortcut support

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

You'll need to create Safari Web Extension targets for the content blockers. See the original wBlock source for reference.

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

#### Keyboard Shortcuts

The plugin supports the following keyboard shortcuts:

- `⌘R` - Check for Updates
- `⌘S` - Apply Changes
- `⌘N` - Add Custom Filter
- `⌘⇧L` - Show Logs
- `⌘,` - Show Settings
- `⌘⌥R` - Reset to Default
- `⌘⇧F` - Toggle Only Enabled Filters
- `⌘⇧K` - Show Keyboard Shortcuts

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

## Architecture

The plugin follows a clean architecture pattern:

```
flutter_wblock_plugin/
├── lib/
│   ├── src/
│   │   ├── models/          # Data models
│   │   ├── managers/        # Business logic
│   │   └── platform/        # Platform channel interface
├── macos/
│   └── Classes/             # Native Swift implementation
└── example/
    └── lib/
        ├── views/           # UI components
        └── widgets/         # Reusable widgets
```

## Native Integration

The plugin uses platform channels to communicate with native macOS code:

- **Method Channel**: For invoking native methods
- **Event Channel**: For progress updates during filter operations

The native implementation handles:

- Safari Content Blocker API integration
- Filter list downloading and conversion
- App group shared storage
- Background updates

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Run `flutter pub get` in the root directory
3. Run `cd example && flutter pub get`
4. Open `example/macos/Runner.xcworkspace` in Xcode
5. Run the example app

### Testing

```bash
flutter test
```

## License

This project is licensed under the GPLv3 License - see the LICENSE file for details.

## Acknowledgments

- Original wBlock project by [0xCUB3](https://github.com/0xCUB3/wBlock)
- AdGuard for filter lists
- EasyList maintainers

## Support

For issues and feature requests, please use the [GitHub issue tracker](https://github.com/yourusername/flutter_wblock_plugin/issues).
