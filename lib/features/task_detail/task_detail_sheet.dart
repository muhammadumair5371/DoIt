import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../providers/task_providers.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final Task? initialTask;

  const TaskDetailSheet({super.key, this.initialTask});

  static Future<void> show(BuildContext context, {Task? task}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(initialTask: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'task';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      final task = widget.initialTask!;
      _titleController.text = task.title;
      _notesController.text = task.notes;
      _selectedType = task.type;
      if (task.dueDate != null) {
        _selectedDate = task.dueDate;
        // Only set time if not midnight 00:00
        if (!(task.dueDate!.hour == 0 && task.dueDate!.minute == 0)) {
          _selectedTime = TimeOfDay.fromDateTime(task.dueDate!);
        }
      }
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = null; // No default clock time
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime? get _combinedDueDateTime {
    if (_selectedDate == null) return null;
    final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    final due = _combinedDueDateTime;

    if (widget.initialTask != null) {
      repo.updateTaskDetails(
        id: widget.initialTask!.id,
        title: title,
        type: _selectedType,
        dueDate: due,
        notes: _notesController.text.trim(),
        reason: widget.initialTask!.reason,
      );
    } else {
      repo.addTask(
        title: title,
        type: _selectedType,
        dueDate: due,
        notes: _notesController.text.trim(),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialTask != null;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Task Details' : 'New Task',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.deadlineColor),
                    onPressed: () {
                      ref.read(taskRepositoryProvider).deleteTask(widget.initialTask!.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Why DoIt added this section
            if (widget.initialTask?.reason != null && widget.initialTask!.reason.isNotEmpty) ...[
              Text(
                'Why DoIt added this',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.initialTask!.reason,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 18),

            Text('Type', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
            const SizedBox(height: 8),

            // FIX F: Wrap instead of Row to prevent 15px overflow on 360dp screens
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['task', 'reminder', 'deadline', 'event'].map((type) {
                final isSelected = _selectedType == type;
                final color = AppColors.getTaskTypeColor(type);
                return FilterChip(
                  label: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.12),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = type);
                  },
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            Text('Due Date & Time', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      _selectedDate != null
                          ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                          : 'Select Date',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      _selectedTime != null ? _selectedTime!.format(context) : 'Add time',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text('Notes', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Short summary notes...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            if (widget.initialTask?.sourceImagePath != null &&
                File(widget.initialTask!.sourceImagePath!).existsSync()) ...[
              const SizedBox(height: 16),
              Text('Source Screenshot', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.initialTask!.sourceImagePath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Task',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
