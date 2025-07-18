import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../models/filter_list.dart';
import '../models/filter_stats.dart';

abstract class WBlockPlatformInterface extends PlatformInterface {
  WBlockPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static WBlockPlatformInterface _instance = MethodChannelWBlock();

  static WBlockPlatformInterface get instance => _instance;

  static set instance(WBlockPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<FilterList>> loadFilterLists() {
    throw UnimplementedError('loadFilterLists() has not been implemented.');
  }

  Future<void> saveFilterLists(List<FilterList> filterLists) {
    throw UnimplementedError('saveFilterLists() has not been implemented.');
  }

  Future<void> toggleFilter(String filterId) {
    throw UnimplementedError('toggleFilter() has not been implemented.');
  }

  Future<void> applyChanges(List<FilterList> filterLists) {
    throw UnimplementedError('applyChanges() has not been implemented.');
  }

  Future<List<FilterList>> checkForUpdates(List<FilterList> filterLists) {
    throw UnimplementedError('checkForUpdates() has not been implemented.');
  }

  Future<void> updateFilters(List<FilterList> filterLists) {
    throw UnimplementedError('updateFilters() has not been implemented.');
  }

  Future<void> addCustomFilter(FilterList filter) {
    throw UnimplementedError('addCustomFilter() has not been implemented.');
  }

  Future<void> removeCustomFilter(String filterId) {
    throw UnimplementedError('removeCustomFilter() has not been implemented.');
  }

  Future<FilterStats> getFilterStats(List<FilterList> filterLists) {
    throw UnimplementedError('getFilterStats() has not been implemented.');
  }

  Future<String> getLogs() {
    throw UnimplementedError('getLogs() has not been implemented.');
  }

  Future<void> clearLogs() {
    throw UnimplementedError('clearLogs() has not been implemented.');
  }

  Future<void> downloadFilter(FilterList filter) {
    throw UnimplementedError('downloadFilter() has not been implemented.');
  }

  Future<int> getRuleCount(FilterList filter) {
    throw UnimplementedError('getRuleCount() has not been implemented.');
  }

  Future<bool> filterFileExists(FilterList filter) {
    throw UnimplementedError('filterFileExists() has not been implemented.');
  }

  Stream<double> get progressStream {
    throw UnimplementedError('progressStream has not been implemented.');
  }
}

class MethodChannelWBlock extends WBlockPlatformInterface {
  final MethodChannel _channel = const MethodChannel('flutter_wblock_plugin');
  final EventChannel _progressChannel = const EventChannel('flutter_wblock_plugin/progress');

  @override
  Future<List<FilterList>> loadFilterLists() async {
    final List<dynamic> result = await _channel.invokeMethod('loadFilterLists');
    return result.map((e) => FilterList.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> saveFilterLists(List<FilterList> filterLists) async {
    await _channel.invokeMethod('saveFilterLists', {
      'filterLists': filterLists.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<void> toggleFilter(String filterId) async {
    await _channel.invokeMethod('toggleFilter', {'filterId': filterId});
  }

  @override
  Future<void> applyChanges(List<FilterList> filterLists) async {
    await _channel.invokeMethod('applyChanges', {
      'filterLists': filterLists.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<List<FilterList>> checkForUpdates(List<FilterList> filterLists) async {
    final List<dynamic> result = await _channel.invokeMethod('checkForUpdates', {
      'filterLists': filterLists.map((e) => e.toJson()).toList(),
    });
    return result.map((e) => FilterList.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> updateFilters(List<FilterList> filterLists) async {
    await _channel.invokeMethod('updateFilters', {
      'filterLists': filterLists.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<void> addCustomFilter(FilterList filter) async {
    await _channel.invokeMethod('addCustomFilter', filter.toJson());
  }

  @override
  Future<void> removeCustomFilter(String filterId) async {
    await _channel.invokeMethod('removeCustomFilter', {'filterId': filterId});
  }

  @override
  Future<FilterStats> getFilterStats(List<FilterList> filterLists) async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('getFilterStats', {
      'filterLists': filterLists.map((e) => e.toJson()).toList(),
    });
    return FilterStats.fromJson(Map<String, dynamic>.from(result));
  }

  @override
  Future<String> getLogs() async {
    final String result = await _channel.invokeMethod('getLogs');
    return result;
  }

  @override
  Future<void> clearLogs() async {
    await _channel.invokeMethod('clearLogs');
  }

  @override
  Future<void> downloadFilter(FilterList filter) async {
    await _channel.invokeMethod('downloadFilter', filter.toJson());
  }

  @override
  Future<int> getRuleCount(FilterList filter) async {
    final int result = await _channel.invokeMethod('getRuleCount', filter.toJson());
    return result;
  }

  @override
  Future<bool> filterFileExists(FilterList filter) async {
    final bool result = await _channel.invokeMethod('filterFileExists', filter.toJson());
    return result;
  }

  @override
  Stream<double> get progressStream {
    return _progressChannel.receiveBroadcastStream().cast<double>();
  }
}
