import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

void main() {
  group('FilterList', () {
    test('should create FilterList with all properties', () {
      final filter = FilterList(
        name: 'Test Filter',
        url: 'https://example.com/filter.txt',
        category: FilterListCategory.ads,
        isSelected: true,
        description: 'Test description',
        version: '1.0.0',
      );

      expect(filter.name, 'Test Filter');
      expect(filter.url, 'https://example.com/filter.txt');
      expect(filter.category, FilterListCategory.ads);
      expect(filter.isSelected, true);
      expect(filter.description, 'Test description');
      expect(filter.version, '1.0.0');
      expect(filter.id, isNotEmpty);
    });

    test('should convert to and from JSON', () {
      final filter = FilterList(
        id: 'test-id',
        name: 'Test Filter',
        url: 'https://example.com/filter.txt',
        category: FilterListCategory.privacy,
        isSelected: false,
        description: 'Test description',
        version: '2.0.0',
      );

      final json = filter.toJson();
      final restored = FilterList.fromJson(json);

      expect(restored.id, filter.id);
      expect(restored.name, filter.name);
      expect(restored.url, filter.url);
      expect(restored.category, filter.category);
      expect(restored.isSelected, filter.isSelected);
      expect(restored.description, filter.description);
      expect(restored.version, filter.version);
    });

    test('should generate unique IDs for different instances', () {
      final filter1 = FilterList(
        name: 'Filter 1',
        url: 'https://example.com/1.txt',
        category: FilterListCategory.ads,
      );

      final filter2 = FilterList(
        name: 'Filter 2',
        url: 'https://example.com/2.txt',
        category: FilterListCategory.ads,
      );

      expect(filter1.id, isNot(equals(filter2.id)));
    });
  });

  group('FilterListCategory', () {
    test('should have all expected categories', () {
      expect(FilterListCategory.values.length, 9);
      expect(FilterListCategory.values, contains(FilterListCategory.all));
      expect(FilterListCategory.values, contains(FilterListCategory.ads));
      expect(FilterListCategory.values, contains(FilterListCategory.privacy));
      expect(FilterListCategory.values, contains(FilterListCategory.security));
      expect(FilterListCategory.values, contains(FilterListCategory.multipurpose));
      expect(FilterListCategory.values, contains(FilterListCategory.annoyances));
      expect(FilterListCategory.values, contains(FilterListCategory.experimental));
      expect(FilterListCategory.values, contains(FilterListCategory.custom));
      expect(FilterListCategory.values, contains(FilterListCategory.foreign));
    });

    test('should convert from string correctly', () {
      expect(FilterListCategory.fromString('Ads'), FilterListCategory.ads);
      expect(FilterListCategory.fromString('Privacy'), FilterListCategory.privacy);
      expect(FilterListCategory.fromString('Custom'), FilterListCategory.custom);
      expect(FilterListCategory.fromString('Invalid'), FilterListCategory.all);
    });
  });

  group('Default Filter Lists', () {
    test('should provide default filter lists', () {
      final defaults = getDefaultFilterLists();
      
      expect(defaults, isNotEmpty);
      expect(defaults.length, greaterThan(20));
      
      // Check for recommended filters
      final recommendedNames = [
        'AdGuard Base Filter',
        'AdGuard Tracking Protection Filter',
        'AdGuard Annoyances Filter',
        'EasyPrivacy',
        'Online Malicious URL Blocklist',
        'd3Host List by d3ward',
        'Anti-Adblock List',
      ];
      
      for (final name in recommendedNames) {
        expect(
          defaults.any((f) => f.name == name),
          true,
          reason: 'Should include $name',
        );
      }
    });

    test('should have recommended filters selected by default', () {
      final defaults = getDefaultFilterLists();
      
      final selectedByDefault = defaults.where((f) => f.isSelected).toList();
      expect(selectedByDefault.length, 7);
      
      final selectedNames = selectedByDefault.map((f) => f.name).toSet();
      expect(selectedNames, contains('AdGuard Base Filter'));
      expect(selectedNames, contains('AdGuard Tracking Protection Filter'));
      expect(selectedNames, contains('EasyPrivacy'));
    });

    test('should categorize filters correctly', () {
      final defaults = getDefaultFilterLists();
      
      final adFilters = defaults.where((f) => f.category == FilterListCategory.ads);
      final privacyFilters = defaults.where((f) => f.category == FilterListCategory.privacy);
      final securityFilters = defaults.where((f) => f.category == FilterListCategory.security);
      
      expect(adFilters, isNotEmpty);
      expect(privacyFilters, isNotEmpty);
      expect(securityFilters, isNotEmpty);
    });
  });

  group('FilterStats', () {
    test('should create FilterStats with counts', () {
      final stats = FilterStats(
        enabledListsCount: 5,
        totalRulesCount: 150000,
      );

      expect(stats.enabledListsCount, 5);
      expect(stats.totalRulesCount, 150000);
    });

    test('should convert to and from JSON', () {
      final stats = FilterStats(
        enabledListsCount: 10,
        totalRulesCount: 200000,
      );

      final json = stats.toJson();
      final restored = FilterStats.fromJson(json);

      expect(restored.enabledListsCount, stats.enabledListsCount);
      expect(restored.totalRulesCount, stats.totalRulesCount);
    });
  });
}
