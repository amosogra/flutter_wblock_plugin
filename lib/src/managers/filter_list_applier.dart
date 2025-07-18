import 'dart:convert';
import 'dart:io';
import '../models/filter_list.dart';
import '../utilities/file_storage.dart';
import 'log_manager.dart';

class FilterListApplier {
  final LogManager _logManager;

  // Safari Content Blocker identifiers
  static const List<String> contentBlockerIdentifiers = [
    'syferlab.wBlock.wBlock-Filters',
    'syferlab.wBlock.wBlock-Filters-2',
    'syferlab.wBlock.wBlock-Scripts',
  ];

  // Maximum rules per content blocker
  static const int maxRulesPerBlocker = 50000;
  static const int maxSelectorsPerBlocker = 150000;

  FilterListApplier({LogManager? logManager}) : _logManager = logManager ?? LogManager();

  Future<void> checkAndCreateBlockerList(List<FilterList> filterLists) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();

      // Create default empty blocker lists if they don't exist
      for (int i = 1; i <= 3; i++) {
        final blockerFile = File('${dir.path}/blockerList$i.json');
        if (!await blockerFile.exists()) {
          await blockerFile.writeAsString('[]');
          await _logManager.log('Created empty blockerList$i.json');
        }
      }
    } catch (e) {
      await _logManager.log('Error creating blocker lists: $e');
    }
  }

  Future<void> applyChanges(
    List<FilterList> filterLists,
    Function(double) progressCallback,
  ) async {
    await _logManager.log('Applying changes to Safari content blockers');

    try {
      // Get enabled filters
      final enabledFilters = filterLists.where((f) => f.isSelected).toList();

      if (enabledFilters.isEmpty) {
        await _clearAllBlockerLists();
        progressCallback(1.0);
        return;
      }

      // Load all rules
      final allRules = await _loadAllRules(enabledFilters, (progress) {
        progressCallback(progress * 0.5); // First 50% for loading
      });

      // Distribute rules among content blockers
      await _distributeRules(allRules, (progress) {
        progressCallback(0.5 + progress * 0.5); // Last 50% for distribution
      });

      await _logManager.log('Successfully applied changes');
    } catch (e) {
      await _logManager.log('Error applying changes: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAllRules(
    List<FilterList> filterLists,
    Function(double) progressCallback,
  ) async {
    final allRules = <Map<String, dynamic>>[];
    final total = filterLists.length.toDouble();
    var completed = 0.0;

    for (final filter in filterLists) {
      final rules = await _loadFilterRules(filter);
      allRules.addAll(rules);

      completed += 1;
      progressCallback(completed / total);
    }

    await _logManager.log('Loaded ${allRules.length} total rules');
    return allRules;
  }

  Future<List<Map<String, dynamic>>> _loadFilterRules(FilterList filter) async {
    final rules = <Map<String, dynamic>>[];

    try {
      final dir = await FileStorage.getSharedContainerDirectory();

      // Load standard rules
      final standardFile = File('${dir.path}/${filter.name}.json');
      if (await standardFile.exists()) {
        final content = await standardFile.readAsString();
        final standardRules = json.decode(content) as List;
        rules.addAll(standardRules.cast<Map<String, dynamic>>());
      }

      // Load advanced rules
      final advancedFile = File('${dir.path}/${filter.name}_advanced.json');
      if (await advancedFile.exists()) {
        final content = await advancedFile.readAsString();
        final advancedRules = json.decode(content) as List;
        rules.addAll(advancedRules.cast<Map<String, dynamic>>());
      }

      // Don't load scriptlet rules here - they go to the Scripts extension
    } catch (e) {
      await _logManager.log('Error loading rules for ${filter.name}: $e');
    }

    return rules;
  }

  Future<void> _distributeRules(
    List<Map<String, dynamic>> allRules,
    Function(double) progressCallback,
  ) async {
    await _logManager.log('Distributing ${allRules.length} rules among content blockers');

    // Separate rules by type
    final blockingRules = <Map<String, dynamic>>[];
    final hidingRules = <Map<String, dynamic>>[];
    final scriptletRules = <Map<String, dynamic>>[];

    for (final rule in allRules) {
      final actionType = rule['action']?['type'];

      if (actionType == 'css-display-none') {
        hidingRules.add(rule);
      } else if (actionType == 'scriptlet') {
        scriptletRules.add(rule);
      } else {
        blockingRules.add(rule);
      }
    }

    // Distribute to content blockers
    final dir = await FileStorage.getSharedContainerDirectory();

    // Blocker 1: Blocking rules (up to limit)
    final blocker1Rules = blockingRules.take(maxRulesPerBlocker).toList();
    await _saveBlockerList(
      File('${dir.path}/blockerList1.json'),
      blocker1Rules,
    );

    // Blocker 2: Hiding rules and overflow blocking rules
    final blocker2Rules = <Map<String, dynamic>>[];
    if (blockingRules.length > maxRulesPerBlocker) {
      blocker2Rules.addAll(
        blockingRules.skip(maxRulesPerBlocker).take(maxRulesPerBlocker),
      );
    }
    blocker2Rules.addAll(hidingRules.take(maxRulesPerBlocker - blocker2Rules.length));
    await _saveBlockerList(
      File('${dir.path}/blockerList2.json'),
      blocker2Rules,
    );

    // Blocker 3 (Scripts): Scriptlet rules for YouTube and advanced blocking
    await _saveScriptletRules(scriptletRules);

    progressCallback(1.0);

    await _logManager.log(
      'Distributed rules: ${blocker1Rules.length} in blocker 1, '
      '${blocker2Rules.length} in blocker 2, '
      '${scriptletRules.length} scriptlets',
    );
  }

  Future<void> _saveBlockerList(File file, List<Map<String, dynamic>> rules) async {
    try {
      // Validate rules before saving
      final validRules = _validateRules(rules);
      await file.writeAsString(json.encode(validRules));
    } catch (e) {
      await _logManager.log('Error saving blocker list ${file.path}: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _validateRules(List<Map<String, dynamic>> rules) {
    final validRules = <Map<String, dynamic>>[];

    for (final rule in rules) {
      try {
        // Ensure required fields
        if (rule['action'] != null && rule['trigger'] != null) {
          // Validate trigger
          final trigger = rule['trigger'] as Map<String, dynamic>;
          if (trigger['url-filter'] != null) {
            validRules.add(rule);
          }
        }
      } catch (e) {
        // Skip invalid rule
        continue;
      }
    }

    return validRules;
  }

  Future<void> _saveScriptletRules(List<Map<String, dynamic>> scriptletRules) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();

      // Group scriptlets by type for the Scripts extension
      final youtubeScriptlets = <Map<String, dynamic>>[];
      final generalScriptlets = <Map<String, dynamic>>[];

      for (final rule in scriptletRules) {
        final domains = rule['trigger']?['if-domain'] as List?;
        if (domains != null && domains.any((d) => d.toString().contains('youtube'))) {
          youtubeScriptlets.add(rule);
        } else {
          generalScriptlets.add(rule);
        }
      }

      // Save YouTube-specific scriptlets
      if (youtubeScriptlets.isNotEmpty) {
        final youtubeFile = File('${dir.path}/youtube_scriptlets.json');
        await youtubeFile.writeAsString(json.encode(youtubeScriptlets));
        await _logManager.log('Saved ${youtubeScriptlets.length} YouTube scriptlets');
      }

      // Save general scriptlets
      if (generalScriptlets.isNotEmpty) {
        final generalFile = File('${dir.path}/general_scriptlets.json');
        await generalFile.writeAsString(json.encode(generalScriptlets));
      }

      // Create the main scriptlet configuration for the Scripts extension
      final scriptletConfig = {
        'youtube': youtubeScriptlets.isNotEmpty,
        'general': generalScriptlets.isNotEmpty,
        'totalScriptlets': scriptletRules.length,
      };

      final configFile = File('${dir.path}/scriptlet_config.json');
      await configFile.writeAsString(json.encode(scriptletConfig));
    } catch (e) {
      await _logManager.log('Error saving scriptlet rules: $e');
    }
  }

  Future<void> _clearAllBlockerLists() async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();

      for (int i = 1; i <= 3; i++) {
        final blockerFile = File('${dir.path}/blockerList$i.json');
        await blockerFile.writeAsString('[]');
      }

      // Clear scriptlet files
      final scriptletFiles = [
        'youtube_scriptlets.json',
        'general_scriptlets.json',
        'scriptlet_config.json',
      ];

      for (final filename in scriptletFiles) {
        final file = File('${dir.path}/$filename');
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _logManager.log('Cleared all blocker lists');
    } catch (e) {
      await _logManager.log('Error clearing blocker lists: $e');
    }
  }

  Future<int> getRuleCount(FilterList filter) async {
    var count = 0;

    try {
      final dir = await FileStorage.getSharedContainerDirectory();

      // Count standard rules
      final standardFile = File('${dir.path}/${filter.name}.json');
      if (await standardFile.exists()) {
        final content = await standardFile.readAsString();
        final rules = json.decode(content) as List;
        count += rules.length;
      }

      // Count advanced rules
      final advancedFile = File('${dir.path}/${filter.name}_advanced.json');
      if (await advancedFile.exists()) {
        final content = await advancedFile.readAsString();
        final rules = json.decode(content) as List;
        count += rules.length;
      }

      // Count scriptlet rules
      final scriptletFile = File('${dir.path}/${filter.name}_scriptlets.json');
      if (await scriptletFile.exists()) {
        final content = await scriptletFile.readAsString();
        final rules = json.decode(content) as List;
        count += rules.length;
      }
    } catch (e) {
      await _logManager.log('Error counting rules for ${filter.name}: $e');
    }

    return count;
  }
}
