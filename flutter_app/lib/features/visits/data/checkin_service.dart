import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../home/models/active_visit_item.dart';
import '../models/checkin_request.dart';

class CheckInService {
  CheckInService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<ActiveVisitItem>> checkIn(CheckInRequest request) async {
    final result = await _apiClient.post(
      ApiEndpoints.checkIn,
      data: request.toJson(),
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(ActiveVisitItem.fromJson(payload));
  }
}
