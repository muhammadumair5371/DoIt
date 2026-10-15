import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/task_providers.dart';
import 'circular_progress_painter.dart';

class HeroCard extends ConsumerStatefulWidget {
  const HeroCard({super.key});

  @override
  ConsumerState<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<HeroCard> {
  late ConfettiController _confettiController;
  late String _motivationalLine;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    final random = Random();
    _motivationalLine = AppConstants.motivationalLines[random.nextInt(AppConstants.motivationalLines.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(taskStatsProvider);

    if (stats.totalToday > 0 && stats.pendingToday == 0) {
      _confettiController.play();
    }

    final isAllDone = stats.totalToday > 0 && stats.pendingToday == 0;
    final percentText = '${(stats.completionPercentage * 100).round()}%';

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6B35),
                Color(0xFFFF9F1C),
                Color(0xFFFFC857),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAllDone
                              ? 'All done. Shabash! 🎉'
                              : stats.pendingToday == 0
                                  ? 'No tasks for today! 🙌'
                                  : '${stats.pendingToday} ${stats.pendingToday == 1 ? "task" : "tasks"} left today',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${stats.completedToday} of ${stats.totalToday} completed',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: stats.completionPercentage),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CustomPaint(
                              size: const Size(72, 72),
                              painter: CircularProgressPainter(
                                progress: value,
                                trackColor: Colors.white.withOpacity(0.25),
                                gradientColors: const [Colors.white, Color(0xFF22C55E)],
                                strokeWidth: 8,
                              ),
                            );
                          },
                        ),
                        Text(
                          percentText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _motivationalLine,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.white,
              AppColors.accent,
              AppColors.success,
              AppColors.reminderColor,
              AppColors.eventColor,
            ],
          ),
        ),
      ],
    );
  }
}
