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
  Future<List<Map<String, dynamic>>> getLogs();
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
  Future<List<Map<String, dynamic>>> getLogs() async {
    final result = await methodChannel.invokeMethod<List>('getLogs');
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
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
  static Future<List<Map<String, dynamic>>> getLogs() {
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
}
