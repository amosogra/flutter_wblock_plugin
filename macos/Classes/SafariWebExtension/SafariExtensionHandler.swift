import Foundation
import SafariServices

class SafariExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey]
        
        if let messageDict = message as? [String: Any] {
            handleMessage(messageDict) { response in
                let responseItem = NSExtensionItem()
                responseItem.userInfo = [SFExtensionMessageKey: response ?? [:]]
                context.completeRequest(returningItems: [responseItem], completionHandler: nil)
            }
        }
    }
    
    private func handleMessage(_ message: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        guard let action = message["action"] as? String else {
            completion(["error": "No action specified"])
            return
        }
        
        switch action {
        case "getAdvancedBlockingData":
            handleAdvancedBlockingRequest(message, completion: completion)
            
        case "getScriptlets":
            handleScriptletRequest(message, completion: completion)
            
        case "getFilterStatus":
            handleFilterStatusRequest(completion: completion)
            
        case "reloadFilters":
            handleReloadRequest(completion: completion)
            
        default:
            completion(["error": "Unknown action: \(action)"])
        }
    }
    
    private func handleAdvancedBlockingRequest(_ message: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        guard let url = message["url"] as? String else {
            completion(["error": "URL not provided"])
            return
        }
        
        let fromBeginning = message["fromBeginning"] as? Bool ?? true
        
        Task {
            do {
                let blockingData = await loadAdvancedBlockingData(for: url)
                let response: [String: Any] = [
                    "data": blockingData,
                    "chunked": false,
                    "more": false
                ]
                completion(response)
            } catch {
                completion(["error": error.localizedDescription])
            }
        }
    }
    
    private func handleScriptletRequest(_ message: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        // This handler is not used in the current architecture
        // The background.js script handles scriptlet loading directly
        // from the web_accessible_resources/scriptlets directory
        completion(["error": "Scriptlet loading is handled by background.js"])
    }
    
    private func handleFilterStatusRequest(completion: @escaping ([String: Any]?) -> Void) {
        Task {
            let status = await getFilterStatus()
            completion(["status": status])
        }
    }
    
    private func handleReloadRequest(completion: @escaping ([String: Any]?) -> Void) {
        Task {
            await reloadContentBlockers()
            completion(["success": true])
        }
    }
    
    private func loadAdvancedBlockingData(for urlString: String) async -> String {
        guard let url = URL(string: urlString),
              let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.syferlab.wBlock") else {
            return "{}"
        }
        
        var blockingData: [String: Any] = [:]
        
        // Load YouTube-specific rules if on YouTube
        if url.host?.contains("youtube") == true || url.host?.contains("youtu.be") == true {
            // Use YouTubeAdBlockHandler to generate scriptlet configuration
            let scriptletConfigs = YouTubeAdBlockHandler.generateScriptletConfiguration()
            
            // Convert scriptlet configs to JSON strings for the content script
            let scriptletStrings = scriptletConfigs.compactMap { config -> String? in
                guard let data = try? JSONSerialization.data(withJSONObject: config),
                      let jsonString = String(data: data, encoding: .utf8) else {
                    return nil
                }
                return jsonString
            }
            
            blockingData["scriptlets"] = scriptletStrings
            
            // Add YouTube-specific CSS
            blockingData["cssInject"] = [YouTubeAdBlockHandler.generateYouTubeAdBlockCSS()]
            
            // Add YouTube-specific scripts
            blockingData["scripts"] = [YouTubeAdBlockHandler.generateYouTubeAdBlockScript()]
            
            // Add extended CSS selectors
            blockingData["cssExtended"] = [
                ":has(ytd-display-ad-renderer)",
                ":has([id*=\"player-ads\"])",
                "ytd-rich-item-renderer:has(ytd-promoted-video-renderer)"
            ]
        }
        
        // Load general scriptlets from configuration
        let scriptletConfig = containerURL.appendingPathComponent("scriptlet_config.json")
        if let configData = try? Data(contentsOf: scriptletConfig),
           let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
            
            if config["general"] as? Bool == true {
                let generalScriptlets = loadScriptlets(from: containerURL.appendingPathComponent("general_scriptlets.json"))
                if var existingScriptlets = blockingData["scriptlets"] as? [String] {
                    existingScriptlets.append(contentsOf: generalScriptlets)
                    blockingData["scriptlets"] = existingScriptlets
                } else {
                    blockingData["scriptlets"] = generalScriptlets
                }
            }
        }
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: blockingData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }

    
    private func loadScriptlets(from url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url),
              let scriptlets = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return scriptlets.compactMap { scriptlet in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: scriptlet),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            return jsonString
        }
    }

    
    private func getFilterStatus() async -> [String: Any] {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.syferlab.wBlock")
        
        var status: [String: Any] = [
            "enabled": true,
            "filterCount": 0,
            "ruleCount": 0
        ]
        
        if let containerURL = containerURL {
            // Count active filters
            let filterFiles = try? FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" && $0.lastPathComponent.starts(with: "blockerList") }
            
            status["filterCount"] = filterFiles?.count ?? 0
            
            // Count total rules
            var totalRules = 0
            for file in filterFiles ?? [] {
                if let data = try? Data(contentsOf: file),
                   let rules = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    totalRules += rules.count
                }
            }
            status["ruleCount"] = totalRules
        }
        
        return status
    }
    
    private func reloadContentBlockers() async {
        let identifiers = [
            "syferlab.wBlock.wBlock-Filters",
            "syferlab.wBlock.wBlock-Advance",
            "syferlab.wBlock.wBlock-Scripts"
        ]
        
        for identifier in identifiers {
            await withCheckedContinuation { continuation in
                SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { _ in
                    continuation.resume()
                }
            }
        }
    }
}
