import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../domain/usecases/process_screenshot_usecase.dart';
import '../providers/settings_provider.dart';

class ScreenshotWatcher with WidgetsBindingObserver {
  final ProcessScreenshotUseCase processUseCase;
  final AppSettings settings;

  bool _isWatching = false;

  ScreenshotWatcher({
    required this.processUseCase,
    required this.settings,
  });

  void start() {
    if (_isWatching || !settings.autoDetectEnabled) return;
    _isWatching = true;

    WidgetsBinding.instance.addObserver(this);

    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();

    scanRecentScreenshots();
  }

  void stop() {
    if (!_isWatching) return;
    _isWatching = false;

    WidgetsBinding.instance.removeObserver(this);
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && settings.autoDetectEnabled) {
      debugPrint("[DoIt] App resumed, scanning recent screenshots");
      scanRecentScreenshots();
    }
  }

  void _onGalleryChanged(MethodCall call) {
    if (settings.autoDetectEnabled) {
      debugPrint("[DoIt] Gallery change event received via PhotoManager");
      scanRecentScreenshots();
    }
  }

  Future<bool> _isScreenshotAsset(AssetEntity asset, String albumName) async {
    final albumLower = albumName.toLowerCase();

    // Explicit screenshot album match
    if (albumLower.contains('screenshot') ||
        albumLower.contains('screenshots') ||
        albumLower.contains('screen_shot') ||
        albumLower.contains('screen_capture')) {
      return true;
    }

    // Check title / filename
    final title = (asset.title ?? '').toLowerCase();

    // Reject standard camera photo patterns
    if ((title.startsWith('img_') ||
         title.startsWith('pxl_') ||
         title.startsWith('dsc_') ||
         title.startsWith('vid_')) &&
        !title.contains('screenshot') &&
        !title.contains('screen_shot')) {
      return false;
    }

    if (title.contains('screenshot') ||
        title.contains('screenshots') ||
        title.contains('screen_shot') ||
        title.contains('screenshot_') ||
        title.contains('screen_') ||
        title.contains('scr_') ||
        title.contains('shot_')) {
      return true;
    }

    // Check relativePath
    final relPath = (asset.relativePath ?? '').toLowerCase();
    if (relPath.contains('screenshots') || relPath.contains('screen_shot')) {
      return true;
    }

    // Check TitleAsync
    try {
      final titleAsync = (await asset.titleAsync).toLowerCase();
      if (titleAsync.contains('screenshot') ||
          titleAsync.contains('screen_shot') ||
          titleAsync.contains('screenshot_')) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<bool> _ensurePermissions() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) return true;

    final photoStatus = await Permission.photos.request();
    if (photoStatus.isGranted || photoStatus.isLimited) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    return false;
  }

  /// Automatic scan for background / lifecycle / callback triggers
  Future<List<ProcessScreenshotResult>> scanRecentScreenshots() async {
    final List<ProcessScreenshotResult> results = [];
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        debugPrint("[DoIt] Gallery permission denied");
        return results;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      if (albums.isEmpty) return results;

      final Set<String> processedInThisRun = {};

      for (final album in albums) {
        final isScreenshotAlbum = album.name.toLowerCase().contains('screenshot');
        final isRecentAlbum = album.isAll;

        if (isScreenshotAlbum || isRecentAlbum) {
          final recentAssets = await album.getAssetListRange(start: 0, end: 15);

          for (final asset in recentAssets) {
            if (processedInThisRun.contains(asset.id)) continue;
            processedInThisRun.add(asset.id);

            final isScreenshot = await _isScreenshotAsset(asset, album.name);
            if (isScreenshot) {
              final res = await processUseCase.processScreenshot(asset, settings: settings);
              results.add(res);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[DoIt] Error scanning screenshots: $e");
    }
    return results;
  }

  /// Manual scan for existing screenshots with progress reporting and cancellation support
  Future<int> scanExistingScreenshotsProgressively({
    required void Function(int processed, int total) onProgress,
    required bool Function() isCancelled,
  }) async {
    int totalCreated = 0;
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) return 0;

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      if (albums.isEmpty) return 0;

      final Set<String> assetIds = {};
      final List<AssetEntity> candidateAssets = [];

      // 1. Look for explicit Screenshots album first
      AssetPathEntity? screenshotAlbum;
      for (final album in albums) {
        final name = album.name.toLowerCase();
        if (name.contains('screenshot') || name.contains('screen_shot') || name.contains('captures')) {
          screenshotAlbum = album;
          break;
        }
      }

      if (screenshotAlbum != null) {
        final count = await screenshotAlbum.assetCountAsync;
        final list = await screenshotAlbum.getAssetListRange(start: 0, end: count);
        for (final a in list) {
          if (!assetIds.contains(a.id)) {
            assetIds.add(a.id);
            candidateAssets.add(a);
          }
        }
      } else {
        // Fallback: check Recent album, but strictly filter using _isScreenshotAsset
        final recentAlbum = albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
        final count = await recentAlbum.assetCountAsync;
        final list = await recentAlbum.getAssetListRange(start: 0, end: count.clamp(0, 100));
        for (final a in list) {
          if (!assetIds.contains(a.id) && await _isScreenshotAsset(a, recentAlbum.name)) {
            assetIds.add(a.id);
            candidateAssets.add(a);
          }
        }
      }

      final totalToProcess = candidateAssets.length;
      debugPrint("[DoIt] Found $totalToProcess genuine screenshots for progressive scan");

      for (int i = 0; i < totalToProcess; i++) {
        if (isCancelled()) {
          debugPrint("[DoIt] Manual scan cancelled by user");
          break;
        }

        onProgress(i + 1, totalToProcess);

        final asset = candidateAssets[i];
        final result = await processUseCase.processScreenshot(asset, settings: settings, forceProcess: true);
        if (result.success) {
          totalCreated += result.createdCount;
        }
      }
    } catch (e) {
      debugPrint("[DoIt] Error in progressive manual scan: $e");
    }

    return totalCreated;
  }

  /// Manual trigger for testing latest screenshot from gallery
  Future<ProcessScreenshotResult> scanLatestScreenshot({bool force = true}) async {
    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        return ProcessScreenshotResult(
          success: false,
          stage: 'permission_denied',
          message: 'Gallery access permission was denied',
        );
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      if (albums.isEmpty) {
        return ProcessScreenshotResult(
          success: false,
          stage: 'no_photos',
          message: 'No photo albums found on device',
        );
      }

      // Try finding 'Screenshots' album or 'Recent'
      AssetPathEntity targetAlbum = albums.firstWhere(
        (a) => a.name.toLowerCase().contains('screenshot'),
        orElse: () => albums.first,
      );

      final recentAssets = await targetAlbum.getAssetListRange(start: 0, end: 10);
      if (recentAssets.isEmpty) {
        return ProcessScreenshotResult(
          success: false,
          stage: 'no_photos',
          message: 'No photos found in ${targetAlbum.name}',
        );
      }

      // Search for first screenshot match
      AssetEntity? targetAsset;
      for (final asset in recentAssets) {
        if (await _isScreenshotAsset(asset, targetAlbum.name)) {
          targetAsset = asset;
          break;
        }
      }

      // Fallback to the newest image asset if no explicit screenshot name was matched
      targetAsset ??= recentAssets.first;

      return await processUseCase.processScreenshot(
        targetAsset,
        settings: settings,
        forceProcess: force,
      );
    } catch (e) {
      return ProcessScreenshotResult(
        success: false,
        stage: 'error',
        message: 'Scan error: $e',
      );
    }
  }
}
