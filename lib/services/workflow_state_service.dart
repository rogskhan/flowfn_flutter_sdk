import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../models/workflow_run.dart';
import 'workflow_service.dart';

/// Service for managing workflow run state persistence and polling
/// 
/// This service handles:
/// - Persisting workflow run IDs by workflow code
/// - Polling workflow status until completion
/// - Clearing persisted workflows when complete
class WorkflowStateService {
  final WorkflowService workflowService;
  final Map<String, StreamController<WorkflowRun>> _activePolling = {};
  static const String _storagePrefix = 'flowfn_workflow_run_';

  WorkflowStateService(this.workflowService);

  /// Save a running workflow run ID for a workflow code
  /// 
  /// [workflowCode] - The workflow code
  /// [runId] - The workflow run ID or code to persist
  Future<void> saveRunningWorkflow(String workflowCode, String runId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getStorageKey(workflowCode), runId);
  }

  /// Clear a persisted workflow run ID
  /// 
  /// [workflowCode] - The workflow code to clear
  Future<void> clearWorkflow(String workflowCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getStorageKey(workflowCode));
    
    // Cancel any active polling for this workflow
    _activePolling[workflowCode]?.close();
    _activePolling.remove(workflowCode);
  }

  /// Get the persisted run ID for a workflow code
  /// 
  /// [workflowCode] - The workflow code
  /// Returns the run ID if found, null otherwise
  Future<String?> getRunningWorkflowId(String workflowCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getStorageKey(workflowCode));
  }

  /// Get all persisted workflow run IDs
  /// 
  /// Returns a map of workflow codes to run IDs
  Future<Map<String, String>> getAllRunningWorkflows() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final result = <String, String>{};
    
    for (final key in keys) {
      if (key.startsWith(_storagePrefix)) {
        final workflowCode = key.substring(_storagePrefix.length);
        final runId = prefs.getString(key);
        if (runId != null) {
          result[workflowCode] = runId;
        }
      }
    }
    
    return result;
  }

  /// Check if a workflow code has a persisted run ID
  /// 
  /// [workflowCode] - The workflow code to check
  /// Returns true if a run ID is persisted for this workflow code
  Future<bool> isWorkflowRunning(String workflowCode) async {
    final runId = await getRunningWorkflowId(workflowCode);
    return runId != null;
  }

  /// Poll workflow status until completion
  /// 
  /// [workflowCode] - The workflow code
  /// [runId] - The workflow run ID to poll
  /// [onStatusUpdate] - Optional callback called on each status check with the current WorkflowRun
  /// [onComplete] - Optional callback called when workflow completes (success or failure)
  /// [maxTimeoutSeconds] - Maximum time to poll (default: 120 seconds)
  /// 
  /// Returns a Stream that emits WorkflowRun updates and completes when the workflow finishes
  /// The stream can be cancelled by calling cancel() on the returned StreamSubscription
  Stream<WorkflowRun> pollWorkflowStatus(
    String workflowCode,
    String runId, {
    void Function(WorkflowRun)? onStatusUpdate,
    void Function(WorkflowRun)? onComplete,
    int maxTimeoutSeconds = AppConfig.maxPollTimeoutSeconds,
  }) {
    // Cancel existing polling if any
    _activePolling[workflowCode]?.close();
    
    final controller = StreamController<WorkflowRun>();
    _activePolling[workflowCode] = controller;
    
    final startTime = DateTime.now();
    final maxDuration = Duration(seconds: maxTimeoutSeconds);
    final pollInterval = Duration(seconds: AppConfig.pollIntervalSeconds);
    
    Future<void> poll() async {
      // Initial wait before first poll
      await Future.delayed(pollInterval);

      while (true) {
        // Check if stream is closed (cancelled)
        if (controller.isClosed) {
          return;
        }

        // Check timeout
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed >= maxDuration) {
          if (!controller.isClosed) {
            controller.addError(TimeoutException(
              'Workflow run did not complete within ${maxTimeoutSeconds} seconds',
              maxDuration,
            ));
            controller.close();
          }
          await clearWorkflow(workflowCode);
          return;
        }

        // Poll for run status
        try {
          final run = await workflowService.getWorkflowRun(runId);

          // Emit status update
          if (!controller.isClosed) {
            controller.add(run);
            onStatusUpdate?.call(run);
          }

          // Check if complete
          if (run.isComplete) {
            if (!controller.isClosed) {
              onComplete?.call(run);
              controller.close();
            }
            await clearWorkflow(workflowCode);
            return;
          }

          // If still running or queued, wait and poll again
          if (run.isRunning || run.isQueued) {
            await Future.delayed(pollInterval);
            continue;
          }

          // Unknown status, treat as complete
          if (!controller.isClosed) {
            onComplete?.call(run);
            controller.close();
          }
          await clearWorkflow(workflowCode);
          return;
        } catch (e) {
          // If run not found, might be a timing issue, wait and retry
          if (e.toString().contains('not found') || e.toString().contains('404')) {
            await Future.delayed(pollInterval);
            continue;
          }
          
          // Other errors - emit and close stream
          if (!controller.isClosed) {
            controller.addError(e);
            controller.close();
          }
          await clearWorkflow(workflowCode);
          return;
        }
      }
    }

    // Start polling
    poll().then((_) {
      // Clean up when polling completes
      _activePolling.remove(workflowCode);
    }).catchError((error) {
      // Clean up on error
      _activePolling.remove(workflowCode);
    });

    return controller.stream;
  }

  /// Cancel polling for a specific workflow code
  /// 
  /// [workflowCode] - The workflow code to cancel polling for
  void cancelPolling(String workflowCode) {
    _activePolling[workflowCode]?.close();
    _activePolling.remove(workflowCode);
  }

  /// Cancel all active polling
  void cancelAllPolling() {
    for (final controller in _activePolling.values) {
      controller.close();
    }
    _activePolling.clear();
  }

  /// Get storage key for a workflow code
  String _getStorageKey(String workflowCode) {
    return '$_storagePrefix$workflowCode';
  }
}

