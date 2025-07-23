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
```

## Extension Architecture

### 1. Content Blocker Extensions
Used for network-level blocking and CSS injection:
- **wBlock-Filters**: Standard network blocking rules
- **wBlock-Advance**: Advanced rules and YouTube CSS rules

### 2. Safari Web Extension (wBlock-Scripts)
Used for JavaScript execution and scriptlet injection:
- Handles `getAdvancedBlockingData` messages
- Injects scriptlets for YouTube ad blocking
- Applies extended CSS selectors

## Data Flow

### Filter Updates (Flutter → Native → Extensions)
```
1. User enables/disables filters in Flutter UI
2. FlutterWblockPlugin.applyChanges() called
3. ContentBlockerManager:
   - Converts filter lists to Safari rules
   - Saves to shared container:
     - blockerList.json (for wBlock-Filters)
     - blockerList2.json (for wBlock-Advance)
     - youtube_scriptlets.json (for wBlock-Scripts)
     - youtube-adblock.js
     - youtube-adblock.css
4. Reloads content blockers
```

### YouTube Ad Blocking (Browser → Extension → Page)
```
1. User navigates to YouTube
2. content.js detects YouTube domain
3. Sends "getAdvancedBlockingData" message to background.js
4. background.js forwards to SafariExtensionHandler.swift
5. Handler returns YouTube-specific blocking data
6. background.js loads scriptlet code from files
7. content.js injects:
   - CSS to hide ad elements
   - Scriptlets to modify JavaScript behavior
   - Scripts to intercept player initialization
```

## Key Files

### Shared Container Files
Located in `group.syferlab.wBlock`:
- `blockerList.json` - Network blocking rules
- `blockerList2.json` - Advanced blocking rules
- `general_scriptlets.json` - General scriptlet configurations
- `youtube_scriptlets.json` - YouTube-specific scriptlet configurations
- `youtube-adblock.js` - YouTube ad blocking script
- `youtube-adblock.css` - YouTube ad hiding CSS
- `scriptlet_config.json` - Configuration flags

### Filter Storage
- Filter lists downloaded to: `[container]/FilterLists/`
- Converted rules saved to: `[container]/`
- Logs saved to: `[container]/logs.txt`

## Testing

1. Enable filters in Flutter app
2. Open Safari and go to YouTube
3. Check Developer Console for "[wBlock Scripts]" logs
4. Verify ads are blocked and scriptlets are applied

## Notes

- Content blockers can only do network blocking and CSS injection
- JavaScript execution requires Safari Web Extension
- All scriptlet files are included in the web extension bundle
- The extension uses native messaging to communicate with the app
