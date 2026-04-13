import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/bootstrap_payload.dart';

class BootstrapService {
  BootstrapService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<BootstrapPayload>> load() async {
    final result = await _apiClient.get(ApiEndpoints.bootstrap);
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(BootstrapPayload.fromJson(payload));
  }
}
