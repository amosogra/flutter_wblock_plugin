import Foundation

class ContentBlockerConverter {
    
    struct ConversionResult {
        let standardRules: [[String: Any]]
        let advancedRules: [[String: Any]]
        let scriptletRules: [[String: Any]]
    }
    
    func convertFilterList(from content: String) -> ConversionResult {
        var standardRules: [[String: Any]] = []
        var advancedRules: [[String: Any]] = []
        var scriptletRules: [[String: Any]] = []
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("!") || trimmedLine.hasPrefix("[") {
                continue
            }
            
            if let rules = parseRule(trimmedLine) {
                // parseRule now returns an array of rules to handle split rules
                for rule in rules {
                    // Validate each rule before categorizing
                    if validateRule(rule) {
                        if let action = rule["action"] as? [String: Any],
                           let actionType = action["type"] as? String {
                            if actionType == "scriptlet" {
                                scriptletRules.append(rule)
                            } else if isAdvancedRule(rule) {
                                advancedRules.append(rule)
                            } else {
                                standardRules.append(rule)
                            }
                        } else {
                            standardRules.append(rule)
                        }
                    } else {
                        // Rule failed validation, skip it
                        // Don't log here to avoid async issues
                        print("Skipping invalid rule: \(rule)")
                    }
                }
            }
        }
        
        return ConversionResult(
            standardRules: standardRules,
            advancedRules: advancedRules,
            scriptletRules: scriptletRules
        )
    }
    
    private func parseRule(_ rule: String) -> [[String: Any]]? {
        // Handle element hiding rules (##)
        if rule.contains("##") {
            return parseElementHidingRule(rule)
        }
        
        // Handle scriptlet injection rules (##+js)
        if rule.contains("##+js(") {
            if let scriptletRule = parseScriptletRule(rule) {
                return [scriptletRule]
            }
            return nil
        }
        
        // Handle exception rules (@@)
        if rule.hasPrefix("@@") {
            return parseExceptionRule(rule)
        }
        
        // Handle network blocking rules
        return parseNetworkRule(rule)
    }
    
    private func parseElementHidingRule(_ rule: String) -> [[String: Any]]? {
        let parts = rule.components(separatedBy: "##")
        guard parts.count == 2 else { return nil }
        
        let domains = parts[0]
        let selector = parts[1].trimmingCharacters(in: .whitespaces)
        
        guard !selector.isEmpty else { return nil }
        
        var baseRule: [String: Any] = [
            "action": [
                "type": "css-display-none",
                "selector": selector
            ],
            "trigger": [
                "url-filter": ".*"
            ]
        ]
        
        // Add domain conditions if specified
        if !domains.isEmpty {
            let domainInfo = parseDomains(domains)
            let ifDomains = domainInfo["if-domain"] as? [String] ?? []
            let unlessDomains = domainInfo["unless-domain"] as? [String] ?? []
            
            // Check if we have multiple exclusive conditions
            if !ifDomains.isEmpty && !unlessDomains.isEmpty {
                // Create multiple rules to handle both conditions
                var rules: [[String: Any]] = []
                
                // Rule 1: Apply CSS hiding on if-domains
                var ifDomainRule = baseRule
                var trigger1 = ifDomainRule["trigger"] as? [String: Any] ?? [:]
                trigger1["if-domain"] = ifDomains
                ifDomainRule["trigger"] = trigger1
                rules.append(ifDomainRule)
                
                // Rule 2: Exception rule for unless-domains
                let unlessDomainRule: [String: Any] = [
                    "action": ["type": "ignore-previous-rules"],
                    "trigger": [
                        "url-filter": ".*",
                        "if-domain": unlessDomains
                    ]
                ]
                rules.append(unlessDomainRule)
                
                return rules
            } else if !ifDomains.isEmpty {
                // Only if-domain condition
                var trigger = baseRule["trigger"] as? [String: Any] ?? [:]
                trigger["if-domain"] = ifDomains
                baseRule["trigger"] = trigger
                return [baseRule]
            } else if !unlessDomains.isEmpty {
                // Only unless-domain - need to handle this differently
                // Create a general rule and then an exception
                var rules: [[String: Any]] = []
                
                // First add the general rule (without domain restriction)
                rules.append(baseRule)
                
                // Then add exception for the unless-domains
                let exceptionRule: [String: Any] = [
                    "action": ["type": "ignore-previous-rules"],
                    "trigger": [
                        "url-filter": ".*",
                        "if-domain": unlessDomains
                    ]
                ]
                rules.append(exceptionRule)
                
                return rules
            }
        }
        
        return [baseRule]
    }
    
    private func parseScriptletRule(_ rule: String) -> [String: Any]? {
        // Extract scriptlet name and arguments
        let regex = try? NSRegularExpression(pattern: "#\\+js\\(([^)]+)\\)")
        guard let match = regex?.firstMatch(in: rule, range: NSRange(rule.startIndex..., in: rule)) else { return nil }
        
        let scriptletData = (rule as NSString).substring(with: match.range(at: 1))
        let scriptletParts = scriptletData.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard !scriptletParts.isEmpty else { return nil }
        
        let scriptletName = scriptletParts[0]
        let scriptletArgs = Array(scriptletParts.dropFirst())
        
        // Special handling for YouTube scriptlets
        if isYouTubeScriptlet(scriptletName) {
            return createYouTubeBlockingRule(scriptletName, args: scriptletArgs)
        }
        
        return [
            "action": [
                "type": "scriptlet",
                "scriptlet": scriptletName,
                "arguments": scriptletArgs
            ],
            "trigger": [
                "url-filter": ".*",
                "if-domain": ["*youtube.com", "*youtube-nocookie.com"]
            ]
        ]
    }
    
    private func parseExceptionRule(_ rule: String) -> [[String: Any]]? {
        let baseRule = String(rule.dropFirst(2)) // Remove @@
        guard var parsedRules = parseNetworkRule(baseRule) else { return nil }
        
        // Update all rules to be exception rules
        for i in 0..<parsedRules.count {
            parsedRules[i]["action"] = ["type": "ignore-previous-rules"]
        }
        
        return parsedRules
    }
    
    private func parseNetworkRule(_ rule: String) -> [[String: Any]]? {
        var pattern = rule
        var options: [String: Any] = [:]
        
        // Extract options if present
        if let dollarIndex = rule.firstIndex(of: "$") {
            pattern = String(rule[..<dollarIndex])
            let optionsStr = String(rule[rule.index(after: dollarIndex)...])
            parseOptions(optionsStr, into: &options)
        }
        
        // Convert pattern to regex
        let urlFilter = convertPatternToRegex(pattern)
        guard !urlFilter.isEmpty else { return nil }
        
        var baseRule: [String: Any] = [
            "action": ["type": "block"],
            "trigger": ["url-filter": urlFilter]
        ]
        
        // Collect all conditions
        var conditions: [String: Any] = [:]
        
        // Domain conditions
        if let domains = options["domain"] as? [String: [String]] {
            if let include = domains["include"], !include.isEmpty {
                conditions["if-domain"] = include
            }
            if let exclude = domains["exclude"], !exclude.isEmpty {
                conditions["unless-domain"] = exclude
            }
        }
        
        // Top URL conditions (if present in options)
        if let topUrls = options["top-url"] as? [String: [String]] {
            if let include = topUrls["include"], !include.isEmpty {
                conditions["if-top-url"] = include
            }
            if let exclude = topUrls["exclude"], !exclude.isEmpty {
                conditions["unless-top-url"] = exclude
            }
        }
        
        // Load type
        if options["third-party"] != nil {
            conditions["load-type"] = ["third-party"]
        }
        
        // Resource types
        if let resourceTypes = options["resource-type"] as? [String] {
            conditions["resource-type"] = resourceTypes
        }
        
        // Check if we have multiple exclusive conditions
        let hasMultipleExclusiveConditions = 
            (conditions["if-domain"] != nil ? 1 : 0) +
            (conditions["unless-domain"] != nil ? 1 : 0) +
            (conditions["if-top-url"] != nil ? 1 : 0) +
            (conditions["unless-top-url"] != nil ? 1 : 0) > 1
        
        if hasMultipleExclusiveConditions {
            // Need to split into multiple rules
            return splitIntoMultipleRules(baseRule: baseRule, conditions: conditions)
        } else {
            // Single rule is sufficient
            var trigger = baseRule["trigger"] as? [String: Any] ?? [:]
            for (key, value) in conditions {
                trigger[key] = value
            }
            baseRule["trigger"] = trigger
            return [baseRule]
        }
    }
    
    private func splitIntoMultipleRules(baseRule: [String: Any], conditions: [String: Any]) -> [[String: Any]] {
        var rules: [[String: Any]] = []
        
        // Priority order: if-domain, if-top-url, unless-domain, unless-top-url
        // Create the main rule with if-conditions
        var mainRule = baseRule
        var mainTrigger = mainRule["trigger"] as? [String: Any] ?? [:]
        var hasMainCondition = false
        
        if let ifDomain = conditions["if-domain"] {
            mainTrigger["if-domain"] = ifDomain
            hasMainCondition = true
        } else if let ifTopUrl = conditions["if-top-url"] {
            mainTrigger["if-top-url"] = ifTopUrl
            hasMainCondition = true
        }
        
        // Add non-exclusive conditions
        if let loadType = conditions["load-type"] {
            mainTrigger["load-type"] = loadType
        }
        if let resourceType = conditions["resource-type"] {
            mainTrigger["resource-type"] = resourceType
        }
        
        if hasMainCondition {
            mainRule["trigger"] = mainTrigger
            rules.append(mainRule)
        }
        
        // Create exception rules for unless-conditions
        if let unlessDomain = conditions["unless-domain"] {
            var exceptionRule = baseRule
            exceptionRule["action"] = ["type": "ignore-previous-rules"]
            var trigger = exceptionRule["trigger"] as? [String: Any] ?? [:]
            trigger["if-domain"] = unlessDomain // Convert unless to if for exception
            
            // Copy non-exclusive conditions
            if let loadType = conditions["load-type"] {
                trigger["load-type"] = loadType
            }
            if let resourceType = conditions["resource-type"] {
                trigger["resource-type"] = resourceType
            }
            
            exceptionRule["trigger"] = trigger
            rules.append(exceptionRule)
        }
        
        if let unlessTopUrl = conditions["unless-top-url"] {
            var exceptionRule = baseRule
            exceptionRule["action"] = ["type": "ignore-previous-rules"]
            var trigger = exceptionRule["trigger"] as? [String: Any] ?? [:]
            trigger["if-top-url"] = unlessTopUrl // Convert unless to if for exception
            
            // Copy non-exclusive conditions
            if let loadType = conditions["load-type"] {
                trigger["load-type"] = loadType
            }
            if let resourceType = conditions["resource-type"] {
                trigger["resource-type"] = resourceType
            }
            
            exceptionRule["trigger"] = trigger
            rules.append(exceptionRule)
        }
        
        // If we only had unless-conditions and no if-conditions, create a base blocking rule
        if !hasMainCondition && rules.isEmpty {
            var blockAllRule = baseRule
            var trigger = blockAllRule["trigger"] as? [String: Any] ?? [:]
            
            // Add non-exclusive conditions
            if let loadType = conditions["load-type"] {
                trigger["load-type"] = loadType
            }
            if let resourceType = conditions["resource-type"] {
                trigger["resource-type"] = resourceType
            }
            
            blockAllRule["trigger"] = trigger
            rules.insert(blockAllRule, at: 0)
        }
        
        return rules
    }
    
    // Helper function to normalize and validate domains
    private func normalizeDomain(_ domain: String) -> String {
        var normalized = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle punycode conversion for international domains
        if normalized.contains(where: { $0.unicodeScalars.first?.value ?? 0 > 127 }) {
            // Convert to punycode
            if let punycoded = normalized.applyingPunycode() {
                normalized = punycoded
            }
        }
        
        return normalized
    }
    
    private func convertPatternToRegex(_ pattern: String) -> String {
        if pattern.isEmpty { return "" }
        if pattern == "*" { return ".*" }
        
        if pattern.hasPrefix("||") {
            // Domain anchor
            let domain = String(pattern.dropFirst(2))
            let escapedDomain = escapeRegexDomain(domain)
            return "^https?://([a-z0-9-_]+\\.)*\(escapedDomain)"
        }
        
        if pattern.hasPrefix("|") && pattern.hasSuffix("|") {
            // Exact match
            let exact = String(pattern.dropFirst().dropLast())
            return "^\(escapeRegex(exact))$"
        }
        
        // Convert wildcards and special patterns
        var regex = pattern
        
        // Replace ^ separator with regex
        regex = regex.replacingOccurrences(of: "^", with: "(?:[\\x00-\\x24\\x26-\\x2C\\x2F\\x3A-\\x40\\x5B-\\x5E\\x60\\x7B-\\x7F]|$)")
        
        // Escape special regex characters first
        regex = escapeRegex(regex)
        
        // Then convert wildcards
        regex = regex.replacingOccurrences(of: "\\*", with: ".*")
        regex = regex.replacingOccurrences(of: "\\?", with: ".")
        
        return regex
    }
    
    private func escapeRegex(_ str: String) -> String {
        let specialChars = "\\^$.|?+()[]{}"
        var escaped = str
        for char in specialChars {
            escaped = escaped.replacingOccurrences(of: String(char), with: "\\\\\(char)")
        }
        return escaped
    }
    
    private func escapeRegexDomain(_ domain: String) -> String {
        var escaped = domain
        // Only escape dots and wildcards for domains
        escaped = escaped.replacingOccurrences(of: ".", with: "\\\\.")
        escaped = escaped.replacingOccurrences(of: "*", with: ".*")
        return escaped
    }
    
    private func parseOptions(_ optionsStr: String, into options: inout [String: Any]) {
        let optionsList = optionsStr.components(separatedBy: ",")
        
        for option in optionsList {
            let trimmedOption = option.trimmingCharacters(in: .whitespaces)
            
            if trimmedOption.hasPrefix("domain=") {
                let domainStr = String(trimmedOption.dropFirst("domain=".count))
                options["domain"] = parseDomainOption(domainStr)
            } else if trimmedOption.hasPrefix("from=") {
                // Handle top-url conditions (from= is used in some filter lists)
                let topUrlStr = String(trimmedOption.dropFirst("from=".count))
                options["top-url"] = parseTopUrlOption(topUrlStr)
            } else if trimmedOption == "third-party" || trimmedOption == "3p" {
                options["third-party"] = true
            } else if trimmedOption == "~third-party" || trimmedOption == "~3p" || trimmedOption == "1p" {
                options["first-party"] = true
            } else if trimmedOption == "script" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("script")
                options["resource-type"] = types
            } else if trimmedOption == "image" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("image")
                options["resource-type"] = types
            } else if trimmedOption == "stylesheet" || trimmedOption == "css" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("style-sheet")
                options["resource-type"] = types
            } else if trimmedOption == "xmlhttprequest" || trimmedOption == "xhr" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("raw")
                options["resource-type"] = types
            } else if trimmedOption == "media" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("media")
                options["resource-type"] = types
            } else if trimmedOption == "font" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("font")
                options["resource-type"] = types
            } else if trimmedOption == "subdocument" || trimmedOption == "frame" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("document")
                options["resource-type"] = types
            }
        }
    }
    
    private func parseTopUrlOption(_ topUrlStr: String) -> [String: [String]] {
        let urls = topUrlStr.components(separatedBy: "|")
        var include: [String] = []
        var exclude: [String] = []
        
        for url in urls {
            let trimmed = url.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("~") {
                let urlPattern = String(trimmed.dropFirst())
                if !urlPattern.isEmpty {
                    exclude.append(normalizeTopUrl(urlPattern))
                }
            } else if !trimmed.isEmpty {
                include.append(normalizeTopUrl(trimmed))
            }
        }
        
        return [
            "include": include,
            "exclude": exclude
        ]
    }
    
    private func normalizeTopUrl(_ url: String) -> String {
        // Convert domain patterns to proper URL patterns for top-url
        var normalized = url.lowercased()
        
        // If it's just a domain, convert to a URL pattern
        if !normalized.contains("://") && !normalized.hasPrefix("*") {
            normalized = "*://\(normalized)/*"
        }
        
        return normalized
    }
    
    private func parseDomains(_ domainsStr: String) -> [String: Any] {
        let domains = domainsStr.components(separatedBy: ",")
        var includeDomains: [String] = []
        var excludeDomains: [String] = []
        
        for domain in domains {
            let trimmed = domain.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("~") {
                let domainName = normalizeDomain(String(trimmed.dropFirst()))
                if !domainName.isEmpty {
                    excludeDomains.append(domainName)
                }
            } else if !trimmed.isEmpty {
                let domainName = normalizeDomain(trimmed)
                if !domainName.isEmpty {
                    includeDomains.append(domainName)
                }
            }
        }
        
        return [
            "if-domain": includeDomains,
            "unless-domain": excludeDomains
        ]
    }
    
    private func parseDomainOption(_ domainStr: String) -> [String: [String]] {
        let domains = domainStr.components(separatedBy: "|")
        var include: [String] = []
        var exclude: [String] = []
        
        for domain in domains {
            let trimmed = domain.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("~") {
                let domainName = normalizeDomain(String(trimmed.dropFirst()))
                if !domainName.isEmpty {
                    exclude.append(domainName)
                }
            } else if !trimmed.isEmpty {
                let domainName = normalizeDomain(trimmed)
                if !domainName.isEmpty {
                    include.append(domainName)
                }
            }
        }
        
        return [
            "include": include,
            "exclude": exclude
        ]
    }
    
    private func isAdvancedRule(_ rule: [String: Any]) -> Bool {
        guard let action = rule["action"] as? [String: Any],
              let actionType = action["type"] as? String else { return false }
        
        return actionType == "css-display-none" ||
               actionType == "scriptlet" ||
               actionType == "ignore-previous-rules"
    }
    
    private func isYouTubeScriptlet(_ scriptletName: String) -> Bool {
        let youtubeScriptlets = [
            "json-prune",
            "set-constant",
            "abort-on-property-read",
            "abort-on-property-write",
            "abort-current-inline-script",
            "addEventListener-defuser",
            "prevent-addEventListener",
            "remove-attr",
            "set-attr"
        ]
        return youtubeScriptlets.contains(scriptletName)
    }
    
    private func createYouTubeBlockingRule(_ scriptletName: String, args: [String]) -> [String: Any] {
        // Ensure YouTube domains are lowercase
        let youtubeDomains = [
            "*youtube.com",
            "*youtube-nocookie.com",
            "*googlevideo.com",
            "*ytimg.com"
        ].map { normalizeDomain($0) }
        
        return [
            "action": [
                "type": "scriptlet",
                "scriptlet": scriptletName,
                "arguments": args
            ],
            "trigger": [
                "url-filter": ".*",
                "if-domain": youtubeDomains,
                "resource-type": ["document", "script"]
            ]
        ]
    }
    
    // Validation function to ensure Safari compatibility
    private func validateRule(_ rule: [String: Any]) -> Bool {
        guard let trigger = rule["trigger"] as? [String: Any] else { return false }
        
        // Check for multiple exclusive conditions
        let exclusiveConditions = ["if-domain", "unless-domain", "if-top-url", "unless-top-url"]
        let presentConditions = exclusiveConditions.filter { trigger[$0] != nil }
        
        if presentConditions.count > 1 {
            // Multiple exclusive conditions found - rule is invalid
            print("WARNING: Rule has multiple exclusive conditions: \(presentConditions)")
            return false
        }
        
        // Validate domains are lowercase
        for condition in ["if-domain", "unless-domain"] {
            if let domains = trigger[condition] as? [String] {
                for domain in domains {
                    if domain != domain.lowercased() {
                        // Domain not lowercase
                        print("WARNING: Domain not lowercase: \(domain)")
                        return false
                    }
                    // Check for non-ASCII characters
                    if domain.unicodeScalars.contains(where: { $0.value > 127 }) {
                        // Domain contains non-ASCII characters
                        print("WARNING: Domain contains non-ASCII characters: \(domain)")
                        return false
                    }
                }
            }
        }
        
        return true
    }
}

// Extension to handle punycode conversion
extension String {
    func applyingPunycode() -> String? {
        // Try to convert using IDN
        guard let encoded = self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: "https://\(encoded)"),
              let host = url.host else {
            return nil
        }
        return host
    }
}