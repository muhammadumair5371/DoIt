import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text().withDefault(const Constant('task'))(); // task, reminder, deadline, event
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get contentHash => text().withDefault(const Constant(''))(); // OCR text hash for deduplication
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get sourceAssetId => text().nullable()();
  TextColumn get sourceImagePath => text().nullable()();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ProcessedScreenshots extends Table {
  TextColumn get assetId => text()(); // Primary Key & Unique
  TextColumn get contentHash => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('success'))(); // success, no_action, failed
  DateTimeColumn get processedAt => dateTime()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get ocrText => text().withDefault(const Constant(''))();
  TextColumn get rawAiResponse => text().withDefault(const Constant(''))();
  IntColumn get attemptCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {assetId};
}

@DriftDatabase(tables: [Tasks, ProcessedScreenshots])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.reason);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.contentHash);
            await m.addColumn(processedScreenshots, processedScreenshots.contentHash);
            await m.addColumn(processedScreenshots, processedScreenshots.errorMessage);
            await m.addColumn(processedScreenshots, processedScreenshots.rawAiResponse);
            await m.addColumn(processedScreenshots, processedScreenshots.attemptCount);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'doit_database');
  }

  // --- Task Queries ---
  Future<List<Task>> getAllTasks() => select(tasks).get();
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  }

  Future<Task?> getTaskById(String id) => (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> deleteTaskById(String id) => (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> markTaskCompleted(String id, bool completed) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
        isNew: const Value(false),
      ),
    );
  }

  Future<void> markTaskReviewed(String id, bool keepAsTask) {
    if (keepAsTask) {
      return (update(tasks)..where((t) => t.id.equals(id))).write(
        const TasksCompanion(needsReview: Value(false)),
      );
    } else {
      return deleteTaskById(id);
    }
  }

  Future<void> clearIsNewFlag(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(isNew: Value(false)),
    );
  }

  // Check if a task with same contentHash + normalized title + due date exists
  Future<bool> hasDuplicateTask({
    required String sourceAssetId,
    required String title,
    required DateTime? dueDate,
    required String contentHash,
  }) async {
    final normTitle = title.trim().toLowerCase();

    // Check by contentHash & title
    if (contentHash.isNotEmpty) {
      final existingByHash = await (select(tasks)
            ..where((t) => t.contentHash.equals(contentHash) & t.title.lower().equals(normTitle)))
          .get();
      if (existingByHash.isNotEmpty) return true;
    }

    // Check by sourceAssetId & title
    if (sourceAssetId.isNotEmpty) {
      final existingByAsset = await (select(tasks)
            ..where((t) => t.sourceAssetId.equals(sourceAssetId) & t.title.lower().equals(normTitle)))
          .get();
      if (existingByAsset.isNotEmpty) return true;
    }

    return false;
  }

  // --- Processed Screenshot Queries ---
  Future<ProcessedScreenshot?> getProcessedScreenshot(String assetId) {
    return (select(processedScreenshots)..where((s) => s.assetId.equals(assetId))).getSingleOrNull();
  }

  Future<bool> isScreenshotProcessedOrNoAction(String assetId) async {
    final result = await getProcessedScreenshot(assetId);
    if (result == null) return false;
    return result.status == 'success' || result.status == 'no_action';
  }

  Future<int> logProcessedScreenshot({
    required String assetId,
    required String status, // success, no_action, failed
    String contentHash = '',
    String ocrText = '',
    String rawAiResponse = '',
    String? errorMessage,
    int attemptCount = 1,
  }) {
    return into(processedScreenshots).insertOnConflictUpdate(
      ProcessedScreenshotsCompanion.insert(
        assetId: assetId,
        status: Value(status),
        contentHash: Value(contentHash),
        processedAt: DateTime.now(),
        ocrText: Value(ocrText),
        rawAiResponse: Value(rawAiResponse),
        errorMessage: Value(errorMessage),
        attemptCount: Value(attemptCount),
      ),
    );
  }

  Future<List<ProcessedScreenshot>> getRecentDebugLogs({int limit = 50}) {
    return (select(processedScreenshots)
          ..orderBy([(s) => OrderingTerm(expression: s.processedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  Future<void> clearProcessedScreenshots() async {
    await delete(processedScreenshots).go();
  }

  Future<void> clearAllTasks() async {
    await delete(tasks).go();
  }

  Future<void> clearAllData() async {
    await delete(tasks).go();
    await delete(processedScreenshots).go();
  }
}
