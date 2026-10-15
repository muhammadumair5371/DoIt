import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScreenshotPreviewModal extends StatelessWidget {
  final String? imagePath;
  final String taskTitle;
  final String notes;

  const ScreenshotPreviewModal({
    super.key,
    required this.imagePath,
    required this.taskTitle,
    required this.notes,
  });

  static void show(BuildContext context, {required String? imagePath, required String taskTitle, required String notes}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScreenshotPreviewModal(
        imagePath: imagePath,
        taskTitle: taskTitle,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
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
            children: [
              const Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Original Screenshot',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            taskTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagePath != null && File(imagePath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_rounded, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Original screenshot file no longer cached.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Extracted Notes & Context:',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        notes,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
