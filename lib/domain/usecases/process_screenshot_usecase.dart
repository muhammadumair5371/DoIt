import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';

class ProcessScreenshotResult {
  final bool success;
  final String stage;
  final String message;
  final int ocrCharCount;
  final String ocrTextSnippet;
  final String rawAiResponse;
  final int? httpStatus;
  final String? errorMessage;
  final int createdCount;
  final List<String> createdTitles;

  ProcessScreenshotResult({
    required this.success,
    required this.stage,
    required this.message,
    this.ocrCharCount = 0,
    this.ocrTextSnippet = '',
    this.rawAiResponse = '',
    this.httpStatus,
    this.errorMessage,
    this.createdCount = 0,
    this.createdTitles = const [],
  });
}

class ProcessScreenshotUseCase {
  final TaskRepository taskRepository;
  final OCRService ocrService;
  final AIService aiService;
  final NotificationService notificationService;

  static final Set<String> _inFlightAssets = {};

  ProcessScreenshotUseCase({
    required this.taskRepository,
    required this.ocrService,
    required this.aiService,
    required this.notificationService,
  });

  Future<ProcessScreenshotResult> processScreenshot(
    AssetEntity asset, {
    AppSettings? settings,
    bool forceProcess = false,
  }) async {
    final assetId = asset.id;

    // Mutex / In-flight deduplication check
    if (!forceProcess && _inFlightAssets.contains(assetId)) {
      debugPrint("[DoIt] Asset $assetId is currently in-flight, skipping");
      return ProcessScreenshotResult(
        success: false,
        stage: 'in_flight',
        message: 'Screenshot is currently being processed',
      );
    }

    _inFlightAssets.add(assetId);

    try {
      debugPrint("[DoIt] screenshot detected: $assetId");

      // 1. Check processed_screenshots table before processing
      final existingLog = await taskRepository.getProcessedScreenshot(assetId);
      final attemptCount = (existingLog?.attemptCount ?? 0) + 1;

      if (!forceProcess && existingLog != null) {
        if (existingLog.status == 'success' || existingLog.status == 'no_action') {
          debugPrint("[DoIt] Asset $assetId already evaluated with status '${existingLog.status}', skipping");
          return ProcessScreenshotResult(
            success: true,
            stage: existingLog.status,
            message: 'Screenshot already evaluated (${existingLog.status})',
            ocrCharCount: existingLog.ocrText.length,
            rawAiResponse: existingLog.rawAiResponse,
          );
        }

        if (existingLog.status == 'failed' && attemptCount > 3) {
          debugPrint("[DoIt] Asset $assetId failed 3 attempts previously, skipping");
          return ProcessScreenshotResult(
            success: false,
            stage: 'failed_max_attempts',
            message: 'Screenshot failed 3 times previously',
            errorMessage: existingLog.errorMessage,
          );
        }
      }

      // 2. File Retrieval
      File? file = await asset.file;
      if (file == null || !file.existsSync()) {
        file = await asset.originFile;
      }

      if (file == null || !file.existsSync()) {
        try {
          final bytes = await asset.originBytes;
          if (bytes != null && bytes.isNotEmpty) {
            final tempDir = await getTemporaryDirectory();
            final cleanId = asset.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
            final tempFile = File('${tempDir.path}/screenshot_$cleanId.jpg');
            await tempFile.writeAsBytes(bytes);
            file = tempFile;
            debugPrint("[DoIt] Temp file fallback succeeded: ${file.path}");
          }
        } catch (e) {
          debugPrint("[DoIt] Temp file fallback failed: $e");
        }
      }

      if (file == null || !file.existsSync()) {
        debugPrint("[DoIt] File read failed for asset $assetId");
        await taskRepository.logProcessedScreenshot(
          assetId: assetId,
          status: 'failed',
          errorMessage: 'Failed to read image file from storage',
          attemptCount: attemptCount,
        );
        return ProcessScreenshotResult(
          success: false,
          stage: 'file_failed',
          message: 'Failed to read image file from storage',
          errorMessage: 'Failed to read image file from storage',
        );
      }

      final filePath = file.path;

      // 3. Cheap OCR Pre-check (Optional fast filter to skip blank/non-text images)
      final String? ocrText = await ocrService.extractTextFromImage(filePath);
      final charCount = ocrText?.trim().length ?? 0;
      final snippet = charCount > 60 ? '${ocrText!.trim().substring(0, 60)}...' : (ocrText?.trim() ?? '');
      final contentHash = charCount > 0 ? sha256.convert(utf8.encode(ocrText!.trim())).toString() : '';

      if (ocrText == null || charCount < 5) {
        debugPrint("[DoIt] OCR pre-check chars: $charCount (under 5, skipping)");
        await taskRepository.logProcessedScreenshot(
          assetId: assetId,
          status: 'no_action',
          contentHash: contentHash,
          ocrText: ocrText ?? '',
          errorMessage: 'OCR text under 5 chars',
          attemptCount: attemptCount,
        );
        return ProcessScreenshotResult(
          success: true,
          stage: 'no_action',
          message: 'Ignored: Screenshot has under 5 text characters',
          ocrCharCount: charCount,
          ocrTextSnippet: snippet,
        );
      }

      // 4. Send Screenshot Image directly to Claude Vision API
      final aiResult = await aiService.classifyScreenshotImage(filePath);

      // STRICT RULE: If AI call failed, create NO task and mark as 'failed' (retry up to 3 times)
      if (!aiResult.isSuccess) {
        final errorText = aiResult.errorMessage ?? 'AI API Call Failed';
        debugPrint("[DoIt] AI call failed: $errorText");

        await taskRepository.logProcessedScreenshot(
          assetId: assetId,
          status: 'failed',
          contentHash: contentHash,
          ocrText: ocrText,
          rawAiResponse: aiResult.rawResponse,
          errorMessage: errorText,
          attemptCount: attemptCount,
        );

        return ProcessScreenshotResult(
          success: false,
          stage: 'ai_error',
          message: errorText,
          ocrCharCount: charCount,
          ocrTextSnippet: snippet,
          rawAiResponse: aiResult.rawResponse,
          httpStatus: aiResult.statusCode,
          errorMessage: errorText,
        );
      }

      final items = aiResult.items;

      if (items.isEmpty) {
        debugPrint("[DoIt] AI decision: 0 items found (No action)");
        await taskRepository.logProcessedScreenshot(
          assetId: assetId,
          status: 'no_action',
          contentHash: contentHash,
          ocrText: ocrText,
          rawAiResponse: aiResult.rawResponse,
          attemptCount: attemptCount,
        );
        return ProcessScreenshotResult(
          success: true,
          stage: 'no_action',
          message: 'Ignored: No personal commitment items found in screenshot',
          ocrCharCount: charCount,
          ocrTextSnippet: snippet,
          rawAiResponse: aiResult.rawResponse,
          httpStatus: aiResult.statusCode,
        );
      }

      // 5. Validate & Deduplicate Items, Save Tasks to Drift DB
      final bool reviewMandatory = settings?.reviewBeforeAdding ?? false;
      int autoAddedCount = 0;
      int reviewCount = 0;
      final List<String> createdTitles = [];

      for (final item in items) {
        final title = item.title.trim();
        if (title.isEmpty || title.length > 80) continue;

        if (!['task', 'reminder', 'deadline', 'event'].contains(item.type)) continue;

        // Confidence Rule 1: confidence < 0.45 -> ignore
        if (item.confidence < 0.45) {
          debugPrint("[DoIt] Item '$title' confidence < 0.45 (${item.confidence}), ignoring");
          continue;
        }

        // Deduplication Check: Never insert duplicate (sourceAssetId / contentHash, title, dueDate)
        final isDuplicate = await taskRepository.hasDuplicateTask(
          sourceAssetId: assetId,
          title: title,
          dueDate: item.dueDateTime,
          contentHash: contentHash,
        );

        if (isDuplicate) {
          debugPrint("[DoIt] Duplicate task detected for '$title', skipping");
          continue;
        }

        // Confidence Rule 2: 0.45 <= confidence < 0.75 -> Needs review
        final bool needsReview = (item.confidence < 0.75) || reviewMandatory;

        final taskId = await taskRepository.addTask(
          title: title,
          type: item.type,
          dueDate: item.dueDateTime,
          notes: item.notes, // Short human line from AI (max 60 chars)
          reason: item.reason, // AI reason field
          contentHash: contentHash,
          sourceAssetId: assetId,
          sourceImagePath: filePath,
          needsReview: needsReview,
          confidence: item.confidence,
        );

        createdTitles.add(title);
        if (needsReview) {
          reviewCount++;
        } else {
          autoAddedCount++;
        }

        // Trigger Notification
        final notificationId = taskId.hashCode;
        await notificationService.showNotificationNow(
          id: notificationId,
          title: needsReview ? 'Task needs review 🧐' : 'New task added 📸',
          body: title,
        );

        // Schedule reminders if due date is present
        if (item.dueDateTime != null && (settings?.remindersEnabled ?? true)) {
          // If dueTime was specified by AI, use exact dueDateTime
          // If dueTime was null (only date provided), schedule default 9:00 AM reminder on due date
          final reminderTime = item.dueTime != null
              ? item.dueDateTime!
              : DateTime(item.dueDateTime!.year, item.dueDateTime!.month, item.dueDateTime!.day, 9, 0);

          await notificationService.scheduleTaskReminders(
            baseId: notificationId,
            title: title,
            dueTime: reminderTime,
            leadMinutes: settings?.reminderLeadMinutes ?? 30,
          );
        }
      }

      final finalStatus = createdTitles.isNotEmpty ? 'success' : 'no_action';

      await taskRepository.logProcessedScreenshot(
        assetId: assetId,
        status: finalStatus,
        contentHash: contentHash,
        ocrText: ocrText,
        rawAiResponse: aiResult.rawResponse,
        attemptCount: attemptCount,
      );

      final summaryMsg = createdTitles.isNotEmpty
          ? 'Added ${createdTitles.length} items ($autoAddedCount auto, $reviewCount for review)'
          : 'Ignored: No items met confidence threshold';

      return ProcessScreenshotResult(
        success: createdTitles.isNotEmpty,
        stage: finalStatus,
        message: summaryMsg,
        ocrCharCount: charCount,
        ocrTextSnippet: snippet,
        rawAiResponse: aiResult.rawResponse,
        httpStatus: aiResult.statusCode,
        createdCount: createdTitles.length,
        createdTitles: createdTitles,
      );
    } finally {
      _inFlightAssets.remove(assetId);
    }
  }
}
