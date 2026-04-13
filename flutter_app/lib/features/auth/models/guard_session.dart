class GuardSession {
  GuardSession({
    required this.token,
    required this.guardName,
    required this.role,
    required this.themeDefault,
  });

  final String token;
  final String guardName;
  final String role;
  final String themeDefault;

  factory GuardSession.fromJson(Map<String, dynamic> json) {
    return GuardSession(
      token: json['token'] as String? ?? '',
      guardName: json['guard_name'] as String? ?? '',
      role: json['role'] as String? ?? 'GUARDIA',
      themeDefault: json['theme_default'] as String? ?? 'midnight',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'guard_name': guardName,
      'role': role,
      'theme_default': themeDefault,
    };
  }
}
