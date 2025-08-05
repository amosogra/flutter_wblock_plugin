import 'package:flutter/foundation.dart';

class UserScript {
  final String id;
  final String name;
  final String description;
  final String content;
  final bool isEnabled;
  final bool isDownloaded;
  final String version;
  final List<String> matches;
  final Uri? url;
  final bool isLocal;

  const UserScript({
    required this.id,
    required this.name,
    this.description = '',
    this.content = '',
    this.isEnabled = false,
    this.isDownloaded = false,
    this.version = '',
    this.matches = const [],
    this.url,
    this.isLocal = false,
  });

  UserScript copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    bool? isEnabled,
    bool? isDownloaded,
    String? version,
    List<String>? matches,
    Uri? url,
    bool? isLocal,
  }) {
    return UserScript(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      isEnabled: isEnabled ?? this.isEnabled,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      version: version ?? this.version,
      matches: matches ?? this.matches,
      url: url ?? this.url,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  factory UserScript.fromMap(Map<String, dynamic> map) {
    return UserScript(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      content: map['content'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      isDownloaded: map['isDownloaded'] ?? false,
      version: map['version'] ?? '',
      matches: List<String>.from(map['matches'] ?? []),
      url: map['url'] != null ? Uri.tryParse(map['url']) : null,
      isLocal: map['isLocal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content': content,
      'isEnabled': isEnabled,
      'isDownloaded': isDownloaded,
      'version': version,
      'matches': matches,
      'url': url?.toString(),
      'isLocal': isLocal,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserScript &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.content == content &&
        other.isEnabled == isEnabled &&
        other.isDownloaded == isDownloaded &&
        other.version == version &&
        listEquals(other.matches, matches) &&
        other.url == url &&
        other.isLocal == isLocal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        content.hashCode ^
        isEnabled.hashCode ^
        isDownloaded.hashCode ^
        version.hashCode ^
        matches.hashCode ^
        url.hashCode ^
        isLocal.hashCode;
  }
}
