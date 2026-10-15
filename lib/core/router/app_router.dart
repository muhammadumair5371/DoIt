import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/debug_logs/debug_logs_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../providers/settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);

  return GoRouter(
    initialLocation: settings.onboardingCompleted ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/debug-logs',
        builder: (context, state) => const DebugLogsScreen(),
      ),
    ],
  );
});
