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
            
            if let rule = parseRule(trimmedLine) {
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
            }
        }
        
        return ConversionResult(
            standardRules: standardRules,
            advancedRules: advancedRules,
            scriptletRules: scriptletRules
        )
    }
    
    private func parseRule(_ rule: String) -> [String: Any]? {
        // Handle element hiding rules (##)
        if rule.contains("##") {
            return parseElementHidingRule(rule)
        }
        
        // Handle scriptlet injection rules (##+js)
        if rule.contains("##+js(") {
            return parseScriptletRule(rule)
        }
        
        // Handle exception rules (@@)
        if rule.hasPrefix("@@") {
            return parseExceptionRule(rule)
        }
        
        // Handle network blocking rules
        return parseNetworkRule(rule)
    }
    
    private func parseElementHidingRule(_ rule: String) -> [String: Any]? {
        let parts = rule.components(separatedBy: "##")
        guard parts.count == 2 else { return nil }
        
        let domains = parts[0]
        let selector = parts[1].trimmingCharacters(in: .whitespaces)
        
        guard !selector.isEmpty else { return nil }
        
        var ruleMap: [String: Any] = [
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
            var trigger = ruleMap["trigger"] as? [String: Any] ?? [:]
            
            if let ifDomains = domainInfo["if-domain"] as? [String], !ifDomains.isEmpty {
                trigger["if-domain"] = ifDomains
            }
            if let unlessDomains = domainInfo["unless-domain"] as? [String], !unlessDomains.isEmpty {
                trigger["unless-domain"] = unlessDomains
            }
            
            ruleMap["trigger"] = trigger
        }
        
        return ruleMap
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
    
    private func parseExceptionRule(_ rule: String) -> [String: Any]? {
        let baseRule = String(rule.dropFirst(2)) // Remove @@
        var parsedRule = parseNetworkRule(baseRule)
        parsedRule?["action"] = ["type": "ignore-previous-rules"]
        return parsedRule
    }
    
    private func parseNetworkRule(_ rule: String) -> [String: Any]? {
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
        
        var trigger: [String: Any] = ["url-filter": urlFilter]
        
        // Apply options to trigger
        if let domains = options["domain"] as? [String: [String]] {
            if let includeDomains = domains["include"], !includeDomains.isEmpty {
                trigger["if-domain"] = includeDomains
            }
            if let excludeDomains = domains["exclude"], !excludeDomains.isEmpty {
                trigger["unless-domain"] = excludeDomains
            }
        }
        
        if options["third-party"] != nil {
            trigger["load-type"] = ["third-party"]
        }
        
        if let resourceTypes = options["resource-type"] as? [String] {
            trigger["resource-type"] = resourceTypes
        }
        
        return [
            "action": ["type": "block"],
            "trigger": trigger
        ]
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
            if option.hasPrefix("domain=") {
                let domainStr = String(option.dropFirst("domain=".count))
                options["domain"] = parseDomainOption(domainStr)
            } else if option == "third-party" || option == "3p" {
                options["third-party"] = true
            } else if option == "~third-party" || option == "~3p" || option == "1p" {
                options["first-party"] = true
            } else if option == "script" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("script")
                options["resource-type"] = types
            } else if option == "image" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("image")
                options["resource-type"] = types
            } else if option == "stylesheet" || option == "css" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("style-sheet")
                options["resource-type"] = types
            } else if option == "xmlhttprequest" || option == "xhr" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("raw")
                options["resource-type"] = types
            } else if option == "media" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("media")
                options["resource-type"] = types
            } else if option == "font" {
                var types = options["resource-type"] as? [String] ?? []
                types.append("font")
                options["resource-type"] = types
            }
        }
    }
    
    private func parseDomains(_ domainsStr: String) -> [String: Any] {
        let domains = domainsStr.components(separatedBy: ",")
        var includeDomains: [String] = []
        var excludeDomains: [String] = []
        
        for domain in domains {
            let trimmed = domain.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("~") {
                excludeDomains.append(String(trimmed.dropFirst()))
            } else if !trimmed.isEmpty {
                includeDomains.append(trimmed)
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
            if domain.hasPrefix("~") {
                exclude.append(String(domain.dropFirst()))
            } else {
                include.append(domain)
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
        return [
            "action": [
                "type": "scriptlet",
                "scriptlet": scriptletName,
                "arguments": args
            ],
            "trigger": [
                "url-filter": ".*",
                "if-domain": [
                    "*youtube.com",
                    "*youtube-nocookie.com",
                    "*googlevideo.com",
                    "*ytimg.com"
                ],
                "resource-type": ["document", "script"]
            ]
        ]
    }
}
