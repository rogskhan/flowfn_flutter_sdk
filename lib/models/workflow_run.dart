enum WorkflowRunStatus {
  queued,
  running,
  succeeded,
  failed,
  timedOut,
  retried,
}

enum WorkflowRunTaskStatus {
  pending,
  running,
  succeeded,
  failed,
}

enum WorkflowRunLogLevel {
  debug,
  info,
  warn,
  error,
}

class WorkflowRunLog {
  final WorkflowRunLogLevel level;
  final String message;
  final dynamic details;
  final String timestamp;

  WorkflowRunLog({
    required this.level,
    required this.message,
    this.details,
    required this.timestamp,
  });

  factory WorkflowRunLog.fromJson(Map<String, dynamic> json) {
    return WorkflowRunLog(
      level: _parseLogLevel(json['level'] as String),
      message: json['message'] as String,
      details: json['details'],
      timestamp: json['timestamp'] as String,
    );
  }

  static WorkflowRunLogLevel _parseLogLevel(String level) {
    switch (level) {
      case 'debug':
        return WorkflowRunLogLevel.debug;
      case 'info':
        return WorkflowRunLogLevel.info;
      case 'warn':
        return WorkflowRunLogLevel.warn;
      case 'error':
        return WorkflowRunLogLevel.error;
      default:
        return WorkflowRunLogLevel.info;
    }
  }
}

class WorkflowRunTrigger {
  final String? triggerId;
  final String type;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> metadata;
  final String? initiatedBy;

  WorkflowRunTrigger({
    this.triggerId,
    required this.type,
    required this.inputs,
    required this.metadata,
    this.initiatedBy,
  });

  factory WorkflowRunTrigger.fromJson(Map<String, dynamic> json) {
    return WorkflowRunTrigger(
      triggerId: json['trigger_id'] as String?,
      type: json['type'] as String,
      inputs: (json['inputs'] as Map<String, dynamic>?) ?? {},
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      initiatedBy: json['initiated_by'] as String?,
    );
  }
}

class WorkflowRunTask {
  final String id;
  final String taskId;
  final String title;
  final String referenceCode;
  final String type;
  final WorkflowRunTaskStatus status;
  final int attempt;
  final String? startedAt;
  final String? finishedAt;
  final int durationMs;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> inputs;
  final dynamic outputs;
  final dynamic error;
  final List<WorkflowRunLog> logs;
  final List<Map<String, String>> artifacts;

  WorkflowRunTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.referenceCode,
    required this.type,
    required this.status,
    required this.attempt,
    this.startedAt,
    this.finishedAt,
    required this.durationMs,
    required this.settings,
    required this.inputs,
    this.outputs,
    this.error,
    required this.logs,
    required this.artifacts,
  });

  factory WorkflowRunTask.fromJson(Map<String, dynamic> json) {
    return WorkflowRunTask(
      id: json['_id'] as String,
      taskId: json['task_id'] as String,
      title: json['title'] as String? ?? '',
      referenceCode: json['reference_code'] as String? ?? '',
      type: json['type'] as String,
      status: _parseTaskStatus(json['status'] as String),
      attempt: json['attempt'] as int? ?? 0,
      startedAt: json['started_at'] as String?,
      finishedAt: json['finished_at'] as String?,
      durationMs: json['duration_ms'] as int? ?? -1,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      inputs: (json['inputs'] as Map<String, dynamic>?) ?? {},
      outputs: json['outputs'],
      error: json['error'],
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => WorkflowRunLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      artifacts: (json['artifacts'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
    );
  }

  static WorkflowRunTaskStatus _parseTaskStatus(String status) {
    switch (status) {
      case 'pending':
        return WorkflowRunTaskStatus.pending;
      case 'running':
        return WorkflowRunTaskStatus.running;
      case 'succeeded':
        return WorkflowRunTaskStatus.succeeded;
      case 'failed':
        return WorkflowRunTaskStatus.failed;
      default:
        return WorkflowRunTaskStatus.pending;
    }
  }
}

class WorkflowRun {
  final String id;
  final WorkflowRunStatus status;
  final List<WorkflowRunTask> tasks;
  final dynamic result;
  final dynamic error;
  final Map<String, dynamic> context;
  final dynamic outputs; // Outputs from last task (for simplified response)

  WorkflowRun({
    required this.id,
    required this.status,
    this.tasks = const [],
    this.result,
    this.error,
    this.context = const {},
    this.outputs,
  });

  factory WorkflowRun.fromJson(Map<String, dynamic> json) {
    return WorkflowRun(
      id: json['_id'] as String,
      status: _parseStatus(json['status'] as String),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => WorkflowRunTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: json['result'],
      error: json['error'],
      context: (json['context'] as Map<String, dynamic>?) ?? {},
      outputs:
          json['outputs'], // Outputs from last task (for simplified response)
    );
  }

  static WorkflowRunStatus _parseStatus(String status) {
    switch (status) {
      case 'queued':
        return WorkflowRunStatus.queued;
      case 'running':
        return WorkflowRunStatus.running;
      case 'succeeded':
        return WorkflowRunStatus.succeeded;
      case 'failed':
        return WorkflowRunStatus.failed;
      case 'timed_out':
        return WorkflowRunStatus.timedOut;
      case 'retried':
        return WorkflowRunStatus.retried;
      default:
        return WorkflowRunStatus.queued;
    }
  }

  bool get isComplete =>
      status == WorkflowRunStatus.succeeded ||
      status == WorkflowRunStatus.failed;
  bool get isRunning => status == WorkflowRunStatus.running;
  bool get isQueued => status == WorkflowRunStatus.queued;
}
