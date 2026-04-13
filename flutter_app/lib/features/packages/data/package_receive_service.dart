import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/package_receive_request.dart';
import '../models/package_receive_response.dart';

class PackageReceiveService {
  PackageReceiveService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<PackageReceiveResponse>> receive(
    PackageReceiveRequest request,
  ) async {
    final result = await _apiClient.post(
      ApiEndpoints.packageReceive,
      data: request.toJson(),
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(PackageReceiveResponse.fromJson(payload));
  }
}
