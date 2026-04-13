import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/storage/session_store.dart';
import '../models/guard_session.dart';

class AuthService {
  AuthService(this._apiClient, this._sessionStore);

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  Future<ApiResult<GuardSession>> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.login,
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'device_id': deviceId,
      },
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    final session = GuardSession.fromJson(payload);
    if (session.token.isEmpty) {
      return const ApiResult.failure(
        'El servidor no devolvio un token valido.',
      );
    }
    await _sessionStore.saveSession(session);
    return ApiResult.success(session);
  }
}
