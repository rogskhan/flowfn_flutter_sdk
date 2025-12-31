/// FlowFn SDK for Flutter
/// 
/// A comprehensive SDK for interacting with the FlowFn workflow engine API.
/// 
/// Example usage:
/// ```dart
/// import 'package:flowfn_sdk/flowfn_sdk.dart';
/// 
/// final apiClient = ApiClient();
/// apiClient.setAppAuth('your-app-code', 'your-api-key');
/// 
/// final workflowService = WorkflowService(apiClient);
/// final authService = AuthService(apiClient);
/// ```
library flowfn_sdk;

export 'core/core.dart';
export 'models/models.dart';
export 'services/services.dart';

