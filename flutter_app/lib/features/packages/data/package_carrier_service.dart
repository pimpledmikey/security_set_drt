import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/package_carrier_item.dart';

class PackageCarrierService {
  PackageCarrierService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<List<PackageCarrierItem>>> fetchActive() async {
    final result = await _apiClient.get(ApiEndpoints.packageCarriers);
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final raw = result.data?['data'] as List<dynamic>? ?? const [];
    final carriers = raw
        .whereType<Map<String, dynamic>>()
        .map(PackageCarrierItem.fromJson)
        .toList();
    return ApiResult.success(carriers);
  }
}
