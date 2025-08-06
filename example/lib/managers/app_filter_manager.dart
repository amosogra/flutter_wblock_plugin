import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/whitelist_view_model.dart';

class AppFilterManager extends ChangeNotifier {
  List<FilterList> _filterLists = [];
  bool _isLoading = false;
  String _statusDescription = '';
  int _lastRuleCount = 0;
  bool _showingUpdatePopup = false;
  bool _showMissingFiltersSheet = false;
  bool _showingApplyProgressSheet = false;
  bool _showingNoUpdatesAlert = false;
  bool _showingDownloadCompleteAlert = false;
  String _downloadCompleteMessage = '';
  bool _showingCategoryWarningAlert = false;
  String _categoryWarningMessage = '';

  // Progress tracking properties
  double _progress = 0.0;
  String _conversionStageDescription = '';
  String _currentFilterName = '';
  int _processedFiltersCount = 0;
  int _totalFiltersCount = 0;
  bool _isInConversionPhase = false;
  bool _isInSavingPhase = false;
  bool _isInEnginePhase = false;
  bool _isInReloadPhase = false;
  int _sourceRulesCount = 0;
  String _lastConversionTime = 'N/A';
  String _lastReloadTime = 'N/A';
  bool _hasError = false;
  Map<FilterListCategory, int> _ruleCountsByCategory = {};
  Set<FilterListCategory> _categoriesApproachingLimit = {};

  // Update related properties
  List<FilterList> _availableUpdates = [];
  List<FilterList> _missingFilters = [];

  // Whitelist
  late final WhitelistViewModel whitelistViewModel;

  // Getters
  List<FilterList> get filterLists => _filterLists;
  bool get isLoading => _isLoading;
  String get statusDescription => _statusDescription;
  int get lastRuleCount => _lastRuleCount;
  bool get showingUpdatePopup => _showingUpdatePopup;
  bool get showMissingFiltersSheet => _showMissingFiltersSheet;
  bool get showingApplyProgressSheet => _showingApplyProgressSheet;
  bool get showingNoUpdatesAlert => _showingNoUpdatesAlert;
  bool get showingDownloadCompleteAlert => _showingDownloadCompleteAlert;
  String get downloadCompleteMessage => _downloadCompleteMessage;
  bool get showingCategoryWarningAlert => _showingCategoryWarningAlert;
  String get categoryWarningMessage => _categoryWarningMessage;

  // Progress getters
  double get progress => _progress;
  String get conversionStageDescription => _conversionStageDescription;
  String get currentFilterName => _currentFilterName;
  int get processedFiltersCount => _processedFiltersCount;
  int get totalFiltersCount => _totalFiltersCount;
  bool get isInConversionPhase => _isInConversionPhase;
  bool get isInSavingPhase => _isInSavingPhase;
  bool get isInEnginePhase => _isInEnginePhase;
  bool get isInReloadPhase => _isInReloadPhase;
  int get sourceRulesCount => _sourceRulesCount;
  String get lastConversionTime => _lastConversionTime;
  String get lastReloadTime => _lastReloadTime;
  bool get hasError => _hasError;
  Map<FilterListCategory, int> get ruleCountsByCategory => _ruleCountsByCategory;
  Set<FilterListCategory> get categoriesApproachingLimit => _categoriesApproachingLimit;

  // Update getters
  List<FilterList> get availableUpdates => _availableUpdates;
  List<FilterList> get missingFilters => _missingFilters;

  // Setters
  set showingUpdatePopup(bool value) {
    _showingUpdatePopup = value;
    notifyListeners();
  }

  set showMissingFiltersSheet(bool value) {
    _showMissingFiltersSheet = value;
    notifyListeners();
  }

  set showingApplyProgressSheet(bool value) {
    _showingApplyProgressSheet = value;
    notifyListeners();
  }

  set showingNoUpdatesAlert(bool value) {
    _showingNoUpdatesAlert = value;
    notifyListeners();
  }

  set showingDownloadCompleteAlert(bool value) {
    _showingDownloadCompleteAlert = value;
    notifyListeners();
  }

  set showingCategoryWarningAlert(bool value) {
    _showingCategoryWarningAlert = value;
    notifyListeners();
  }

  set filterLists(List<FilterList> value) {
    _filterLists = value;
    notifyListeners();
  }

  AppFilterManager() {
    whitelistViewModel = WhitelistViewModel();
    _loadFilterLists();
  }

  void setUserScriptManager(UserScriptManager userScriptManager) {}

  Future<void> _loadFilterLists() async {
    try {
      _isLoading = true;
      _statusDescription = 'Loading filter lists...';
      notifyListeners();

      final lists = await FlutterWblockPlugin.getFilterLists();
      _filterLists = lists.map((map) => FilterList.fromMap(map)).toList();

      await _updateStatusAndCounts();
    } catch (e) {
      debugPrint('Error loading filter lists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateStatusAndCounts() async {
    try {
      _statusDescription = await FlutterWblockPlugin.getStatusDescription();
      _lastRuleCount = await FlutterWblockPlugin.getLastRuleCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating status and counts: $e');
    }
  }

  Future<void> toggleFilterListSelection(String filterId) async {
    try {
      await FlutterWblockPlugin.toggleFilterListSelection(filterId);

      // Update local state
      final index = _filterLists.indexWhere((f) => f.id == filterId);
      if (index != -1) {
        _filterLists[index] = _filterLists[index].copyWith(
          isSelected: !_filterLists[index].isSelected,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling filter list selection: $e');
    }
  }

  Future<void> checkAndEnableFilters({bool forceReload = false}) async {
    try {
      _isLoading = true;
      _statusDescription = 'Applying filters...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring
      _monitorApplyProgress();

      await FlutterWblockPlugin.checkAndEnableFilters(forceReload: forceReload);
      await _updateStatusAndCounts();

      _showingApplyProgressSheet = false;
    } catch (e) {
      debugPrint('Error checking and enabling filters: $e');
      _showingApplyProgressSheet = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _monitorApplyProgress() async {
    while (_isLoading && _showingApplyProgressSheet) {
      try {
        final progressData = await FlutterWblockPlugin.getApplyProgress();
        if (progressData != null) {
          _progress = (progressData['progress'] as num?)?.toDouble() ?? 0.0;
          _conversionStageDescription = progressData['stageDescription'] ?? '';
          _currentFilterName = progressData['currentFilterName'] ?? '';
          _processedFiltersCount = progressData['processedFiltersCount'] ?? 0;
          _totalFiltersCount = progressData['totalFiltersCount'] ?? 0;
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
          final categoryRules = progressData['ruleCountsByCategory'];
          if (categoryRules != null) {
            _ruleCountsByCategory =
                (categoryRules as Map).map((key, value) => MapEntry(ParseFilterListCategory.fromRawValue(key) ?? FilterListCategory.all, value as int));
          }

          // Update categories approaching limit
          final approachingCategories = progressData['categoriesApproachingLimit'] as List<dynamic>?;
          if (approachingCategories != null) {
            _categoriesApproachingLimit =
                approachingCategories.map((name) => FilterListCategory.values.firstWhere((c) => c.rawValue == name, orElse: () => FilterListCategory.all)).toSet();
          }

          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error monitoring apply progress: $e');
      }

      // Check progress every 100ms
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> checkForUpdates() async {
    try {
      _isLoading = true;
      _statusDescription = 'Checking for updates...';
      notifyListeners();

      await FlutterWblockPlugin.checkForUpdates();

      final updates = await FlutterWblockPlugin.checkForFilterUpdates();
      if (updates == null || updates.isEmpty) {
        _showingNoUpdatesAlert = true;
      } else {
        _availableUpdates = updates.map((map) => FilterList.fromMap(map)).toList();
        _showingUpdatePopup = true;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFilterList({required String name, required String urlString}) async {
    try {
      await FlutterWblockPlugin.addFilterList(
        name: name.isEmpty ? 'Custom Filter' : name,
        urlString: urlString,
      );

      // Reload filter lists
      await _loadFilterLists();
    } catch (e) {
      debugPrint('Error adding filter list: $e');
    }
  }

  Future<void> removeFilterList(FilterList filter) async {
    try {
      await FlutterWblockPlugin.removeFilterList(filter.id);

      // Remove from local state
      _filterLists.removeWhere((f) => f.id == filter.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing filter list: $e');
    }
  }

  Future<void> updateVersionsAndCounts() async {
    try {
      await FlutterWblockPlugin.updateVersionsAndCounts();
      await _loadFilterLists();
    } catch (e) {
      debugPrint('Error updating versions and counts: $e');
    }
  }

  Future<bool> hasUnappliedChanges() async {
    try {
      return await FlutterWblockPlugin.hasUnappliedChanges();
    } catch (e) {
      debugPrint('Error checking unapplied changes: $e');
      return false;
    }
  }

  Future<void> applyDownloadedChanges() async {
    try {
      _isLoading = true;
      _statusDescription = 'Applying changes...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring
      _monitorApplyProgress();

      await FlutterWblockPlugin.applyDownloadedChanges();
      await _updateStatusAndCounts();

      _showingApplyProgressSheet = false;
    } catch (e) {
      debugPrint('Error applying downloaded changes: $e');
      _showingApplyProgressSheet = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isCategoryApproachingLimit(FilterListCategory category) {
    return _categoriesApproachingLimit.contains(category);
  }

  Future<void> showCategoryWarning(FilterListCategory category) async {
    try {
      await FlutterWblockPlugin.showCategoryWarning(category.rawValue);
      _categoryWarningMessage = 'The ${category.displayName} category is approaching its rule limit.';
      _showingCategoryWarningAlert = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error showing category warning: $e');
    }
  }

  Future<bool> doesFilterFileExist(FilterList filter) async {
    try {
      return await FlutterWblockPlugin.doesFilterFileExist(filter.id);
    } catch (e) {
      debugPrint('Error checking if filter file exists: $e');
      return false;
    }
  }

  Future<void> downloadMissingFilters() async {
    try {
      _isLoading = true;
      _statusDescription = 'Downloading missing filters...';
      notifyListeners();

      await FlutterWblockPlugin.downloadMissingFilters();
      await _loadFilterLists();

      _showMissingFiltersSheet = false;
    } catch (e) {
      debugPrint('Error downloading missing filters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMissingFilters() async {
    try {
      final missing = await FlutterWblockPlugin.getMissingFilters();
      _missingFilters = missing.map((map) => FilterList.fromMap(map)).toList();

      if (_missingFilters.isNotEmpty) {
        _showMissingFiltersSheet = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating missing filters: $e');
    }
  }

  Future<void> downloadSelectedFilters(List<FilterList> filters) async {
    try {
      _isLoading = true;
      _statusDescription = 'Downloading selected filters...';
      notifyListeners();

      // Start progress monitoring
      _monitorApplyProgress();

      final filterIds = filters.map((f) => f.id).toList();
      await FlutterWblockPlugin.downloadSelectedFilters(filterIds);
      await _updateStatusAndCounts();

      _showingUpdatePopup = false;
      _showingDownloadCompleteAlert = true;
      _downloadCompleteMessage = 'Downloaded ${filters.length} filter list${filters.length == 1 ? '' : 's'}.';
    } catch (e) {
      debugPrint('Error downloading selected filters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetToDefaultLists() async {
    try {
      _isLoading = true;
      _statusDescription = 'Resetting to default lists...';
      notifyListeners();

      await FlutterWblockPlugin.resetToDefaultLists();
      await _loadFilterLists();
    } catch (e) {
      debugPrint('Error resetting to default lists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void saveFilterLists() {
    // This would be handled by the native side
    notifyListeners();
  }

  Future<void> downloadAndApplyFilters(List<FilterList> filters, {Function(double)? progress}) async {
    try {
      _isLoading = true;
      _statusDescription = 'Downloading and applying filters...';
      notifyListeners();

      // Simulate progress updates
      for (int i = 0; i <= filters.length; i++) {
        final progressValue = i / filters.length;
        _progress = progressValue;
        progress?.call(progressValue);
        notifyListeners();

        if (i < filters.length) {
          await Future.delayed(const Duration(milliseconds: 500)); // Simulate download time
        }
      }

      // Apply the filters
      await checkAndEnableFilters(forceReload: true);
    } catch (e) {
      debugPrint('Error downloading and applying filters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
