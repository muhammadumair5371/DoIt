import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class AiQuotaService {
  static final AiQuotaService instance = AiQuotaService._internal();
  AiQuotaService._internal();

  DateTime? _quotaBlockedUntil;
  int _lastStatusCode = 200;
  String _currentModel = AppConstants.defaultGeminiModel;
  double _lastResponseDurationSeconds = 0.0;
  int _apiCallsToday = 0;
  DateTime _lastResetDate = DateTime.now();
  final List<DateTime> _hourlyCallTimestamps = [];
  DateTime? _lastApiCallTime;

  bool get isQuotaBlocked {
    if (_quotaBlockedUntil == null) return false;
    if (DateTime.now().isAfter(_quotaBlockedUntil!)) {
      _quotaBlockedUntil = null;
      return false;
    }
    return true;
  }

  DateTime? get quotaBlockedUntil => _quotaBlockedUntil;
  int get lastStatusCode => _lastStatusCode;
  String get currentModel => _currentModel;
  double get lastResponseDurationSeconds => _lastResponseDurationSeconds;

  int get apiCallsToday {
    _checkDailyReset();
    return _apiCallsToday;
  }

  void setActiveModel(String model, double durationSeconds) {
    _currentModel = model;
    _lastResponseDurationSeconds = durationSeconds;
    _lastStatusCode = 200;
    debugPrint("[DoIt] Active model set to: $model (${durationSeconds.toStringAsFixed(2)}s)");
  }

  void setQuotaBlocked(Duration duration) {
    _quotaBlockedUntil = DateTime.now().add(duration);
    _lastStatusCode = 429;
    debugPrint("[DoIt] Quota blocked for ${duration.inMinutes} minutes until $_quotaBlockedUntil");
  }

  void updateLastStatus(int statusCode, {String? model, double? durationSeconds}) {
    _lastStatusCode = statusCode;
    if (model != null && model.isNotEmpty) {
      _currentModel = model;
    }
    if (durationSeconds != null) {
      _lastResponseDurationSeconds = durationSeconds;
    }
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day ||
        now.month != _lastResetDate.month ||
        now.year != _lastResetDate.year) {
      _apiCallsToday = 0;
      _lastResetDate = now;
    }
  }

  /// Pacing: Ensures 6 seconds gap between API calls & caps at 20 calls/hour
  Future<bool> prepareApiCall() async {
    if (isQuotaBlocked) {
      debugPrint("[DoIt] API Call blocked due to quota exhaustion until $_quotaBlockedUntil");
      return false;
    }

    _checkDailyReset();

    final now = DateTime.now();

    // 1. Clean hourly timestamps older than 1 hour
    _hourlyCallTimestamps.removeWhere((ts) => now.difference(ts).inHours >= 1);
    if (_hourlyCallTimestamps.length >= 20) {
      debugPrint("[DoIt] Hourly API cap reached (20 calls/hr). Blocking further calls for now.");
      setQuotaBlocked(const Duration(minutes: 30));
      return false;
    }

    // 2. Enforce 6-second delay between calls
    if (_lastApiCallTime != null) {
      final elapsed = now.difference(_lastApiCallTime!);
      if (elapsed < const Duration(seconds: 6)) {
        final waitDuration = const Duration(seconds: 6) - elapsed;
        debugPrint("[DoIt] Pacing API call: waiting ${waitDuration.inSeconds}s");
        await Future.delayed(waitDuration);
      }
    }

    final callTime = DateTime.now();
    _lastApiCallTime = callTime;
    _hourlyCallTimestamps.add(callTime);
    _apiCallsToday++;

    return true;
  }
}
