import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teekoob/core/config/app_config.dart';

class NetworkService {
  late Dio _dio;
  final Connectivity _connectivity = Connectivity();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  NetworkService();

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Auto-load auth token from secure storage
        try {
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('⚠️ NetworkService: Could not load auth token: $e');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        // Handle 401 (Unauthorized) - token expired or invalid
        if (error.response?.statusCode == 401) {
          // Clear token and notify listeners
          await _secureStorage.delete(key: _tokenKey);
          clearAuthToken();
        }
        handler.next(error);
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }

  // Check connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Stream connectivity changes
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;


  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error: $e',
      );
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error: $e',
      );
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error: $e',
      );
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error: $e',
      );
    }
  }

  // Upload file
  Future<Response> upload(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.post(
        path,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network error: $e',
      );
    }
  }

  // Download file
  Future<Response> download(
    String url,
    String savePath, {
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Check connectivity - but allow download if already cached/started
      if (!await isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          error: 'No internet connection',
        );
      }

      // Ensure URL is full URL
      final fullUrl = url.startsWith('http') 
          ? url 
          : '${AppConfig.mediaBaseUrl}$url';

      final response = await _dio.download(
        fullUrl,
        savePath,
        options: options ?? Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: 'Network error: $e',
      );
    }
  }

  // Handle Dio errors
  DioException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Connection timeout',
        );
      case DioExceptionType.sendTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Send timeout',
        );
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Receive timeout',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        dynamic respData = error.response?.data;
        String message;
        if (respData is Map) {
          message = (respData['message'] ?? respData['error'] ?? 'Bad response').toString();
        } else if (respData is String) {
          message = respData;
        } else {
          message = 'Bad response';
        }
        // Friendlier message for rate limiting
        if (statusCode == 429) {
          message = 'Too many requests. Please try again later.';
        }
        return DioException(
          requestOptions: error.requestOptions,
          error: 'HTTP $statusCode: $message',
        );
      case DioExceptionType.cancel:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Request cancelled',
        );
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Connection error',
        );
      default:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Network error: ${error.message}',
        );
    }
  }

  // Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Get Dio instance
  Dio get dio => _dio;
}
