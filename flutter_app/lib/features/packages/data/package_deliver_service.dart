import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/package_deliver_request.dart';

class PackageDeliverService {
  PackageDeliverService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<String>> deliver(PackageDeliverRequest request) async {
    final result = await _apiClient.post(
      ApiEndpoints.packageDeliver,
      data: request.toJson(),
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    final message = result.data?['message'] as String? ??
        payload['message'] as String? ??
        'Paquete entregado correctamente.';
    return ApiResult.success(message);
  }
}
