import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

enum HttpMethod { get, post, put, patch, delete }

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final String appCode;
  final String apiKey;
  
  /// Create an ApiClient with required app credentials and environment
  /// 
  /// [appCode] - Your application code (required)
  /// [apiKey] - Your API key (required)
  /// [environment] - Environment (sandbox or production) to determine base URL
  /// [baseUrl] - Optional override for base URL (if not provided, uses environment default)
  ApiClient({
    required String appCode,
    required String apiKey,
    required Environment environment,
    String? baseUrl,
    Map<String, String>? defaultHeaders,
  })  : appCode = appCode,
        apiKey = apiKey,
        baseUrl = baseUrl ?? AppConfig.getBaseUrl(environment),
        defaultHeaders = {
          'x-app-code': appCode,
          'x-api-key': apiKey,
          ...?defaultHeaders,
        };

  /// Set app authentication headers (deprecated - credentials are set in constructor)
  @Deprecated('App credentials are now required in constructor')
  void setAppAuth(String appCode, String apiKey) {
    defaultHeaders['x-app-code'] = appCode;
    defaultHeaders['x-api-key'] = apiKey;
  }

  /// Clear app authentication headers (deprecated - credentials cannot be cleared)
  @Deprecated('App credentials cannot be cleared')
  void clearAppAuth() {
    // Do nothing - credentials are required
    defaultHeaders['x-app-code'] = appCode;
    defaultHeaders['x-api-key'] = apiKey;
  }

  /// Set user authentication token
  void setUserAuth(String token) {
    defaultHeaders['Authorization'] = 'Bearer $token';
  }

  /// Clear user authentication token
  void clearUserAuth() {
    defaultHeaders.remove('Authorization');
  }

  /// Make an HTTP request
  Future<http.Response> request(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: path,
      queryParameters: queryParameters,
    );

    final requestHeaders = {
      'Content-Type': 'application/json',
      ...defaultHeaders,
      ...?headers,
    };

    http.Response response;

    try {
      switch (method) {
        case HttpMethod.get:
          response = await http
              .get(uri, headers: requestHeaders)
              .timeout(AppConfig.requestTimeout);
          break;
        case HttpMethod.post:
          response = await http
              .post(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.requestTimeout);
          break;
        case HttpMethod.put:
          response = await http
              .put(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.requestTimeout);
          break;
        case HttpMethod.patch:
          response = await http
              .patch(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(AppConfig.requestTimeout);
          break;
        case HttpMethod.delete:
          response = await http
              .delete(uri, headers: requestHeaders)
              .timeout(AppConfig.requestTimeout);
          break;
      }

      return response;
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('TimeoutException')) {
        throw ApiException('Network error: ${e.toString()}', 0);
      }
      rethrow;
    }
  }

  /// Handle response and throw appropriate exceptions
  T handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) parser) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return parser(json);
      } catch (e) {
        throw ApiException('Invalid JSON response', response.statusCode);
      }
    } else {
      String message = 'Request failed';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        message = json['message'] as String? ?? message;
      } catch (_) {
        message = response.body.isNotEmpty ? response.body : message;
      }
      throw ApiException(message, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

