# Flutter wBlock Plugin

A Flutter plugin that provides content blocking functionality for Safari with support for up to 750,000 rules on macOS and 500,000 on iOS.

## Features

- **Massive Filter Capacity**: Supports up to 750,000 rules on macOS and 500,000 on iOS
- **Multiple Filter Categories**: Ads, Trackers, Annoyances, Social, Regional, and Custom filters
- **User Script Support**: Add custom JavaScript to enhance browsing
- **Whitelist Management**: Exclude specific domains from filtering
- **Cross-Platform**: Works on both iOS and macOS

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_wblock_plugin:
    git:
      url: https://github.com/amosogra/flutter_wblock_plugin.git
```

## Usage

```dart
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

// Get all filter lists
final filterLists = await FlutterWblockPlugin.getFilterLists();

// Toggle a filter
await FlutterWblockPlugin.toggleFilterListSelection(filterId);

// Apply filter changes
await FlutterWblockPlugin.checkAndEnableFilters(forceReload: true);

// Check for updates
await FlutterWblockPlugin.checkForUpdates();
```

## Example App

The example app demonstrates a complete implementation of the wBlock functionality with:

- Filter list management
- User script management
- Whitelist management
- Onboarding flow
- Native iOS/macOS UI adaptation

## Architecture

The plugin maintains the original Swift architecture:

- **Native Side**: All business logic remains in Swift (Managers, Models, wBlockCoreService)
- **Flutter Side**: Handles UI and communicates with native code via method channels
- **wBlockCoreService**: External Swift package dependency for content blocking

## Configuration

### iOS
- Bundle Identifier: `syferlab.wBlock`
- App Group: `group.syferlab.wBlock`
- Minimum iOS Version: 15.0

### macOS
- Bundle Identifier: `syferlab.wBlock`
- App Group: `group.syferlab.wBlock`
- Minimum macOS Version: 10.15

## Important Notes

1. The wBlockCoreService folder in ios/macos directories is temporary. The actual dependency is:
   ```
   https://github.com/amosogra/wBlockCoreService_Package.git, :tag => '1.0.0'
   ```

2. Web Extension and Content Blocker Extension setup must be done in Xcode when running the app.

3. After applying filters, users must manually enable wBlock extensions in Safari settings.

## License

This project is licensed under the MIT License.
