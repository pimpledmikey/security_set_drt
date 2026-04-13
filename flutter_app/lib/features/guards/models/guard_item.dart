class GuardItem {
  GuardItem({
    required this.id,
    required this.fullName,
    required this.username,
  });

  final int id;
  final String fullName;
  final String username;

  factory GuardItem.fromJson(Map<String, dynamic> json) {
    return GuardItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
}
