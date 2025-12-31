class AppConfig {
  // Base URL for the flowfn-engine API
  // This should be configured based on your environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  // Polling configuration
  static const int pollIntervalSeconds = 2;
  static const int maxPollTimeoutSeconds = 120; // 2 minutes
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
}

