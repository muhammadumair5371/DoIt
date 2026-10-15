import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // WorkManager periodic scan fallback
    return Future.value(true);
  });
}

class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Foreground service started
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Periodically executed every ~15 seconds while active
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Service destroyed
  }
}

class BackgroundTasksService {
  static Future<void> initializeBackgroundServices() async {
    // 1. Initialize Flutter Foreground Task
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'doit_foreground_watcher',
        channelName: 'Screenshot Watcher Service',
        channelDescription: 'DoIt is watching for new screenshots in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000), // 15 seconds
        autoRunOnBoot: true,
        allowWifiLock: false,
      ),
    );

    // 2. Initialize WorkManager Fallback
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      await Workmanager().registerPeriodicTask(
        'doit_screenshot_scan_workmanager',
        'periodicScreenshotScan',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
    } catch (_) {}
  }

  static Future<void> startForegroundWatcher() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'DoIt is active',
      notificationText: 'DoIt is watching for screenshots',
      callback: _startTaskHandler,
    );
  }

  static Future<void> stopForegroundWatcher() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void _startTaskHandler() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}
