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
        guard let scriptlets = message["scriptlets"] as? [[String: Any]] else {
            completion(["error": "Scriptlets not provided"])
            return
        }
        
        var scriptletPayloads: [[String: Any]] = []
        
        for scriptlet in scriptlets {
            if let name = scriptlet["name"] as? String,
               let code = loadScriptletCode(name: name) {
                
                let payload: [String: Any] = [
                    "code": code,
                    "source": [
                        "name": name,
                        "args": scriptlet["args"] ?? [],
                        "engine": "wBlock",
                        "version": "0.2.0"
                    ],
                    "args": scriptlet["args"] ?? []
                ]
                scriptletPayloads.append(payload)
            }
        }
        
        completion(["scriptlets": scriptletPayloads])
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
            blockingData = loadYouTubeBlockingData(containerURL: containerURL)
        }
        
        // Load general scriptlets
        let scriptletConfig = containerURL.appendingPathComponent("scriptlet_config.json")
        if let configData = try? Data(contentsOf: scriptletConfig),
           let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
            
            if config["general"] as? Bool == true {
                let generalScriptlets = loadScriptlets(from: containerURL.appendingPathComponent("general_scriptlets.json"))
                blockingData["scriptlets"] = generalScriptlets
            }
        }
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: blockingData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func loadYouTubeBlockingData(containerURL: URL) -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Load YouTube scriptlets
        let youtubeScriptlets = loadScriptlets(from: containerURL.appendingPathComponent("youtube_scriptlets.json"))
        
        // Add hardcoded YouTube scriptlets
        let additionalScriptlets = [
            [
                "name": "json-prune",
                "args": ["playerResponse.adPlacements", "playerResponse.playerAds", "adSlots"]
            ],
            [
                "name": "set-constant",
                "args": ["ytInitialPlayerResponse.adPlacements", "undefined"]
            ],
            [
                "name": "abort-on-property-read",
                "args": ["playerResponse.adPlacements"]
            ]
        ]
        
        data["scriptlets"] = youtubeScriptlets + additionalScriptlets.map { try? JSONSerialization.data(withJSONObject: $0) }.compactMap { $0 }.map { String(data: $0, encoding: .utf8) }.compactMap { $0 }
        
        // Load YouTube CSS
        if let cssData = try? String(contentsOf: containerURL.appendingPathComponent("youtube-adblock.css")) {
            data["cssInject"] = [cssData]
        }
        
        // Load YouTube scripts
        if let scriptData = try? String(contentsOf: containerURL.appendingPathComponent("youtube-adblock.js")) {
            data["scripts"] = [scriptData]
        }
        
        // Extended CSS for advanced selectors
        data["cssExtended"] = [
            ":has(ytd-display-ad-renderer)",
            ":has([id*=\"player-ads\"])",
            "ytd-rich-item-renderer:has(ytd-promoted-video-renderer)"
        ]
        
        return data
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
    
    private func loadScriptletCode(name: String) -> String? {
        // Map of scriptlet names to their implementations
        let scriptletCode = ScriptletLibrary.getScriptletCode(for: name)
        return scriptletCode
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
            "syferlab.wBlock.wBlock-Filters-2",
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
