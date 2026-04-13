import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/guard_session.dart';

class SessionStore {
  static const _tokenKey = 'runway_token';
  static const _sessionKey = 'runway_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession(GuardSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<GuardSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return GuardSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }
}
