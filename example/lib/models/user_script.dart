class UserScript {
  final String id;
  final String name;
  final String content;
  final bool isEnabled;

  UserScript({
    required this.id,
    required this.name,
    required this.content,
    required this.isEnabled,
  });

  factory UserScript.fromMap(Map<String, dynamic> map) {
    return UserScript(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String,
      isEnabled: map['isEnabled'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'isEnabled': isEnabled,
    };
  }
}
