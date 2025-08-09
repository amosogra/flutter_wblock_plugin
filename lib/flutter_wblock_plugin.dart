import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
/// The interface that implementations of flutter_wblock_plugin must implement.
abstract class FlutterWblockPluginPlatform extends PlatformInterface {
  /// Constructs a FlutterWblockPluginPlatform.
  FlutterWblockPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWblockPluginPlatform _instance = MethodChannelFlutterWblockPlugin();

  /// The default instance of [FlutterWblockPluginPlatform] to use.
  static FlutterWblockPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWblockPluginPlatform] when
  /// they register themselves.
  static set instance(FlutterWblockPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Core methods that need to be implemented
  Future<List<Map<String, dynamic>>> getFilterLists();
  Future<void> toggleFilterListSelection(String filterId);
  Future<void> checkAndEnableFilters({bool forceReload = false});
  Future<void> checkForUpdates();
  Future<bool> isLoading();
  Future<String> getStatusDescription();
  Future<int> getLastRuleCount();
  Future<void> addFilterList({required String name, required String urlString});
  Future<void> removeFilterList(String filterId);
  Future<void> updateVersionsAndCounts();
  Future<bool> hasUnappliedChanges();
  Future<void> applyDownloadedChanges();
  Future<void> showCategoryWarning(String category);
  Future<bool> isCategoryApproachingLimit(String category);
  Future<String> getLogs();
  Future<void> clearLogs();
  Future<List<Map<String, dynamic>>> getUserScripts();
  Future<void> toggleUserScript(String scriptId);
  Future<void> removeUserScript(String scriptId);
  Future<void> addUserScript({required String name, required String content});
  Future<List<String>> getWhitelistedDomains();
  Future<void> addWhitelistedDomain(String domain);
  Future<void> removeWhitelistedDomain(String domain);
  Future<void> updateWhitelistedDomains(List<String> domains);
  Future<Map<String, dynamic>> getFilterDetails(String filterId);
  Future<void> resetOnboarding();
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted(bool completed);
  Future<Map<String, dynamic>?> getApplyProgress();
  Future<Map<String, int>?> getRuleCountsByCategory();
  Future<List<String>?> getCategoriesApproachingLimit();
  Future<List<Map<String, dynamic>>?> checkForFilterUpdates();
  Future<void> applyFilterUpdates(List<String> updateIds);
  Future<void> downloadMissingFilters();
  Future<void> updateMissingFilters();
  Future<void> downloadSelectedFilters(List<String> filterIds);
  Future<void> resetToDefaultLists();
  Future<void> setUserScriptManager();
  Future<bool> doesFilterFileExist(String filterId);
  Future<List<Map<String, dynamic>>> getMissingFilters();
  Future<Map<String, dynamic>> getTimingStatistics();
  Future<int> getSourceRulesCount();
  Future<Map<String, dynamic>> getDetailedProgress();
  Future<bool> getShowingUpdatePopup();
  Future<bool> getShowingApplyProgressSheet();
  Future<bool> getShowMissingFiltersSheet();
  Future<void> setShowingUpdatePopup(bool value);
  Future<void> setShowingApplyProgressSheet(bool value);
  Future<void> setShowMissingFiltersSheet(bool value);
  Future<List<Map<String, dynamic>>> getAvailableUpdates();
  Future<String> getCategoryWarningMessage();
  Future<bool> getShowingCategoryWarningAlert();
  Future<void> setShowingCategoryWarningAlert(bool value);
  Future<bool> getShowingNoUpdatesAlert();
  Future<void> setShowingNoUpdatesAlert(bool value);
  Future<bool> getShowingDownloadCompleteAlert();
  Future<void> setShowingDownloadCompleteAlert(bool value);
  Future<String> getDownloadCompleteMessage();
}

/// An implementation of [FlutterWblockPluginPlatform] that uses method channels.
class MethodChannelFlutterWblockPlugin extends FlutterWblockPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_wblock_plugin');

  @override
  Future<List<Map<String, dynamic>>> getFilterLists() async {
    final result = await methodChannel.invokeMethod<List>('getFilterLists');
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> toggleFilterListSelection(String filterId) async {
    await methodChannel.invokeMethod('toggleFilterListSelection', {'filterId': filterId});
  }

  @override
  Future<void> checkAndEnableFilters({bool forceReload = false}) async {
    await methodChannel.invokeMethod('checkAndEnableFilters', {'forceReload': forceReload});
  }

  @override
  Future<void> checkForUpdates() async {
    await methodChannel.invokeMethod('checkForUpdates');
  }

  @override
  Future<bool> isLoading() async {
    final result = await methodChannel.invokeMethod<bool>('isLoading');
    return result ?? false;
  }

  @override
  Future<String> getStatusDescription() async {
    final result = await methodChannel.invokeMethod<String>('getStatusDescription');
    return result ?? '';
  }

  @override
  Future<int> getLastRuleCount() async {
    final result = await methodChannel.invokeMethod<int>('getLastRuleCount');
    return result ?? 0;
  }

  @override
  Future<void> addFilterList({required String name, required String urlString}) async {
    await methodChannel.invokeMethod('addFilterList', {
      'name': name,
      'urlString': urlString,
    });
  }

  @override
  Future<void> removeFilterList(String filterId) async {
    await methodChannel.invokeMethod('removeFilterList', {'filterId': filterId});
  }

  @override
  Future<void> updateVersionsAndCounts() async {
    await methodChannel.invokeMethod('updateVersionsAndCounts');
  }

  @override
  Future<bool> hasUnappliedChanges() async {
    final result = await methodChannel.invokeMethod<bool>('hasUnappliedChanges');
    return result ?? false;
  }

  @override
  Future<void> applyDownloadedChanges() async {
    await methodChannel.invokeMethod('applyDownloadedChanges');
  }

  @override
  Future<void> showCategoryWarning(String category) async {
    await methodChannel.invokeMethod('showCategoryWarning', {'category': category});
  }

  @override
  Future<bool> isCategoryApproachingLimit(String category) async {
    final result = await methodChannel.invokeMethod<bool>('isCategoryApproachingLimit', {
      'category': category,
    });
    return result ?? false;
  }

  @override
  Future<String> getLogs() async {
    final result = await methodChannel.invokeMethod<String>('getLogs');
    return result ?? '';
  }

  @override
  Future<void> clearLogs() async {
    await methodChannel.invokeMethod('clearLogs');
  }

  @override
  Future<List<Map<String, dynamic>>> getUserScripts() async {
    final result = await methodChannel.invokeMethod<List>('getUserScripts');
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> toggleUserScript(String scriptId) async {
    await methodChannel.invokeMethod('toggleUserScript', {'scriptId': scriptId});
  }

  @override
  Future<void> removeUserScript(String scriptId) async {
    await methodChannel.invokeMethod('removeUserScript', {'scriptId': scriptId});
  }

  @override
  Future<void> addUserScript({required String name, required String content}) async {
    await methodChannel.invokeMethod('addUserScript', {
      'name': name,
      'content': content,
    });
  }

  @override
  Future<List<String>> getWhitelistedDomains() async {
    final result = await methodChannel.invokeMethod<List>('getWhitelistedDomains');
    return (result ?? []).cast<String>();
  }

  @override
  Future<void> addWhitelistedDomain(String domain) async {
    await methodChannel.invokeMethod('addWhitelistedDomain', {'domain': domain});
  }

  @override
  Future<void> removeWhitelistedDomain(String domain) async {
    await methodChannel.invokeMethod('removeWhitelistedDomain', {'domain': domain});
  }

  @override
  Future<void> updateWhitelistedDomains(List<String> domains) async {
    await methodChannel.invokeMethod('updateWhitelistedDomains', {'domains': domains});
  }

  @override
  Future<Map<String, dynamic>> getFilterDetails(String filterId) async {
    final result = await methodChannel.invokeMethod<Map>('getFilterDetails', {
      'filterId': filterId,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<void> resetOnboarding() async {
    await methodChannel.invokeMethod('resetOnboarding');
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final result = await methodChannel.invokeMethod<bool>('hasCompletedOnboarding');
    return result ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await methodChannel.invokeMethod('setOnboardingCompleted', {'completed': completed});
  }

  @override
  Future<Map<String, dynamic>?> getApplyProgress() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getApplyProgress');
      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Error getting apply progress: $e');
      return null;
    }
  }

  @override
  Future<Map<String, int>?> getRuleCountsByCategory() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getRuleCountsByCategory');
      return result?.cast<String, int>();
    } catch (e) {
      debugPrint('Error getting rule counts by category: $e');
      return null;
    }
  }

  @override
  Future<List<String>?> getCategoriesApproachingLimit() async {
    try {
      final result = await methodChannel.invokeMethod<List>('getCategoriesApproachingLimit');
      return result?.cast<String>();
    } catch (e) {
      debugPrint('Error getting categories approaching limit: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> checkForFilterUpdates() async {
    try {
      final result = await methodChannel.invokeMethod<List>('checkForFilterUpdates');
      return result?.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error checking for filter updates: $e');
      return null;
    }
  }

  @override
  Future<void> applyFilterUpdates(List<String> updateIds) async {
    await methodChannel.invokeMethod('applyFilterUpdates', {'updateIds': updateIds});
  }

  @override
  Future<void> downloadMissingFilters() async {
    await methodChannel.invokeMethod('downloadMissingFilters');
  }

  @override
  Future<void> updateMissingFilters() async {
    await methodChannel.invokeMethod('updateMissingFilters');
  }

  @override
  Future<void> downloadSelectedFilters(List<String> filterIds) async {
    await methodChannel.invokeMethod('downloadSelectedFilters', {'filterIds': filterIds});
  }

  @override
  Future<void> resetToDefaultLists() async {
    await methodChannel.invokeMethod('resetToDefaultLists');
  }

  @override
  Future<void> setUserScriptManager() async {
    await methodChannel.invokeMethod('setUserScriptManager');
  }

  @override
  Future<bool> doesFilterFileExist(String filterId) async {
    final result = await methodChannel.invokeMethod<bool>('doesFilterFileExist', {
      'filterId': filterId,
    });
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getMissingFilters() async {
    final result = await methodChannel.invokeMethod<List>('getMissingFilters');
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> getTimingStatistics() async {
    final result = await methodChannel.invokeMethod<Map>('getTimingStatistics');
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<int> getSourceRulesCount() async {
    final result = await methodChannel.invokeMethod<int>('getSourceRulesCount');
    return result ?? 0;
  }

  @override
  Future<Map<String, dynamic>> getDetailedProgress() async {
    final result = await methodChannel.invokeMethod<Map>('getDetailedProgress');
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<bool> getShowingUpdatePopup() async {
    final result = await methodChannel.invokeMethod<bool>('getShowingUpdatePopup');
    return result ?? false;
  }

  @override
  Future<bool> getShowingApplyProgressSheet() async {
    final result = await methodChannel.invokeMethod<bool>('getShowingApplyProgressSheet');
    return result ?? false;
  }

  @override
  Future<bool> getShowMissingFiltersSheet() async {
    final result = await methodChannel.invokeMethod<bool>('getShowMissingFiltersSheet');
    return result ?? false;
  }

  @override
  Future<void> setShowingUpdatePopup(bool value) async {
    await methodChannel.invokeMethod('setShowingUpdatePopup', {'value': value});
  }

  @override
  Future<void> setShowingApplyProgressSheet(bool value) async {
    await methodChannel.invokeMethod('setShowingApplyProgressSheet', {'value': value});
  }

  @override
  Future<void> setShowMissingFiltersSheet(bool value) async {
    await methodChannel.invokeMethod('setShowMissingFiltersSheet', {'value': value});
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableUpdates() async {
    final result = await methodChannel.invokeMethod<List>('getAvailableUpdates');
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<String> getCategoryWarningMessage() async {
    final result = await methodChannel.invokeMethod<String>('getCategoryWarningMessage');
    return result ?? '';
  }

  @override
  Future<bool> getShowingCategoryWarningAlert() async {
    final result = await methodChannel.invokeMethod<bool>('getShowingCategoryWarningAlert');
    return result ?? false;
  }

  @override
  Future<void> setShowingCategoryWarningAlert(bool value) async {
    await methodChannel.invokeMethod('setShowingCategoryWarningAlert', {'value': value});
  }

  @override
  Future<bool> getShowingNoUpdatesAlert() async {
    final result = await methodChannel.invokeMethod<bool>('getShowingNoUpdatesAlert');
    return result ?? false;
  }

  @override
  Future<void> setShowingNoUpdatesAlert(bool value) async {
    await methodChannel.invokeMethod('setShowingNoUpdatesAlert', {'value': value});
  }

  @override
  Future<bool> getShowingDownloadCompleteAlert() async {
    final result = await methodChannel.invokeMethod<bool>('getShowingDownloadCompleteAlert');
    return result ?? false;
  }

  @override
  Future<void> setShowingDownloadCompleteAlert(bool value) async {
    await methodChannel.invokeMethod('setShowingDownloadCompleteAlert', {'value': value});
  }

  @override
  Future<String> getDownloadCompleteMessage() async {
    final result = await methodChannel.invokeMethod<String>('getDownloadCompleteMessage');
    return result ?? '';
  }
}

/// The main plugin class
class FlutterWblockPlugin {
  static FlutterWblockPluginPlatform get _platform => FlutterWblockPluginPlatform.instance;

  /// Get all filter lists
  static Future<List<Map<String, dynamic>>> getFilterLists() {
    return _platform.getFilterLists();
  }

  /// Toggle filter list selection
  static Future<void> toggleFilterListSelection(String filterId) {
    return _platform.toggleFilterListSelection(filterId);
  }

  /// Check and enable filters
  static Future<void> checkAndEnableFilters({bool forceReload = false}) {
    return _platform.checkAndEnableFilters(forceReload: forceReload);
  }

  /// Check for updates
  static Future<void> checkForUpdates() {
    return _platform.checkForUpdates();
  }

  /// Check if loading
  static Future<bool> isLoading() {
    return _platform.isLoading();
  }

  /// Get status description
  static Future<String> getStatusDescription() {
    return _platform.getStatusDescription();
  }

  /// Get last rule count
  static Future<int> getLastRuleCount() {
    return _platform.getLastRuleCount();
  }

  /// Add filter list
  static Future<void> addFilterList({required String name, required String urlString}) {
    return _platform.addFilterList(name: name, urlString: urlString);
  }

  /// Remove filter list
  static Future<void> removeFilterList(String filterId) {
    return _platform.removeFilterList(filterId);
  }

  /// Update versions and counts
  static Future<void> updateVersionsAndCounts() {
    return _platform.updateVersionsAndCounts();
  }

  /// Check if has unapplied changes
  static Future<bool> hasUnappliedChanges() {
    return _platform.hasUnappliedChanges();
  }

  /// Apply downloaded changes
  static Future<void> applyDownloadedChanges() {
    return _platform.applyDownloadedChanges();
  }

  /// Show category warning
  static Future<void> showCategoryWarning(String category) {
    return _platform.showCategoryWarning(category);
  }

  /// Check if category is approaching limit
  static Future<bool> isCategoryApproachingLimit(String category) {
    return _platform.isCategoryApproachingLimit(category);
  }

  /// Get logs
  static Future<String> getLogs() {
    return _platform.getLogs();
  }

  /// Clear logs
  static Future<void> clearLogs() {
    return _platform.clearLogs();
  }

  /// Get user scripts
  static Future<List<Map<String, dynamic>>> getUserScripts() {
    return _platform.getUserScripts();
  }

  /// Toggle user script
  static Future<void> toggleUserScript(String scriptId) {
    return _platform.toggleUserScript(scriptId);
  }

  /// Remove user script
  static Future<void> removeUserScript(String scriptId) {
    return _platform.removeUserScript(scriptId);
  }

  /// Add user script
  static Future<void> addUserScript({required String name, required String content}) {
    return _platform.addUserScript(name: name, content: content);
  }

  /// Get whitelisted domains
  static Future<List<String>> getWhitelistedDomains() {
    return _platform.getWhitelistedDomains();
  }

  /// Add whitelisted domain
  static Future<void> addWhitelistedDomain(String domain) {
    return _platform.addWhitelistedDomain(domain);
  }

  /// Remove whitelisted domain
  static Future<void> removeWhitelistedDomain(String domain) {
    return _platform.removeWhitelistedDomain(domain);
  }

  /// Update whitelisted domains
  static Future<void> updateWhitelistedDomains(List<String> domains) {
    return _platform.updateWhitelistedDomains(domains);
  }

  /// Get filter details
  static Future<Map<String, dynamic>> getFilterDetails(String filterId) {
    return _platform.getFilterDetails(filterId);
  }

  /// Reset onboarding
  static Future<void> resetOnboarding() {
    return _platform.resetOnboarding();
  }

  /// Check if has completed onboarding
  static Future<bool> hasCompletedOnboarding() {
    return _platform.hasCompletedOnboarding();
  }

  /// Set onboarding completed
  static Future<void> setOnboardingCompleted(bool completed) {
    return _platform.setOnboardingCompleted(completed);
  }

  /// Get apply progress
  static Future<Map<String, dynamic>?> getApplyProgress() {
    return _platform.getApplyProgress();
  }

  /// Get rule counts by category
  static Future<Map<String, int>?> getRuleCountsByCategory() {
    return _platform.getRuleCountsByCategory();
  }

  /// Get categories approaching limit
  static Future<List<String>?> getCategoriesApproachingLimit() {
    return _platform.getCategoriesApproachingLimit();
  }

  /// Check for filter updates
  static Future<List<Map<String, dynamic>>?> checkForFilterUpdates() {
    return _platform.checkForFilterUpdates();
  }

  /// Apply filter updates
  static Future<void> applyFilterUpdates(List<String> updateIds) {
    return _platform.applyFilterUpdates(updateIds);
  }

  /// Download missing filters
  static Future<void> downloadMissingFilters() {
    return _platform.downloadMissingFilters();
  }

  /// Update missing filters
  static Future<void> updateMissingFilters() {
    return _platform.updateMissingFilters();
  }

  /// Download selected filters
  static Future<void> downloadSelectedFilters(List<String> filterIds) {
    return _platform.downloadSelectedFilters(filterIds);
  }

  /// Reset to default lists
  static Future<void> resetToDefaultLists() {
    return _platform.resetToDefaultLists();
  }

  /// Set user script manager
  static Future<void> setUserScriptManager() {
    return _platform.setUserScriptManager();
  }

  /// Check if filter file exists
  static Future<bool> doesFilterFileExist(String filterId) {
    return _platform.doesFilterFileExist(filterId);
  }

  /// Get missing filters
  static Future<List<Map<String, dynamic>>> getMissingFilters() {
    return _platform.getMissingFilters();
  }

  /// Get timing statistics
  static Future<Map<String, dynamic>> getTimingStatistics() {
    return _platform.getTimingStatistics();
  }

  /// Get source rules count
  static Future<int> getSourceRulesCount() {
    return _platform.getSourceRulesCount();
  }

  /// Get detailed progress
  static Future<Map<String, dynamic>> getDetailedProgress() {
    return _platform.getDetailedProgress();
  }

  /// Get showing update popup
  static Future<bool> getShowingUpdatePopup() {
    return _platform.getShowingUpdatePopup();
  }

  /// Get showing apply progress sheet
  static Future<bool> getShowingApplyProgressSheet() {
    return _platform.getShowingApplyProgressSheet();
  }

  /// Get show missing filters sheet
  static Future<bool> getShowMissingFiltersSheet() {
    return _platform.getShowMissingFiltersSheet();
  }

  /// Set showing update popup
  static Future<void> setShowingUpdatePopup(bool value) {
    return _platform.setShowingUpdatePopup(value);
  }

  /// Set showing apply progress sheet
  static Future<void> setShowingApplyProgressSheet(bool value) {
    return _platform.setShowingApplyProgressSheet(value);
  }

  /// Set show missing filters sheet
  static Future<void> setShowMissingFiltersSheet(bool value) {
    return _platform.setShowMissingFiltersSheet(value);
  }

  /// Get available updates
  static Future<List<Map<String, dynamic>>> getAvailableUpdates() {
    return _platform.getAvailableUpdates();
  }

  /// Get category warning message
  static Future<String> getCategoryWarningMessage() {
    return _platform.getCategoryWarningMessage();
  }

  /// Get showing category warning alert
  static Future<bool> getShowingCategoryWarningAlert() {
    return _platform.getShowingCategoryWarningAlert();
  }

  /// Set showing category warning alert
  static Future<void> setShowingCategoryWarningAlert(bool value) {
    return _platform.setShowingCategoryWarningAlert(value);
  }

  /// Get showing no updates alert
  static Future<bool> getShowingNoUpdatesAlert() {
    return _platform.getShowingNoUpdatesAlert();
  }

  /// Set showing no updates alert
  static Future<void> setShowingNoUpdatesAlert(bool value) {
    return _platform.setShowingNoUpdatesAlert(value);
  }

  /// Get showing download complete alert
  static Future<bool> getShowingDownloadCompleteAlert() {
    return _platform.getShowingDownloadCompleteAlert();
  }

  /// Set showing download complete alert
  static Future<void> setShowingDownloadCompleteAlert(bool value) {
    return _platform.setShowingDownloadCompleteAlert(value);
  }

  /// Get download complete message
  static Future<String> getDownloadCompleteMessage() {
    return _platform.getDownloadCompleteMessage();
  }
}
