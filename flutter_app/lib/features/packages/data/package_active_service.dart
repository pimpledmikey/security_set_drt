import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/package_dashboard_data.dart';

class PackageActiveService {
  PackageActiveService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<PackageDashboardData>> fetchDashboard() async {
    final result = await _apiClient.get(ApiEndpoints.activePackages);
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(PackageDashboardData.fromJson(payload));
  }
}
