import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/package_detail.dart';

class PackageDetailService {
  PackageDetailService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<PackageDetail>> fetchDetail(int packageId) async {
    final result = await _apiClient.get(
      ApiEndpoints.packageDetail,
      queryParameters: <String, dynamic>{'package_id': packageId},
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(PackageDetail.fromJson(payload));
  }
}
