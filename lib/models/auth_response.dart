import 'user.dart';

enum AuthStatus {
  otpSent,
  userNotFound,
  invalidOtp,
  userInactive,
  success,
  emailInUse,
  ok,
}

class AuthResponse {
  final AuthStatus status;
  final String? token;
  final User? user;

  AuthResponse({
    required this.status,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    AuthStatus status;
    final statusStr = json['status'] as String?;
    
    if (statusStr != null) {
      switch (statusStr) {
        case 'otp_sent':
          status = AuthStatus.otpSent;
          break;
        case 'user_not_found':
          status = AuthStatus.userNotFound;
          break;
        case 'invalid_otp':
          status = AuthStatus.invalidOtp;
          break;
        case 'user_inactive':
          status = AuthStatus.userInactive;
          break;
        case 'email_in_use':
          status = AuthStatus.emailInUse;
          break;
        case 'ok':
          status = AuthStatus.ok;
          break;
        default:
          status = AuthStatus.success;
      }
    } else {
      // If no status field, assume success (login response with token)
      status = AuthStatus.success;
    }

    return AuthResponse(
      status: status,
      token: json['token'] as String?,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }
}

class WorkflowTriggerResponse {
  final String message;
  final String workflowId;
  final String triggerId;
  final String? runId;
  final String? runCode;

  WorkflowTriggerResponse({
    required this.message,
    required this.workflowId,
    required this.triggerId,
    this.runId,
    this.runCode,
  });

  factory WorkflowTriggerResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowTriggerResponse(
      message: json['message'] as String? ?? 'Workflow trigger accepted',
      workflowId: json['workflow_id'] as String,
      triggerId: json['trigger_id'] as String,
      runId: json['run_id'] as String?,
      runCode: json['run_code'] as String?,
    );
  }
}

