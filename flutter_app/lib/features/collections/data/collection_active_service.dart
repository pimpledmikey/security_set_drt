import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/collection_dashboard_data.dart';

class CollectionActiveService {
  CollectionActiveService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<CollectionDashboardData>> fetchDashboard() async {
    final result = await _apiClient.get(ApiEndpoints.activeCollections);
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(CollectionDashboardData.fromJson(payload));
  }
}
