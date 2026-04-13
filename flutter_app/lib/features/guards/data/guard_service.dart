import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/guard_item.dart';

class GuardService {
  GuardService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<List<GuardItem>>> fetchActive({String query = ''}) async {
    final result = await _apiClient.get(
      ApiEndpoints.activeGuards,
      queryParameters: <String, dynamic>{'q': query},
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final raw = result.data?['data'] as List<dynamic>? ?? const [];
    final guards =
        raw.whereType<Map<String, dynamic>>().map(GuardItem.fromJson).toList();
    return ApiResult.success(guards);
  }
}
