import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/usecases/process_screenshot_usecase.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import '../../services/ai_quota_service.dart';
import '../../services/ai_service.dart';
import '../../services/api_key_service.dart';
import '../../services/manual_scan_service.dart';
import '../../services/network_check_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../services/screenshot_watcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showTestResultDialog(BuildContext context, ProcessScreenshotResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Last Screenshot'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OCR Result:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Length: ${result.ocrCharCount} characters'),
              if (result.ocrTextSnippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.ocrTextSnippet,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Raw AI JSON Response:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.rawAiResponse.isEmpty ? '(No response / skipped)' : result.rawAiResponse,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Final Decision:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                result.message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: result.success ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startManualScanWorkflow(BuildContext context, WidgetRef ref) async {
    final scanService = ManualScanService.instance;
    final taskRepo = ref.read(taskRepositoryProvider);
    final settings = ref.read(settingsProvider);

    await scanService.prepareScan();

    if (!context.mounted) return;

    if (scanService.status == ManualScanStatus.permissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanService.statusMessage),
          backgroundColor: AppColors.deadlineColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (scanService.totalFound == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Screenshots Found'),
          content: const Text('No screenshot assets were found in your photo gallery.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Range selection dialog
    int selectedLimit = scanService.totalFound >= 25 ? 25 : scanService.totalFound;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Scan Existing Screenshots'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${scanService.totalFound} screenshots in gallery.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Choose range to scan:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [10, 25, 50, scanService.totalFound].map((val) {
                    final label = val == scanService.totalFound ? 'All (${scanService.totalFound})' : 'Last $val';
                    final isSel = selectedLimit == val;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) setStateDialog(() => selectedLimit = val);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  scanService.startScanWithLimit(selectedLimit, taskRepo, settings);
                  _showScanProgressDialog(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Scan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showScanProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: ManualScanService.instance,
          builder: (context, child) {
            final scan = ManualScanService.instance;
            final progress = scan.limitSelected == 0
                ? null
                : (scan.currentProcessed / scan.limitSelected).clamp(0.0, 1.0);

            if (scan.status == ManualScanStatus.completed ||
                scan.status == ManualScanStatus.cancelled ||
                scan.status == ManualScanStatus.pausedQuota) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  _showScanSummaryDialog(context, ref, scan);
                }
              });
            }

            return AlertDialog(
              title: Text(
                scan.status == ManualScanStatus.pausedQuota ? 'Scan Paused (Quota Limit)' : 'Scanning Screenshots',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text(
                    'Processed ${scan.currentProcessed} of ${scan.limitSelected} screenshots...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Active Model: ${scan.activeModel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  if (scan.statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      scan.statusMessage,
                      style: const TextStyle(fontSize: 12, color: AppColors.deadlineColor),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    scan.cancelScan();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel Scan', style: TextStyle(color: AppColors.deadlineColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScanSummaryDialog(BuildContext context, WidgetRef ref, ManualScanService scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Summary'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow('Total Selected:', '${scan.limitSelected}'),
              _buildSummaryRow('Already Done:', '${scan.alreadyDone}'),
              _buildSummaryRow('Tasks Added:', '${scan.tasksAdded}', isSuccess: true),
              _buildSummaryRow('No Action Required:', '${scan.noAction}'),
              _buildSummaryRow('Failed / Skipped:', '${scan.failed}', isError: scan.failed > 0),
              if (scan.failedReasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Failure Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      scan.failedReasons.join('\n'),
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isSuccess = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess ? AppColors.success : (isError ? AppColors.deadlineColor : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, 'AI API CONFIGURATION'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: const [
              ApiKeySettingsCard(),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'AI STATUS'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: const [
              AiStatusCard(),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'SCREENSHOT DETECTION'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              SwitchListTile(
                value: settings.autoDetectEnabled,
                onChanged: (val) => settingsNotifier.setAutoDetect(val),
                activeTrackColor: AppColors.primary,
                title: const Text('Auto-Detect Screenshots', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Automatically process new screenshots into tasks'),
                secondary: const Icon(Icons.camera_enhance_rounded, color: AppColors.primary),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: settings.reviewBeforeAdding,
                onChanged: (val) => settingsNotifier.setReviewBeforeAdding(val),
                activeTrackColor: AppColors.primary,
                title: const Text('Review Before Adding', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Ask for confirmation before creating any task'),
                secondary: const Icon(Icons.rate_review_rounded, color: AppColors.primary),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.collections_bookmark_rounded, color: AppColors.primary),
                title: const Text('Scan Existing Screenshots', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Process old screenshots from gallery one by one'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => _startManualScanWorkflow(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'DEBUG & VISIBILITY'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt_rounded, color: AppColors.primary),
                title: const Text('View Debug Log', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Inspect recent 50 screenshot OCR, AI JSON & decisions'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.push('/debug-logs'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report_rounded, color: AppColors.primary),
                title: const Text('Test Last Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Show OCR text, raw AI JSON & final decision'),
                trailing: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Testing latest screenshot pipeline...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  final taskRepo = ref.read(taskRepositoryProvider);
                  final processUseCase = ProcessScreenshotUseCase(
                    taskRepository: taskRepo,
                    ocrService: OCRService(),
                    aiService: AIService(),
                    notificationService: NotificationService(),
                  );

                  final watcher = ScreenshotWatcher(
                    processUseCase: processUseCase,
                    settings: settings,
                  );

                  final result = await watcher.scanLatestScreenshot(force: true);

                  if (context.mounted) {
                    messenger.clearSnackBars();
                    _showTestResultDialog(context, result);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                title: const Text('Reset Screenshot History', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Allow past screenshots to be evaluated again'),
                onTap: () async {
                  await ref.read(taskRepositoryProvider).clearProcessedScreenshots();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Screenshot history reset successfully!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'REMINDERS'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              SwitchListTile(
                value: settings.remindersEnabled,
                onChanged: (val) => settingsNotifier.setRemindersEnabled(val),
                activeTrackColor: AppColors.primary,
                title: const Text('Enable Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Notify me before deadlines and event times'),
                secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
              ),
              if (settings.remindersEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_rounded, color: AppColors.primary),
                  title: const Text('Reminder Lead Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${settings.reminderLeadMinutes} minutes before due date'),
                  trailing: DropdownButton<int>(
                    value: settings.reminderLeadMinutes,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(16),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 120, child: Text('2 hours')),
                    ],
                    onChanged: (val) {
                      if (val != null) settingsNotifier.setReminderLeadMinutes(val);
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'APPEARANCE'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_rounded, color: AppColors.primary),
                title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  settings.themeMode == ThemeMode.system
                      ? 'System Default'
                      : settings.themeMode == ThemeMode.light
                          ? 'Light Mode'
                          : 'Dark Mode',
                ),
                trailing: SegmentedButton<ThemeMode>(
                  selected: {settings.themeMode},
                  onSelectionChanged: (set) => settingsNotifier.setThemeMode(set.first),
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18)),
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_rounded, size: 18)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader(context, 'DATA & PRIVACY'),
          const SizedBox(height: 10),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.deadlineColor),
                title: const Text('Delete All Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deadlineColor)),
                subtitle: const Text('Clear all created tasks from task list'),
                onTap: () async {
                  await ref.read(taskRepositoryProvider).clearAllTasks();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All tasks deleted.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.deadlineColor),
                title: const Text('Clear All Tasks & Log History', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deadlineColor)),
                subtitle: const Text('Wipe local SQLite database and scan logs completely'),
                onTap: () => _confirmClearData(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'v1.0.0 • Gemini Vision AI Auto-Detection',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all tasks, reminders, and screenshot logs. This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(taskRepositoryProvider).clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All data cleared successfully.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deadlineColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class AiStatusCard extends StatelessWidget {
  const AiStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quota = AiQuotaService.instance;
    final model = quota.currentModel;
    final lastStatus = quota.lastStatusCode;
    final lastDuration = quota.lastResponseDurationSeconds;
    final callsToday = quota.apiCallsToday;
    final blockedUntil = quota.quotaBlockedUntil;

    final blockedTimeStr = blockedUntil != null
        ? DateFormat('h:mm:ss a').format(blockedUntil)
        : 'Not blocked';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Model:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(model, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Status & Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$lastStatus (${lastDuration.toStringAsFixed(2)}s)', style: TextStyle(fontWeight: FontWeight.bold, color: lastStatus == 200 ? AppColors.success : AppColors.deadlineColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('API Calls Today:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$callsToday / 20 per hr max', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (blockedUntil != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quota Retry At:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.deadlineColor)),
                Text(blockedTimeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deadlineColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ApiKeySettingsCard extends StatefulWidget {
  const ApiKeySettingsCard({super.key});

  @override
  State<ApiKeySettingsCard> createState() => _ApiKeySettingsCardState();
}

class _ApiKeySettingsCardState extends State<ApiKeySettingsCard> {
  final TextEditingController _controller = TextEditingController();
  final ApiKeyService _apiKeyService = ApiKeyService();
  bool _obscureText = true;
  bool _isTesting = false;
  String? _statusMessage;
  bool _statusSuccess = false;

  String _keySource = 'loading...';
  int _keyLength = 0;
  String _maskedEnding = '----';

  @override
  void initState() {
    super.initState();
    _loadKeyInfo();
  }

  Future<void> _loadKeyInfo() async {
    final key = await _apiKeyService.getApiKey();
    final info = await _apiKeyService.getKeyInfo();
    if (mounted) {
      setState(() {
        _controller.text = key;
        _keySource = info.source;
        _keyLength = info.length;
        _maskedEnding = info.last4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Source: $_keySource',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              Text(
                'Length: $_keyLength • Ending: ...$_maskedEnding',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'Enter API Key...',
              prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null && mounted) {
                        setState(() {
                          _controller.text = data!.text!.trim();
                        });
                      }
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _apiKeyService.saveApiKey(_controller.text);
                    await _loadKeyInfo();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('API key saved securely!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting
                      ? null
                      : () async {
                          setState(() {
                            _isTesting = true;
                            _statusMessage = null;
                          });

                          final res = await _apiKeyService.testApiKey(_controller.text);

                          if (mounted) {
                            setState(() {
                              _isTesting = false;
                              _statusMessage = res.message;
                              _statusSuccess = res.success;
                            });
                          }
                        },
                  icon: _isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('Test Connection'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting
                      ? null
                      : () async {
                          setState(() {
                            _isTesting = true;
                            _statusMessage = null;
                          });

                          final res = await NetworkCheckService.instance.runFullNetworkCheck();

                          if (mounted) {
                            setState(() {
                              _isTesting = false;
                              _statusMessage = res.message;
                              _statusSuccess = res.success;
                            });
                          }
                        },
                  icon: const Icon(Icons.network_check_rounded, size: 16),
                  label: const Text('Network Check'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    await _apiKeyService.clearApiKey();
                    await _loadKeyInfo();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Saved API key cleared.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppColors.deadlineColor),
                  label: const Text('Clear Saved Key', style: TextStyle(color: AppColors.deadlineColor, fontSize: 13)),
                ),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_statusSuccess ? AppColors.success : AppColors.deadlineColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusSuccess ? AppColors.success : AppColors.deadlineColor),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _statusSuccess ? AppColors.success : AppColors.deadlineColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
