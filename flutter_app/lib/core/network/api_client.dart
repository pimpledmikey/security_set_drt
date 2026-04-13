import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/session_store.dart';
import 'api_result.dart';

class ApiClient {
  ApiClient({required SessionStore sessionStore})
      : _sessionStore = sessionStore,
        _dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  final SessionStore _sessionStore;
  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: await _headers()),
      );
      return ApiResult.success(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiResult.failure(_messageFromDio(error));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(headers: await _headers()),
      );
      return ApiResult.success(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiResult.failure(_messageFromDio(error));
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _sessionStore.readToken();
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    final path = error.requestOptions.path;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      if (path.contains('blank_api_package_receive')) {
        return 'El servidor tardó demasiado en responder. El paquete pudo haberse guardado; revisa la lista.';
      }
      if (path.contains('blank_api_collection_receive')) {
        return 'El servidor tardó demasiado en responder. La recolección pudo haberse guardado; revisa la lista.';
      }
      if (path.contains('blank_api_package_deliver')) {
        return 'El servidor tardó demasiado en responder. La entrega del paquete pudo haberse guardado; revisa la lista.';
      }
      if (path.contains('blank_api_collection_deliver')) {
        return 'El servidor tardó demasiado en responder. La entrega de la recolección pudo haberse guardado; revisa la lista.';
      }
      return 'El servidor tardó demasiado en responder. Intenta de nuevo en un momento.';
    }
    if (error.type == DioExceptionType.connectionError) {
      if (path.contains('blank_api_package_receive') ||
          path.contains('blank_api_collection_receive') ||
          path.contains('blank_api_package_deliver') ||
          path.contains('blank_api_collection_deliver')) {
        return 'No se pudo confirmar la respuesta del servidor. Revisa la lista antes de repetir la operación.';
      }
      return 'No se pudo conectar con el servidor.';
    }
    if (statusCode == 404) {
      if (path.contains('blank_api_package_deliver')) {
        return 'No se encontro el endpoint blank_api_package_deliver en Scriptcase.';
      }
      if (path.contains('blank_api_package_receive')) {
        return 'No se encontro el endpoint blank_api_package_receive en Scriptcase.';
      }
      if (path.contains('blank_api_package_active')) {
        return 'No se encontro el endpoint blank_api_package_active en Scriptcase.';
      }
      if (path.contains('blank_api_collection_receive')) {
        return 'No se encontro el endpoint blank_api_collection_receive en Scriptcase.';
      }
      if (path.contains('blank_api_collection_active')) {
        return 'No se encontro el endpoint blank_api_collection_active en Scriptcase.';
      }
      if (path.contains('blank_api_collection_deliver')) {
        return 'No se encontro el endpoint blank_api_collection_deliver en Scriptcase.';
      }
      if (path.contains('blank_api_media_public')) {
        return 'No se encontro el endpoint blank_api_media_public en Scriptcase.';
      }
      return 'El endpoint solicitado no existe o no esta publicado en Scriptcase.';
    }
    if (statusCode == 500) {
      if (path.contains('blank_api_package_deliver')) {
        return 'El servidor no pudo cerrar la entrega del paquete. Revisa que la tabla ra_package_delivery este actualizada en Scriptcase.';
      }
      if (path.contains('blank_api_collection_deliver')) {
        return 'El servidor no pudo cerrar la entrega de la recolección. Revisa que la tabla ra_collection_delivery este actualizada en Scriptcase.';
      }
      if (path.contains('blank_api_package_receive')) {
        return 'El servidor guardó el paquete, pero falló en alguna validación posterior. Revisa los blanks y la configuración de notificaciones.';
      }
      if (path.contains('blank_api_collection_receive')) {
        return 'El servidor no pudo registrar la recolección. Revisa que las tablas de recolección estén actualizadas.';
      }
      return 'El servidor respondió con un error interno. Revisa los blanks de Scriptcase y el log del servidor.';
    }
    if (error.type == DioExceptionType.unknown) {
      if (path.contains('blank_api_package_receive') ||
          path.contains('blank_api_collection_receive') ||
          path.contains('blank_api_package_deliver') ||
          path.contains('blank_api_collection_deliver') ||
          path.contains('blank_api_visit_checkin')) {
        return 'La operación se completó pero no se recibió confirmación. Revisa la lista.';
      }
      return 'Error de comunicación con el servidor. Verifica tu conexión.';
    }
    return error.message ?? 'No se pudo conectar con el servidor.';
  }
}
