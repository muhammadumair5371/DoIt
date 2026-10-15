import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../domain/usecases/process_screenshot_usecase.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_providers.dart';
import '../../services/ai_quota_service.dart';
import '../../services/ai_service.dart';
import '../../services/api_key_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../services/screenshot_watcher.dart';
import '../task_detail/task_detail_sheet.dart';
import 'widgets/hero_card.dart';
import 'widgets/needs_review_card.dart';
import 'widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning ☀️";
    } else if (hour < 17) {
      return "Good afternoon 🌤️";
    } else {
      return "Good evening 🌙";
    }
  }

  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final laterStart = tomorrowStart.add(const Duration(days: 1));

    final Map<String, List<Task>> groups = {
      'Overdue': [],
      'Today': [],
      'Tomorrow': [],
      'Later': [],
    };

    for (final task in tasks) {
      if (task.dueDate == null) {
        groups['Today']!.add(task);
      } else if (!task.isCompleted && task.dueDate!.isBefore(todayStart)) {
        groups['Overdue']!.add(task);
      } else if (task.dueDate!.isBefore(tomorrowStart)) {
        groups['Today']!.add(task);
      } else if (task.dueDate!.isBefore(laterStart)) {
        groups['Tomorrow']!.add(task);
      } else {
        groups['Later']!.add(task);
      }
    }

    return groups;
  }

  void _triggerManualGalleryScan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Scanning recent screenshots in gallery...'),
        duration: Duration(seconds: 2),
      ),
    );

    final taskRepo = ref.read(taskRepositoryProvider);
    final settings = ref.read(settingsProvider);

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
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? AppColors.success
              : (result.stage == 'no_action' ? Colors.blue : AppColors.primary),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedFilter = ref.watch(selectedFilterProvider);
    final selectedTypeFilter = ref.watch(selectedTypeFilterProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final needsReviewTasks = ref.watch(needsReviewTasksProvider);

    final groupedTasks = _groupTasks(filteredTasks);
    final todayDateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    final bool isQuotaExhausted = AiQuotaService.instance.isQuotaBlocked;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Quota Exhausted Banner
            if (isQuotaExhausted)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_bottom_rounded, color: Color(0xFF856404), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI quota reached, will retry later',
                          style: TextStyle(
                            color: Color(0xFF856404),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // API Key Check Banner
            FutureBuilder<bool>(
              future: ApiKeyService().hasApiKey(),
              builder: (context, snapshot) {
                final hasKey = snapshot.data ?? true;
                if (hasKey || isQuotaExhausted) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      margin: const EdgeInsets.only(left: 20, right: 20, top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEEBA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'API key missing. Add it in Settings or env.json',
                              style: TextStyle(
                                color: Color(0xFF856404),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF856404), size: 14),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 12, top: 16, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          todayDateStr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Scan Recent Screenshot',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                          ),
                          onPressed: () => _triggerManualGalleryScan(context, ref),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Settings',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_outlined, color: AppColors.primary),
                          ),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Hero Gradient Card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: HeroCard(),
              ),
            ),

            // "Needs Review" Cards Section if present
            if (needsReviewTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: needsReviewTasks.map((task) => NeedsReviewCard(task: task)).toList(),
                  ),
                ),
              ),

            // Filter Chips Bar
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: TaskFilter.values.map((filter) {
                        final isSelected = selectedFilter == filter;
                        final label = filter.name[0].toUpperCase() + filter.name.substring(1);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            onSelected: (val) {
                              if (val) ref.read(selectedFilterProvider.notifier).state = filter;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: TypeFilter.values.map((type) {
                        final isSelected = selectedTypeFilter == type;
                        final label = type == TypeFilter.all ? 'All Types' : (type.name[0].toUpperCase() + type.name.substring(1));
                        final color = type == TypeFilter.all ? AppColors.primary : AppColors.getTaskTypeColor(type.name);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: color.withOpacity(0.2),
                            side: isSelected ? BorderSide(color: color, width: 1.5) : BorderSide.none,
                            labelStyle: TextStyle(
                              color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            onSelected: (val) {
                              ref.read(selectedTypeFilterProvider.notifier).state = val ? type : TypeFilter.all;
                            },
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Task List or Empty State
            if (filteredTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildGroupedTaskWidgets(context, ref, groupedTasks),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskDetailSheet.show(context),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
    );
  }

  List<Widget> _buildGroupedTaskWidgets(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<Task>> groupedTasks,
  ) {
    final List<Widget> widgets = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    groupedTasks.forEach((header, tasks) {
      if (tasks.isNotEmpty) {
        final isOverdueHeader = header == 'Overdue';

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Row(
              children: [
                Text(
                  header,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isOverdueHeader
                        ? AppColors.deadlineColor
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isOverdueHeader ? AppColors.deadlineColor : AppColors.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isOverdueHeader ? AppColors.deadlineColor : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        for (final task in tasks) {
          widgets.add(
            TaskCard(
              task: task,
              onTap: () => TaskDetailSheet.show(context, task: task),
            ),
          );
        }
      }
    });

    return widgets;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📲✨', style: TextStyle(fontSize: 54)),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'No tasks here!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a screenshot of a text, event, or reminder.\nDoIt handles the rest automatically!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
