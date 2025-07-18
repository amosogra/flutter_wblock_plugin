enum FilterCategory {
  all('All'),
  ads('Ads'),
  privacy('Privacy'),
  security('Security'),
  multipurpose('Multipurpose'),
  annoyances('Annoyances'),
  experimental('Experimental'),
  custom('Custom'),
  foreign('Foreign');

  final String displayName;
  const FilterCategory(this.displayName);

  static FilterCategory fromString(String value) {
    return FilterCategory.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => FilterCategory.all,
    );
  }
}
