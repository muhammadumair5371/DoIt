import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import 'api_key_service.dart';

class NetworkCheckService {
  static final NetworkCheckService instance = NetworkCheckService._internal();
  NetworkCheckService._internal();

  static const String host = 'generativelanguage.googleapis.com';

  /// Returns platform & runtime build mode details
  String getEnvironmentInfo() {
    final os = Platform.operatingSystem;
    final mode = kReleaseMode
        ? 'Release'
        : (kProfileMode ? 'Profile' : 'Debug');
    final isAndroidOrIos = Platform.isAndroid || Platform.isIOS;
    final deviceType = isAndroidOrIos ? 'Mobile Device' : 'Desktop/Other Environment';

    return 'Platform: $os ($deviceType) • Mode: $mode';
  }

  /// Performs DNS lookup pre-check for Google Gemini API host
  Future<({bool success, double durationSeconds, String detail})> checkDns() async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await InternetAddress.lookup(host).timeout(const Duration(seconds: 10));
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;

      if (results.isNotEmpty && results.first.rawAddress.isNotEmpty) {
        return (
          success: true,
          durationSeconds: duration,
          detail: 'DNS resolved (${results.first.address}) in ${duration.toStringAsFixed(2)}s'
        );
      }
      return (
        success: false,
        durationSeconds: duration,
        detail: 'DNS lookup returned no IP addresses'
      );
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      return (
        success: false,
        durationSeconds: duration,
        detail: 'DNS lookup exception ($host): $e'
      );
    }
  }

  /// Full Network check (Environment + Key Check + DNS + GET /v1beta/models)
  Future<({bool success, String message})> runFullNetworkCheck() async {
    final envInfo = getEnvironmentInfo();
    final apiKeyService = ApiKeyService();
    final keyInfo = await apiKeyService.getKeyInfo();
    final key = await apiKeyService.getApiKey();

    final logs = <String>[];
    logs.add('--- RUNTIME ENVIRONMENT ---\n$envInfo');

    if (key.isEmpty || keyInfo.source == 'none') {
      logs.add('--- API KEY STATUS ---\nKey Source: NOT LOADED\nLength: 0 • Ending: ----\n\nKey not loaded. Run the app with --dart-define-from-file=env.json');
      return (
        success: false,
        message: logs.join('\n\n')
      );
    }

    logs.add('--- API KEY STATUS ---\nKey Source: ${keyInfo.source}\nLength: ${keyInfo.length} • Ending: ...${keyInfo.last4}');

    // DNS Check
    final dnsRes = await checkDns();
    logs.add('--- DNS LOOKUP ($host) ---\nStatus: ${dnsRes.success ? "SUCCESS" : "FAILED"} (${dnsRes.durationSeconds.toStringAsFixed(2)}s)\nDetail: ${dnsRes.detail}');

    if (!dnsRes.success) {
      return (
        success: false,
        message: '${logs.join('\n\n')}\n\nConclusion: No connection to Google. Check Wi-Fi, mobile data, VPN or Private DNS.'
      );
    }

    // GET /v1beta/models
    final stopwatch = Stopwatch()..start();
    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstants.geminiApiBaseUrl}/models',
        options: Options(
          headers: {
            'x-goog-api-key': key,
            'content-type': 'application/json',
          },
          validateStatus: (status) => true,
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      final statusCode = response.statusCode ?? 500;

      if (statusCode == 200) {
        int count = 0;
        if (response.data is Map && response.data['models'] is List) {
          count = (response.data['models'] as List).length;
        }
        logs.add('--- GET /v1beta/models ---\nStatus: HTTP 200 OK (${duration.toStringAsFixed(2)}s)\nModels Count: $count');
        return (success: true, message: logs.join('\n\n'));
      }

      String errorMsg = 'HTTP $statusCode';
      if (response.data is Map) {
        final err = response.data['error'];
        if (err is Map) {
          errorMsg = 'status: ${err['status']}, message: ${err['message']}';
        }
      }

      logs.add('--- GET /v1beta/models ---\nStatus: HTTP $statusCode (${duration.toStringAsFixed(2)}s)\nDetail: $errorMsg');
      return (success: false, message: logs.join('\n\n'));
    } on DioException catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      final errDetail = 'type: ${e.type}, errorType: ${e.error?.runtimeType}, errorStr: ${e.error?.toString()}';
      logs.add('--- GET /v1beta/models ---\nStatus: Exception (${duration.toStringAsFixed(2)}s)\nDetail: $errDetail');
      return (success: false, message: logs.join('\n\n'));
    } catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      logs.add('--- GET /v1beta/models ---\nStatus: Exception (${duration.toStringAsFixed(2)}s)\nDetail: $e');
      return (success: false, message: logs.join('\n\n'));
    }
  }
}
