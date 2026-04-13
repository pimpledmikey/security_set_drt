import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/collection_detail.dart';

class CollectionDetailService {
  CollectionDetailService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<CollectionDetail>> fetchDetail(int collectionId) async {
    final result = await _apiClient.get(
      ApiEndpoints.collectionDetail,
      queryParameters: <String, dynamic>{'collection_id': collectionId},
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    return ApiResult.success(CollectionDetail.fromJson(payload));
  }
}
