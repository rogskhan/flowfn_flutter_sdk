import 'dart:async';
import '../core/api_client.dart';
import '../core/config.dart';
import '../models/workflow_run.dart';
import '../models/auth_response.dart';

class WorkflowService {
  final ApiClient apiClient;

  WorkflowService(this.apiClient);

  /// Trigger a workflow via API
  ///
  /// [workflowCode] - The workflow code to trigger
  /// [method] - HTTP method (GET, POST, PUT, PATCH)
  /// [inputs] - Input data for the workflow (will be sent as request body, excluding 'code')
  /// [executionType] - Expected execution type: 'sync' or 'async'.
  ///                   Note: The actual behavior is determined by the workflow's execution_type.
  ///                   This parameter is for documentation/clarity only (default: 'async')
  ///
  /// Returns:
  /// - For sync workflows: WorkflowRun with the completed result (status, outputs, result, context)
  /// - For async workflows: WorkflowTriggerResponse with run_id and run_code
  ///
  /// The response type is automatically detected based on the API response format.
  /// Use `is` or `runtimeType` to check the return type:
  /// ```dart
  /// final result = await triggerWorkflow(...);
  /// if (result is WorkflowRun) {
  ///   // Sync workflow - result is available immediately
  ///   print('Status: ${result.status}');
  /// } else if (result is WorkflowTriggerResponse) {
  ///   // Async workflow - use runId to poll for results
  ///   final run = await awaitWorkflowResult(runId: result.runId!);
  /// }
  /// ```
  Future<dynamic> triggerWorkflow({
    required String workflowCode,
    required HttpMethod method,
    Map<String, dynamic>? inputs,
    String executionType = 'async',
  }) async {
    // Prepare body - include code and other inputs
    final body = <String, dynamic>{
      'code': workflowCode,
      ...?inputs,
    };

    final response = await apiClient.request(
      method,
      '/app/workflow/api',
      body: method != HttpMethod.get ? body : null,
      queryParameters: method == HttpMethod.get ? {'code': workflowCode} : null,
    );

    // Handle response - automatically detect sync vs async format
    // Sync workflows return: { item: { _id, status, outputs, result, context } }
    // Async workflows return: { message, workflow_id, trigger_id, run_id, run_code }
    return apiClient.handleResponse<dynamic>(
      response,
      (json) {
        // Check if response has 'item' field (sync workflow response format)
        if (json.containsKey('item') && json['item'] is Map<String, dynamic>) {
          // Sync workflow: return WorkflowRun directly from the item
          final item = json['item'] as Map<String, dynamic>;
          return WorkflowRun.fromJson(item);
        } else {
          // Async workflow: return WorkflowTriggerResponse
          return WorkflowTriggerResponse.fromJson(json);
        }
      },
    );
  }

  /// Await workflow run completion by polling
  ///
  /// [runId] - The workflow run ID or code
  /// [maxTimeoutSeconds] - Maximum time to wait (default: 120 seconds / 2 minutes)
  ///
  /// Returns the completed WorkflowRun or throws an exception on timeout
  Future<WorkflowRun> awaitWorkflowResult({
    required String runId,
    int maxTimeoutSeconds = AppConfig.maxPollTimeoutSeconds,
  }) async {
    final startTime = DateTime.now();
    final maxDuration = Duration(seconds: maxTimeoutSeconds);
    final pollInterval = Duration(seconds: AppConfig.pollIntervalSeconds);

    // Initial wait before first poll
    await Future.delayed(pollInterval);

    while (true) {
      // Check timeout
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed >= maxDuration) {
        throw TimeoutException(
          'Workflow run did not complete within ${maxTimeoutSeconds} seconds',
          maxDuration,
        );
      }

      // Poll for run status
      try {
        final run = await getWorkflowRun(runId);

        // Check if complete
        if (run.isComplete) {
          return run;
        }

        // If still running or queued, wait and poll again
        if (run.isRunning || run.isQueued) {
          await Future.delayed(pollInterval);
          continue;
        }

        // Unknown status, return anyway
        return run;
      } catch (e) {
        // If run not found, might be a timing issue, wait and retry
        if (e.toString().contains('not found') ||
            e.toString().contains('404')) {
          await Future.delayed(pollInterval);
          continue;
        }
        // Other errors, rethrow
        rethrow;
      }
    }
  }

  /// Get workflow run by ID or code
  Future<WorkflowRun> getWorkflowRun(String runId) async {
    final response = await apiClient.request(
      HttpMethod.get,
      '/app/runs/$runId',
    );

    return apiClient.handleResponse<WorkflowRun>(
      response,
      (json) {
        final item = json['item'] as Map<String, dynamic>;
        return WorkflowRun.fromJson(item);
      },
    );
  }
}
