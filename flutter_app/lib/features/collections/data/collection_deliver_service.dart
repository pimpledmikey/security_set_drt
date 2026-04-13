import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/collection_deliver_request.dart';

class CollectionDeliverService {
  CollectionDeliverService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<String>> deliver(CollectionDeliverRequest request) async {
    final result = await _apiClient.post(
      ApiEndpoints.collectionDeliver,
      data: request.toJson(),
    );
    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    final payload = result.data?['data'] as Map<String, dynamic>? ??
        result.data ??
        <String, dynamic>{};
    final message = payload['notification_message'] as String? ??
        result.data?['message'] as String? ??
        'Recoleccion entregada correctamente.';
    return ApiResult.success(message);
  }
}
