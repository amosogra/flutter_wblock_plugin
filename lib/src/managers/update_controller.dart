import 'dart:async';
import 'package:flutter/foundation.dart';
import 'filter_list_manager.dart';
import 'log_manager.dart';

class UpdateController extends ChangeNotifier {
  static final UpdateController shared = UpdateController._internal();
  
  UpdateController._internal();
  
  Timer? _updateTimer;
  bool _updateAvailable = false;
  String? _latestVersion;
  bool _autoUpdateEnabled = false;
  Duration _updateInterval = const Duration(hours: 24);
  
  final LogManager _logManager = LogManager();
  
  bool get updateAvailable => _updateAvailable;
  String? get latestVersion => _latestVersion;
  bool get autoUpdateEnabled => _autoUpdateEnabled;
  Duration get updateInterval => _updateInterval;
  
  set autoUpdateEnabled(bool value) {
    _autoUpdateEnabled = value;
    notifyListeners();
    
    if (value) {
      _startAutoUpdate();
    } else {
      _stopAutoUpdate();
    }
  }
  
  set updateInterval(Duration value) {
    _updateInterval = value;
    notifyListeners();
    
    if (_autoUpdateEnabled) {
      _stopAutoUpdate();
      _startAutoUpdate();
    }
  }
  
  Future<void> scheduleBackgroundUpdates({
    required FilterListManager filterListManager,
  }) async {
    await _logManager.log('Scheduling background updates');
    
    // Check for app updates
    await checkForAppUpdates();
    
    // Start auto-update if enabled
    if (_autoUpdateEnabled) {
      _startAutoUpdate();
    }
  }
  
  Future<void> checkForAppUpdates() async {
    try {
      // Check GitHub releases for updates
      // This is a placeholder - in a real implementation, 
      // you would check against GitHub API
      await _logManager.log('Checking for app updates');
      
      // For now, we'll just set this to false
      _updateAvailable = false;
      _latestVersion = null;
      
      notifyListeners();
    } catch (e) {
      await _logManager.log('Error checking for app updates: $e');
    }
  }
  
  void openReleasesPage() {
    // Open GitHub releases page
    // This would use url_launcher in the UI layer
    _updateAvailable = false;
    notifyListeners();
  }
  
  void _startAutoUpdate() {
    _stopAutoUpdate(); // Cancel any existing timer
    
    _updateTimer = Timer.periodic(_updateInterval, (_) async {
      await _performAutoUpdate();
    });
    
    // Also perform an immediate update
    _performAutoUpdate();
  }
  
  void _stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
  
  Future<void> _performAutoUpdate() async {
    await _logManager.log('Performing automatic filter update');
    
    // This will be called from the UI layer to actually update filters
    // For now, we just log it
    notifyListeners();
  }
  
  @override
  void dispose() {
    _stopAutoUpdate();
    super.dispose();
  }
}
