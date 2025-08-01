import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWblockPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWblockPluginPlatform {
  @override
  Future<List<Map<String, dynamic>>> getFilterLists() async {
    return [
      {
        'id': 'test-id',
        'name': 'Test Filter',
        'description': 'Test Description',
        'category': 'Ads',
        'url': 'https://example.com/filter.txt',
        'version': '1.0.0',
        'isSelected': false,
        'sourceRuleCount': 1000,
      }
    ];
  }

  @override
  Future<void> toggleFilterListSelection(String filterId) async {
    // Mock implementation
  }

  @override
  Future<void> checkAndEnableFilters({bool forceReload = false}) async {
    // Mock implementation
  }

  @override
  Future<void> checkForUpdates() async {
    // Mock implementation
  }

  @override
  Future<bool> isLoading() async {
    return false;
  }

  @override
  Future<String> getStatusDescription() async {
    return 'Ready';
  }

  @override
  Future<int> getLastRuleCount() async {
    return 1000;
  }

  @override
  Future<void> addFilterList({required String name, required String urlString}) async {
    // Mock implementation
  }

  @override
  Future<void> removeFilterList(String filterId) async {
    // Mock implementation
  }

  @override
  Future<void> updateVersionsAndCounts() async {
    // Mock implementation
  }

  @override
  Future<bool> hasUnappliedChanges() async {
    return false;
  }

  @override
  Future<void> applyDownloadedChanges() async {
    // Mock implementation
  }

  @override
  Future<void> showCategoryWarning(String category) async {
    // Mock implementation
  }

  @override
  Future<bool> isCategoryApproachingLimit(String category) async {
    return false;
  }

  @override
  Future<List<Map<String, dynamic>>> getLogs() async {
    return [];
  }

  @override
  Future<void> clearLogs() async {
    // Mock implementation
  }

  @override
  Future<List<Map<String, dynamic>>> getUserScripts() async {
    return [];
  }

  @override
  Future<void> toggleUserScript(String scriptId) async {
    // Mock implementation
  }

  @override
  Future<void> removeUserScript(String scriptId) async {
    // Mock implementation
  }

  @override
  Future<void> addUserScript({required String name, required String content}) async {
    // Mock implementation
  }

  @override
  Future<List<String>> getWhitelistedDomains() async {
    return [];
  }

  @override
  Future<void> addWhitelistedDomain(String domain) async {
    // Mock implementation
  }

  @override
  Future<void> removeWhitelistedDomain(String domain) async {
    // Mock implementation
  }

  @override
  Future<void> updateWhitelistedDomains(List<String> domains) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>> getFilterDetails(String filterId) async {
    return {};
  }

  @override
  Future<void> resetOnboarding() async {
    // Mock implementation
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return true;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    // Mock implementation
  }
  
  @override
  Future<void> applyFilterUpdates(List<String> updateIds) {
    // TODO: implement applyFilterUpdates
    throw UnimplementedError();
  }
  
  @override
  Future<List<Map<String, dynamic>>?> checkForFilterUpdates() {
    // TODO: implement checkForFilterUpdates
    throw UnimplementedError();
  }
  
  @override
  Future<void> downloadMissingFilters() {
    // TODO: implement downloadMissingFilters
    throw UnimplementedError();
  }
  
  @override
  Future<void> downloadSelectedFilters(List<String> filterIds) {
    // TODO: implement downloadSelectedFilters
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, dynamic>?> getApplyProgress() {
    // TODO: implement getApplyProgress
    throw UnimplementedError();
  }
  
  @override
  Future<List<String>?> getCategoriesApproachingLimit() {
    // TODO: implement getCategoriesApproachingLimit
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, int>?> getRuleCountsByCategory() {
    // TODO: implement getRuleCountsByCategory
    throw UnimplementedError();
  }
  
  @override
  Future<void> resetToDefaultLists() {
    // TODO: implement resetToDefaultLists
    throw UnimplementedError();
  }
  
  @override
  Future<void> setUserScriptManager() {
    // TODO: implement setUserScriptManager
    throw UnimplementedError();
  }
  
  @override
  Future<void> updateMissingFilters() {
    // TODO: implement updateMissingFilters
    throw UnimplementedError();
  }
}

void main() {
  final FlutterWblockPluginPlatform initialPlatform = FlutterWblockPluginPlatform.instance;

  test('$MethodChannelFlutterWblockPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWblockPlugin>());
  });

  test('getFilterLists returns expected data', () async {
    MockFlutterWblockPluginPlatform fakePlatform = MockFlutterWblockPluginPlatform();
    FlutterWblockPluginPlatform.instance = fakePlatform;

    final result = await FlutterWblockPlugin.getFilterLists();
    expect(result.length, 1);
    expect(result[0]['name'], 'Test Filter');
  });

  test('getLastRuleCount returns expected value', () async {
    MockFlutterWblockPluginPlatform fakePlatform = MockFlutterWblockPluginPlatform();
    FlutterWblockPluginPlatform.instance = fakePlatform;

    final result = await FlutterWblockPlugin.getLastRuleCount();
    expect(result, 1000);
  });
}
