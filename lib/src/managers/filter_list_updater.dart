import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/filter_list.dart';
import '../utilities/file_storage.dart';
import 'filter_list_converter.dart';
import 'filter_list_loader.dart';
import 'filter_list_applier.dart';
import 'log_manager.dart';

class FilterListUpdater {
  final FilterListLoader _loader;
  final FilterListConverter _converter;
  final FilterListApplier _applier;
  final LogManager _logManager;
  
  FilterListUpdater({
    required FilterListLoader loader,
    required FilterListConverter converter,
    required FilterListApplier applier,
    LogManager? logManager,
  }) : _loader = loader,
       _converter = converter,
       _applier = applier,
       _logManager = logManager ?? LogManager();
  
  Future<bool> fetchAndProcessFilter(FilterList filter) async {
    try {
      await _logManager.log('Fetching filter: ${filter.name} from ${filter.url}');
      
      // Download filter content
      final response = await http.get(Uri.parse(filter.url));
      
      if (response.statusCode != 200) {
        await _logManager.log('Failed to download ${filter.name}: HTTP ${response.statusCode}');
        return false;
      }
      
      final content = response.body;
      
      // Extract version from content
      String? version;
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.startsWith('! Version:')) {
          version = line.substring('! Version:'.length).trim();
          break;
        }
      }
      
      // Save raw filter file
      final dir = await FileStorage.getSharedContainerDirectory();
      final txtFile = File('${dir.path}/${filter.name}.txt');
      await txtFile.writeAsString(content);
      
      // Convert to Safari Content Blocker format
      final convertedRules = await _converter.convertFilterToContentBlockerRules(
        filter,
        content,
      );
      
      // Update version if found
      if (version != null) {
        convertedRules['version'] = version;
      }
      
      // Save converted rules
      await _converter.saveConvertedRules(filter.name, convertedRules);
      
      await _logManager.log('Successfully processed ${filter.name}');
      return true;
    } catch (e) {
      await _logManager.log('Error processing filter ${filter.name}: $e');
      return false;
    }
  }
  
  Future<List<FilterList>> checkForUpdates(List<FilterList> filterLists) async {
    final updatesAvailable = <FilterList>[];
    
    await _logManager.log('Checking for updates...');
    
    for (final filter in filterLists) {
      if (await _hasUpdate(filter)) {
        updatesAvailable.add(filter);
      }
    }
    
    await _logManager.log('Found ${updatesAvailable.length} updates available');
    return updatesAvailable;
  }
  
  Future<bool> _hasUpdate(FilterList filter) async {
    try {
      // Check if filter file exists
      if (!await _loader.filterFileExists(filter)) {
        return true; // Need to download
      }
      
      // Get current version from saved file
      final dir = await FileStorage.getSharedContainerDirectory();
      final jsonFile = File('${dir.path}/${filter.name}.json');
      
      if (!await jsonFile.exists()) {
        return true; // Need to convert
      }
      
      // Check remote for updates
      final response = await http.head(Uri.parse(filter.url));
      
      if (response.statusCode != 200) {
        return false; // Can't check, assume no update
      }
      
      // Check Last-Modified header
      final lastModified = response.headers['last-modified'];
      if (lastModified != null) {
        final remoteDate = HttpDate.parse(lastModified);
        final localDate = await jsonFile.lastModified();
        
        if (remoteDate.isAfter(localDate)) {
          return true;
        }
      }
      
      // Check ETag if available
      final etag = response.headers['etag'];
      if (etag != null) {
        final savedEtag = await _getSavedEtag(filter.name);
        if (etag != savedEtag) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      await _logManager.log('Error checking update for ${filter.name}: $e');
      return false;
    }
  }
  
  Future<String?> _getSavedEtag(String filterName) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      final etagFile = File('${dir.path}/$filterName.etag');
      
      if (await etagFile.exists()) {
        return await etagFile.readAsString();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
  
  Future<void> _saveEtag(String filterName, String etag) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      final etagFile = File('${dir.path}/$filterName.etag');
      await etagFile.writeAsString(etag);
    } catch (e) {
      // Ignore errors
    }
  }
  
  Future<Map<int, String>> updateMissingVersions(List<FilterList> filterLists) async {
    final updatedVersions = <int, String>{};
    
    for (int i = 0; i < filterLists.length; i++) {
      final filter = filterLists[i];
      
      if (filter.version.isEmpty) {
        final version = await _getFilterVersion(filter);
        if (version != null) {
          updatedVersions[i] = version;
        }
      }
    }
    
    return updatedVersions;
  }
  
  Future<String?> _getFilterVersion(FilterList filter) async {
    try {
      // First check local file
      final dir = await FileStorage.getSharedContainerDirectory();
      final jsonFile = File('${dir.path}/${filter.name}.json');
      
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final rules = json.decode(content) as List;
        
        // Check if version is stored in metadata
        if (rules.isNotEmpty && rules[0] is Map && rules[0]['_version'] != null) {
          return rules[0]['_version'] as String;
        }
      }
      
      // Check text file for version
      final txtFile = File('${dir.path}/${filter.name}.txt');
      if (await txtFile.exists()) {
        final lines = await txtFile.readAsLines();
        for (final line in lines.take(20)) { // Check first 20 lines
          if (line.startsWith('! Version:')) {
            return line.substring('! Version:'.length).trim();
          }
        }
      }
    } catch (e) {
      await _logManager.log('Error getting version for ${filter.name}: $e');
    }
    
    return null;
  }
  
  Future<List<FilterList>> autoUpdateFilters(
    List<FilterList> filterLists,
    Function(double) progressCallback,
  ) async {
    final updatedFilters = <FilterList>[];
    final enabledFilters = filterLists.where((f) => f.isSelected).toList();
    final total = enabledFilters.length.toDouble();
    var completed = 0.0;
    
    await _logManager.log('Starting auto-update for ${enabledFilters.length} filters');
    
    for (final filter in enabledFilters) {
      if (await _hasUpdate(filter)) {
        final success = await fetchAndProcessFilter(filter);
        if (success) {
          updatedFilters.add(filter);
          
          // Update ETag if available
          try {
            final response = await http.head(Uri.parse(filter.url));
            final etag = response.headers['etag'];
            if (etag != null) {
              await _saveEtag(filter.name, etag);
            }
          } catch (e) {
            // Ignore ETag errors
          }
        }
      }
      
      completed += 1;
      progressCallback(completed / total);
    }
    
    await _logManager.log('Auto-update completed: ${updatedFilters.length} filters updated');
    return updatedFilters;
  }
  
  Future<List<FilterList>> updateSelectedFilters(
    List<FilterList> selectedFilters,
    Function(double) progressCallback,
  ) async {
    final updatedFilters = <FilterList>[];
    final total = selectedFilters.length.toDouble();
    var completed = 0.0;
    
    for (final filter in selectedFilters) {
      final success = await fetchAndProcessFilter(filter);
      if (success) {
        updatedFilters.add(filter);
        
        // Update ETag
        try {
          final response = await http.head(Uri.parse(filter.url));
          final etag = response.headers['etag'];
          if (etag != null) {
            await _saveEtag(filter.name, etag);
          }
        } catch (e) {
          // Ignore ETag errors
        }
      }
      
      completed += 1;
      progressCallback(completed / total);
    }
    
    return updatedFilters;
  }
}
