import 'dart:convert';
import 'dart:io';
import '../models/filter_list.dart';
import '../utilities/file_storage.dart';
import 'log_manager.dart';

class FilterListConverter {
  final LogManager _logManager;
  
  FilterListConverter({LogManager? logManager})
    : _logManager = logManager ?? LogManager();
  
  // Maximum rules per content blocker (Safari limit)
  static const int maxRulesPerBlocker = 50000;
  static const int maxSelectors = 150000;
  
  Future<Map<String, dynamic>> convertFilterToContentBlockerRules(
    FilterList filter,
    String filterContent,
  ) async {
    await _logManager.log('Converting filter: ${filter.name}');
    
    final lines = filterContent.split('\n');
    final standardRules = <Map<String, dynamic>>[];
    final advancedRules = <Map<String, dynamic>>[];
    final scriptletRules = <Map<String, dynamic>>[];
    
    String? currentVersion;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip empty lines and comments
      if (trimmedLine.isEmpty || 
          trimmedLine.startsWith('!') || 
          trimmedLine.startsWith('[')) {
        // Extract version if present
        if (trimmedLine.startsWith('! Version:')) {
          currentVersion = trimmedLine.substring('! Version:'.length).trim();
        }
        continue;
      }
      
      try {
        final rule = _parseRule(trimmedLine);
        if (rule != null) {
          if (rule['action']?['type'] == 'scriptlet') {
            scriptletRules.add(rule);
          } else if (_isAdvancedRule(rule)) {
            advancedRules.add(rule);
          } else {
            standardRules.add(rule);
          }
        }
      } catch (e) {
        // Skip malformed rules
        continue;
      }
    }
    
    await _logManager.log(
      'Converted ${filter.name}: ${standardRules.length} standard, '
      '${advancedRules.length} advanced, ${scriptletRules.length} scriptlet rules'
    );
    
    return {
      'standard': standardRules,
      'advanced': advancedRules,
      'scriptlet': scriptletRules,
      'version': currentVersion ?? filter.version,
    };
  }
  
  Map<String, dynamic>? _parseRule(String rule) {
    // Handle element hiding rules (##)
    if (rule.contains('##')) {
      return _parseElementHidingRule(rule);
    }
    
    // Handle scriptlet injection rules (##+js)
    if (rule.contains('##+js(')) {
      return _parseScriptletRule(rule);
    }
    
    // Handle exception rules (@@)
    if (rule.startsWith('@@')) {
      return _parseExceptionRule(rule);
    }
    
    // Handle network blocking rules
    return _parseNetworkRule(rule);
  }
  
  Map<String, dynamic>? _parseElementHidingRule(String rule) {
    final parts = rule.split('##');
    if (parts.length != 2) return null;
    
    final domains = parts[0];
    final selector = parts[1].trim();
    
    if (selector.isEmpty) return null;
    
    final ruleMap = <String, dynamic>{
      'action': {
        'type': 'css-display-none',
        'selector': selector,
      },
      'trigger': <String, dynamic>{
        'url-filter': '.*',
      },
    };
    
    // Add domain conditions if specified
    if (domains.isNotEmpty) {
      final domainList = _parseDomains(domains);
      if (domainList['if-domain']?.isNotEmpty ?? false) {
        ruleMap['trigger']['if-domain'] = domainList['if-domain'];
      }
      if (domainList['unless-domain']?.isNotEmpty ?? false) {
        ruleMap['trigger']['unless-domain'] = domainList['unless-domain'];
      }
    }
    
    return ruleMap;
  }
  
  Map<String, dynamic>? _parseScriptletRule(String rule) {
    final scriptletMatch = RegExp(r'#\+js\(([^)]+)\)').firstMatch(rule);
    if (scriptletMatch == null) return null;
    
    final scriptletData = scriptletMatch.group(1)!;
    final scriptletParts = scriptletData.split(',').map((s) => s.trim()).toList();
    
    if (scriptletParts.isEmpty) return null;
    
    final scriptletName = scriptletParts[0];
    final scriptletArgs = scriptletParts.skip(1).toList();
    
    // Special handling for YouTube ad blocking scriptlets
    if (_isYouTubeScriptlet(scriptletName)) {
      return _createYouTubeBlockingRule(scriptletName, scriptletArgs);
    }
    
    return {
      'action': {
        'type': 'scriptlet',
        'scriptlet': scriptletName,
        'arguments': scriptletArgs,
      },
      'trigger': {
        'url-filter': '.*',
        'if-domain': ['*youtube.com', '*youtube-nocookie.com'],
      },
    };
  }
  
  Map<String, dynamic>? _parseExceptionRule(String rule) {
    final baseRule = rule.substring(2); // Remove @@
    final parsedRule = _parseNetworkRule(baseRule);
    
    if (parsedRule != null) {
      parsedRule['action'] = {'type': 'ignore-previous-rules'};
      return parsedRule;
    }
    
    return null;
  }
  
  Map<String, dynamic>? _parseNetworkRule(String rule) {
    String pattern = rule;
    final options = <String, dynamic>{};
    
    // Extract options if present
    final dollarIndex = rule.indexOf('\$');
    if (dollarIndex != -1) {
      pattern = rule.substring(0, dollarIndex);
      final optionsStr = rule.substring(dollarIndex + 1);
      _parseOptions(optionsStr, options);
    }
    
    // Convert pattern to regex
    final urlFilter = _convertPatternToRegex(pattern);
    if (urlFilter.isEmpty) return null;
    
    final trigger = <String, dynamic>{
      'url-filter': urlFilter,
    };
    
    // Apply options to trigger
    if (options.containsKey('domain')) {
      final domains = options['domain'] as Map<String, List<String>>;
      if (domains['include']?.isNotEmpty ?? false) {
        trigger['if-domain'] = domains['include'];
      }
      if (domains['exclude']?.isNotEmpty ?? false) {
        trigger['unless-domain'] = domains['exclude'];
      }
    }
    
    if (options.containsKey('third-party')) {
      trigger['load-type'] = ['third-party'];
    }
    
    if (options.containsKey('resource-type')) {
      trigger['resource-type'] = options['resource-type'];
    }
    
    return {
      'action': {'type': 'block'},
      'trigger': trigger,
    };
  }
  
  String _convertPatternToRegex(String pattern) {
    if (pattern.isEmpty) return '';
    
    // Handle special patterns
    if (pattern == '*') return '.*';
    if (pattern.startsWith('||')) {
      // Domain anchor
      final domain = pattern.substring(2).replaceAll('*', '.*');
      return '^https?://([^/]+\\.)?$domain';
    }
    if (pattern.startsWith('|') && pattern.endsWith('|')) {
      // Exact match
      return '^${_escapeRegex(pattern.substring(1, pattern.length - 1))}\$';
    }
    
    // Convert wildcards and escape special characters
    String regex = pattern
        .replaceAll('*', '.*')
        .replaceAll('?', '.')
        .replaceAll('^', '(?:[^\\w\\d_\\-.%]|^)');
    
    // Escape regex special characters
    regex = regex.replaceAllMapped(
      RegExp(r'[.+[\]{}()\\]'),
      (match) => '\\${match.group(0)}',
    );
    
    return regex;
  }
  
  String _escapeRegex(String str) {
    return str.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }
  
  void _parseOptions(String optionsStr, Map<String, dynamic> options) {
    final optionsList = optionsStr.split(',');
    
    for (final option in optionsList) {
      if (option.startsWith('domain=')) {
        final domainStr = option.substring('domain='.length);
        options['domain'] = _parseDomainOption(domainStr);
      } else if (option == 'third-party' || option == '3p') {
        options['third-party'] = true;
      } else if (option == '~third-party' || option == '~3p' || option == '1p') {
        options['first-party'] = true;
      } else if (option == 'script') {
        options['resource-type'] ??= [];
        options['resource-type'].add('script');
      } else if (option == 'image') {
        options['resource-type'] ??= [];
        options['resource-type'].add('image');
      } else if (option == 'stylesheet' || option == 'css') {
        options['resource-type'] ??= [];
        options['resource-type'].add('style-sheet');
      } else if (option == 'xmlhttprequest' || option == 'xhr') {
        options['resource-type'] ??= [];
        options['resource-type'].add('raw');
      }
    }
  }
  
  Map<String, List<String>> _parseDomains(String domainsStr) {
    final domains = domainsStr.split(',');
    final includeDomains = <String>[];
    final excludeDomains = <String>[];
    
    for (final domain in domains) {
      final trimmed = domain.trim();
      if (trimmed.startsWith('~')) {
        excludeDomains.add(trimmed.substring(1));
      } else if (trimmed.isNotEmpty) {
        includeDomains.add(trimmed);
      }
    }
    
    return {
      'if-domain': includeDomains,
      'unless-domain': excludeDomains,
    };
  }
  
  Map<String, List<String>> _parseDomainOption(String domainStr) {
    final domains = domainStr.split('|');
    final include = <String>[];
    final exclude = <String>[];
    
    for (final domain in domains) {
      if (domain.startsWith('~')) {
        exclude.add(domain.substring(1));
      } else {
        include.add(domain);
      }
    }
    
    return {
      'include': include,
      'exclude': exclude,
    };
  }
  
  bool _isAdvancedRule(Map<String, dynamic> rule) {
    // Rules that require advanced content blocker
    final action = rule['action'];
    if (action == null) return false;
    
    final actionType = action['type'];
    return actionType == 'css-display-none' ||
           actionType == 'scriptlet' ||
           actionType == 'ignore-previous-rules';
  }
  
  bool _isYouTubeScriptlet(String scriptletName) {
    // Scriptlets specifically for YouTube ad blocking
    return scriptletName == 'json-prune' ||
           scriptletName == 'set-constant' ||
           scriptletName == 'abort-on-property-read' ||
           scriptletName == 'abort-on-property-write' ||
           scriptletName == 'abort-current-inline-script' ||
           scriptletName == 'addEventListener-defuser' ||
           scriptletName == 'prevent-addEventListener';
  }
  
  Map<String, dynamic> _createYouTubeBlockingRule(
    String scriptletName,
    List<String> args,
  ) {
    // Create specific rules for YouTube ad blocking
    return {
      'action': {
        'type': 'scriptlet',
        'scriptlet': scriptletName,
        'arguments': args,
      },
      'trigger': {
        'url-filter': '.*',
        'if-domain': [
          '*youtube.com',
          '*youtube-nocookie.com',
          '*googlevideo.com',
          '*ytimg.com',
        ],
        'resource-type': ['document', 'script'],
      },
    };
  }
  
  Future<void> saveConvertedRules(
    String filterName,
    Map<String, dynamic> convertedRules,
  ) async {
    try {
      final dir = await FileStorage.getSharedContainerDirectory();
      
      // Save standard rules
      if (convertedRules['standard']?.isNotEmpty ?? false) {
        final standardFile = File('${dir.path}/$filterName.json');
        await standardFile.writeAsString(
          json.encode(convertedRules['standard']),
        );
      }
      
      // Save advanced rules
      if (convertedRules['advanced']?.isNotEmpty ?? false) {
        final advancedFile = File('${dir.path}/${filterName}_advanced.json');
        await advancedFile.writeAsString(
          json.encode(convertedRules['advanced']),
        );
      }
      
      // Save scriptlet rules for the Scripts extension
      if (convertedRules['scriptlet']?.isNotEmpty ?? false) {
        final scriptletFile = File('${dir.path}/${filterName}_scriptlets.json');
        await scriptletFile.writeAsString(
          json.encode(convertedRules['scriptlet']),
        );
      }
      
      await _logManager.log('Saved converted rules for $filterName');
    } catch (e) {
      await _logManager.log('Error saving converted rules: $e');
      rethrow;
    }
  }
}
