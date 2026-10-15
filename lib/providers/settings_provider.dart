import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AppSettings {
  final bool autoDetectEnabled;
  final bool remindersEnabled;
  final int reminderLeadMinutes;
  final ThemeMode themeMode;
  final bool reviewBeforeAdding;
  final bool onboardingCompleted;
  final DateTime firstLaunchTime;

  AppSettings({
    this.autoDetectEnabled = true,
    this.remindersEnabled = true,
    this.reminderLeadMinutes = 30,
    this.themeMode = ThemeMode.system,
    this.reviewBeforeAdding = false,
    this.onboardingCompleted = false,
    required this.firstLaunchTime,
  });

  AppSettings copyWith({
    bool? autoDetectEnabled,
    bool? remindersEnabled,
    int? reminderLeadMinutes,
    ThemeMode? themeMode,
    bool? reviewBeforeAdding,
    bool? onboardingCompleted,
    DateTime? firstLaunchTime,
  }) {
    return AppSettings(
      autoDetectEnabled: autoDetectEnabled ?? this.autoDetectEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      themeMode: themeMode ?? this.themeMode,
      reviewBeforeAdding: reviewBeforeAdding ?? this.reviewBeforeAdding,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      firstLaunchTime: firstLaunchTime ?? this.firstLaunchTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs) : super(AppSettings(firstLaunchTime: DateTime.now())) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final autoDetect = prefs.getBool(AppConstants.prefAutoDetect) ?? true;
    final reminders = prefs.getBool(AppConstants.prefRemindersEnabled) ?? true;
    final leadMinutes = prefs.getInt(AppConstants.prefReminderLeadMinutes) ?? 30;
    final themeStr = prefs.getString(AppConstants.prefThemeMode) ?? 'system';
    final review = prefs.getBool(AppConstants.prefReviewBeforeAdding) ?? false;
    final onboarding = prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;

    final storedLaunchStr = prefs.getString(AppConstants.prefFirstLaunchTime);
    DateTime launchTime;
    if (storedLaunchStr != null) {
      launchTime = DateTime.tryParse(storedLaunchStr) ?? DateTime.now();
    } else {
      launchTime = DateTime.now();
      prefs.setString(AppConstants.prefFirstLaunchTime, launchTime.toIso8601String());
    }

    ThemeMode mode;
    switch (themeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    state = AppSettings(
      autoDetectEnabled: autoDetect,
      remindersEnabled: reminders,
      reminderLeadMinutes: leadMinutes,
      themeMode: mode,
      reviewBeforeAdding: review,
      onboardingCompleted: onboarding,
      firstLaunchTime: launchTime,
    );
  }

  Future<void> setAutoDetect(bool value) async {
    await prefs.setBool(AppConstants.prefAutoDetect, value);
    state = state.copyWith(autoDetectEnabled: value);
  }

  Future<void> setRemindersEnabled(bool value) async {
    await prefs.setBool(AppConstants.prefRemindersEnabled, value);
    state = state.copyWith(remindersEnabled: value);
  }

  Future<void> setReminderLeadMinutes(int minutes) async {
    await prefs.setInt(AppConstants.prefReminderLeadMinutes, minutes);
    state = state.copyWith(reminderLeadMinutes: minutes);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    await prefs.setString(AppConstants.prefThemeMode, modeStr);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setReviewBeforeAdding(bool value) async {
    await prefs.setBool(AppConstants.prefReviewBeforeAdding, value);
    state = state.copyWith(reviewBeforeAdding: value);
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await prefs.setBool(AppConstants.prefOnboardingCompleted, value);
    state = state.copyWith(onboardingCompleted: value);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main() via override');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
