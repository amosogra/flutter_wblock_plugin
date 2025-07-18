class FilterStats {
  final int enabledListsCount;
  final int totalRulesCount;

  FilterStats({
    required this.enabledListsCount,
    required this.totalRulesCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabledListsCount': enabledListsCount,
      'totalRulesCount': totalRulesCount,
    };
  }

  factory FilterStats.fromJson(Map<String, dynamic> json) {
    return FilterStats(
      enabledListsCount: json['enabledListsCount'] as int? ?? 0,
      totalRulesCount: json['totalRulesCount'] as int? ?? 0,
    );
  }
}
