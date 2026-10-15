import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../local/app_database.dart';

class TaskRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  TaskRepository(this.db);

  Stream<List<Task>> watchTasks() => db.watchAllTasks();

  Future<List<Task>> getTasks() => db.getAllTasks();

  Future<String> addTask({
    required String title,
    String type = 'task',
    DateTime? dueDate,
    String notes = '',
    String reason = '',
    String contentHash = '',
    String? sourceAssetId,
    String? sourceImagePath,
    bool needsReview = false,
    double confidence = 1.0,
  }) async {
    final id = _uuid.v4();
    await db.insertTask(
      TasksCompanion.insert(
        id: id,
        title: title,
        type: Value(type),
        dueDate: Value(dueDate),
        notes: Value(notes),
        reason: Value(reason),
        contentHash: Value(contentHash),
        sourceAssetId: Value(sourceAssetId),
        sourceImagePath: Value(sourceImagePath),
        needsReview: Value(needsReview),
        confidence: Value(confidence),
        createdAt: DateTime.now(),
        isNew: const Value(true),
      ),
    );
    return id;
  }

  Future<void> markCompleted(String id, bool completed) {
    return db.markTaskCompleted(id, completed);
  }

  Future<void> reviewTask(String id, bool keepAsTask) {
    return db.markTaskReviewed(id, keepAsTask);
  }

  Future<void> deleteTask(String id) {
    return db.deleteTaskById(id);
  }

  Future<void> clearIsNewFlag(String id) {
    return db.clearIsNewFlag(id);
  }

  Future<void> updateTaskDetails({
    required String id,
    required String title,
    required String type,
    DateTime? dueDate,
    required String notes,
    String reason = '',
  }) async {
    final existing = await db.getTaskById(id);
    if (existing == null) return;

    await db.updateTask(
      TasksCompanion(
        id: Value(id),
        title: Value(title),
        type: Value(type),
        dueDate: Value(dueDate),
        notes: Value(notes),
        reason: Value(reason.isNotEmpty ? reason : existing.reason),
        isCompleted: Value(existing.isCompleted),
        completedAt: Value(existing.completedAt),
        sourceAssetId: Value(existing.sourceAssetId),
        sourceImagePath: Value(existing.sourceImagePath),
        needsReview: Value(existing.needsReview),
        confidence: Value(existing.confidence),
        createdAt: Value(existing.createdAt),
        isNew: const Value(false),
      ),
    );
  }

  Future<bool> hasDuplicateTask({
    required String sourceAssetId,
    required String title,
    required DateTime? dueDate,
    required String contentHash,
  }) {
    return db.hasDuplicateTask(
      sourceAssetId: sourceAssetId,
      title: title,
      dueDate: dueDate,
      contentHash: contentHash,
    );
  }

  Future<bool> isScreenshotProcessedOrNoAction(String assetId) {
    return db.isScreenshotProcessedOrNoAction(assetId);
  }

  Future<ProcessedScreenshot?> getProcessedScreenshot(String assetId) {
    return db.getProcessedScreenshot(assetId);
  }

  Future<void> logProcessedScreenshot({
    required String assetId,
    required String status,
    String contentHash = '',
    String ocrText = '',
    String rawAiResponse = '',
    String? errorMessage,
    int attemptCount = 1,
  }) {
    return db.logProcessedScreenshot(
      assetId: assetId,
      status: status,
      contentHash: contentHash,
      ocrText: ocrText,
      rawAiResponse: rawAiResponse,
      errorMessage: errorMessage,
      attemptCount: attemptCount,
    );
  }

  Future<List<ProcessedScreenshot>> getRecentDebugLogs({int limit = 50}) {
    return db.getRecentDebugLogs(limit: limit);
  }

  Future<void> clearAllTasks() => db.clearAllTasks();

  Future<void> clearProcessedScreenshots() => db.clearProcessedScreenshots();

  Future<void> clearAllData() => db.clearAllData();
}
