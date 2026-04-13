import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/host_item.dart';

class HostService {
  HostService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<List<HostItem>>> search(String query) async {
    final result = await _apiClient.get(
      ApiEndpoints.hostsSearch,
      queryParameters: <String, dynamic>{'q': query},
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final raw = result.data?['data'] as List<dynamic>? ?? const [];
    final hosts =
        raw.whereType<Map<String, dynamic>>().map(HostItem.fromJson).toList();
    return ApiResult.success(hosts);
  }
}
