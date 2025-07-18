import 'package:uuid/uuid.dart';

enum FilterListCategory {
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
  const FilterListCategory(this.displayName);
  
  static FilterListCategory fromString(String value) {
    return FilterListCategory.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => FilterListCategory.all,
    );
  }
}

class FilterList {
  final String id;
  final String name;
  final String url;
  final FilterListCategory category;
  bool isSelected;
  final String description;
  String version;

  FilterList({
    String? id,
    required this.name,
    required this.url,
    required this.category,
    this.isSelected = false,
    this.description = '',
    this.version = '',
  }) : id = id ?? const Uuid().v4();

  FilterList copyWith({
    String? id,
    String? name,
    String? url,
    FilterListCategory? category,
    bool? isSelected,
    String? description,
    String? version,
  }) {
    return FilterList(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      description: description ?? this.description,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'category': category.displayName,
      'isSelected': isSelected,
      'description': description,
      'version': version,
    };
  }

  factory FilterList.fromJson(Map<String, dynamic> json) {
    return FilterList(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      category: FilterListCategory.fromString(json['category'] as String),
      isSelected: json['isSelected'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterList &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Default filter lists that come with wBlock
List<FilterList> getDefaultFilterLists() {
  return [
    // Ads
    FilterList(
      name: 'AdGuard Base Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/2.txt',
      category: FilterListCategory.ads,
      description: 'AdGuard Base filter removes ads from websites',
      isSelected: true,
    ),
    FilterList(
      name: 'AdGuard Mobile Ads Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/11.txt',
      category: FilterListCategory.ads,
      description: 'Filter for all known mobile ad networks',
    ),
    FilterList(
      name: 'EasyList',
      url: 'https://easylist.to/easylist/easylist.txt',
      category: FilterListCategory.ads,
      description: 'Primary subscription that removes adverts from web pages',
    ),
    
    // Privacy
    FilterList(
      name: 'AdGuard Tracking Protection Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/3.txt',
      category: FilterListCategory.privacy,
      description: 'Comprehensive list of various trackers',
      isSelected: true,
    ),
    FilterList(
      name: 'EasyPrivacy',
      url: 'https://easylist.to/easylist/easyprivacy.txt',
      category: FilterListCategory.privacy,
      description: 'Blocks tracking, telemetry, and analytics',
      isSelected: true,
    ),
    
    // Security
    FilterList(
      name: 'Online Malicious URL Blocklist',
      url: 'https://gitlab.com/malware-filter/urlhaus-filter/-/raw/master/urlhaus-filter-online.txt',
      category: FilterListCategory.security,
      description: 'Blocks malicious websites',
      isSelected: true,
    ),
    FilterList(
      name: 'Phishing URL Blocklist',
      url: 'https://gitlab.com/malware-filter/phishing-filter/-/raw/master/phishing-filter.txt',
      category: FilterListCategory.security,
      description: 'Blocks phishing websites',
    ),
    
    // Multipurpose
    FilterList(
      name: 'd3Host List by d3ward',
      url: 'https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.txt',
      category: FilterListCategory.multipurpose,
      description: 'Simple and small list with the most popular advertising services',
      isSelected: true,
    ),
    FilterList(
      name: 'Peter Lowe\'s List',
      url: 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1',
      category: FilterListCategory.multipurpose,
      description: 'Blocks ads, trackers, and malware',
    ),
    
    // Annoyances
    FilterList(
      name: 'AdGuard Annoyances Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/14.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks popups, banners, and other annoyances',
      isSelected: true,
    ),
    FilterList(
      name: 'AdGuard Cookie Notices Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/18.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks cookie notices on web pages',
    ),
    FilterList(
      name: 'AdGuard Popups Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/19.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks all kinds of popups',
    ),
    FilterList(
      name: 'AdGuard Mobile App Banners Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/20.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks irritating banners that promote mobile apps',
    ),
    FilterList(
      name: 'AdGuard Other Annoyances Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/21.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks annoyances that are not covered by other filters',
    ),
    FilterList(
      name: 'AdGuard Widgets Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/22.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks widgets like live support chats',
    ),
    FilterList(
      name: 'EasyList Cookie List',
      url: 'https://secure.fanboy.co.nz/fanboy-cookiemonster.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks cookies banners and GDPR overlay windows',
    ),
    FilterList(
      name: 'Fanboy\'s Annoyance List',
      url: 'https://secure.fanboy.co.nz/fanboy-annoyance.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks social media, in-page pop-ups and other annoyances',
    ),
    FilterList(
      name: 'I don\'t care about cookies',
      url: 'https://www.i-dont-care-about-cookies.eu/abp/',
      category: FilterListCategory.annoyances,
      description: 'Removes cookie warnings from websites',
    ),
    FilterList(
      name: 'Fanboy\'s Social Blocking List',
      url: 'https://easylist.to/easylist/fanboy-social.txt',
      category: FilterListCategory.annoyances,
      description: 'Blocks social media widgets',
    ),
    
    // Experimental
    FilterList(
      name: 'Experimental filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/5.txt',
      category: FilterListCategory.experimental,
      description: 'Filter designed to test new filtering rules',
    ),
    FilterList(
      name: 'AdGuard DNS Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/15.txt',
      category: FilterListCategory.experimental,
      description: 'Filter composed of other filters for DNS-level blocking',
    ),
    FilterList(
      name: 'Anti-Adblock List',
      url: 'https://easylist-downloads.adblockplus.org/antiadblockfilters.txt',
      category: FilterListCategory.experimental,
      description: 'Counters anti-adblock scripts',
      isSelected: true,
    ),
    
    // Foreign
    FilterList(
      name: 'AdGuard Chinese Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/224.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Chinese websites',
    ),
    FilterList(
      name: 'AdGuard French Filter', 
      url: 'https://filters.adtidy.org/extension/safari/filters/16.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for French websites',
    ),
    FilterList(
      name: 'AdGuard German Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/6.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for German websites',
    ),
    FilterList(
      name: 'AdGuard Japanese Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/7.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Japanese websites',
    ),
    FilterList(
      name: 'AdGuard Russian Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/1.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Russian websites',
    ),
    FilterList(
      name: 'AdGuard Spanish/Portuguese Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/9.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Spanish and Portuguese websites',
    ),
    FilterList(
      name: 'AdGuard Turkish Filter',
      url: 'https://filters.adtidy.org/extension/safari/filters/13.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Turkish websites',
    ),
    FilterList(
      name: 'EasyList Dutch',
      url: 'https://easylist-downloads.adblockplus.org/easylistdutch.txt',
      category: FilterListCategory.foreign,
      description: 'Filter for Dutch websites',
    ),
  ];
}
