// Test file to verify progress tracking fixes
// Place this in the test folder and run with `flutter test`

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';

void main() {
  group('FilterListCategory Tests', () {
    test('fromRawValue should parse categories correctly', () {
      // Test with capitalized raw values (as they come from Swift)
      expect(ParseFilterListCategory.fromRawValue('Ads'), equals(FilterListCategory.ads));
      expect(ParseFilterListCategory.fromRawValue('Privacy'), equals(FilterListCategory.privacy));
      expect(ParseFilterListCategory.fromRawValue('Security'), equals(FilterListCategory.security));
      expect(ParseFilterListCategory.fromRawValue('Multipurpose'), equals(FilterListCategory.multipurpose));
      expect(ParseFilterListCategory.fromRawValue('Annoyances'), equals(FilterListCategory.annoyances));
      expect(ParseFilterListCategory.fromRawValue('Experimental'), equals(FilterListCategory.experimental));
      expect(ParseFilterListCategory.fromRawValue('Foreign'), equals(FilterListCategory.foreign));
      expect(ParseFilterListCategory.fromRawValue('Custom'), equals(FilterListCategory.custom));
      expect(ParseFilterListCategory.fromRawValue('Scripts'), equals(FilterListCategory.scripts));
      expect(ParseFilterListCategory.fromRawValue('All'), equals(FilterListCategory.all));
    });

    test('fromRawValue should handle lowercase values', () {
      // Test with lowercase values
      expect(ParseFilterListCategory.fromRawValue('ads'), equals(FilterListCategory.ads));
      expect(ParseFilterListCategory.fromRawValue('privacy'), equals(FilterListCategory.privacy));
      expect(ParseFilterListCategory.fromRawValue('security'), equals(FilterListCategory.security));
    });

    test('fromRawValue should return null for invalid values', () {
      expect(ParseFilterListCategory.fromRawValue('invalid'), isNull);
      expect(ParseFilterListCategory.fromRawValue(''), isNull);
      expect(ParseFilterListCategory.fromRawValue('unknown'), isNull);
    });

    test('rawValue should return correct string values', () {
      expect(FilterListCategory.ads.rawValue, equals('Ads'));
      expect(FilterListCategory.privacy.rawValue, equals('Privacy'));
      expect(FilterListCategory.security.rawValue, equals('Security'));
      expect(FilterListCategory.multipurpose.rawValue, equals('Multipurpose'));
      expect(FilterListCategory.annoyances.rawValue, equals('Annoyances'));
      expect(FilterListCategory.experimental.rawValue, equals('Experimental'));
      expect(FilterListCategory.foreign.rawValue, equals('Foreign'));
      expect(FilterListCategory.custom.rawValue, equals('Custom'));
      expect(FilterListCategory.scripts.rawValue, equals('Scripts'));
      expect(FilterListCategory.all.rawValue, equals('All'));
    });
  });

  group('Progress Data Parsing Tests', () {
    test('Category rules parsing should handle various formats', () {
      // Simulate data from native side
      final testData = {
        'ruleCountsByCategory': {
          'ads': 1500,
          'privacy': 2000,
          'security': 500,
          'Ads': 1500,  // Test capitalized
          'Privacy': 2000,  // Test capitalized
        }
      };

      final Map<FilterListCategory, int> parsed = {};
      
      final categoryRules = testData['ruleCountsByCategory'] as Map;
      for (final entry in categoryRules.entries) {
        final category = ParseFilterListCategory.fromRawValue(entry.key.toString());
        if (category != null) {
          parsed[category] = entry.value as int;
        }
      }

      // Should have parsed all unique categories
      expect(parsed.containsKey(FilterListCategory.ads), isTrue);
      expect(parsed.containsKey(FilterListCategory.privacy), isTrue);
      expect(parsed.containsKey(FilterListCategory.security), isTrue);
      expect(parsed[FilterListCategory.ads], equals(1500));
      expect(parsed[FilterListCategory.privacy], equals(2000));
      expect(parsed[FilterListCategory.security], equals(500));
    });
  });
}
