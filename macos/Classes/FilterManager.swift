import Foundation

@MainActor
class FilterManager {
    private let appGroupIdentifier = "group.syferlab.wBlock"
    private let filterListsKey = "filterLists"
    private let customFilterListsKey = "customFilterLists"
    private let lastUpdateKey = "lastUpdateDates"
    
    private var groupDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }
    
    func loadFilterLists() async -> [NativeFilterList] {
        // Try to load saved filter lists
        if let data = groupDefaults?.data(forKey: filterListsKey),
           let filterLists = try? JSONDecoder().decode([NativeFilterList].self, from: data) {
            return filterLists
        }
        
        // Return empty array if none found (Flutter side will provide defaults)
        return []
    }
    
    func saveFilterLists(_ filterLists: [NativeFilterList]) async {
        if let data = try? JSONEncoder().encode(filterLists) {
            groupDefaults?.set(data, forKey: filterListsKey)
            await LogManager.shared.log("Saved \(filterLists.count) filter lists")
        }
    }
    
    func toggleFilter(filterId: String) async {
        var filterLists = await loadFilterLists()
        if let index = filterLists.firstIndex(where: { $0.id == filterId }) {
            filterLists[index].isSelected.toggle()
            await saveFilterLists(filterLists)
            await LogManager.shared.log("Toggled filter: \(filterLists[index].name)")
        }
    }
    
    func addCustomFilter(_ filter: NativeFilterList) async {
        var filterLists = await loadFilterLists()
        filterLists.append(filter)
        await saveFilterLists(filterLists)
        
        // Also save to custom filters list
        var customFilters = loadCustomFilterLists()
        customFilters.append(filter)
        saveCustomFilterLists(customFilters)
        
        await LogManager.shared.log("Added custom filter: \(filter.name)")
    }
    
    func removeCustomFilter(filterId: String) async {
        var filterLists = await loadFilterLists()
        filterLists.removeAll { $0.id == filterId }
        await saveFilterLists(filterLists)
        
        // Also remove from custom filters list
        var customFilters = loadCustomFilterLists()
        if let filter = customFilters.first(where: { $0.id == filterId }) {
            customFilters.removeAll { $0.id == filterId }
            saveCustomFilterLists(customFilters)
            
            // Remove associated files
            if let containerURL = containerURL {
                let fileURLs = [
                    containerURL.appendingPathComponent("\(filter.name).json"),
                    containerURL.appendingPathComponent("\(filter.name)_advanced.json"),
                    containerURL.appendingPathComponent("\(filter.name)_scriptlets.json"),
                    containerURL.appendingPathComponent("\(filter.name).txt")
                ]
                
                for url in fileURLs {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        
        await LogManager.shared.log("Removed custom filter with ID: \(filterId)")
    }
    
    func filterFileExists(_ filter: NativeFilterList) -> Bool {
        guard let containerURL = containerURL else { return false }
        
        let standardFileURL = containerURL.appendingPathComponent("\(filter.name).json")
        let advancedFileURL = containerURL.appendingPathComponent("\(filter.name)_advanced.json")
        let txtFileURL = containerURL.appendingPathComponent("\(filter.name).txt")
        
        return FileManager.default.fileExists(atPath: standardFileURL.path) ||
               FileManager.default.fileExists(atPath: advancedFileURL.path) ||
               FileManager.default.fileExists(atPath: txtFileURL.path)
    }
    
    func downloadFilter(_ filter: NativeFilterList) async {
        await LogManager.shared.log("Downloading filter: \(filter.name) from \(filter.url)")
        
        do {
            var request = URLRequest(url: filter.url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpMethod = "GET"
            request.setValue("wBlock/0.2.0 (macOS Safari Extension)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await LogManager.shared.log("Failed to download filter \(filter.name): Invalid response")
                return
            }
            
            if let containerURL = containerURL {
                let fileURL = containerURL.appendingPathComponent("\(filter.name).txt")
                try data.write(to: fileURL)
                
                // Save last update time
                saveLastUpdateTime(for: filter.id)
                
                // Extract version from content if available
                if let content = String(data: data, encoding: .utf8) {
                    let version = extractVersion(from: content)
                    if !version.isEmpty {
                        await updateFilterVersion(filter.id, version: version)
                    }
                }
                
                await LogManager.shared.log("Downloaded filter: \(filter.name) (\(data.count) bytes)")
            }
        } catch {
            await LogManager.shared.log("Failed to download filter \(filter.name): \(error)")
        }
    }
    
    func checkForUpdates(filterLists: [NativeFilterList]) async -> [NativeFilterList] {
        var updatesAvailable: [NativeFilterList] = []
        
        await LogManager.shared.log("Checking for updates for \(filterLists.count) filters")
        
        for filter in filterLists where filter.isSelected {
            if await hasUpdate(for: filter) {
                updatesAvailable.append(filter)
            }
        }
        
        await LogManager.shared.log("Found \(updatesAvailable.count) filters with updates")
        return updatesAvailable
    }
    
    func updateFilters(filterLists: [NativeFilterList], progressCallback: @escaping (Double) -> Void) async {
        let total = Double(filterLists.count)
        var completed = 0.0
        
        for filter in filterLists {
            await downloadFilter(filter)
            completed += 1
            progressCallback(completed / total)
        }
        
        await LogManager.shared.log("Updated \(filterLists.count) filters")
    }
    
    // MARK: - Private Methods
    
    private func loadCustomFilterLists() -> [NativeFilterList] {
        if let data = groupDefaults?.data(forKey: customFilterListsKey),
           let customFilters = try? JSONDecoder().decode([NativeFilterList].self, from: data) {
            return customFilters
        }
        return []
    }
    
    private func saveCustomFilterLists(_ customFilters: [NativeFilterList]) {
        if let data = try? JSONEncoder().encode(customFilters) {
            groupDefaults?.set(data, forKey: customFilterListsKey)
        }
    }
    
    private func hasUpdate(for filter: NativeFilterList) async -> Bool {
        // Check if filter file exists
        guard filterFileExists(filter) else {
            return true // Need to download
        }
        
        // Check last update time
        if let lastUpdate = getLastUpdateTime(for: filter.id) {
            let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
            
            // Update if older than 24 hours
            if hoursSinceUpdate > 24 {
                return true
            }
        } else {
            // No update time recorded, should update
            return true
        }
        
        // Check version via HEAD request
        return await checkRemoteVersion(for: filter)
    }
    
    private func checkRemoteVersion(for filter: NativeFilterList) async -> Bool {
        do {
            var request = URLRequest(url: filter.url)
            request.httpMethod = "HEAD"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // Check Last-Modified header
            if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified"),
               let lastUpdate = getLastUpdateTime(for: filter.id) {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                if let remoteDate = formatter.date(from: lastModified) {
                    return remoteDate > lastUpdate
                }
            }
            
            // Check ETag
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                let savedEtag = getSavedETag(for: filter.id)
                return etag != savedEtag
            }
            
            return false
        } catch {
            await LogManager.shared.log("Failed to check remote version for \(filter.name): \(error)")
            return false
        }
    }
    
    private func extractVersion(from content: String) -> String {
        // Look for version in filter list header
        let lines = content.components(separatedBy: .newlines).prefix(10)
        
        for line in lines {
            if line.contains("Version:") || line.contains("version:") {
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Check for date-based version
            if line.contains("Last modified:") || line.contains("Updated:") {
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Use current date as version
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func updateFilterVersion(_ filterId: String, version: String) async {
        var filterLists = await loadFilterLists()
        if let index = filterLists.firstIndex(where: { $0.id == filterId }) {
            filterLists[index].version = version
            await saveFilterLists(filterLists)
        }
    }
    
    private func saveLastUpdateTime(for filterId: String) {
        var updateTimes = groupDefaults?.dictionary(forKey: lastUpdateKey) ?? [:]
        updateTimes[filterId] = Date().timeIntervalSince1970
        groupDefaults?.set(updateTimes, forKey: lastUpdateKey)
    }
    
    private func getLastUpdateTime(for filterId: String) -> Date? {
        guard let updateTimes = groupDefaults?.dictionary(forKey: lastUpdateKey),
              let timestamp = updateTimes[filterId] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func getSavedETag(for filterId: String) -> String? {
        return groupDefaults?.string(forKey: "etag_\(filterId)")
    }
    
    private func saveETag(_ etag: String, for filterId: String) {
        groupDefaults?.set(etag, forKey: "etag_\(filterId)")
    }
}
