import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

enum HttpMethod { get, post, put, patch, delete }

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  
  ApiClient({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        defaultHeaders = defaultHeaders ?? {};

  /// Set app authentication headers
  void setAppAuth(String appCode, String apiKey) {
    defaultHeaders['x-app-code'] = appCode;
    defaultHeaders['x-api-key'] = apiKey;
  }

  /// Clear app authentication headers
  void clearAppAuth() {
    defaultHeaders.remove('x-app-code');
    defaultHeaders.remove('x-api-key');
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

