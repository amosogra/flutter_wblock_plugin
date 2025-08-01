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
}
