/// Environment enum for SDK configuration
enum Environment {
  local,
  sandbox,
  production,
}

/// Configuration class for FlowFn SDK
class AppConfig {
  // Base URLs for different environments
  static const String localBaseUrl = 'http://localhost:3000';
  static const String sandboxBaseUrl = 'https://sandbox-api.flowfn.com';
  static const String productionBaseUrl = 'https://api.flowfn.com';
  
  // Get base URL based on environment
  static String getBaseUrl(Environment environment) {
    switch (environment) {
      case Environment.local:
        return localBaseUrl;
      case Environment.sandbox:
        return sandboxBaseUrl;
      case Environment.production:
        return productionBaseUrl;
    }
  }
  
  // Polling configuration
  static const int pollIntervalSeconds = 2;
  static const int maxPollTimeoutSeconds = 120; // 2 minutes
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
}

