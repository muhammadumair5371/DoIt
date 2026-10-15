import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../../providers/task_providers.dart';
import 'screenshot_preview_modal.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    final bool hasTime = !(date.hour == 0 && date.minute == 0);
    final timeStr = hasTime ? ', ${DateFormat('h:mm a').format(date)}' : '';

    if (taskDate == today) {
      return 'Today$timeStr';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow$timeStr';
    } else {
      return '${DateFormat('MMM d').format(date)}$timeStr';
    }
  }

  bool _isOverdue(DateTime? date) {
    if (date == null || task.isCompleted) return false;
    // Overdue only if time is past
    return date.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = AppColors.getTaskTypeColor(task.type);
    final typeIcon = AppColors.getTaskTypeIcon(task.type);
    final isOverdue = _isOverdue(task.dueDate);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.deadlineColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          ref.read(taskRepositoryProvider).markCompleted(task.id, !task.isCompleted);
          return false;
        } else {
          HapticFeedback.mediumImpact();
          final repo = ref.read(taskRepositoryProvider);
          final deletedTask = task;
          await repo.deleteTask(task.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted "${deletedTask.title}"'),
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: AppColors.accent,
                  onPressed: () {
                    repo.addTask(
                      title: deletedTask.title,
                      type: deletedTask.type,
                      dueDate: deletedTask.dueDate,
                      notes: deletedTask.notes,
                      sourceAssetId: deletedTask.sourceAssetId,
                      sourceImagePath: deletedTask.sourceImagePath,
                      needsReview: deletedTask.needsReview,
                      confidence: deletedTask.confidence,
                    );
                  },
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return true;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: task.isNew
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: task.isNew ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: task.isNew
                ? AppColors.primary
                : isOverdue
                    ? AppColors.deadlineColor.withOpacity(0.5)
                    : Colors.transparent,
            width: task.isNew ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: InkWell(
            onTap: () {
              if (task.isNew) {
                ref.read(taskRepositoryProvider).clearIsNewFlag(task.id);
              }
              onTap();
            },
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 24),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted
                                      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (task.isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (task.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOverdue
                                      ? AppColors.deadlineColor.withOpacity(0.12)
                                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: isOverdue
                                          ? AppColors.deadlineColor
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDueDate(task.dueDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isOverdue
                                            ? AppColors.deadlineColor
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (task.sourceAssetId != null || task.sourceImagePath != null)
                              GestureDetector(
                                onTap: () {
                                  ScreenshotPreviewModal.show(
                                    context,
                                    imagePath: task.sourceImagePath,
                                    taskTitle: task.title,
                                    notes: task.notes,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.center_focus_weak_rounded, size: 13, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Screenshot',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(taskRepositoryProvider).markCompleted(task.id, !task.isCompleted);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? AppColors.success : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted ? AppColors.success : (isDark ? Colors.white38 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
