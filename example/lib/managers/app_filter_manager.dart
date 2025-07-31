import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import '../models/filter_list.dart';

class AppFilterManager extends ChangeNotifier {
  List<FilterList> _filterLists = [];
  bool _isLoading = false;
  String _statusDescription = '';
  int _lastRuleCount = 0;
  bool _hasUnappliedChanges = false;
  bool _showingUpdatePopup = false;
  bool _showMissingFiltersSheet = false;
  bool _showingApplyProgressSheet = false;
  bool _showingNoUpdatesAlert = false;
  bool _showingDownloadCompleteAlert = false;
  bool _showingCategoryWarningAlert = false;
  String _downloadCompleteMessage = '';
  String _categoryWarningMessage = '';
  List<String> _whitelistedDomains = [];
  
  // Track available updates
  List<Map<String, dynamic>> _availableUpdates = [];

  // Getters
  List<FilterList> get filterLists => _filterLists;
  bool get isLoading => _isLoading;
  String get statusDescription => _statusDescription;
  int get lastRuleCount => _lastRuleCount;
  bool get hasUnappliedChanges => _hasUnappliedChanges;
  bool get showingUpdatePopup => _showingUpdatePopup;
  bool get showMissingFiltersSheet => _showMissingFiltersSheet;
  bool get showingApplyProgressSheet => _showingApplyProgressSheet;
  bool get showingNoUpdatesAlert => _showingNoUpdatesAlert;
  bool get showingDownloadCompleteAlert => _showingDownloadCompleteAlert;
  bool get showingCategoryWarningAlert => _showingCategoryWarningAlert;
  String get downloadCompleteMessage => _downloadCompleteMessage;
  String get categoryWarningMessage => _categoryWarningMessage;
  List<String> get whitelistedDomains => _whitelistedDomains;
  List<Map<String, dynamic>> get availableUpdates => _availableUpdates;

  AppFilterManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadFilterLists();
    await _loadWhitelistedDomains();
  }

  Future<void> loadFilterLists() async {
    try {
      _isLoading = true;
      _statusDescription = 'Loading filter lists...';
      notifyListeners();

      final lists = await FlutterWblockPlugin.getFilterLists();
      _filterLists = lists.map((data) => FilterList.fromMap(data)).toList();
      
      _lastRuleCount = await FlutterWblockPlugin.getLastRuleCount();
      _statusDescription = await FlutterWblockPlugin.getStatusDescription();
      _hasUnappliedChanges = await FlutterWblockPlugin.hasUnappliedChanges();

      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
      debugPrint('Error loading filter lists: $e');
    }
  }

  Future<void> _loadWhitelistedDomains() async {
    try {
      _whitelistedDomains = await FlutterWblockPlugin.getWhitelistedDomains();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading whitelisted domains: $e');
    }
  }

  Future<void> toggleFilterListSelection(String id) async {
    try {
      await FlutterWblockPlugin.toggleFilterListSelection(id);
      await loadFilterLists();
    } catch (e) {
      debugPrint('Error toggling filter list: $e');
    }
  }

  Future<void> checkAndEnableFilters({bool forceReload = false}) async {
    try {
      _isLoading = true;
      _statusDescription = 'Applying filters...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      await FlutterWblockPlugin.checkAndEnableFilters(forceReload: forceReload);
      
      await loadFilterLists();
      
      _showingApplyProgressSheet = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _showingApplyProgressSheet = false;
      notifyListeners();
      debugPrint('Error applying filters: $e');
    }
  }

  Future<void> checkForUpdates() async {
    try {
      _isLoading = true;
      _statusDescription = 'Checking for updates...';
      notifyListeners();

      // Check for updates from native side
      await FlutterWblockPlugin.checkForUpdates();
      
      // Simulate finding updates by checking version differences
      _availableUpdates = [];
      for (var filter in _filterLists) {
        if (filter.isSelected && filter.version.isNotEmpty) {
          // In a real implementation, this would compare with server versions
          // For now, we'll simulate some filters having updates
          if (filter.name.contains('AdGuard') || filter.name.contains('EasyList')) {
            _availableUpdates.add({
              'id': filter.id,
              'name': filter.name,
              'currentVersion': filter.version,
              'newVersion': _incrementVersion(filter.version),
              'url': filter.url,
            });
          }
        }
      }

      if (_availableUpdates.isEmpty) {
        _showingNoUpdatesAlert = true;
      } else {
        _showingUpdatePopup = true;
      }
      
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
      debugPrint('Error checking for updates: $e');
    }
  }

  String _incrementVersion(String version) {
    // Simple version increment for simulation
    if (version.contains('.')) {
      final parts = version.split('.');
      if (parts.isNotEmpty) {
        final lastPart = int.tryParse(parts.last) ?? 0;
        parts[parts.length - 1] = (lastPart + 1).toString();
        return parts.join('.');
      }
    }
    return '${version}.1';
  }

  void addFilterList({required String name, required String urlString}) async {
    try {
      await FlutterWblockPlugin.addFilterList(name: name, urlString: urlString);
      await loadFilterLists();
    } catch (e) {
      debugPrint('Error adding filter list: $e');
    }
  }

  void removeFilterList(FilterList filter) async {
    try {
      await FlutterWblockPlugin.removeFilterList(filter.id);
      await loadFilterLists();
    } catch (e) {
      debugPrint('Error removing filter list: $e');
    }
  }

  Future<void> updateVersionsAndCounts() async {
    try {
      await FlutterWblockPlugin.updateVersionsAndCounts();
      await loadFilterLists();
    } catch (e) {
      debugPrint('Error updating versions and counts: $e');
    }
  }

  Future<void> applyDownloadedChanges() async {
    try {
      _showingApplyProgressSheet = true;
      notifyListeners();
      
      await FlutterWblockPlugin.applyDownloadedChanges();
      await loadFilterLists();
      
      _showingApplyProgressSheet = false;
      notifyListeners();
    } catch (e) {
      _showingApplyProgressSheet = false;
      notifyListeners();
      debugPrint('Error applying downloaded changes: $e');
    }
  }

  Future<void> showCategoryWarning(String category) async {
    try {
      await FlutterWblockPlugin.showCategoryWarning(category);
      _showingCategoryWarningAlert = true;
      _categoryWarningMessage = 'The $category category is approaching the rule limit. Consider disabling some filters in this category to avoid issues.';
      notifyListeners();
    } catch (e) {
      debugPrint('Error showing category warning: $e');
    }
  }

  Future<bool> isCategoryApproachingLimit(String category) async {
    try {
      return await FlutterWblockPlugin.isCategoryApproachingLimit(category);
    } catch (e) {
      debugPrint('Error checking category limit: $e');
      return false;
    }
  }

  bool doesFilterFileExist(FilterList filter) {
    // Check if the filter has been downloaded by looking at rule count
    return filter.sourceRuleCount != null && filter.sourceRuleCount! > 0;
  }

  void setShowingUpdatePopup(bool value) {
    _showingUpdatePopup = value;
    notifyListeners();
  }

  void setShowingNoUpdatesAlert(bool value) {
    _showingNoUpdatesAlert = value;
    notifyListeners();
  }

  void setShowingDownloadCompleteAlert(bool value) {
    _showingDownloadCompleteAlert = value;
    notifyListeners();
  }

  void setShowingCategoryWarningAlert(bool value) {
    _showingCategoryWarningAlert = value;
    notifyListeners();
  }

  void setShowingApplyProgressSheet(bool value) {
    _showingApplyProgressSheet = value;
    notifyListeners();
  }

  void setShowMissingFiltersSheet(bool value) {
    _showMissingFiltersSheet = value;
    notifyListeners();
  }

  void setDownloadCompleteMessage(String message) {
    _downloadCompleteMessage = message;
    _showingDownloadCompleteAlert = true;
    notifyListeners();
  }

  // Whitelist management methods
  Future<void> addWhitelistedDomain(String domain) async {
    try {
      await FlutterWblockPlugin.addWhitelistedDomain(domain);
      await _loadWhitelistedDomains();
    } catch (e) {
      debugPrint('Error adding whitelisted domain: $e');
    }
  }

  Future<void> removeWhitelistedDomain(String domain) async {
    try {
      await FlutterWblockPlugin.removeWhitelistedDomain(domain);
      await _loadWhitelistedDomains();
    } catch (e) {
      debugPrint('Error removing whitelisted domain: $e');
    }
  }

  Future<void> updateWhitelistedDomains(List<String> domains) async {
    try {
      await FlutterWblockPlugin.updateWhitelistedDomains(domains);
      await _loadWhitelistedDomains();
    } catch (e) {
      debugPrint('Error updating whitelisted domains: $e');
    }
  }

  // Check for missing filters
  void checkMissingFilters() {
    final missingFilters = _filterLists
        .where((filter) => filter.isSelected && !doesFilterFileExist(filter))
        .toList();
    
    if (missingFilters.isNotEmpty) {
      _showMissingFiltersSheet = true;
      notifyListeners();
    }
  }

  // Apply updates from the update popup
  Future<void> applyUpdates(List<String> selectedUpdateIds) async {
    try {
      _isLoading = true;
      _statusDescription = 'Downloading updates...';
      notifyListeners();

      // Download and apply the selected updates
      int downloaded = 0;
      for (var updateId in selectedUpdateIds) {
        // In real implementation, this would download the specific update
        downloaded++;
      }

      if (downloaded > 0) {
        setDownloadCompleteMessage('Downloaded $downloaded filter updates. Apply now to activate the changes.');
      }

      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
      debugPrint('Error applying updates: $e');
    }
  }

  // This method would be called by UserScriptManager when it's set
  void setUserScriptManager(dynamic userScriptManager) {
    // The native code handles the relationship between managers
    // This is just to match the Swift implementation
  }
}
