# FlowFn SDK

A Flutter SDK for interacting with the FlowFn workflow engine API.

## Features

- **API Client**: HTTP client with app and user authentication support
- **Workflow Service**: Trigger workflows and await results with polling
- **Auth Service**: User authentication (login, signup, OTP)
- **Models**: Type-safe models for workflows, runs, and users

## Installation

Add this package as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flowfn_sdk:
    path: ../flowfn_sdk  # For local development
```

Or if published:

```yaml
dependencies:
  flowfn_sdk: ^1.0.0
```

## Usage

### Basic Setup

```dart
import 'package:flowfn_sdk/flowfn_sdk.dart';

// Initialize API client
final apiClient = ApiClient(
  baseUrl: 'https://api.example.com', // Optional, defaults to localhost:3000
);

// Set app authentication
apiClient.setAppAuth('your-app-code', 'your-api-key');

// Initialize services
final workflowService = WorkflowService(apiClient);
final authService = AuthService(apiClient);
```

### Triggering a Workflow

```dart
// Trigger a workflow
final response = await workflowService.triggerWorkflow(
  workflowCode: 'my-workflow-code',
  method: HttpMethod.post,
  inputs: {'key': 'value'},
);

// Await the result (polls with 2-minute timeout)
final result = await workflowService.awaitWorkflowResult(
  runId: response.runId ?? response.runCode!,
);
```

### Authentication

```dart
// Request OTP
final status = await authService.requestOtp('user@example.com');

// Login with OTP
final authResponse = await authService.login('user@example.com', '123456');

// Sign up
final signupStatus = await authService.signup(
  name: 'John Doe',
  email: 'user@example.com',
  agreementsAccepted: true,
  ageConfirmed: true,
);
```

## API Reference

### ApiClient

- `setAppAuth(String appCode, String apiKey)` - Set app authentication headers
- `setUserAuth(String token)` - Set user authentication token
- `request(HttpMethod method, String path, ...)` - Make HTTP request

### WorkflowService

- `triggerWorkflow(...)` - Trigger a workflow via API
- `awaitWorkflowResult(...)` - Poll for workflow completion (2-minute timeout)
- `getWorkflowRun(String runId)` - Get workflow run by ID or code

### AuthService

- `requestOtp(String email)` - Request OTP for login
- `login(String email, String otp)` - Login with OTP
- `signup(...)` - Sign up new user
- `getCurrentUser()` - Get current authenticated user
- `logout()` - Logout and clear session
- `refresh()` - Refresh authentication token

## Models

- `User` - User model
- `WorkflowRun` - Workflow run model with status enums
- `AuthResponse` - Authentication response
- `WorkflowTriggerResponse` - Workflow trigger response

## Configuration

The SDK uses `AppConfig` for default settings:

- `baseUrl`: API base URL (default: `http://localhost:3000`)
- `pollIntervalSeconds`: Polling interval (default: 2 seconds)
- `maxPollTimeoutSeconds`: Maximum polling timeout (default: 120 seconds / 2 minutes)
- `requestTimeout`: HTTP request timeout (default: 30 seconds)

You can override the base URL when creating `ApiClient`:

```dart
final apiClient = ApiClient(baseUrl: 'https://api.example.com');
```

## License

This package is private and not published to pub.dev.

