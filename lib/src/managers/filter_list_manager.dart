import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/filter_list.dart';
import '../models/filter_stats.dart';
import '../platform/wblock_platform_interface.dart';
import 'log_manager.dart';

class FilterListManager extends ChangeNotifier {
  final WBlockPlatformInterface _platform = WBlockPlatformInterface.instance;
  
  // Local logging (fallback)
  late final LogManager _logManager;
  
  List<FilterList> _filterLists = [];
  List<FilterList> _customFilterLists = [];
  List<FilterList> _missingFilters = [];
  List<FilterList> _availableUpdates = [];
  
  bool _isUpdating = false;
  double _progress = 0.0;
  bool _hasUnappliedChanges = false;
  bool _showProgressView = false;
  String _logs = '';
  Map<String, int> _ruleCounts = {};
  
  StreamSubscription<double>? _progressSubscription;

  // Getters
  List<FilterList> get filterLists => _filterLists;
  List<FilterList> get customFilterLists => _customFilterLists;
  List<FilterList> get missingFilters => _missingFilters;
  List<FilterList> get availableUpdates => _availableUpdates;
  bool get isUpdating => _isUpdating;
  double get progress => _progress;
  bool get hasUnappliedChanges => _hasUnappliedChanges;
  bool get showProgressView => _showProgressView;
  String get logs => _logs;
  Map<String, int> get ruleCounts => _ruleCounts;
  
  FilterListManager() {
    // Initialize local logging
    _logManager = LogManager();
    _init();
  }

  Future<void> _init() async {
    // Load filter lists from native side
    await loadFilterLists();
    
    // Load existing logs from native side
    await loadLogsFromFile();
    
    // Set up progress tracking from native operations
    _progressSubscription = _platform.progressStream.listen((progress) {
      _progress = progress;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadFilterLists() async {
    try {
      // Load from native side via platform channel (this includes app group container access)
      _filterLists = await _platform.loadFilterLists();
      
      if (_filterLists.isEmpty) {
        // If no saved lists, use defaults and save them
        _filterLists = getDefaultFilterLists();
        await _platform.saveFilterLists(_filterLists);
      }
      
      // Separate custom filters
      _customFilterLists = _filterLists.where((f) => f.category == FilterListCategory.custom).toList();
      
      // Update rule counts using native side
      for (var filter in _filterLists) {
        if (filter.isSelected) {
          final count = await _platform.getRuleCount(filter);
          _ruleCounts[filter.id] = count;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filter lists: $e');
    }
  }

  void toggleFilterListSelection(String filterId) {
    final index = _filterLists.indexWhere((f) => f.id == filterId);
    if (index != -1) {
      _filterLists[index].isSelected = !_filterLists[index].isSelected;
      _hasUnappliedChanges = true;
      notifyListeners();
      // Save via platform channel to ensure native side is updated
      _platform.saveFilterLists(_filterLists);
    }
  }

  List<FilterList> filterListsForCategory(FilterListCategory category) {
    if (category == FilterListCategory.all) {
      return _filterLists;
    }
    return _filterLists.where((f) => f.category == category).toList();
  }

  Future<void> checkAndEnableFilters() async {
    _missingFilters.clear();
    
    for (var filter in _filterLists.where((f) => f.isSelected)) {
      // Use platform channel to check file existence (requires app group access)
      final exists = await _platform.filterFileExists(filter);
      if (!exists) {
        _missingFilters.add(filter);
      }
    }
    
    if (_missingFilters.isEmpty) {
      await applyChanges();
    } else {
      notifyListeners();
    }
  }

  Future<void> applyChanges() async {
    _showProgressView = true;
    _isUpdating = true;
    _progress = 0.0;
    notifyListeners();
    
    try {
      // CRITICAL: This MUST use platform channel to call native Safari Content Blocker APIs
      await _platform.applyChanges(_filterLists.where((f) => f.isSelected).toList());
      _hasUnappliedChanges = false;
      
      // Update rule counts using platform channel
      for (var filter in _filterLists) {
        if (filter.isSelected) {
          final count = await _platform.getRuleCount(filter);
          _ruleCounts[filter.id] = count;
        }
      }
    } catch (e) {
      debugPrint('Error applying changes: $e');
    } finally {
      _isUpdating = false;
      _showProgressView = false;
      notifyListeners();
    }
  }

  Future<void> checkForUpdates() async {
    _isUpdating = true;
    notifyListeners();
    
    try {
      final enabledFilters = _filterLists.where((f) => f.isSelected).toList();
      // Use platform channel for update checking (requires network access and file operations)
      _availableUpdates = await _platform.checkForUpdates(enabledFilters);
      
      if (_availableUpdates.isEmpty) {
        await appendLog('No updates available.');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateSelectedFilters(List<FilterList> selectedFilters) async {
    _showProgressView = true;
    _isUpdating = true;
    _progress = 0.0;
    notifyListeners();
    
    try {
      // Use platform channel for downloading and processing filters
      await _platform.updateFilters(selectedFilters);
      
      // Remove updated filters from available updates
      for (var filter in selectedFilters) {
        _availableUpdates.removeWhere((f) => f.id == filter.id);
      }
      
      await applyChanges();
    } catch (e) {
      debugPrint('Error updating filters: $e');
    } finally {
      _isUpdating = false;
      _showProgressView = false;
      notifyListeners();
    }
  }

  Future<void> updateMissingFilters() async {
    _showProgressView = true;
    _isUpdating = true;
    _progress = 0.0;
    notifyListeners();
    
    try {
      // Download missing filters using platform channel
      for (var filter in _missingFilters) {
        await _platform.downloadFilter(filter);
      }
      _missingFilters.clear();
      await applyChanges();
    } catch (e) {
      debugPrint('Error updating missing filters: $e');
    } finally {
      _isUpdating = false;
      _showProgressView = false;
      notifyListeners();
    }
  }

  Future<void> addCustomFilterList(FilterList filter) async {
    try {
      // Check if filter with same URL already exists
      if (_customFilterLists.any((f) => f.url == filter.url)) {
        await appendLog('Custom filter with URL ${filter.url} already exists');
        return;
      }
      
      // Add to lists
      _customFilterLists.add(filter);
      _filterLists.add(filter);
      
      // Save and download using platform channel
      await _platform.addCustomFilter(filter);
      await _platform.saveFilterLists(_filterLists);
      
      // Download the filter
      await _platform.downloadFilter(filter);
      
      _hasUnappliedChanges = true;
      await appendLog('Added custom filter: ${filter.name}');
      notifyListeners();
    } catch (e) {
      await appendLog('Failed to add custom filter: $e');
      // Remove if failed
      _customFilterLists.removeWhere((f) => f.id == filter.id);
      _filterLists.removeWhere((f) => f.id == filter.id);
      notifyListeners();
    }
  }

  Future<void> removeCustomFilterList(FilterList filter) async {
    try {
      _customFilterLists.removeWhere((f) => f.id == filter.id);
      _filterLists.removeWhere((f) => f.id == filter.id);
      
      // Remove using platform channel (handles file cleanup)
      await _platform.removeCustomFilter(filter.id);
      await _platform.saveFilterLists(_filterLists);
      
      _hasUnappliedChanges = true;
      await appendLog('Removed custom filter: ${filter.name}');
      notifyListeners();
    } catch (e) {
      await appendLog('Failed to remove custom filter: $e');
    }
  }

  void resetToDefaultLists() {
    // Reset all to unselected
    for (var filter in _filterLists) {
      filter.isSelected = false;
    }
    
    // Enable recommended filters
    const recommendedFilters = [
      'AdGuard Base Filter',
      'AdGuard Tracking Protection Filter',
      'AdGuard Annoyances Filter',
      'EasyPrivacy',
      'Online Malicious URL Blocklist',
      'd3Host List by d3ward',
      'Anti-Adblock List',
    ];
    
    for (var filter in _filterLists) {
      if (recommendedFilters.contains(filter.name)) {
        filter.isSelected = true;
      }
    }
    
    _hasUnappliedChanges = true;
    // Save using platform channel
    _platform.saveFilterLists(_filterLists);
    notifyListeners();
  }

  Future<FilterStats> getFilterStats() async {
    final enabledCount = _filterLists.where((f) => f.isSelected).length;
    final enabledIds = _filterLists.where((f) => f.isSelected).map((f) => f.id).toList();
    
    int totalRules = 0;
    for (var id in enabledIds) {
      totalRules += _ruleCounts[id] ?? 0;
    }
    
    return FilterStats(
      enabledListsCount: enabledCount,
      totalRulesCount: totalRules,
    );
  }

  Future<void> appendLog(String message) async {
    // Use LogManager for local logging, but also ensure platform side logs
    await _logManager.log(message);
    _logs = await _logManager.getAllLogs();
    notifyListeners();
  }

  Future<void> clearLogs() async {
    _logs = '';
    // Clear both local and platform logs
    await _logManager.clearLogs();
    await _platform.clearLogs();
    notifyListeners();
  }

  Future<void> loadLogsFromFile() async {
    try {
      // Try platform logs first, fallback to local logs
      try {
        _logs = await _platform.getLogs();
      } catch (e) {
        _logs = await _logManager.getAllLogs();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading logs: $e');
    }
  }
}
