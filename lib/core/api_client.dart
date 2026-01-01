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
    // Ensure path starts with /
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // Construct URI - handle baseUrl with or without trailing slash
    final baseUri = Uri.parse(baseUrl);
    final uri = baseUri.replace(
      path: baseUri.path.isEmpty || baseUri.path == '/'
          ? normalizedPath
          : '${baseUri.path}$normalizedPath',
      queryParameters: queryParameters,
    );

    final requestHeaders = {
      'Content-Type': 'application/json',
      ...defaultHeaders,
      ...?headers,
    };

    // Debug logging (can be removed in production)
    if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
      print(
          '[ApiClient] Request: ${method.toString().split('.').last.toUpperCase()} $uri');
      print('[ApiClient] Headers: ${requestHeaders.keys.join(', ')}');
      if (body != null) {
        print('[ApiClient] Body: ${jsonEncode(body)}');
      }
    }

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

      // Debug response
      if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
        print(
            '[ApiClient] Response: ${response.statusCode} ${response.reasonPhrase}');
      }

      return response;
    } catch (e) {
      // Enhanced error handling for connection issues
      if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
        print('[ApiClient] Error: $e');
        print('[ApiClient] Error type: ${e.runtimeType}');
      }

      if (e is http.ClientException) {
        final errorMsg = e.message;
        if (errorMsg.contains('Connection failed') ||
            errorMsg.contains('Operation not permitted') ||
            errorMsg.contains('SocketException')) {
          throw ApiException(
            'Cannot connect to server at $baseUrl\n'
            'Request was: ${method.toString().split('.').last.toUpperCase()} $uri\n'
            'Error: $errorMsg\n\n'
            'Troubleshooting:\n'
            '1. Verify server is running: curl http://127.0.0.1:3000/health\n'
            '2. Check macOS network permissions: System Settings > Privacy & Security > Network\n'
            '3. Ensure no firewall is blocking localhost connections\n'
            '4. Try restarting the Flutter app to refresh network permissions',
            0,
          );
        }
        throw ApiException('Network error: $errorMsg', 0);
      }
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
            'Request timeout: Server did not respond in time', 0);
      }
      rethrow;
    }
  }

  /// Handle response and throw appropriate exceptions
  T handleResponse<T>(
      http.Response response, T Function(Map<String, dynamic>) parser) {
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
