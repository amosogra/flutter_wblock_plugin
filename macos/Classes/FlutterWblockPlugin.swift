import Cocoa
import FlutterMacOS
import wBlockCoreService

public class FlutterWblockPlugin: NSObject, FlutterPlugin {
    private var filterManager: AppFilterManager?
    private var userScriptManager: UserScriptManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_wblock_plugin", binaryMessenger: registrar.messenger)
        let instance = FlutterWblockPlugin()
        Task { @MainActor in
            instance.setupManagers()
        }
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    @MainActor
    private func setupManagers() {
        filterManager = AppFilterManager()
        userScriptManager = UserScriptManager()
        filterManager?.setUserScriptManager(userScriptManager!)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getFilterLists":
            getFilterLists(result: result)
            
        case "toggleFilterListSelection":
            guard let args = call.arguments as? [String: Any],
                  let filterId = args["filterId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filterId", details: nil))
                return
            }
            toggleFilterListSelection(filterId: filterId, result: result)
            
        case "checkAndEnableFilters":
            let args = call.arguments as? [String: Any]
            let forceReload = args?["forceReload"] as? Bool ?? false
            checkAndEnableFilters(forceReload: forceReload, result: result)
            
        case "checkForUpdates":
            checkForUpdates(result: result)
            
        case "isLoading":
            Task { @MainActor in
                result(filterManager?.isLoading ?? false)
            }
            
        case "getStatusDescription":
            Task { @MainActor in
                result(filterManager?.statusDescription ?? "")
            }
            
        case "getLastRuleCount":
            Task { @MainActor in
                result(filterManager?.lastRuleCount ?? 0)
            }
            
        case "addFilterList":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String,
                  let urlString = args["urlString"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing name or urlString", details: nil))
                return
            }
            addFilterList(name: name, urlString: urlString, result: result)
            
        case "removeFilterList":
            guard let args = call.arguments as? [String: Any],
                  let filterId = args["filterId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filterId", details: nil))
                return
            }
            removeFilterList(filterId: filterId, result: result)
            
        case "updateVersionsAndCounts":
            updateVersionsAndCounts(result: result)
            
        case "hasUnappliedChanges":
            Task { @MainActor in
                result(filterManager?.hasUnappliedChanges ?? false)
            }
            
        case "applyDownloadedChanges":
            applyDownloadedChanges(result: result)
            
        case "showCategoryWarning":
            guard let args = call.arguments as? [String: Any],
                  let category = args["category"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing category", details: nil))
                return
            }
            showCategoryWarning(category: category, result: result)
            
        case "isCategoryApproachingLimit":
            guard let args = call.arguments as? [String: Any],
                  let category = args["category"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing category", details: nil))
                return
            }
            isCategoryApproachingLimit(category: category, result: result)
            
        case "getLogs":
            getLogs(result: result)
            
        case "clearLogs":
            clearLogs(result: result)
            
        case "getUserScripts":
            getUserScripts(result: result)
            
        case "toggleUserScript":
            guard let args = call.arguments as? [String: Any],
                  let scriptId = args["scriptId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing scriptId", details: nil))
                return
            }
            toggleUserScript(scriptId: scriptId, result: result)
            
        case "removeUserScript":
            guard let args = call.arguments as? [String: Any],
                  let scriptId = args["scriptId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing scriptId", details: nil))
                return
            }
            removeUserScript(scriptId: scriptId, result: result)
            
        case "addUserScript":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String,
                  let content = args["content"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing name or content", details: nil))
                return
            }
            addUserScript(name: name, content: content, result: result)
            
        case "getWhitelistedDomains":
            getWhitelistedDomains(result: result)
            
        case "addWhitelistedDomain":
            guard let args = call.arguments as? [String: Any],
                  let domain = args["domain"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing domain", details: nil))
                return
            }
            addWhitelistedDomain(domain: domain, result: result)
            
        case "removeWhitelistedDomain":
            guard let args = call.arguments as? [String: Any],
                  let domain = args["domain"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing domain", details: nil))
                return
            }
            removeWhitelistedDomain(domain: domain, result: result)
            
        case "updateWhitelistedDomains":
            guard let args = call.arguments as? [String: Any],
                  let domains = args["domains"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing domains", details: nil))
                return
            }
            updateWhitelistedDomains(domains: domains, result: result)
            
        case "getFilterDetails":
            guard let args = call.arguments as? [String: Any],
                  let filterId = args["filterId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filterId", details: nil))
                return
            }
            getFilterDetails(filterId: filterId, result: result)
            
        case "resetOnboarding":
            resetOnboarding(result: result)
            
        case "hasCompletedOnboarding":
            hasCompletedOnboarding(result: result)
            
        case "setOnboardingCompleted":
            guard let args = call.arguments as? [String: Any],
                  let completed = args["completed"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing completed", details: nil))
                return
            }
            setOnboardingCompleted(completed: completed, result: result)
            
        case "getApplyProgress":
            getApplyProgress(result: result)
            
        case "getRuleCountsByCategory":
            getRuleCountsByCategory(result: result)
            
        case "getCategoriesApproachingLimit":
            getCategoriesApproachingLimit(result: result)
            
        case "checkForFilterUpdates":
            checkForFilterUpdates(result: result)
            
        case "applyFilterUpdates":
            guard let args = call.arguments as? [String: Any],
                  let updateIds = args["updateIds"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing updateIds", details: nil))
                return
            }
            applyFilterUpdates(updateIds: updateIds, result: result)
            
        case "downloadMissingFilters":
            downloadMissingFilters(result: result)
            
        case "updateMissingFilters":
            updateMissingFilters(result: result)
            
        case "downloadSelectedFilters":
            guard let args = call.arguments as? [String: Any],
                  let filterIds = args["filterIds"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filterIds", details: nil))
                return
            }
            downloadSelectedFilters(filterIds: filterIds, result: result)
            
        case "resetToDefaultLists":
            resetToDefaultLists(result: result)
            
        case "setUserScriptManager":
            setUserScriptManager(result: result)
            
        case "doesFilterFileExist":
            guard let args = call.arguments as? [String: Any],
                  let filterId = args["filterId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filterId", details: nil))
                return
            }
            doesFilterFileExist(filterId: filterId, result: result)
            
        case "getMissingFilters":
            getMissingFilters(result: result)
            
        case "getTimingStatistics":
            getTimingStatistics(result: result)
            
        case "getSourceRulesCount":
            getSourceRulesCount(result: result)
            
        case "getDetailedProgress":
            getDetailedProgress(result: result)
            
        case "getShowingUpdatePopup":
            getShowingUpdatePopup(result: result)
            
        case "getShowingApplyProgressSheet":
            getShowingApplyProgressSheet(result: result)
            
        case "getShowMissingFiltersSheet":
            getShowMissingFiltersSheet(result: result)
            
        case "setShowingUpdatePopup":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowingUpdatePopup(value: value, result: result)
            
        case "setShowingApplyProgressSheet":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowingApplyProgressSheet(value: value, result: result)
            
        case "setShowMissingFiltersSheet":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowMissingFiltersSheet(value: value, result: result)
            
        case "getAvailableUpdates":
            getAvailableUpdates(result: result)
            
        case "getCategoryWarningMessage":
            getCategoryWarningMessage(result: result)
            
        case "getShowingCategoryWarningAlert":
            getShowingCategoryWarningAlert(result: result)
            
        case "setShowingCategoryWarningAlert":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowingCategoryWarningAlert(value: value, result: result)
            
        case "getShowingNoUpdatesAlert":
            getShowingNoUpdatesAlert(result: result)
            
        case "setShowingNoUpdatesAlert":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowingNoUpdatesAlert(value: value, result: result)
            
        case "getShowingDownloadCompleteAlert":
            getShowingDownloadCompleteAlert(result: result)
            
        case "setShowingDownloadCompleteAlert":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing value", details: nil))
                return
            }
            setShowingDownloadCompleteAlert(value: value, result: result)
            
        case "getDownloadCompleteMessage":
            getDownloadCompleteMessage(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Method Implementations
    
    private func getFilterLists(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(FlutterError(code: "NO_MANAGER", message: "Filter manager not initialized", details: nil))
                return
            }
            
            let filterLists = filterManager.filterLists.map { filter in
                return [
                    "id": filter.id.uuidString,
                    "name": filter.name,
                    "description": filter.description,
                    "category": filter.category.rawValue,
                    "url": filter.url.absoluteString,
                    "version": filter.version,
                    "isSelected": filter.isSelected,
                    "sourceRuleCount": filter.sourceRuleCount as Any
                ]
            }
            result(filterLists)
        }
    }
    
    private func toggleFilterListSelection(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid filter ID", details: nil))
            return
        }
        
        Task { @MainActor in
            filterManager?.toggleFilterListSelection(id: uuid)
            result(nil)
        }
    }
    
    private func checkAndEnableFilters(forceReload: Bool, result: @escaping FlutterResult) {
        Task {
            await filterManager?.checkAndEnableFilters(forceReload: forceReload)
            result(nil)
        }
    }
    
    private func checkForUpdates(result: @escaping FlutterResult) {
        Task {
            await filterManager?.checkForUpdates()
            result(nil)
        }
    }
    
    private func addFilterList(name: String, urlString: String, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.addFilterList(name: name, urlString: urlString)
            result(nil)
        }
    }
    
    private func removeFilterList(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid filter ID", details: nil))
            return
        }
        
        Task { @MainActor in
            guard let filter = filterManager?.filterLists.first(where: { $0.id == uuid }) else {
                result(FlutterError(code: "INVALID_ID", message: "Filter not found", details: nil))
                return
            }
            
            filterManager?.removeFilterList(filter)
            result(nil)
        }
    }
    
    private func updateVersionsAndCounts(result: @escaping FlutterResult) {
        Task {
            await filterManager?.updateVersionsAndCounts()
            result(nil)
        }
    }
    
    private func applyDownloadedChanges(result: @escaping FlutterResult) {
        Task {
            await filterManager?.applyDownloadedChanges()
            result(nil)
        }
    }
    
    private func showCategoryWarning(category: String, result: @escaping FlutterResult) {
        guard let category = FilterListCategory(rawValue: category) else {
            result(FlutterError(code: "INVALID_CATEGORY", message: "Invalid category", details: nil))
            return
        }
        
        Task { @MainActor in
            filterManager?.showCategoryWarning(for: category)
            result(nil)
        }
    }
    
    private func isCategoryApproachingLimit(category: String, result: @escaping FlutterResult) {
        guard let category = FilterListCategory(rawValue: category) else {
            result(FlutterError(code: "INVALID_CATEGORY", message: "Invalid category", details: nil))
            return
        }
        
        Task { @MainActor in
            let isApproaching = filterManager?.isCategoryApproachingLimit(category) ?? false
            result(isApproaching)
        }
    }
    
    private func getLogs(result: @escaping FlutterResult) {
        // ConcurrentLogManager doesn't expose getLogs publicly
        // get all logs instead
        Task {
            let logs = await ConcurrentLogManager.shared.getAllLogs()
            result(logs)
        }
    }
    
    private func clearLogs(result: @escaping FlutterResult) {
        Task {
            await ConcurrentLogManager.shared.clearLogs()
            result(nil)
        }
    }
    
    private func getUserScripts(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let userScriptManager = userScriptManager else {
                result(FlutterError(code: "NO_MANAGER", message: "UserScript manager not initialized", details: nil))
                return
            }
            
            let scripts = userScriptManager.userScripts.map { script in
                return [
                    "id": script.id.uuidString,
                    "name": script.name,
                    "content": script.content,
                    "isEnabled": script.isEnabled
                ]
            }
            result(scripts)
        }
    }
    
    private func toggleUserScript(scriptId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: scriptId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid script ID", details: nil))
            return
        }
        
        Task { @MainActor in
            if let script = userScriptManager?.userScripts.first(where: { $0.id == uuid }) {
                userScriptManager?.toggleUserScript(script)
                result(nil)
            } else {
                result(FlutterError(code: "SCRIPT_NOT_FOUND", message: "Script not found", details: nil))
            }
        }
    }
    
    private func removeUserScript(scriptId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: scriptId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid script ID", details: nil))
            return
        }
        
        Task { @MainActor in
            if let script = userScriptManager?.userScripts.first(where: { $0.id == uuid }) {
                userScriptManager?.removeUserScript(script)
                result(nil)
            } else {
                result(FlutterError(code: "SCRIPT_NOT_FOUND", message: "Script not found", details: nil))
            }
        }
    }
    
 
    
    private func getWhitelistedDomains(result: @escaping FlutterResult) {
        Task { @MainActor in
            let domains = filterManager?.whitelistViewModel.whitelistedDomains ?? []
            result(domains)
        }
    }
    
    private func addWhitelistedDomain(domain: String, result: @escaping FlutterResult) {
        Task { @MainActor in
            let addResult = filterManager?.whitelistViewModel.addDomain(domain)
            switch addResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(FlutterError(code: "ADD_DOMAIN_ERROR", 
                                   message: error.localizedDescription, 
                                   details: nil))
            case .none:
                result(FlutterError(code: "NO_MANAGER", 
                                   message: "Filter manager not initialized", 
                                   details: nil))
            }
        }
    }
    
    private func removeWhitelistedDomain(domain: String, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.whitelistViewModel.removeDomain(domain)
            result(nil)
        }
    }
    
    private func updateWhitelistedDomains(domains: [String], result: @escaping FlutterResult) {
        Task { @MainActor in
            // Clear existing domains and add new ones
            filterManager?.whitelistViewModel.whitelistedDomains = domains
            let userDefaults = UserDefaults(suiteName: "group.syferlab.wBlock") ?? UserDefaults.standard
            userDefaults.set(domains, forKey: "disabledSites")
            result(nil)
        }
    }
    
    private func getFilterDetails(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid filter ID", details: nil))
            return
        }
        
        Task { @MainActor in
            guard let filter = filterManager?.filterLists.first(where: { $0.id == uuid }) else {
                result(FlutterError(code: "INVALID_ID", message: "Filter not found", details: nil))
                return
            }
            
            let details = [
                "id": filter.id.uuidString,
                "name": filter.name,
                "description": filter.description,
                "category": filter.category.rawValue,
                "url": filter.url.absoluteString,
                "version": filter.version,
                "isSelected": filter.isSelected,
                "sourceRuleCount": filter.sourceRuleCount as Any
            ]
            result(details)
        }
    }
    
    private func resetOnboarding(result: @escaping FlutterResult) {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        result(nil)
    }
    
    private func hasCompletedOnboarding(result: @escaping FlutterResult) {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        result(hasCompleted)
    }
    
    private func setOnboardingCompleted(completed: Bool, result: @escaping FlutterResult) {
        UserDefaults.standard.set(completed, forKey: "hasCompletedOnboarding")
        result(nil)
    }
    
    private func getApplyProgress(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(nil)
                return
            }
            
            let progressData: [String: Any] = [
                "progress": filterManager.progress,
                "stageDescription": filterManager.conversionStageDescription,
                "currentFilterName": filterManager.currentFilterName,
                "processedFiltersCount": filterManager.processedFiltersCount,
                "totalFiltersCount": filterManager.totalFiltersCount,
                "isInConversionPhase": filterManager.isInConversionPhase,
                "isInSavingPhase": filterManager.isInSavingPhase,
                "isInEnginePhase": filterManager.isInEnginePhase,
                "isInReloadPhase": filterManager.isInReloadPhase,
                "sourceRulesCount": filterManager.sourceRulesCount,
                "lastConversionTime": filterManager.lastConversionTime,
                "lastReloadTime": filterManager.lastReloadTime,
                "lastRuleCount": filterManager.lastRuleCount,
                "hasError": filterManager.hasError,
                "ruleCountsByCategory": filterManager.ruleCountsByCategory.reduce(into: [String: Int]()) { result, pair in
                    result[pair.key.rawValue] = pair.value
                },
                "categoriesApproachingLimit": filterManager.categoriesApproachingLimit.map { $0.rawValue }
            ]
            
            result(progressData)
        }
    }
    
    private func getRuleCountsByCategory(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(nil)
                return
            }
            
            let categoryRuleCounts = filterManager.ruleCountsByCategory.reduce(into: [String: Int]()) { result, pair in
                result[pair.key.rawValue] = pair.value
            }
            
            result(categoryRuleCounts)
        }
    }
    
    private func getCategoriesApproachingLimit(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(nil)
                return
            }
            
            let categories = filterManager.categoriesApproachingLimit.map { $0.rawValue }
            result(categories)
        }
    }
    
    private func checkForFilterUpdates(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(nil)
                return
            }
            
            let updates = filterManager.availableUpdates.map { filter in
                return [
                    "id": filter.id.uuidString,
                    "name": filter.name,
                    "description": filter.description,
                    "category": filter.category.rawValue,
                    "url": filter.url.absoluteString,
                    "version": filter.version,
                    "isSelected": filter.isSelected,
                    "sourceRuleCount": filter.sourceRuleCount as Any
                ]
            }
            
            result(updates)
        }
    }
    
    private func applyFilterUpdates(updateIds: [String], result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(FlutterError(code: "NO_MANAGER", message: "Filter manager not initialized", details: nil))
                return
            }
            
            let selectedUpdates = filterManager.availableUpdates.filter { filter in
                updateIds.contains(filter.id.uuidString)
            }
            
            await filterManager.updateSelectedFilters(selectedUpdates)
            result(nil)
        }
    }
    
    private func downloadMissingFilters(result: @escaping FlutterResult) {
        Task {
            await filterManager?.downloadMissingFilters()
            result(nil)
        }
    }
    
    private func updateMissingFilters(result: @escaping FlutterResult) {
        Task {
            await filterManager?.updateMissingFilters()
            result(nil)
        }
    }
    
    private func downloadSelectedFilters(filterIds: [String], result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result(FlutterError(code: "NO_MANAGER", message: "Filter manager not initialized", details: nil))
                return
            }
            
            let selectedFilters = filterManager.filterLists.filter { filter in
                filterIds.contains(filter.id.uuidString)
            }
            
            await filterManager.downloadSelectedFilters(selectedFilters)
            result(nil)
        }
    }
    
    private func resetToDefaultLists(result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.resetToDefaultLists()
            result(nil)
        }
    }
    
    private func setUserScriptManager(result: @escaping FlutterResult) {
        // UserScriptManager is already set during setupManagers
        // This method exists for API compatibility
        result(nil)
    }
    
    private func addUserScript(name: String, content: String, result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let userScriptManager = userScriptManager else {
                result(FlutterError(code: "NO_MANAGER", message: "UserScript manager not initialized", details: nil))
                return
            }
            
            // Check if content is a URL
            if let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
               url.scheme != nil, url.host != nil {
                // It's a URL, download the script
                await userScriptManager.addUserScript(from: url)
                result(nil)
            } else {
                // It's raw script content, create a local script
                var newUserScript = UserScript(name: name, content: content)
                newUserScript.parseMetadata()
                newUserScript.isEnabled = true
                newUserScript.isLocal = true
                
                // Add to manager's array
                userScriptManager.userScripts.append(newUserScript)
                // Save would be handled by the manager's internal methods
                result(nil)
            }
        }
    }
    
    private func doesFilterFileExist(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId) else {
            result(false)
            return
        }
        
        Task { @MainActor in
            guard let filter = filterManager?.filterLists.first(where: { $0.id == uuid }) else {
                result(false)
                return
            }
            
            let exists = filterManager?.doesFilterFileExist(filter) ?? false
            result(exists)
        }
    }
    
    private func getMissingFilters(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result([])
                return
            }
            
            let missingFilters = filterManager.missingFilters.map { filter in
                return [
                    "id": filter.id.uuidString,
                    "name": filter.name,
                    "description": filter.description,
                    "category": filter.category.rawValue,
                    "url": filter.url.absoluteString,
                    "version": filter.version,
                    "isSelected": filter.isSelected,
                    "sourceRuleCount": filter.sourceRuleCount as Any
                ]
            }
            result(missingFilters)
        }
    }
}


extension FlutterWblockPlugin {
    
    // MARK: - Additional Method Implementations
    
    func getTimingStatistics(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result([:])
                return
            }
            
            let timingStats: [String: Any] = [
                "lastConversionTime": filterManager.lastConversionTime,
                "lastReloadTime": filterManager.lastReloadTime,
                "lastFastUpdateTime": filterManager.lastFastUpdateTime,
                "fastUpdateCount": filterManager.fastUpdateCount
            ]
            
            result(timingStats)
        }
    }
    
    func getSourceRulesCount(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.sourceRulesCount ?? 0)
        }
    }
    
    func getDetailedProgress(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result([:])
                return
            }
            
            let detailedProgress: [String: Any] = [
                "sourceRulesCount": filterManager.sourceRulesCount,
                "conversionStageDescription": filterManager.conversionStageDescription,
                "currentFilterName": filterManager.currentFilterName,
                "processedFiltersCount": filterManager.processedFiltersCount,
                "totalFiltersCount": filterManager.totalFiltersCount,
                "isInConversionPhase": filterManager.isInConversionPhase,
                "isInSavingPhase": filterManager.isInSavingPhase,
                "isInEnginePhase": filterManager.isInEnginePhase,
                "isInReloadPhase": filterManager.isInReloadPhase
            ]
            
            result(detailedProgress)
        }
    }
    
    func getShowingUpdatePopup(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showingUpdatePopup ?? false)
        }
    }
    
    func getShowingApplyProgressSheet(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showingApplyProgressSheet ?? false)
        }
    }
    
    func getShowMissingFiltersSheet(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showMissingFiltersSheet ?? false)
        }
    }
    
    func setShowingUpdatePopup(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showingUpdatePopup = value
            result(nil)
        }
    }
    
    func setShowingApplyProgressSheet(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showingApplyProgressSheet = value
            result(nil)
        }
    }
    
    func setShowMissingFiltersSheet(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showMissingFiltersSheet = value
            result(nil)
        }
    }
    
    func getAvailableUpdates(result: @escaping FlutterResult) {
        Task { @MainActor in
            guard let filterManager = filterManager else {
                result([])
                return
            }
            
            let availableUpdates = filterManager.availableUpdates.map { filter in
                return [
                    "id": filter.id.uuidString,
                    "name": filter.name,
                    "description": filter.description,
                    "category": filter.category.rawValue,
                    "url": filter.url.absoluteString,
                    "version": filter.version,
                    "isSelected": filter.isSelected,
                    "sourceRuleCount": filter.sourceRuleCount as Any
                ]
            }
            result(availableUpdates)
        }
    }
    
    func getCategoryWarningMessage(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.categoryWarningMessage ?? "")
        }
    }
    
    func getShowingCategoryWarningAlert(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showingCategoryWarningAlert ?? false)
        }
    }
    
    func setShowingCategoryWarningAlert(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showingCategoryWarningAlert = value
            result(nil)
        }
    }
    
    func getShowingNoUpdatesAlert(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showingNoUpdatesAlert ?? false)
        }
    }
    
    func setShowingNoUpdatesAlert(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showingNoUpdatesAlert = value
            result(nil)
        }
    }
    
    func getShowingDownloadCompleteAlert(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.showingDownloadCompleteAlert ?? false)
        }
    }
    
    func setShowingDownloadCompleteAlert(value: Bool, result: @escaping FlutterResult) {
        Task { @MainActor in
            filterManager?.showingDownloadCompleteAlert = value
            result(nil)
        }
    }
    
    func getDownloadCompleteMessage(result: @escaping FlutterResult) {
        Task { @MainActor in
            result(filterManager?.downloadCompleteMessage ?? "")
        }
    }
}
