import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/visit_detail.dart';

class VisitDetailService {
  VisitDetailService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<VisitDetail>> fetchDetail(int visitId) async {
    final result = await _apiClient.get(
      ApiEndpoints.visitDetail,
      queryParameters: <String, dynamic>{'visit_id': visitId},
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(VisitDetail.fromJson(payload));
  }
}
