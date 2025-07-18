import Cocoa
import FlutterMacOS
import SafariServices

public class FlutterWblockPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let progressChannel: FlutterEventChannel
    private var progressSink: FlutterEventSink?
    private let filterManager: FilterManager
    private let contentBlockerManager: ContentBlockerManager
    
    init(channel: FlutterMethodChannel, progressChannel: FlutterEventChannel) {
        self.channel = channel
        self.progressChannel = progressChannel
        self.filterManager = FilterManager()
        self.contentBlockerManager = ContentBlockerManager()
        super.init()
        
        setupEventChannel()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_wblock_plugin",
            binaryMessenger: registrar.messenger
        )
        let progressChannel = FlutterEventChannel(
            name: "flutter_wblock_plugin/progress",
            binaryMessenger: registrar.messenger
        )
        let instance = FlutterWblockPlugin(channel: channel, progressChannel: progressChannel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private func setupEventChannel() {
        progressChannel.setStreamHandler(self)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadFilterLists":
            loadFilterLists(result: result)
            
        case "saveFilterLists":
            if let args = call.arguments as? [String: Any],
               let filterListsData = args["filterLists"] as? [[String: Any]] {
                saveFilterLists(filterListsData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "toggleFilter":
            if let args = call.arguments as? [String: Any],
               let filterId = args["filterId"] as? String {
                toggleFilter(filterId, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "applyChanges":
            if let args = call.arguments as? [String: Any],
               let filterListsData = args["filterLists"] as? [[String: Any]] {
                applyChanges(filterListsData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "checkForUpdates":
            if let args = call.arguments as? [String: Any],
               let filterListsData = args["filterLists"] as? [[String: Any]] {
                checkForUpdates(filterListsData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "updateFilters":
            if let args = call.arguments as? [String: Any],
               let filterListsData = args["filterLists"] as? [[String: Any]] {
                updateFilters(filterListsData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "addCustomFilter":
            if let filterData = call.arguments as? [String: Any] {
                addCustomFilter(filterData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "removeCustomFilter":
            if let args = call.arguments as? [String: Any],
               let filterId = args["filterId"] as? String {
                removeCustomFilter(filterId, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "getFilterStats":
            if let args = call.arguments as? [String: Any],
               let filterListsData = args["filterLists"] as? [[String: Any]] {
                getFilterStats(filterListsData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "getLogs":
            getLogs(result: result)
            
        case "clearLogs":
            clearLogs(result: result)
            
        case "downloadFilter":
            if let filterData = call.arguments as? [String: Any] {
                downloadFilter(filterData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "getRuleCount":
            if let filterData = call.arguments as? [String: Any] {
                getRuleCount(filterData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        case "filterFileExists":
            if let filterData = call.arguments as? [String: Any] {
                filterFileExists(filterData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Method Implementations
    
    private func loadFilterLists(result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = await filterManager.loadFilterLists()
                let data = filterLists.map { $0.toDictionary() }
                result(data)
            } catch {
                result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func saveFilterLists(_ filterListsData: [[String: Any]], result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = filterListsData.compactMap { NativeFilterList.fromDictionary($0) }
                await filterManager.saveFilterLists(filterLists)
                result(nil)
            } catch {
                result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func toggleFilter(_ filterId: String, result: @escaping FlutterResult) {
        Task {
            do {
                await filterManager.toggleFilter(filterId: filterId)
                result(nil)
            } catch {
                result(FlutterError(code: "TOGGLE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func applyChanges(_ filterListsData: [[String: Any]], result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = filterListsData.compactMap { NativeFilterList.fromDictionary($0) }
                
                // Report progress
                await contentBlockerManager.applyChanges(
                    filterLists: filterLists,
                    progressCallback: { [weak self] progress in
                        self?.progressSink?(progress)
                    }
                )
                
                result(nil)
            } catch {
                result(FlutterError(code: "APPLY_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func checkForUpdates(_ filterListsData: [[String: Any]], result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = filterListsData.compactMap { NativeFilterList.fromDictionary($0) }
                let updates = await filterManager.checkForUpdates(filterLists: filterLists)
                let data = updates.map { $0.toDictionary() }
                result(data)
            } catch {
                result(FlutterError(code: "UPDATE_CHECK_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func updateFilters(_ filterListsData: [[String: Any]], result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = filterListsData.compactMap { NativeFilterList.fromDictionary($0) }
                
                await filterManager.updateFilters(
                    filterLists: filterLists,
                    progressCallback: { [weak self] progress in
                        self?.progressSink?(progress)
                    }
                )
                
                result(nil)
            } catch {
                result(FlutterError(code: "UPDATE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func addCustomFilter(_ filterData: [String: Any], result: @escaping FlutterResult) {
        Task {
            do {
                guard let filter = NativeFilterList.fromDictionary(filterData) else {
                    result(FlutterError(code: "INVALID_FILTER", message: nil, details: nil))
                    return
                }
                
                await filterManager.addCustomFilter(filter)
                result(nil)
            } catch {
                result(FlutterError(code: "ADD_FILTER_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func removeCustomFilter(_ filterId: String, result: @escaping FlutterResult) {
        Task {
            do {
                await filterManager.removeCustomFilter(filterId: filterId)
                result(nil)
            } catch {
                result(FlutterError(code: "REMOVE_FILTER_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func getFilterStats(_ filterListsData: [[String: Any]], result: @escaping FlutterResult) {
        Task {
            do {
                let filterLists = filterListsData.compactMap { NativeFilterList.fromDictionary($0) }
                let stats = await contentBlockerManager.getFilterStats(filterLists: filterLists)
                result(stats.toDictionary())
            } catch {
                result(FlutterError(code: "STATS_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func getLogs(result: @escaping FlutterResult) {
        Task {
            let logs = await LogManager.shared.getLogs()
            result(logs)
        }
    }
    
    private func clearLogs(result: @escaping FlutterResult) {
        Task {
            await LogManager.shared.clearLogs()
            result(nil)
        }
    }
    
    private func downloadFilter(_ filterData: [String: Any], result: @escaping FlutterResult) {
        Task {
            do {
                guard let filter = NativeFilterList.fromDictionary(filterData) else {
                    result(FlutterError(code: "INVALID_FILTER", message: nil, details: nil))
                    return
                }
                
                await filterManager.downloadFilter(filter)
                result(nil)
            } catch {
                result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func getRuleCount(_ filterData: [String: Any], result: @escaping FlutterResult) {
        Task {
            do {
                guard let filter = NativeFilterList.fromDictionary(filterData) else {
                    result(FlutterError(code: "INVALID_FILTER", message: nil, details: nil))
                    return
                }
                
                let count = await contentBlockerManager.getRuleCount(for: filter)
                result(count)
            } catch {
                result(FlutterError(code: "RULE_COUNT_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func filterFileExists(_ filterData: [String: Any], result: @escaping FlutterResult) {
        guard let filter = NativeFilterList.fromDictionary(filterData) else {
            result(FlutterError(code: "INVALID_FILTER", message: nil, details: nil))
            return
        }
        
        let exists = filterManager.filterFileExists(filter)
        result(exists)
    }
}

// MARK: - FlutterStreamHandler

extension FlutterWblockPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        progressSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        progressSink = nil
        return nil
    }
}
