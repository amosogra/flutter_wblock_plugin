class FilterList {
  final String id;
  final String name;
  final String description;
  final String category;
  final String url;
  final String version;
  final bool isSelected;
  final int? sourceRuleCount;

  FilterList({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.url,
    required this.version,
    required this.isSelected,
    this.sourceRuleCount,
  });

  factory FilterList.fromMap(Map<String, dynamic> map) {
    return FilterList(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? FilterListCategory.other,
      url: map['url'] as String? ?? '',
      version: map['version'] as String? ?? '',
      isSelected: map['isSelected'] as bool? ?? false,
      sourceRuleCount: map['sourceRuleCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'url': url,
      'version': version,
      'isSelected': isSelected,
      'sourceRuleCount': sourceRuleCount,
    };
  }

  FilterList copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? url,
    String? version,
    bool? isSelected,
    int? sourceRuleCount,
  }) {
    return FilterList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      url: url ?? this.url,
      version: version ?? this.version,
      isSelected: isSelected ?? this.isSelected,
      sourceRuleCount: sourceRuleCount ?? this.sourceRuleCount,
    );
  }
}

// Enum for filter categories to match the Swift implementation
class FilterListCategory {
  static const String all = "All";
  static const String ads = "Ads";
  static const String trackers = "Trackers";
  static const String privacy = "Privacy";
  static const String security = "Security";
  static const String multipurpose = "Multipurpose";
  static const String annoyances = "Annoyances";
  static const String social = "Social";
  static const String regional = "Regional";
  static const String experimental = "Experimental";
  static const String foreign = "Foreign";
  static const String other = "Other";
  static const String custom = "Custom";

  static List<String> get allCases => [
    all,
    ads,
    trackers,
    privacy,
    security,
    multipurpose,
    annoyances,
    social,
    regional,
    experimental,
    foreign,
    other,
    custom,
  ];

  static List<String> get displayableCategories => 
    allCases.where((c) => c != all && c != custom).toList();
}
