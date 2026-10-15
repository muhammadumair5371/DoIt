import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../data/repositories/task_repository.dart';
import '../domain/usecases/process_screenshot_usecase.dart';
import '../providers/settings_provider.dart';
import 'ai_quota_service.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'ocr_service.dart';

enum ManualScanStatus {
  idle,
  findingAssets,
  rangeSelection,
  scanning,
  pausedQuota,
  completed,
  cancelled,
  permissionDenied,
}

class ManualScanService with ChangeNotifier {
  static final ManualScanService instance = ManualScanService._internal();
  ManualScanService._internal();

  ManualScanStatus _status = ManualScanStatus.idle;
  String _statusMessage = '';

  List<AssetEntity> _allFoundAssets = [];
  List<AssetEntity> _remainingAssets = [];

  int _totalFound = 0;
  int _limitSelected = 0;
  int _currentProcessed = 0;
  int _alreadyDone = 0;
  int _tasksAdded = 0;
  int _noAction = 0;
  int _failed = 0;

  final List<String> _failedReasons = [];
  final List<String> _createdTaskTitles = [];

  bool _isCancelRequested = false;

  // Getters
  ManualScanStatus get status => _status;
  String get statusMessage => _statusMessage;
  int get totalFound => _totalFound;
  int get limitSelected => _limitSelected;
  int get currentProcessed => _currentProcessed;
  int get alreadyDone => _alreadyDone;
  int get tasksAdded => _tasksAdded;
  int get noAction => _noAction;
  int get failed => _failed;
  List<String> get failedReasons => List.unmodifiable(_failedReasons);
  List<String> get createdTaskTitles => List.unmodifiable(_createdTaskTitles);
  int get remainingCount => _remainingAssets.length;
  String get activeModel => AiQuotaService.instance.currentModel;

  Future<void> prepareScan() async {
    _status = ManualScanStatus.findingAssets;
    _statusMessage = 'Requesting photo permissions...';
    _isCancelRequested = false;
    notifyListeners();

    debugPrint("[DoIt Scan] Requesting photo permissions for manual scan");
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    debugPrint("[DoIt Scan] Photo permission state: $ps");

    if (!ps.isAuth && !ps.hasAccess && !ps.isLimited) {
      _status = ManualScanStatus.permissionDenied;
      _statusMessage = 'Photo library permission was denied.';
      notifyListeners();
      return;
    }

    _statusMessage = 'Finding screenshots in gallery...';
    notifyListeners();

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: false,
    );

    debugPrint("[DoIt Scan] Found ${albums.length} total image albums in gallery");

    final Set<String> assetIds = {};
    final List<AssetEntity> candidateAssets = [];

    // Find all screenshot albums
    final screenshotAlbums = albums.where(
      (a) {
        final name = a.name.toLowerCase();
        return name.contains('screenshot') || name.contains('screen_shot') || name.contains('capture');
      }
    ).toList();

    debugPrint("[DoIt Scan] Matching screenshot albums count: ${screenshotAlbums.length}");

    if (screenshotAlbums.isNotEmpty) {
      for (final album in screenshotAlbums) {
        final count = await album.assetCountAsync;
        int page = 0;
        while (page * 50 < count) {
          final list = await album.getAssetListRange(start: page * 50, end: (page + 1) * 50);
          for (final a in list) {
            if (!assetIds.contains(a.id)) {
              assetIds.add(a.id);
              candidateAssets.add(a);
            }
          }
          page++;
        }
      }
    } else {
      // Fallback: check Recent album and filter by title/relativePath
      debugPrint("[DoIt Scan] No explicit screenshot album found. Falling back to Recent/All album.");
      final recentAlbum = albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
      final count = await recentAlbum.assetCountAsync;
      int page = 0;
      while (page * 50 < count && candidateAssets.length < 100) {
        final list = await recentAlbum.getAssetListRange(start: page * 50, end: (page + 1) * 50);
        for (final a in list) {
          if (!assetIds.contains(a.id) && await _isScreenshotAsset(a, recentAlbum.name)) {
            assetIds.add(a.id);
            candidateAssets.add(a);
          }
        }
        page++;
      }
    }

    // Sort newest first
    candidateAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    _allFoundAssets = candidateAssets;
    _totalFound = candidateAssets.length;

    debugPrint("[DoIt Scan] Total genuine screenshots found: $_totalFound");

    _status = ManualScanStatus.rangeSelection;
    notifyListeners();
  }

  Future<void> startScanWithLimit(int limit, TaskRepository taskRepo, AppSettings settings) async {
    _limitSelected = limit.clamp(1, _totalFound == 0 ? 1 : _totalFound);
    _remainingAssets = _allFoundAssets.take(_limitSelected).toList();

    _currentProcessed = 0;
    _alreadyDone = 0;
    _tasksAdded = 0;
    _noAction = 0;
    _failed = 0;
    _failedReasons.clear();
    _createdTaskTitles.clear();
    _isCancelRequested = false;

    _status = ManualScanStatus.scanning;
    notifyListeners();

    await _processRemainingAssets(taskRepo, settings);
  }

  Future<void> resumeScan(TaskRepository taskRepo, AppSettings settings) async {
    if (_remainingAssets.isEmpty) return;
    _isCancelRequested = false;
    _status = ManualScanStatus.scanning;
    notifyListeners();

    await _processRemainingAssets(taskRepo, settings);
  }

  void cancelScan() {
    _isCancelRequested = true;
    _status = ManualScanStatus.cancelled;
    _statusMessage = 'Manual scan cancelled by user.';
    debugPrint("[DoIt Scan] Manual scan cancelled by user");
    notifyListeners();
  }

  Future<void> _processRemainingAssets(TaskRepository taskRepo, AppSettings settings) async {
    final processUseCase = ProcessScreenshotUseCase(
      taskRepository: taskRepo,
      ocrService: OCRService(),
      aiService: AIService(),
      notificationService: NotificationService(),
    );

    while (_remainingAssets.isNotEmpty && !_isCancelRequested) {
      final asset = _remainingAssets.first;

      // Skip those already in processed_screenshots with status success or no_action
      final existingLog = await taskRepo.getProcessedScreenshot(asset.id);
      if (existingLog != null && (existingLog.status == 'success' || existingLog.status == 'no_action')) {
        _alreadyDone++;
        _currentProcessed++;
        _remainingAssets.removeAt(0);
        debugPrint("[DoIt Scan] Asset ${asset.id} already done (${existingLog.status}), skipping.");
        notifyListeners();
        continue;
      }

      // Process asset one at a time through processScreenshot
      debugPrint("[DoIt Scan] Processing asset ${asset.id} (${_currentProcessed + 1}/$_limitSelected)...");
      final result = await processUseCase.processScreenshot(
        asset,
        settings: settings,
        forceProcess: true,
      );

      // Check for HTTP 429 / Quota Error
      if (result.httpStatus == 429 || AiQuotaService.instance.isQuotaBlocked) {
        _status = ManualScanStatus.pausedQuota;
        _statusMessage = "Quota reached. ${_remainingAssets.length} screenshots left. Tap Continue later";
        debugPrint("[DoIt Scan] Quota limit reached. Pausing manual scan. ${_remainingAssets.length} left.");
        notifyListeners();
        return;
      }

      if (result.success) {
        _tasksAdded += result.createdCount;
        _createdTaskTitles.addAll(result.createdTitles);
      } else if (result.stage == 'no_action') {
        _noAction++;
      } else {
        _failed++;
        _failedReasons.add("${asset.id}: ${result.message}");
      }

      _currentProcessed++;
      _remainingAssets.removeAt(0);

      debugPrint("[DoIt Scan] Asset ${asset.id} result: stage=${result.stage}, added=${result.createdCount}");
      notifyListeners();
    }

    if (_isCancelRequested) {
      _status = ManualScanStatus.cancelled;
      _statusMessage = 'Scan cancelled';
    } else if (_remainingAssets.isEmpty) {
      _status = ManualScanStatus.completed;
      _statusMessage = 'Scan complete!';
      debugPrint("[DoIt Scan] Manual scan completed! Found: $_totalFound, Already Done: $_alreadyDone, Added: $_tasksAdded, No Action: $_noAction, Failed: $_failed");
    }

    notifyListeners();
  }

  Future<bool> _isScreenshotAsset(AssetEntity asset, String albumName) async {
    final albumLower = albumName.toLowerCase();
    if (albumLower.contains('screenshot') || albumLower.contains('screen_shot') || albumLower.contains('capture')) {
      return true;
    }

    final title = (asset.title ?? '').toLowerCase();
    if (title.contains('screenshot') || title.contains('screen_shot') || title.contains('screenshot_')) {
      return true;
    }

    final relPath = (asset.relativePath ?? '').toLowerCase();
    if (relPath.contains('screenshot') || relPath.contains('screen_shot')) {
      return true;
    }

    return false;
  }
}
