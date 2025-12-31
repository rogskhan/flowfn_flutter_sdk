import '../core/api_client.dart';
import '../models/user.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  /// Request OTP for email (Step 1 of login)
  /// 
  /// Returns AuthStatus indicating if OTP was sent or user not found
  Future<AuthStatus> requestOtp(String email) async {
    final response = await apiClient.request(
      HttpMethod.post,
      '/auth/login',
      body: {'email': email},
    );

    final authResponse = apiClient.handleResponse<AuthResponse>(
      response,
      (json) => AuthResponse.fromJson(json),
    );

    return authResponse.status;
  }

  /// Login with email and OTP (Step 2 of login)
  /// 
  /// Returns AuthResponse with token and user if successful
  Future<AuthResponse> login(String email, String otp) async {
    final response = await apiClient.request(
      HttpMethod.post,
      '/auth/login',
      body: {
        'email': email,
        'otp': otp,
      },
    );

    final authResponse = apiClient.handleResponse<AuthResponse>(
      response,
      (json) => AuthResponse.fromJson(json),
    );

    // If login successful, set the token in API client
    if (authResponse.status == AuthStatus.success && authResponse.token != null) {
      apiClient.setUserAuth(authResponse.token!);
    }

    return authResponse;
  }

  /// Sign up with name, email, and agreements
  /// 
  /// [name] - User's name
  /// [email] - User's email
  /// [agreementsAccepted] - Whether user accepted agreements
  /// [ageConfirmed] - Whether user confirmed age (must be true)
  /// 
  /// Returns AuthStatus indicating success or email_in_use
  Future<AuthStatus> signup({
    required String name,
    required String email,
    bool agreementsAccepted = false,
    bool ageConfirmed = false,
  }) async {
    final response = await apiClient.request(
      HttpMethod.post,
      '/auth/signup',
      body: {
        'name': name,
        'email': email,
        'agreementsAccepted': agreementsAccepted,
        'ageConfirmed': ageConfirmed,
      },
    );

    final authResponse = apiClient.handleResponse<AuthResponse>(
      response,
      (json) => AuthResponse.fromJson(json),
    );

    return authResponse.status;
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final response = await apiClient.request(
        HttpMethod.get,
        '/auth/me',
      );

      return apiClient.handleResponse<User>(
        response,
        (json) {
          final userJson = json['user'] as Map<String, dynamic>;
          return User.fromJson(userJson);
        },
      );
    } catch (e) {
      // If unauthorized or user not found, return null
      return null;
    }
  }

  /// Logout - clear user authentication
  Future<void> logout() async {
    try {
      await apiClient.request(
        HttpMethod.post,
        '/auth/logout',
      );
    } catch (_) {
      // Ignore errors on logout
    } finally {
      apiClient.clearUserAuth();
    }
  }

  /// Refresh authentication token
  Future<String?> refresh() async {
    try {
      final response = await apiClient.request(
        HttpMethod.post,
        '/auth/refresh',
      );

      final json = apiClient.handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      final token = json['token'] as String?;
      if (token != null) {
        apiClient.setUserAuth(token);
      }

      return token;
    } catch (_) {
      return null;
    }
  }
}

