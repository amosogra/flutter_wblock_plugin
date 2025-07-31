import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import '../models/filter_list.dart';

class AppFilterManager extends ChangeNotifier {
  List<FilterList> _filterLists = [];
  bool _isLoading = false;
  String _statusDescription = '';
  String _lastConversionTime = 'N/A';
  String _lastReloadTime = 'N/A';
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

  // Per-category rule count tracking
  Map<String, int> _ruleCountsByCategory = {};
  Set<String> _categoriesApproachingLimit = {};

  // Performance tracking
  String _lastFastUpdateTime = 'N/A';
  int _fastUpdateCount = 0;

  // Detailed progress tracking
  int _sourceRulesCount = 0;
  String _conversionStageDescription = '';
  String _currentFilterName = '';
  int _processedFiltersCount = 0;
  int _totalFiltersCount = 0;
  bool _isInConversionPhase = false;
  bool _isInSavingPhase = false;
  bool _isInEnginePhase = false;
  bool _isInReloadPhase = false;
  double _progress = 0.0;
  bool _hasError = false;

  // Getters
  List<FilterList> get filterLists => _filterLists;
  bool get isLoading => _isLoading;
  String get statusDescription => _statusDescription;
  String get lastConversionTime => _lastConversionTime;
  String get lastReloadTime => _lastReloadTime;
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

  // Progress tracking getters
  Map<String, int> get ruleCountsByCategory => _ruleCountsByCategory;
  Set<String> get categoriesApproachingLimit => _categoriesApproachingLimit;
  int get sourceRulesCount => _sourceRulesCount;
  String get conversionStageDescription => _conversionStageDescription;
  String get currentFilterName => _currentFilterName;
  int get processedFiltersCount => _processedFiltersCount;
  int get totalFiltersCount => _totalFiltersCount;
  bool get isInConversionPhase => _isInConversionPhase;
  bool get isInSavingPhase => _isInSavingPhase;
  bool get isInEnginePhase => _isInEnginePhase;
  bool get isInReloadPhase => _isInReloadPhase;
  double get progress => _progress;
  bool get hasError => _hasError;
  String get lastFastUpdateTime => _lastFastUpdateTime;
  int get fastUpdateCount => _fastUpdateCount;

  AppFilterManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadFilterLists();
    await _loadWhitelistedDomains();
    await _loadSavedRuleCounts();
  }

  Future<void> loadFilterLists() async {
    try {
      _isLoading = true;
      _statusDescription = 'Loading filter lists...';
      notifyListeners();

      final lists = await FlutterWblockPlugin.getFilterLists();
      _filterLists = lists.map((data) => FilterList.fromMap(data)).toList();

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

  Future<void> _loadSavedRuleCounts() async {
    try {
      // Load the last known rule count
      _lastRuleCount = await FlutterWblockPlugin.getLastRuleCount();

      // Load per-category rule counts from native side
      final categoryCounts = await FlutterWblockPlugin.getRuleCountsByCategory();
      if (categoryCounts != null) {
        _ruleCountsByCategory = Map<String, int>.from(categoryCounts);
      }

      // Load categories approaching limit from native side
      final approachingCategories = await FlutterWblockPlugin.getCategoriesApproachingLimit();
      if (approachingCategories != null) {
        _categoriesApproachingLimit = Set<String>.from(approachingCategories);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved rule counts: $e');
    }
  }

  Future<void> toggleFilterListSelection(String id) async {
    try {
      await FlutterWblockPlugin.toggleFilterListSelection(id);
      _hasUnappliedChanges = true;
      await loadFilterLists();
    } catch (e) {
      debugPrint('Error toggling filter list: $e');
    }
  }

  Future<void> checkAndEnableFilters({bool forceReload = false}) async {
    try {
      // First check for missing filters
      final missingFilters = _filterLists.where((filter) => filter.isSelected && !doesFilterFileExist(filter)).toList();

      if (missingFilters.isNotEmpty) {
        _showMissingFiltersSheet = true;
        notifyListeners();
        return;
      }

      if (forceReload || _hasUnappliedChanges) {
        _showingApplyProgressSheet = true;
        notifyListeners();

        // The actual conversion will be handled by the native side
        await FlutterWblockPlugin.checkAndEnableFilters(forceReload: forceReload);

        // Start monitoring the progress
        await _monitorApplyProgress();
      }
    } catch (e) {
      _isLoading = false;
      _showingApplyProgressSheet = false;
      notifyListeners();
      debugPrint('Error applying filters: $e');
    }
  }

  Future<void> _monitorApplyProgress() async {
    _isLoading = true;
    _progress = 0.0;
    _processedFiltersCount = 0;
    _totalFiltersCount = _filterLists.where((f) => f.isSelected).length;
    notifyListeners();

    // Monitor the progress from native side
    while (_isLoading && _progress < 1.0) {
      try {
        final progressData = await FlutterWblockPlugin.getApplyProgress();
        if (progressData != null) {
          _progress = progressData['progress'] ?? 0.0;
          _conversionStageDescription = progressData['stageDescription'] ?? '';
          _currentFilterName = progressData['currentFilterName'] ?? '';
          _processedFiltersCount = progressData['processedFiltersCount'] ?? 0;
          _totalFiltersCount = progressData['totalFiltersCount'] ?? _totalFiltersCount;
          _isInConversionPhase = progressData['isInConversionPhase'] ?? false;
          _isInSavingPhase = progressData['isInSavingPhase'] ?? false;
          _isInEnginePhase = progressData['isInEnginePhase'] ?? false;
          _isInReloadPhase = progressData['isInReloadPhase'] ?? false;
          _sourceRulesCount = progressData['sourceRulesCount'] ?? 0;
          _lastConversionTime = progressData['lastConversionTime'] ?? 'N/A';
          _lastReloadTime = progressData['lastReloadTime'] ?? 'N/A';
          _lastRuleCount = progressData['lastRuleCount'] ?? 0;
          _hasError = progressData['hasError'] ?? false;

          // Update rule counts by category
          final categoryRuleCounts = progressData['ruleCountsByCategory'];
          if (categoryRuleCounts != null) {
            _ruleCountsByCategory = Map<String, int>.from(categoryRuleCounts);
          }

          // Update categories approaching limit
          final approachingCategories = progressData['categoriesApproachingLimit'];
          if (approachingCategories != null) {
            _categoriesApproachingLimit = Set<String>.from(approachingCategories);
          }

          notifyListeners();

          if (_progress >= 1.0 || _hasError) {
            _isLoading = false;
            _hasUnappliedChanges = false;
            await _loadSavedRuleCounts(); // Reload saved counts after completion
            break;
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Error monitoring progress: $e');
        break;
      }
    }

    notifyListeners();
  }

  Future<void> checkForUpdates() async {
    try {
      _isLoading = true;
      _statusDescription = 'Checking for updates...';
      notifyListeners();

      // First ensure versions and counts are up to date
      await updateVersionsAndCounts();

      // Get available updates from native side
      final updates = await FlutterWblockPlugin.checkForFilterUpdates();

      if (updates != null && updates.isNotEmpty) {
        _availableUpdates = updates;
        _showingUpdatePopup = true;
        _statusDescription = 'Found ${updates.length} update(s) available.';
      } else {
        _availableUpdates = [];
        _showingNoUpdatesAlert = true;
        _statusDescription = 'No updates available.';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _statusDescription = '';
      notifyListeners();
      debugPrint('Error checking for updates: $e');
    }
  }

  void addFilterList({required String name, required String urlString}) async {
    try {
      await FlutterWblockPlugin.addFilterList(name: name, urlString: urlString);
      await loadFilterLists();
      _hasUnappliedChanges = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding filter list: $e');
    }
  }

  void removeFilterList(FilterList filter) async {
    try {
      await FlutterWblockPlugin.removeFilterList(filter.id);
      await loadFilterLists();
      _hasUnappliedChanges = true;
      notifyListeners();
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
    _showingApplyProgressSheet = true;
    notifyListeners();
    await checkAndEnableFilters(forceReload: true);
  }

  Future<void> showCategoryWarning(String category) async {
    try {
      final ruleCount = getCategoryRuleCount(category);
      final ruleLimit = Platform.isIOS ? 50000 : 150000;
      final warningThreshold = (ruleLimit * 0.8).toInt();

      _categoryWarningMessage = '''
Category "$category" is approaching its rule limit:

Current rules: ${ruleCount.toString()}
Limit: ${ruleLimit.toString()}
Warning threshold: ${warningThreshold.toString()}

When this category exceeds ${ruleLimit.toString()} rules, it will be automatically reset to recommended filters only to stay within Safari's content blocker limits.
''';

      _showingCategoryWarningAlert = true;
      notifyListeners();

      await FlutterWblockPlugin.showCategoryWarning(category);
    } catch (e) {
      debugPrint('Error showing category warning: $e');
    }
  }

  Future<bool> isCategoryApproachingLimit(String category) async {
    return _categoriesApproachingLimit.contains(category);
  }

  int getCategoryRuleCount(String category) {
    return _ruleCountsByCategory[category] ?? 0;
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
    final missingFilters = _filterLists.where((filter) => filter.isSelected && !doesFilterFileExist(filter)).toList();

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

      // Apply the selected updates through native side
      await FlutterWblockPlugin.applyFilterUpdates(selectedUpdateIds);

      // Reload filter lists to get updated versions
      await loadFilterLists();

      // Clear the updates that were applied
      _availableUpdates.removeWhere((update) => selectedUpdateIds.contains(update['id']));

      if (_availableUpdates.isEmpty) {
        _showingUpdatePopup = false;
      }

      setDownloadCompleteMessage('Downloaded ${selectedUpdateIds.length} filter updates. Apply now to activate the changes.');

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

  // Set UserScriptManager for native side coordination
  void setUserScriptManager(dynamic userScriptManager) async {
    // The native code handles the relationship between managers
    // This method exists to match the Swift implementation pattern
    await FlutterWblockPlugin.setUserScriptManager();
  }

  // Download missing filters
  Future<void> downloadMissingFilters() async {
    try {
      _isLoading = true;
      _progress = 0.0;
      _statusDescription = 'Downloading missing filters...';
      notifyListeners();

      await FlutterWblockPlugin.downloadMissingFilters();

      // Reload filter lists to reflect the downloaded filters
      await loadFilterLists();

      _showMissingFiltersSheet = false;
      setDownloadCompleteMessage('Downloaded missing filters. Apply now to activate the changes.');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error downloading missing filters: $e');
    }
  }

  // Update missing filters (download and apply)
  Future<void> updateMissingFilters() async {
    try {
      _isLoading = true;
      _progress = 0.0;
      notifyListeners();

      await FlutterWblockPlugin.updateMissingFilters();

      // Monitor progress while updating
      await _monitorApplyProgress();

      _showMissingFiltersSheet = false;
      await loadFilterLists();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating missing filters: $e');
    }
  }

  // Download selected filters from update popup
  Future<void> downloadSelectedFilters(List<String> filterIds) async {
    try {
      _isLoading = true;
      _progress = 0.0;
      _statusDescription = 'Downloading filter updates...';
      notifyListeners();

      await FlutterWblockPlugin.downloadSelectedFilters(filterIds);

      // Remove downloaded filters from available updates
      _availableUpdates.removeWhere((update) => filterIds.contains(update['id']));

      if (_availableUpdates.isEmpty) {
        _showingUpdatePopup = false;
      }

      await loadFilterLists();

      setDownloadCompleteMessage('Downloaded ${filterIds.length} filter update(s). Apply now to activate the changes.');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error downloading selected filters: $e');
    }
  }

  // Reset to default/recommended filter lists
  Future<void> resetToDefaultLists() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FlutterWblockPlugin.resetToDefaultLists();
      await loadFilterLists();

      _showingApplyProgressSheet = true;
      notifyListeners();

      await checkAndEnableFilters(forceReload: true);
    } catch (e) {
      _isLoading = false;
      _showingApplyProgressSheet = false;
      notifyListeners();
      debugPrint('Error resetting to default lists: $e');
    }
  }
}
