import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:partener_app/constants.dart';
import 'package:partener_app/controllets/auth_controller.dart';

/// Interceptor to automatically trigger logout on 401 Unauthorized responses.
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      log('⚠️ 401 Unauthorized from: ${err.requestOptions.uri}',
          name: 'AuthInterceptor');
      AuthController.handleUnauthorized();
    }
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401 ||
        (response.data is Map &&
            (response.data['status'] == 401 ||
                response.data['statusCode'] == 401))) {
      log('⚠️ 401 Unauthorized in response body from: ${response.requestOptions.uri}',
          name: 'AuthInterceptor');
      AuthController.handleUnauthorized();
    }
    super.onResponse(response, handler);
  }
}

/// Creates a standard Dio client with headers, timeouts, SSL configuration,
/// and AuthInterceptor for 401 auto-logout.
Dio createDioClient({String? baseUrl}) {
  final dio = Dio();
  final uri = baseUrl ?? ApiRoutes.baseUri;

  dio.options.headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  dio.options.connectTimeout = const Duration(seconds: 15);
  dio.options.receiveTimeout = const Duration(seconds: 15);

  if (dio.httpClientAdapter is IOHttpClientAdapter) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      if (uri.contains("dev-api") || uri.contains("192.168")) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        client.findProxy = (uri) => "DIRECT";
      }
      return client;
    };
  }

  dio.interceptors.add(AuthInterceptor());

  return dio;
}
