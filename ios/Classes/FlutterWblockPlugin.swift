import Flutter
import UIKit
import wBlockCoreService

public class FlutterWblockPlugin: NSObject, FlutterPlugin {
    private var filterManager: AppFilterManager?
    private var userScriptManager: UserScriptManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_wblock_plugin", binaryMessenger: registrar.messenger())
        let instance = FlutterWblockPlugin()
        instance.setupManagers()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
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
            result(filterManager?.isLoading ?? false)
            
        case "getStatusDescription":
            result(filterManager?.statusDescription ?? "")
            
        case "getLastRuleCount":
            result(filterManager?.lastRuleCount ?? 0)
            
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
            result(filterManager?.hasUnappliedChanges ?? false)
            
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Method Implementations
    
    private func getFilterLists(result: @escaping FlutterResult) {
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
    
    private func toggleFilterListSelection(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid filter ID", details: nil))
            return
        }
        
        filterManager?.toggleFilterListSelection(id: uuid)
        result(nil)
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
        filterManager?.addFilterList(name: name, urlString: urlString)
        result(nil)
    }
    
    private func removeFilterList(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId),
              let filter = filterManager?.filterLists.first(where: { $0.id == uuid }) else {
            result(FlutterError(code: "INVALID_ID", message: "Filter not found", details: nil))
            return
        }
        
        filterManager?.removeFilterList(filter)
        result(nil)
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
        
        filterManager?.showCategoryWarning(for: category)
        result(nil)
    }
    
    private func isCategoryApproachingLimit(category: String, result: @escaping FlutterResult) {
        guard let category = FilterListCategory(rawValue: category) else {
            result(FlutterError(code: "INVALID_CATEGORY", message: "Invalid category", details: nil))
            return
        }
        
        let isApproaching = filterManager?.isCategoryApproachingLimit(category) ?? false
        result(isApproaching)
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
    
    private func toggleUserScript(scriptId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: scriptId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid script ID", details: nil))
            return
        }
        
        if let script = userScriptManager?.userScripts.first(where: { $0.id == uuid }) {
            userScriptManager?.toggleUserScript(script)
            result(nil)
        } else {
            result(FlutterError(code: "SCRIPT_NOT_FOUND", message: "Script not found", details: nil))
        }
    }
    
    private func removeUserScript(scriptId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: scriptId) else {
            result(FlutterError(code: "INVALID_ID", message: "Invalid script ID", details: nil))
            return
        }
        
        if let script = userScriptManager?.userScripts.first(where: { $0.id == uuid }) {
            userScriptManager?.removeUserScript(script)
            result(nil)
        } else {
            result(FlutterError(code: "SCRIPT_NOT_FOUND", message: "Script not found", details: nil))
        }
    }
    
    private func addUserScript(name: String, content: String, result: @escaping FlutterResult) {
        // UserScriptManager expects a URL for adding scripts
        // For local content, we'll need to create a temporary file or use a different approach
        result(FlutterError(code: "NOT_IMPLEMENTED", 
                           message: "Adding user scripts from content not implemented. Use URL instead.", 
                           details: nil))
    }
    
    private func getWhitelistedDomains(result: @escaping FlutterResult) {
        let domains = filterManager?.whitelistViewModel.whitelistedDomains ?? []
        result(domains)
    }
    
    private func addWhitelistedDomain(domain: String, result: @escaping FlutterResult) {
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
    
    private func removeWhitelistedDomain(domain: String, result: @escaping FlutterResult) {
        filterManager?.whitelistViewModel.removeDomain(domain)
        result(nil)
    }
    
    private func updateWhitelistedDomains(domains: [String], result: @escaping FlutterResult) {
        // Clear existing domains and add new ones
        filterManager?.whitelistViewModel.whitelistedDomains = domains
        let userDefaults = UserDefaults(suiteName: "group.syferlab.wBlock") ?? UserDefaults.standard
        userDefaults.set(domains, forKey: "disabledSites")
        result(nil)
    }
    
    private func getFilterDetails(filterId: String, result: @escaping FlutterResult) {
        guard let uuid = UUID(uuidString: filterId),
              let filter = filterManager?.filterLists.first(where: { $0.id == uuid }) else {
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
    
    private func getRuleCountsByCategory(result: @escaping FlutterResult) {
        guard let filterManager = filterManager else {
            result(nil)
            return
        }
        
        let categoryRuleCounts = filterManager.ruleCountsByCategory.reduce(into: [String: Int]()) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        
        result(categoryRuleCounts)
    }
    
    private func getCategoriesApproachingLimit(result: @escaping FlutterResult) {
        guard let filterManager = filterManager else {
            result(nil)
            return
        }
        
        let categories = filterManager.categoriesApproachingLimit.map { $0.rawValue }
        result(categories)
    }
    
    private func checkForFilterUpdates(result: @escaping FlutterResult) {
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
    
    private func applyFilterUpdates(updateIds: [String], result: @escaping FlutterResult) {
        guard let filterManager = filterManager else {
            result(FlutterError(code: "NO_MANAGER", message: "Filter manager not initialized", details: nil))
            return
        }
        
        let selectedUpdates = filterManager.availableUpdates.filter { filter in
            updateIds.contains(filter.id.uuidString)
        }
        
        Task {
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
        guard let filterManager = filterManager else {
            result(FlutterError(code: "NO_MANAGER", message: "Filter manager not initialized", details: nil))
            return
        }
        
        let selectedFilters = filterManager.filterLists.filter { filter in
            filterIds.contains(filter.id.uuidString)
        }
        
        Task {
            await filterManager.downloadSelectedFilters(selectedFilters)
            result(nil)
        }
    }
    
    private func resetToDefaultLists(result: @escaping FlutterResult) {
        filterManager?.resetToDefaultLists()
        result(nil)
    }
    
    private func setUserScriptManager(result: @escaping FlutterResult) {
        // UserScriptManager is already set during setupManagers
        // This method exists for API compatibility
        result(nil)
    }
}
