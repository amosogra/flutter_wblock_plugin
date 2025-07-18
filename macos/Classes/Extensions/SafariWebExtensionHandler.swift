import SafariServices
import os.log

/// Handles Safari Web Extension functionality for script injection
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private let appGroupIdentifier = "group.syferlab.wBlock"
    private let logger = Logger(subsystem: "syferlab.wBlock", category: "WebExtension")
    
    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        
        guard let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any],
              let action = message["action"] as? String else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        logger.info("Received action: \(action)")
        
        switch action {
        case "getScripts":
            handleGetScripts(context: context)
        case "reportBlockedAd":
            handleBlockedAdReport(message: message, context: context)
        case "getSettings":
            handleGetSettings(context: context)
        default:
            context.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func handleGetScripts(context: NSExtensionContext) {
        // Provide YouTube ad blocking scripts
        let scripts = [
            [
                "file": "youtube-adblock.js",
                "allFrames": false,
                "runAt": "document_start",
                "matches": ["*://*.youtube.com/*", "*://*.youtu.be/*", "*://*.youtube-nocookie.com/*"]
            ]
        ]
        
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "scripts": scripts,
                "youtubeScript": YouTubeAdBlockHandler.generateYouTubeAdBlockScript()
            ]
        ]
        
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
    
    private func handleBlockedAdReport(message: [String: Any], context: NSExtensionContext) {
        if let url = message["url"] as? String,
           let type = message["type"] as? String {
            logger.info("Blocked \(type) ad: \(url)")
            
            Task {
                await LogManager.shared.log("Blocked \(type) ad on YouTube")
            }
        }
        
        context.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func handleGetSettings(context: NSExtensionContext) {
        // Load current settings
        let settings = loadSettings()
        
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: settings
        ]
        
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
    
    private func loadSettings() -> [String: Any] {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        
        return [
            "youtubeAdBlockEnabled": defaults?.bool(forKey: "youtubeAdBlockEnabled") ?? true,
            "skipAdsAutomatically": defaults?.bool(forKey: "skipAdsAutomatically") ?? true,
            "muteAds": defaults?.bool(forKey: "muteAds") ?? true,
            "hideAdOverlays": defaults?.bool(forKey: "hideAdOverlays") ?? true,
            "blockMidrollAds": defaults?.bool(forKey: "blockMidrollAds") ?? true
        ]
    }
}
