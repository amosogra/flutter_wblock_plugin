import 'dart:async';
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

  // Stream controller for progress updates
  StreamController<Map<String, dynamic>>? _progressStreamController;
  StreamSubscription? _progressSubscription;
  Timer? _progressTimer;

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

  @override
  void dispose() {
    _cancelProgressMonitoring();
    _progressStreamController?.close();
    super.dispose();
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
      
      // Try to get category statistics
      try {
        final categoryRules = await FlutterWblockPlugin.getRuleCountsByCategory();
        if (categoryRules != null && categoryRules.isNotEmpty) {
          _applyProgressData({'ruleCountsByCategory': categoryRules});
        }
      } catch (e) {
        debugPrint('Could not get category rules: $e');
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
      _resetProgressState();
      _isLoading = true;
      _statusDescription = 'Applying filters...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring with stream
      _startProgressMonitoring();

      await FlutterWblockPlugin.checkAndEnableFilters(forceReload: forceReload);
      
      // Give a moment for final progress updates
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get final statistics
      await _updateStatusAndCounts();
      
      // Force final progress check
      await _fetchProgressOnce();
      
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
      
    } catch (e) {
      debugPrint('Error checking and enabling filters: $e');
      _isLoading = false;
      _progress = 1.0;
      notifyListeners();
    } finally {
      _cancelProgressMonitoring();
    }
  }

  void _resetProgressState() {
    _progress = 0.0;
    _sourceRulesCount = 0;
    _lastRuleCount = 0;
    _lastConversionTime = 'N/A';
    _lastReloadTime = 'N/A';
    _ruleCountsByCategory = <FilterListCategory, int>{};
    _categoriesApproachingLimit = <FilterListCategory>{};
    _conversionStageDescription = '';
    _currentFilterName = '';
    _processedFiltersCount = 0;
    _totalFiltersCount = 0;
    _isInConversionPhase = false;
    _isInSavingPhase = false;
    _isInEnginePhase = false;
    _isInReloadPhase = false;
    _hasError = false;
  }

  void _startProgressMonitoring() {
    _cancelProgressMonitoring();
    
    // Create stream for progress updates
    _progressStreamController = StreamController<Map<String, dynamic>>.broadcast();
    
    // Listen to stream
    _progressSubscription = _progressStreamController?.stream.listen((progressData) {
      _applyProgressData(progressData);
      notifyListeners();
    });
    
    // Start timer to fetch progress periodically
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isLoading || !_showingApplyProgressSheet) {
        _cancelProgressMonitoring();
        return;
      }
      
      await _fetchProgressOnce();
    });
  }

  void _cancelProgressMonitoring() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _progressStreamController?.close();
    _progressStreamController = null;
  }

  Future<void> _fetchProgressOnce() async {
    try {
      final progressData = await FlutterWblockPlugin.getApplyProgress();
      if (progressData != null && _progressStreamController != null && !_progressStreamController!.isClosed) {
        _progressStreamController!.add(progressData);
      }
    } catch (e) {
      debugPrint('Error fetching progress: $e');
    }
  }

  void _applyProgressData(Map<String, dynamic> progressData) {
    // Update progress
    _progress = (progressData['progress'] as num?)?.toDouble() ?? _progress;
    
    // Update stage descriptions
    _conversionStageDescription = progressData['stageDescription'] ?? _conversionStageDescription;
    _currentFilterName = progressData['currentFilterName'] ?? _currentFilterName;
    
    // Update counts
    _processedFiltersCount = progressData['processedFiltersCount'] ?? _processedFiltersCount;
    _totalFiltersCount = progressData['totalFiltersCount'] ?? _totalFiltersCount;
    
    // Update phase flags
    _isInConversionPhase = progressData['isInConversionPhase'] ?? false;
    _isInSavingPhase = progressData['isInSavingPhase'] ?? false;
    _isInEnginePhase = progressData['isInEnginePhase'] ?? false;
    _isInReloadPhase = progressData['isInReloadPhase'] ?? false;
    
    // Update statistics - don't overwrite with empty/zero values
    final sourceRules = progressData['sourceRulesCount'] as int?;
    if (sourceRules != null && sourceRules > 0) {
      _sourceRulesCount = sourceRules;
      debugPrint('Updated source rules count: $_sourceRulesCount');
    }
    
    final lastRule = progressData['lastRuleCount'] as int?;
    if (lastRule != null && lastRule > 0) {
      _lastRuleCount = lastRule;
      debugPrint('Updated last rule count: $_lastRuleCount');
    }
    
    final convTime = progressData['lastConversionTime'] as String?;
    if (convTime != null && convTime != 'N/A' && convTime.isNotEmpty) {
      _lastConversionTime = convTime;
      debugPrint('Updated conversion time: $_lastConversionTime');
    }
    
    final reloadTime = progressData['lastReloadTime'] as String?;
    if (reloadTime != null && reloadTime != 'N/A' && reloadTime.isNotEmpty) {
      _lastReloadTime = reloadTime;
      debugPrint('Updated reload time: $_lastReloadTime');
    }
    
    _hasError = progressData['hasError'] ?? false;

    // Update rule counts by category
    final categoryRules = progressData['ruleCountsByCategory'];
    if (categoryRules != null && categoryRules is Map && categoryRules.isNotEmpty) {
      debugPrint('Received category rules: $categoryRules');
      final newCategoryRules = <FilterListCategory, int>{};
      
      for (final entry in categoryRules.entries) {
        final categoryRaw = entry.key.toString();
        final category = ParseFilterListCategory.fromRawValue(categoryRaw);
        if (category != null && entry.value != null) {
          final count = entry.value is int ? entry.value as int : int.tryParse(entry.value.toString()) ?? 0;
          if (count > 0) {
            newCategoryRules[category] = count;
            debugPrint('Category ${category.displayName} (${category.rawValue}): $count rules');
          }
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
      _resetProgressState();
      _isLoading = true;
      _statusDescription = 'Applying changes...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring with stream
      _startProgressMonitoring();

      await FlutterWblockPlugin.applyDownloadedChanges();
      
      // Give a moment for final progress updates
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _updateStatusAndCounts();
      
      // Force final progress check
      await _fetchProgressOnce();
      
      // Mark as complete
      _progress = 1.0;
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error applying downloaded changes: $e');
      _isLoading = false;
      _progress = 1.0;
      notifyListeners();
    } finally {
      _cancelProgressMonitoring();
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
      _resetProgressState();
      _isLoading = true;
      _statusDescription = 'Downloading selected filters...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring with stream
      _startProgressMonitoring();

      final filterIds = filters.map((f) => f.id).toList();
      await FlutterWblockPlugin.downloadSelectedFilters(filterIds);
      
      // Give a moment for final progress updates
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Make sure to get final statistics
      await _updateStatusAndCounts();
      
      // Force final progress check
      await _fetchProgressOnce();
      
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
      
    } catch (e) {
      debugPrint('Error downloading selected filters: $e');
      _isLoading = false;
      _progress = 1.0;
      notifyListeners();
    } finally {
      _cancelProgressMonitoring();
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
      _resetProgressState();
      _isLoading = true;
      _statusDescription = 'Downloading and applying filters...';
      _showingApplyProgressSheet = true;
      notifyListeners();

      // Start progress monitoring with stream
      _startProgressMonitoring();

      // Download selected filters
      final filterIds = filters.map((f) => f.id).toList();
      await FlutterWblockPlugin.downloadSelectedFilters(filterIds);

      // Apply the filters
      await checkAndEnableFilters(forceReload: true);
      
    } catch (e) {
      debugPrint('Error downloading and applying filters: $e');
    } finally {
      _isLoading = false;
      _cancelProgressMonitoring();
      notifyListeners();
    }
  }
}
