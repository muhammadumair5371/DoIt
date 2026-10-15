import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/usecases/process_screenshot_usecase.dart';
import 'providers/settings_provider.dart';
import 'providers/task_providers.dart';
import 'services/ai_service.dart';
import 'services/background_tasks.dart';
import 'services/notification_service.dart';
import 'services/ocr_service.dart';
import 'services/screenshot_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 3. Initialize Background Services
  await BackgroundTasksService.initializeBackgroundServices();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DoItApp(),
    ),
  );
}

class DoItApp extends ConsumerStatefulWidget {
  const DoItApp({super.key});

  @override
  ConsumerState<DoItApp> createState() => _DoItAppState();
}

class _DoItAppState extends ConsumerState<DoItApp> {
  ScreenshotWatcher? _screenshotWatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initScreenshotWatcher();
    });
  }

  void _initScreenshotWatcher() {
    final taskRepo = ref.read(taskRepositoryProvider);
    final settings = ref.read(settingsProvider);

    final processUseCase = ProcessScreenshotUseCase(
      taskRepository: taskRepo,
      ocrService: OCRService(),
      aiService: AIService(),
      notificationService: NotificationService(),
    );

    _screenshotWatcher = ScreenshotWatcher(
      processUseCase: processUseCase,
      settings: settings,
    );

    _screenshotWatcher?.start();

    if (settings.autoDetectEnabled) {
      BackgroundTasksService.startForegroundWatcher();
    }
  }

  @override
  void dispose() {
    _screenshotWatcher?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'DoIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
