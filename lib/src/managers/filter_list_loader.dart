import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_list.dart';
import '../utilities/file_storage.dart';
import 'log_manager.dart';

class FilterListLoader {
  final LogManager _logManager;
  
  FilterListLoader({LogManager? logManager}) 
    : _logManager = logManager ?? LogManager();
  
  static const String filterListsKey = 'filterLists';
  static const String customFilterListsKey = 'customFilterLists';
  static const String selectedStateKey = 'selectedFilterStates';
  
  Future<void> checkAndCreateGroupFolder() async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        await _logManager.log('Created shared container directory');
      }
    } catch (e) {
      await _logManager.log('Error creating group folder: $e');
    }
  }
  
  Future<List<FilterList>> loadFilterLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(filterListsKey);
      
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        return jsonList.map((json) => FilterList.fromJson(json)).toList();
      }
      
      // If no saved lists, return default lists
      final defaultLists = getDefaultFilterLists();
      await saveFilterLists(defaultLists);
      return defaultLists;
    } catch (e) {
      await _logManager.log('Error loading filter lists: $e');
      return getDefaultFilterLists();
    }
  }
  
  Future<void> saveFilterLists(List<FilterList> filterLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = filterLists.map((f) => f.toJson()).toList();
      await prefs.setString(filterListsKey, json.encode(jsonList));
      await _logManager.log('Saved ${filterLists.length} filter lists');
    } catch (e) {
      await _logManager.log('Error saving filter lists: $e');
    }
  }
  
  Future<List<FilterList>> loadCustomFilterLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(customFilterListsKey);
      
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        return jsonList.map((json) => FilterList.fromJson(json)).toList();
      }
    } catch (e) {
      await _logManager.log('Error loading custom filter lists: $e');
    }
    return [];
  }
  
  Future<void> saveCustomFilterLists(List<FilterList> customFilterLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = customFilterLists.map((f) => f.toJson()).toList();
      await prefs.setString(customFilterListsKey, json.encode(jsonList));
      await _logManager.log('Saved ${customFilterLists.length} custom filter lists');
    } catch (e) {
      await _logManager.log('Error saving custom filter lists: $e');
    }
  }
  
  Future<void> loadSelectedState(List<FilterList> filterLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(selectedStateKey);
      
      if (data != null) {
        final Map<String, dynamic> selectedStates = json.decode(data);
        
        for (var filter in filterLists) {
          if (selectedStates.containsKey(filter.id)) {
            filter.isSelected = selectedStates[filter.id] as bool;
          }
        }
      }
    } catch (e) {
      await _logManager.log('Error loading selected states: $e');
    }
  }
  
  Future<void> saveSelectedState(List<FilterList> filterLists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedStates = <String, bool>{};
      
      for (var filter in filterLists) {
        selectedStates[filter.id] = filter.isSelected;
      }
      
      await prefs.setString(selectedStateKey, json.encode(selectedStates));
    } catch (e) {
      await _logManager.log('Error saving selected states: $e');
    }
  }
  
  Future<bool> filterFileExists(FilterList filter) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      
      // Check for converted JSON files
      final standardFile = File('${dir.path}/${filter.name}.json');
      final advancedFile = File('${dir.path}/${filter.name}_advanced.json');
      
      // Check for raw text file
      final txtFile = File('${dir.path}/${filter.name}.txt');
      
      return await standardFile.exists() || 
             await advancedFile.exists() || 
             await txtFile.exists();
    } catch (e) {
      await _logManager.log('Error checking filter file: $e');
      return false;
    }
  }
  
  Future<String?> getContainerURL() async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      return dir.path;
    } catch (e) {
      await _logManager.log('Error getting container URL: $e');
      return null;
    }
  }
}
