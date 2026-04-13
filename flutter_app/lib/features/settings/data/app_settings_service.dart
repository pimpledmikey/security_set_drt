import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';

class AppSettingsService {
  AppSettingsService(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResult<void>> updateNotificationSettings({
    required bool packageEmailEnabled,
    required bool packageWhatsappEnabled,
    required bool collectionEmailEnabled,
    required bool collectionWhatsappEnabled,
    required bool visitEmailEnabled,
    required bool visitWhatsappEnabled,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.updateAppSettings,
      data: <String, dynamic>{
        'package_email_enabled': packageEmailEnabled,
        'package_whatsapp_enabled': packageWhatsappEnabled,
        'collection_email_enabled': collectionEmailEnabled,
        'collection_whatsapp_enabled': collectionWhatsappEnabled,
        'visit_email_enabled': visitEmailEnabled,
        'visit_whatsapp_enabled': visitWhatsappEnabled,
      },
    );

    if (!result.isSuccess) {
      return ApiResult.failure(result.errorMessage);
    }

    return ApiResult.success(null);
  }
}
