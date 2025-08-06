enum FilterListCategory {
  all,
  ads,
  privacy,
  security,
  multipurpose,
  annoyances,
  experimental,
  foreign,
  custom,
  scripts; // Added for userscripts in update popups
}

extension ParseFilterListCategory on FilterListCategory {
  String get rawValue {
    switch (this) {
      case FilterListCategory.all:
        return 'All';
      case FilterListCategory.ads:
        return 'Ads';
      case FilterListCategory.privacy:
        return 'Privacy';
      case FilterListCategory.security:
        return 'Security';
      case FilterListCategory.multipurpose:
        return 'Multipurpose';
      case FilterListCategory.annoyances:
        return 'Annoyances';
      case FilterListCategory.experimental:
        return 'Experimental';
      case FilterListCategory.foreign:
        return 'Foreign';
      case FilterListCategory.custom:
        return 'Custom';
      case FilterListCategory.scripts:
        return 'Scripts';
    }
  }

  String get displayName => rawValue;

  static FilterListCategory? fromRawValue(String rawValue) {
    try {
      return FilterListCategory.values.firstWhere(
        (e) => e.name == rawValue,
        orElse: () => throw ArgumentError('Invalid category: $rawValue'),
      );
    } catch (e) {
      return null;
    }
  }
}

class FilterList {
  final String id;
  final String name;
  final String description;
  final Uri url;
  final FilterListCategory category;
  final bool isSelected;
  final String version;
  final int? sourceRuleCount;

  const FilterList({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.category,
    required this.isSelected,
    required this.version,
    this.sourceRuleCount,
  });

  FilterList copyWith({
    String? id,
    String? name,
    String? description,
    Uri? url,
    FilterListCategory? category,
    bool? isSelected,
    String? version,
    int? sourceRuleCount,
  }) {
    return FilterList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      version: version ?? this.version,
      sourceRuleCount: sourceRuleCount ?? this.sourceRuleCount,
    );
  }

  factory FilterList.fromMap(Map<String, dynamic> map) {
    return FilterList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      url: Uri.parse(map['url'] ?? ''),
      category: _categoryFromString(map['category'] ?? ''),
      isSelected: map['isSelected'] ?? false,
      version: map['version'] ?? '',
      sourceRuleCount: map['sourceRuleCount'],
    );
  }

  static FilterListCategory _categoryFromString(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'ads':
        return FilterListCategory.ads;
      case 'privacy':
        return FilterListCategory.privacy;
      case 'security':
        return FilterListCategory.security;
      case 'multipurpose':
        return FilterListCategory.multipurpose;
      case 'annoyances':
        return FilterListCategory.annoyances;
      case 'experimental':
        return FilterListCategory.experimental;
      case 'foreign':
        return FilterListCategory.foreign;
      case 'custom':
        return FilterListCategory.custom;
      case 'scripts':
        return FilterListCategory.scripts;
      default:
        return FilterListCategory.all;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url.toString(),
      'category': category.rawValue,
      'isSelected': isSelected,
      'version': version,
      'sourceRuleCount': sourceRuleCount,
    };
  }
}
