# Safari Extensions Setup

This Flutter plugin requires three Safari Content Blocker extensions to be added to your macOS app. Here's how to set them up:

## Extension 1: wBlock Filters

This is the primary content blocker for basic filtering rules.

### ContentBlockerRequestHandler.swift

```swift
import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let appGroupIdentifier = "group.syferlab.wBlock"

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            let error = NSError(domain: "wBlock", code: 1, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }

        let blockerListURL = containerURL.appendingPathComponent("blockerList1.json")

        if FileManager.default.fileExists(atPath: blockerListURL.path) {
            let attachment = NSItemProvider(contentsOf: blockerListURL)!
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(returningItems: [item], completionHandler: nil)
        } else {
            // Return empty rules if file doesn't exist
            let emptyRules = "[]"
            let data = emptyRules.data(using: .utf8)!
            let attachment = NSItemProvider(item: data as NSData, typeIdentifier: "public.json")
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(returningItems: [item], completionHandler: nil)
        }
    }
}
```

### Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.content-blocker</string>
        <key>NSExtensionPrincipalClass</key>
        <string>ContentBlockerRequestHandler</string>
    </dict>
</dict>
</plist>
```

## Extension 2: wBlock Filters 2

This handles overflow rules when the first content blocker reaches its limit.

The ContentBlockerRequestHandler.swift is similar to Extension 1, but loads `blockerList2.json` instead.

## Extension 3: wBlock Scripts

This handles advanced rules that require CSS injection or exception rules.

### SafariWebExtensionHandler.swift

```swift
import SafariServices

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(macOS 11.0, iOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(macOS 11.0, iOS 14.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)",
               String(describing: message), profile?.uuidString ?? "none")

        let response = NSExtensionItem()
        response.userInfo = [ SFExtensionMessageKey: [ "Response": "Received" ] ]

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
```

### Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.web-extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>SafariWebExtensionHandler</string>
    </dict>
    <key>SFSafariWebExtensionManifest</key>
    <string>Resources/manifest.json</string>
</dict>
</plist>
```

## App Group Configuration

All extensions and the main app must share the same App Group ID: `group.syferlab.wBlock`

Add this to each extension's entitlements:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.syferlab.wBlock</string>
</array>
```

## Building and Testing

1. Add all three extensions to your Xcode project
2. Ensure proper code signing for each extension
3. Build and run the app
4. Enable the extensions in Safari Preferences > Extensions
5. Test with the Flutter app

## Troubleshooting

- If rules don't apply, check the Console app for extension logs
- Ensure the app group container is accessible
- Verify JSON files are properly formatted
- Check Safari's content blocker reload errors
