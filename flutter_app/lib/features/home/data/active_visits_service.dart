import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/active_visit_item.dart';

class ActiveVisitsService {
  ActiveVisitsService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<List<ActiveVisitItem>>> fetchActiveVisits() async {
    final result = await _apiClient.get(ApiEndpoints.activeVisits);
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final rawList = result.data?['data'] as List<dynamic>? ?? const [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(ActiveVisitItem.fromJson)
        .toList();
    return ApiResult.success(items);
  }
}
