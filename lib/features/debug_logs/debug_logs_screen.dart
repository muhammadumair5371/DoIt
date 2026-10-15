import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../providers/task_providers.dart';

class DebugLogsScreen extends ConsumerWidget {
  const DebugLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.watch(taskRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Debug Log', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ProcessedScreenshot>>(
        future: taskRepo.getRecentDebugLogs(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No screenshot logs found.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Take a screenshot or scan your gallery to see live logs.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isSuccess = log.status == 'success';
              final isNoAction = log.status == 'no_action';
              final statusColor = isSuccess ? AppColors.success : (isNoAction ? Colors.blue : AppColors.deadlineColor);

              final timeStr = DateFormat('MMM d, h:mm a').format(log.processedAt);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  title: Text(
                    'Asset: ${log.assetId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'OCR: ${log.ocrText.length} chars • $timeStr',
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
                            const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deadlineColor)),
                            const SizedBox(height: 2),
                            Text(log.errorMessage!, style: const TextStyle(color: AppColors.deadlineColor, fontSize: 12)),
                            const SizedBox(height: 10),
                          ],
                          const Text('OCR Text Snippet:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.ocrText.isEmpty ? '(Empty OCR)' : (log.ocrText.length > 150 ? '${log.ocrText.substring(0, 150)}...' : log.ocrText),
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('Raw AI JSON Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.rawAiResponse.isEmpty ? '(No AI response / skipped)' : log.rawAiResponse,
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
