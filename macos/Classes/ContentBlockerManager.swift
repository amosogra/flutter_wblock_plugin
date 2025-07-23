import Foundation
import SafariServices

@MainActor
class ContentBlockerManager {
    private let appGroupIdentifier = "group.syferlab.wBlock"
    private let contentBlockerIdentifiers = [
        "syferlab.wBlock.wBlock-Filters",
        "syferlab.wBlock.wBlock-Advance",
        "syferlab.wBlock.wBlock-Scripts"
    ]
    
    private let converter = ContentBlockerConverter()
    
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    func applyChanges(filterLists: [NativeFilterList], progressCallback: @escaping (Double) -> Void) async {
        await LogManager.shared.log("Applying changes to Safari content blockers and web extension")
        
        let enabledFilters = filterLists.filter { $0.isSelected }
        
        // Convert filters to content blocker rules
        let (standardRules, advancedRules, scriptletData) = await convertFiltersToRules(enabledFilters, progressCallback: progressCallback)
        
        // Add YouTube-specific network rules for content blockers
        let youtubeRules = YouTubeAdBlockHandler.generateYouTubeNetworkRules()
        
        // Distribute network rules between content blockers (NOT scriptlets)
        await distributeNetworkRules(
            standardRules: standardRules + youtubeRules,
            advancedRules: advancedRules
        )
        
        // Save scriptlet data for Safari Web Extension
        await saveScriptletData(scriptletData)
        
        // Create YouTube-specific files for web extension
        await createYouTubeWebExtensionFiles()
        
        // Reload Safari content blockers
        await reloadContentBlockers()
        
        progressCallback(1.0)
        await LogManager.shared.log("Successfully applied changes with \(standardRules.count + advancedRules.count) network rules and \(scriptletData.count) scriptlets")
    }
    
    func getFilterStats(filterLists: [NativeFilterList]) async -> FilterStats {
        let enabledFilters = filterLists.filter { $0.isSelected }
        var totalRules = 0
        
        for filter in enabledFilters {
            totalRules += await getRuleCount(for: filter)
        }
        
        return FilterStats(
            enabledListsCount: enabledFilters.count,
            totalRulesCount: totalRules
        )
    }
    
    func getRuleCount(for filter: NativeFilterList) async -> Int {
        guard let containerURL = containerURL else { return 0 }
        
        let standardFileURL = containerURL.appendingPathComponent("\(filter.name).json")
        let advancedFileURL = containerURL.appendingPathComponent("\(filter.name)_advanced.json")
        let txtFileURL = containerURL.appendingPathComponent("\(filter.name).txt")
        
        var count = 0
        
        // If JSON files exist, count from them
        if FileManager.default.fileExists(atPath: standardFileURL.path) {
            count += await countRulesInFile(at: standardFileURL)
        }
        
        if FileManager.default.fileExists(atPath: advancedFileURL.path) {
            count += await countRulesInFile(at: advancedFileURL)
        }
        
        // If only txt file exists, estimate rule count
        if count == 0 && FileManager.default.fileExists(atPath: txtFileURL.path) {
            count = await estimateRulesInTxtFile(at: txtFileURL)
        }
        
        return count
    }
    
    // MARK: - Private Methods
    
    private func convertFiltersToRules(_ filterLists: [NativeFilterList], progressCallback: @escaping (Double) -> Void) async -> ([[String: Any]], [[String: Any]], [[String: Any]]) {
        var allStandardRules: [[String: Any]] = []
        var allAdvancedRules: [[String: Any]] = []
        var allScriptletData: [[String: Any]] = []
        
        let total = Double(filterLists.count)
        var completed = 0.0
        
        for filter in filterLists {
            await LogManager.shared.log("Converting filter: \(filter.name)")
            
            if let (standard, advanced, scriptlet) = await convertFilter(filter) {
                allStandardRules.append(contentsOf: standard)
                allAdvancedRules.append(contentsOf: advanced)
                allScriptletData.append(contentsOf: scriptlet)
            }
            
            completed += 1
            progressCallback(completed / total * 0.7) // 70% for conversion
        }
        
        await LogManager.shared.log("Converted \(allStandardRules.count) standard, \(allAdvancedRules.count) advanced, \(allScriptletData.count) scriptlets")
        
        return (allStandardRules, allAdvancedRules, allScriptletData)
    }
    
    private func convertFilter(_ filter: NativeFilterList) async -> ([[String: Any]], [[String: Any]], [[String: Any]])? {
        guard let containerURL = containerURL else { return nil }
        
        let txtFileURL = containerURL.appendingPathComponent("\(filter.name).txt")
        let standardFileURL = containerURL.appendingPathComponent("\(filter.name).json")
        let advancedFileURL = containerURL.appendingPathComponent("\(filter.name)_advanced.json")
        let scriptletFileURL = containerURL.appendingPathComponent("\(filter.name)_scriptlets.json")
        
        // Check if already converted
        if FileManager.default.fileExists(atPath: standardFileURL.path) {
            let standard = loadJSON(from: standardFileURL) ?? []
            let advanced = loadJSON(from: advancedFileURL) ?? []
            let scriptlet = loadJSON(from: scriptletFileURL) ?? []
            return (standard, advanced, scriptlet)
        }
        
        // Convert from txt file
        guard FileManager.default.fileExists(atPath: txtFileURL.path),
              let content = try? String(contentsOf: txtFileURL, encoding: .utf8) else {
            return nil
        }
        
        let result = converter.convertFilterList(from: content)
        
        // Save converted rules
        saveJSON(result.standardRules, to: standardFileURL)
        saveJSON(result.advancedRules, to: advancedFileURL)
        saveJSON(result.scriptletRules, to: scriptletFileURL)
        
        return (result.standardRules, result.advancedRules, result.scriptletRules)
    }
    
    private func createYouTubeWebExtensionFiles() async {
        guard let containerURL = containerURL else { return }
        
        // Save YouTube scriptlet configuration for web extension
        let scriptletConfigs = YouTubeAdBlockHandler.generateScriptletConfiguration()
        let scriptletURL = containerURL.appendingPathComponent("youtube_scriptlets.json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: scriptletConfigs, options: .prettyPrinted)
            try data.write(to: scriptletURL)
            await LogManager.shared.log("Created YouTube scriptlet configuration")
        } catch {
            await LogManager.shared.log("Failed to create YouTube scriptlets: \(error)")
        }
        
        // Save YouTube ad blocking script
        let scriptContent = YouTubeAdBlockHandler.generateYouTubeAdBlockScript()
        let scriptURL = containerURL.appendingPathComponent("youtube-adblock.js")
        
        do {
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            await LogManager.shared.log("Created YouTube ad blocking script")
        } catch {
            await LogManager.shared.log("Failed to create YouTube script: \(error)")
        }
        
        // Save YouTube CSS rules
        let cssContent = YouTubeAdBlockHandler.generateYouTubeAdBlockCSS()
        let cssURL = containerURL.appendingPathComponent("youtube-adblock.css")
        
        do {
            try cssContent.write(to: cssURL, atomically: true, encoding: .utf8)
            await LogManager.shared.log("Created YouTube ad blocking CSS")
        } catch {
            await LogManager.shared.log("Failed to create YouTube CSS: \(error)")
        }
        
        // Save scriptlet configuration flag
        let configURL = containerURL.appendingPathComponent("scriptlet_config.json")
        let config = ["youtube": true, "general": true]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            try data.write(to: configURL)
            await LogManager.shared.log("Created scriptlet configuration")
        } catch {
            await LogManager.shared.log("Failed to create scriptlet config: \(error)")
        }
    }
    
    private func distributeNetworkRules(standardRules: [[String: Any]], advancedRules: [[String: Any]]) async {
        guard let containerURL = containerURL else { return }
        
        // Safari has a limit of 50,000 rules per content blocker
        let maxRulesPerBlocker = 50000
        
        // Distribute network rules between content blockers:
        // Blocker 1: Standard rules (up to 50k)
        // Blocker 2: Advanced rules + overflow from standard + YouTube CSS rules
        // Note: Scriptlets go to Safari Web Extension, not content blockers
        
        let blocker1Rules = Array(standardRules.prefix(maxRulesPerBlocker))
        let standardOverflow = Array(standardRules.dropFirst(maxRulesPerBlocker))
        
        // Add YouTube CSS rules to advanced blocker
        let youtubeCSSRules = createYouTubeCSSRules()
        let blocker2Rules = advancedRules + standardOverflow + youtubeCSSRules
        let blocker2Limited = Array(blocker2Rules.prefix(maxRulesPerBlocker))
        
        // Save rules for content blockers
        let blockerFiles = [
            ("blockerList.json", blocker1Rules),
            ("blockerList2.json", blocker2Limited)
        ]
        
        for (filename, rules) in blockerFiles {
            let fileURL = containerURL.appendingPathComponent(filename)
            saveJSON(rules, to: fileURL)
            await LogManager.shared.log("Saved \(rules.count) rules to \(filename)")
        }
    }
    
    private func saveScriptletData(_ scriptletData: [[String: Any]]) async {
        guard let containerURL = containerURL else { return }
        
        // Save scriptlet data for Safari Web Extension
        let scriptletURL = containerURL.appendingPathComponent("general_scriptlets.json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: scriptletData, options: .prettyPrinted)
            try data.write(to: scriptletURL)
            await LogManager.shared.log("Saved \(scriptletData.count) scriptlets for web extension")
        } catch {
            await LogManager.shared.log("Failed to save scriptlets: \(error)")
        }
    }
    
    private func createYouTubeCSSRules() -> [[String: Any]] {
        // Convert YouTube CSS to content blocker format
        let cssSelectors = [
            ".video-ads",
            ".ytp-ad-module",
            ".ytp-ad-player-overlay",
            "#masthead-ad",
            "ytd-promoted-video-renderer",
            "ytd-display-ad-renderer",
            "ytd-promoted-sparkles-web-renderer",
            "#player-ads"
        ]
        
        return [[
            "trigger": [
                "url-filter": ".*",
                "if-domain": ["youtube.com", "youtu.be", "youtube-nocookie.com"]
            ],
            "action": [
                "type": "css-display-none",
                "selector": cssSelectors.joined(separator: ", ")
            ]
        ]]
    }
    
    private func reloadContentBlockers() async {
        var reloadedCount = 0
        
        // Only reload the first two content blockers (network blocking)
        // The third one (wBlock-Scripts) is a Safari Web Extension, not a content blocker
        let contentBlockerIds = [
            "syferlab.wBlock.wBlock-Filters",
            "syferlab.wBlock.wBlock-Advance"
        ]
        
        for identifier in contentBlockerIds {
            let success = await reloadContentBlocker(identifier: identifier)
            if success {
                reloadedCount += 1
            }
        }
        
        await LogManager.shared.log("Reloaded \(reloadedCount)/\(contentBlockerIds.count) content blockers")
        
        // Note: Safari Web Extension (wBlock-Scripts) will automatically pick up
        // the new scriptlet configurations when content.js requests them
    }
    
    private func reloadContentBlocker(identifier: String) async -> Bool {
        await withCheckedContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
                Task {
                    if let error = error {
                        await LogManager.shared.log("Failed to reload \(identifier): \(error)")
                        continuation.resume(returning: false)
                    } else {
                        await LogManager.shared.log("Successfully reloaded \(identifier)")
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }
    
    private func loadJSON(from url: URL) -> [[String: Any]]? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return json
    }
    
    private func saveJSON(_ rules: [[String: Any]], to url: URL) {
        do {
            let data = try JSONSerialization.data(withJSONObject: rules, options: .prettyPrinted)
            try data.write(to: url)
        } catch {
            Task {
                await LogManager.shared.log("Failed to save JSON to \(url.lastPathComponent): \(error)")
            }
        }
    }
    
    private func countRulesInFile(at url: URL) async -> Int {
        guard let rules = loadJSON(from: url) else { return 0 }
        return rules.count
    }
    
    private func estimateRulesInTxtFile(at url: URL) async -> Int {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return 0 }
        
        let lines = content.components(separatedBy: .newlines)
        var ruleCount = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Count non-empty, non-comment lines as potential rules
            if !trimmed.isEmpty && !trimmed.hasPrefix("!") && !trimmed.hasPrefix("[") {
                ruleCount += 1
            }
        }
        
        return ruleCount
    }
}
