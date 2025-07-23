import Foundation
import SafariServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    
    private let appGroupIdentifier = "group.syferlab.wBlock"
    
    func beginRequest(with context: NSExtensionContext) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            let error = NSError(domain: "wBlock", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access app group container"])
            context.cancelRequest(withError: error)
            return
        }
        
        // Determine which blocker list to load based on extension identifier
        let extensionIdentifier = Bundle.main.bundleIdentifier ?? ""
        let blockerFileName: String
        
        switch extensionIdentifier {
        case "syferlab.wBlock.wBlock-Filters":
            blockerFileName = "blockerList.json"
        case "syferlab.wBlock.wBlock-Advance":
            blockerFileName = "blockerList2.json"
        default:
            // Default to standard blocker list
            blockerFileName = "blockerList.json"
        }
        
        let blockerListURL = containerURL.appendingPathComponent(blockerFileName)
        
        // Create empty list if file doesn't exist
        if !FileManager.default.fileExists(atPath: blockerListURL.path) {
            let emptyList = "[]"
            try? emptyList.write(to: blockerListURL, atomically: true, encoding: .utf8)
        }
        
        let attachment = NSItemProvider(contentsOf: blockerListURL)!
        let item = NSExtensionItem()
        item.attachments = [attachment]
        
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}