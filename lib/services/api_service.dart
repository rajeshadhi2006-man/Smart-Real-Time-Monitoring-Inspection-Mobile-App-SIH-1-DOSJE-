import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import '../core/config/app_config.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final currentBaseUrl = ApiConfig.baseUrl;
        options.baseUrl = currentBaseUrl; // Ensure updated dynamic base URL

        // If path is an absolute URL that targets an old host, synchronize with current server
        if (options.path.startsWith('http://') || options.path.startsWith('https://')) {
          try {
            final uri = Uri.parse(options.path);
            final baseUri = Uri.parse(AppConfig.serverRootUrl);
            if (uri.host != baseUri.host || uri.scheme != baseUri.scheme) {
              final newUri = uri.replace(
                scheme: baseUri.scheme,
                host: baseUri.host,
                port: baseUri.hasPort ? baseUri.port : (baseUri.scheme == 'https' ? 443 : 80),
              );
              options.path = newUri.toString();
            }
          } catch (_) {}
        }

        // Prevent /api/api/... or duplicate prefixes across baseUrl and path
        if (options.path.contains('/api/api/')) {
          options.path = options.path.replaceAll('/api/api/', '/api/');
        }
        if (options.baseUrl.endsWith('/api') && options.path.startsWith('/api/')) {
          options.path = options.path.substring(4);
        }

        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Auto-failover on connection errors or timeouts (e.g. USB unplugged, switched to Wi-Fi/4G)
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          final workingUrl = await AppConfig.autoDiscoverWorkingEndpoint();
          if (workingUrl != null) {
            try {
              final newOpts = error.requestOptions;
              newOpts.baseUrl = workingUrl;
              if (newOpts.path.startsWith('http://') || newOpts.path.startsWith('https://')) {
                final oldUri = Uri.parse(newOpts.path);
                final targetRoot = workingUrl.endsWith('/api')
                    ? workingUrl.substring(0, workingUrl.length - 4)
                    : workingUrl;
                final workingUri = Uri.parse(targetRoot);
                newOpts.path = oldUri.replace(
                  scheme: workingUri.scheme,
                  host: workingUri.host,
                  port: workingUri.hasPort ? workingUri.port : (workingUri.scheme == 'https' ? 443 : 80),
                ).toString();
              }
              final retryResp = await _dio.fetch(newOpts);
              return handler.resolve(retryResp);
            } catch (_) {}
          }
        }

        String customMessage = "Unable to connect to the server. Please check your network connection.";
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          customMessage = "Connection timed out. Please verify your network and server status.";
        } else if (error.type == DioExceptionType.connectionError) {
          customMessage = "Network connection failed. Auto-discovery searching for reachable server gateway...";
        } else if (error.response != null) {
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;
          String? serverDetail;
          if (data is Map && data['detail'] != null) {
            if (data['detail'] is List) {
              serverDetail = (data['detail'] as List).map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString()).join(', ');
            } else {
              serverDetail = data['detail'].toString();
            }
          } else if (data is Map && data['message'] != null) {
            serverDetail = data['message'].toString();
          }

          switch (statusCode) {
            case 400:
              customMessage = serverDetail ?? "Invalid request submitted.";
              break;
            case 401:
              customMessage = serverDetail ?? "Your session has expired. Please login again.";
              _storage.delete(key: 'jwt_token');
              _storage.delete(key: 'user_profile');
              break;
            case 403:
              customMessage = serverDetail ?? "Access denied. Insufficient operational permissions.";
              break;
            case 404:
              customMessage = serverDetail ?? "Requested resource or endpoint not found.";
              break;
            case 422:
              customMessage = serverDetail ?? "Validation error. Please verify input data.";
              break;
            case 429:
              customMessage = serverDetail ?? "Too many requests. Please slow down.";
              break;
            case 500:
            case 502:
            case 503:
              customMessage = serverDetail ?? "Internal server error. Please retry shortly.";
              break;
            default:
              customMessage = serverDetail ?? customMessage;
          }
        }
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: customMessage,
          ),
        );
      },
    ));
  }

  Dio get client => _dio;

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.delete(path, queryParameters: queryParameters);
  }

  Future<Response> postMultipart(String path, FormData formData, {ProgressCallback? onSendProgress}) async {
    return await _dio.post(
      path,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
      onSendProgress: onSendProgress,
    );
  }
}
