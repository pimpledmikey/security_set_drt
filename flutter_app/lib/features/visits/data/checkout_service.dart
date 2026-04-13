import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';

class CheckOutService {
  CheckOutService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<void>> checkOut(int visitId) async {
    final result = await _apiClient.post(
      ApiEndpoints.checkOut,
      data: <String, dynamic>{'visit_id': visitId},
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }
    return const ApiResult.success(null);
  }
}
