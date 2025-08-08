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
  Map<FilterListCategory, int> _ruleCountsByCategory = <FilterListCategory, int>{};
  Set<FilterListCategory> _categoriesApproachingLimit = <FilterListCategory>{};

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
  Map<FilterListCategory, int> get ruleCountsByCategory => Map<FilterListCategory, int>.from(_ruleCountsByCategory);
  Set<FilterListCategory> get categoriesApproachingLimit => Set<FilterListCategory>.from(_categoriesApproachingLimit);

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
      
      // Get last rule count
      final ruleCount = await FlutterWblockPlugin.getLastRuleCount();
      if (ruleCount > 0) {
        _lastRuleCount = ruleCount;
        debugPrint('Updated last rule count: $_lastRuleCount');
      }
      
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
      _progress = 0.0;
      // Reset statistics to force fresh data
      _sourceRulesCount = 0;
      _lastRuleCount = 0;
      _lastConversionTime = 'N/A';
      _lastReloadTime = 'N/A';
      _ruleCountsByCategory = <FilterListCategory, int>{};
      _categoriesApproachingLimit = <FilterListCategory>{};
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring in background
      final progressFuture = _monitorApplyProgress();

      await FlutterWblockPlugin.checkAndEnableFilters(forceReload: forceReload);
      
      // Make sure to get final statistics
      await _updateStatusAndCounts();

      // Wait for progress monitoring to complete
      await progressFuture;
      
      // Force one more check for progress data
      try {
        final progressData = await FlutterWblockPlugin.getApplyProgress();
        if (progressData != null) {
          debugPrint('Final progress data check: ${progressData.keys.toList()}');
          // Apply any final statistics from progress data
          //_applyProgressData(progressData);
        }
      } catch (e) {
        debugPrint('Could not get final progress data: $e');
      }
      
      // Mark as complete
      _progress = 1.0;
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Apply complete. Final statistics:');
      debugPrint('- Last rule count: $_lastRuleCount');
      debugPrint('- Source rules: $_sourceRulesCount');
      debugPrint('- Categories: ${_ruleCountsByCategory.length}');
      debugPrint('- Conversion time: $_lastConversionTime');
      debugPrint('- Reload time: $_lastReloadTime');
      
      // Keep sheet open to show results
      // Don't auto-close, let user dismiss it
    } catch (e) {
      debugPrint('Error checking and enabling filters: $e');
      _isLoading = false;
      _progress = 1.0;
      notifyListeners();
    }
  }

  void _applyStatistics(Map<String, dynamic> stats) {
    // Apply statistics from direct fetch
    if (stats['sourceRulesCount'] != null) {
      _sourceRulesCount = stats['sourceRulesCount'] as int;
    }
    if (stats['lastRuleCount'] != null) {
      _lastRuleCount = stats['lastRuleCount'] as int;
    }
    if (stats['lastConversionTime'] != null) {
      _lastConversionTime = stats['lastConversionTime'] as String;
    }
    if (stats['lastReloadTime'] != null) {
      _lastReloadTime = stats['lastReloadTime'] as String;
    }
    
    // Apply category rules
    final categoryRules = stats['ruleCountsByCategory'];
    if (categoryRules != null && categoryRules is Map && categoryRules.isNotEmpty) {
      final newCategoryRules = <FilterListCategory, int>{};
      for (final entry in categoryRules.entries) {
        final category = ParseFilterListCategory.fromRawValue(entry.key.toString());
        if (category != null) {
          newCategoryRules[category] = entry.value as int;
        }
      }
      if (newCategoryRules.isNotEmpty) {
        _ruleCountsByCategory = newCategoryRules;
      }
    }
    
    notifyListeners();
  }

  Future<void> _monitorApplyProgress() async {
    int noUpdateCount = 0;
    double lastProgress = 0.0;
    bool hasCompleteData = false;
    
    debugPrint('Starting progress monitoring...');
    
    while (_isLoading && _showingApplyProgressSheet) {
      try {
        final progressData = await FlutterWblockPlugin.getApplyProgress();
        if (progressData != null) {
          debugPrint('Progress data received: ${progressData.keys.toList()}');
          
          _progress = (progressData['progress'] as num?)?.toDouble() ?? 0.0;
          _conversionStageDescription = progressData['stageDescription'] ?? '';
          _currentFilterName = progressData['currentFilterName'] ?? '';
          _processedFiltersCount = progressData['processedFiltersCount'] ?? 0;
          _totalFiltersCount = progressData['totalFiltersCount'] ?? 0;
          _isInConversionPhase = progressData['isInConversionPhase'] ?? false;
          _isInSavingPhase = progressData['isInSavingPhase'] ?? false;
          _isInEnginePhase = progressData['isInEnginePhase'] ?? false;
          _isInReloadPhase = progressData['isInReloadPhase'] ?? false;
          
          // Update statistics - don't overwrite with empty values
          final sourceRules = progressData['sourceRulesCount'] as int?;
          if (sourceRules != null && sourceRules > 0) {
            _sourceRulesCount = sourceRules;
            debugPrint('Source rules count: $_sourceRulesCount');
          }
          
          final lastRule = progressData['lastRuleCount'] as int?;
          if (lastRule != null && lastRule > 0) {
            _lastRuleCount = lastRule;
            debugPrint('Last rule count: $_lastRuleCount');
          }
          
          final convTime = progressData['lastConversionTime'] as String?;
          if (convTime != null && convTime != 'N/A' && convTime.isNotEmpty) {
            _lastConversionTime = convTime;
            debugPrint('Conversion time: $_lastConversionTime');
          }
          
          final reloadTime = progressData['lastReloadTime'] as String?;
          if (reloadTime != null && reloadTime != 'N/A' && reloadTime.isNotEmpty) {
            _lastReloadTime = reloadTime;
            debugPrint('Reload time: $_lastReloadTime');
          }
          
          _hasError = progressData['hasError'] ?? false;

          // Update rule counts by category
          final categoryRules = progressData['ruleCountsByCategory'];
          if (categoryRules != null && categoryRules is Map && categoryRules.isNotEmpty) {
            debugPrint('Received category rules: $categoryRules');
            final newCategoryRules = <FilterListCategory, int>{};
            for (final entry in categoryRules.entries) {
              final category = ParseFilterListCategory.fromRawValue(entry.key.toString());
              if (category != null) {
                newCategoryRules[category] = entry.value as int;
                debugPrint('Category ${category.rawValue}: ${entry.value} rules');
              }
            }
            if (newCategoryRules.isNotEmpty) {
              _ruleCountsByCategory = newCategoryRules;
              debugPrint('Updated rule counts by category: ${_ruleCountsByCategory.length} categories');
            }
          }

          // Update categories approaching limit
          final approachingCategories = progressData['categoriesApproachingLimit'] as List<dynamic>?;
          if (approachingCategories != null) {
            _categoriesApproachingLimit = <FilterListCategory>{};
            for (final name in approachingCategories) {
              final category = ParseFilterListCategory.fromRawValue(name.toString());
              if (category != null) {
                _categoriesApproachingLimit.add(category);
              }
            }
            debugPrint('Categories approaching limit: ${_categoriesApproachingLimit.length}');
          }

          notifyListeners();
          
          // Check if we have complete data
          hasCompleteData = _progress >= 1.0 && 
                           (_lastRuleCount > 0 || _sourceRulesCount > 0) &&
                           (_ruleCountsByCategory.isNotEmpty || _totalFiltersCount > 0);
          
          debugPrint('Progress: $_progress, Has complete data: $hasCompleteData');
          
          // Check if progress is complete with data
          if (_progress >= 1.0) {
            if (hasCompleteData) {
              debugPrint('Progress complete with full data');
              break;
            } else {
              // Give it more time to get complete data
              noUpdateCount++;
              if (noUpdateCount > 50) { // 5 seconds after completion
                debugPrint('Timeout waiting for complete data');
                break;
              }
            }
          }
          
          // Check if progress is stuck
          if (_progress == lastProgress && _progress < 1.0) {
            noUpdateCount++;
            if (noUpdateCount > 100) { // 10 seconds with no progress
              debugPrint('Progress stuck at $_progress');
              break;
            }
          } else if (_progress != lastProgress) {
            noUpdateCount = 0;
            lastProgress = _progress;
          }
        }
      } catch (e) {
        debugPrint('Error monitoring apply progress: $e');
      }

      // Check progress every 100ms
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    debugPrint('Progress monitoring completed. Final stats:');
    debugPrint('- Source rules: $_sourceRulesCount');
    debugPrint('- Last rule count: $_lastRuleCount');
    debugPrint('- Categories: ${_ruleCountsByCategory.length}');
    debugPrint('- Conversion time: $_lastConversionTime');
    debugPrint('- Reload time: $_lastReloadTime');
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
      _progress = 0.0;
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring in background
      final progressFuture = _monitorApplyProgress();

      await FlutterWblockPlugin.applyDownloadedChanges();
      await _updateStatusAndCounts();

      // Wait for progress monitoring to complete
      await progressFuture;
      
      // Mark as complete
      _progress = 1.0;
      _isLoading = false;
      notifyListeners();
      
      // Keep sheet open to show results
      // Don't auto-close, let user dismiss it
    } catch (e) {
      debugPrint('Error applying downloaded changes: $e');
      _isLoading = false;
      _progress = 1.0;
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
      _progress = 0.0;
      // Reset statistics to force fresh data
      _sourceRulesCount = 0;
      _lastRuleCount = 0;
      _lastConversionTime = 'N/A';
      _lastReloadTime = 'N/A';
      _ruleCountsByCategory = <FilterListCategory, int>{};
      _categoriesApproachingLimit = <FilterListCategory>{};
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring in background
      final progressFuture = _monitorApplyProgress();

      final filterIds = filters.map((f) => f.id).toList();
      await FlutterWblockPlugin.downloadSelectedFilters(filterIds);
      
      // Make sure to get final statistics
      await _updateStatusAndCounts();
      
      // Also try to get statistics directly
      /* try {
        final stats = await FlutterWblockPlugin.getFilterStatistics();
        if (stats != null) {
          debugPrint('Direct statistics fetch after download: $stats');
          _applyStatistics(stats);
        }
      } catch (e) {
        debugPrint('Could not get direct statistics: $e');
      } */

      // Wait for progress monitoring to complete
      await progressFuture;
      
      // Mark as complete
      _progress = 1.0;
      _isLoading = false;
      
      _showingUpdatePopup = false;
      _downloadCompleteMessage = 'Downloaded ${filters.length} filter list${filters.length == 1 ? '' : 's'}.';
      notifyListeners();
      
      debugPrint('Download complete. Final statistics:');
      debugPrint('- Last rule count: $_lastRuleCount');
      debugPrint('- Source rules: $_sourceRulesCount');
      debugPrint('- Categories: ${_ruleCountsByCategory.length}');
      
      // Keep sheet open to show results
      // Don't auto-close, let user dismiss it
    } catch (e) {
      debugPrint('Error downloading selected filters: $e');
      _isLoading = false;
      _progress = 1.0;
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
