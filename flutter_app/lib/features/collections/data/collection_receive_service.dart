import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/active_collection_item.dart';
import '../models/collection_receive_request.dart';

class CollectionReceiveService {
  CollectionReceiveService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<ActiveCollectionItem>> receive(
    CollectionReceiveRequest request,
  ) async {
    final result = await _apiClient.post(
      ApiEndpoints.collectionReceive,
      data: request.toJson(),
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    final collectionJson =
        payload['collection'] as Map<String, dynamic>? ?? const {};
    return ApiResult.success(ActiveCollectionItem.fromJson(collectionJson));
  }
}
