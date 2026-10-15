import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import 'ai_quota_service.dart';

class ApiKeyService {
  static const String _storageKey = 'gemini_api_key';
  final FlutterSecureStorage _storage;
  final Dio _dio;

  ApiKeyService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio();

  /// Reads key in exact order:
  /// 1. GEMINI_API_KEY environment variable from env.json
  /// 2. Saved key in FlutterSecureStorage (from Settings screen)
  Future<({String key, String source})> getApiKeyWithSource() async {
    const envGemini = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final cleanGemini = envGemini.trim().replaceAll('\r', '').replaceAll('\n', '');
    if (cleanGemini.isNotEmpty) {
      return (key: cleanGemini, source: 'env.json');
    }

    try {
      final savedKey = await _storage.read(key: _storageKey);
      if (savedKey != null) {
        final cleanSaved = savedKey.trim().replaceAll('\r', '').replaceAll('\n', '');
        if (cleanSaved.isNotEmpty) {
          return (key: cleanSaved, source: 'saved in app');
        }
      }
    } catch (e) {
      debugPrint("[DoIt] Secure storage read error: $e");
    }

    return (key: '', source: 'none');
  }

  Future<String> getApiKey() async {
    final res = await getApiKeyWithSource();
    return res.key;
  }

  Future<void> saveApiKey(String key) async {
    final clean = key.trim().replaceAll('\r', '').replaceAll('\n', '');
    try {
      await _storage.write(key: _storageKey, value: clean);
      debugPrint("[DoIt] Saved API key to FlutterSecureStorage");
    } catch (e) {
      debugPrint("[DoIt] Secure storage write error: $e");
    }
  }

  Future<void> clearApiKey() async {
    try {
      await _storage.delete(key: _storageKey);
      debugPrint("[DoIt] Cleared saved API key from FlutterSecureStorage");
    } catch (e) {
      debugPrint("[DoIt] Secure storage delete error: $e");
    }
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }

  /// Returns key info for Settings screen: source, length, and last 4 characters
  Future<({String source, int length, String last4})> getKeyInfo() async {
    final info = await getApiKeyWithSource();
    final key = info.key;
    if (key.isEmpty) {
      return (source: 'none', length: 0, last4: '----');
    }
    final last4 = key.length >= 4 ? key.substring(key.length - 4) : key;
    return (source: info.source, length: key.length, last4: last4);
  }

  /// Multi-step test connection check
  /// Tried in order: 'gemini-flash-lite-latest', 'gemma-4-26b-a4b-it', 'gemini-2.5-flash-lite'
  /// 2 seconds delay between models.
  /// Automatically picks active model = first model that returns 200 in < 15 seconds.
  Future<({bool success, int statusCode, String message, String rawResponse})> testApiKey(String keyInput) async {
    final keyInfo = await getKeyInfo();
    final cleanKey = keyInput.trim().replaceAll('\r', '').replaceAll('\n', '');

    if (cleanKey.isEmpty || keyInfo.source == 'none') {
      return (
        success: false,
        statusCode: 400,
        message: 'Key Source: NOT LOADED\nLength: 0 • Ending: ----\n\nKey not loaded. Run the app with --dart-define-from-file=env.json',
        rawResponse: '',
      );
    }

    final testModels = [
      'gemini-flash-lite-latest',
      'gemma-4-26b-a4b-it',
      'gemini-2.5-flash-lite',
    ];

    // Step 2a: GET /v1beta/models (free, timeout: 30s)
    final modelsUrl = '${AppConstants.geminiApiBaseUrl}/models';
    try {
      final responseA = await _dio.get(
        modelsUrl,
        options: Options(
          headers: {
            'x-goog-api-key': cleanKey,
            'content-type': 'application/json',
          },
          validateStatus: (status) => true,
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final statusA = responseA.statusCode ?? 500;
      final rawA = responseA.data != null ? jsonEncode(responseA.data) : '';
      debugPrint("[DoIt] Step 2a GET /models HTTP status: $statusA");

      if (statusA != 200) {
        final errDetail = _extractGoogleErrorDetail(responseA.data);
        return (
          success: false,
          statusCode: statusA,
          message: 'Key Source: ${keyInfo.source}\nLength: ${keyInfo.length} • Ending: ...${keyInfo.last4}\n\nGET /v1beta/models Failed — HTTP $statusA\nerror.status: ${errDetail.status}\nerror.message: ${errDetail.message}',
          rawResponse: rawA,
        );
      }

      int modelCount = 0;
      dynamic mapData = responseA.data;
      if (mapData is String) {
        try { mapData = jsonDecode(mapData); } catch (_) {}
      }
      if (mapData is Map && mapData['models'] is List) {
        modelCount = (mapData['models'] as List).length;
      }

      final logs = <String>[];
      logs.add('Key Source: ${keyInfo.source} | Length: ${keyInfo.length} | Ending: ...${keyInfo.last4}');
      logs.add('GET /v1beta/models: HTTP 200 ($modelCount models returned)');

      String? selectedActiveModel;
      double? selectedDuration;
      bool overallSuccess = false;

      for (int i = 0; i < testModels.length; i++) {
        if (i > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }

        final modelId = testModels[i];
        final testResult = await _testSingleModel(cleanKey, modelId);

        final durationStr = testResult.durationSeconds.toStringAsFixed(2);
        if (testResult.statusCode == 200) {
          overallSuccess = true;
          logs.add('Model [$modelId]: HTTP 200 in ${durationStr}s');

          // Select first model returning 200 in under 15 seconds
          if (selectedActiveModel == null && testResult.durationSeconds < 15.0) {
            selectedActiveModel = modelId;
            selectedDuration = testResult.durationSeconds;
          }
        } else {
          logs.add('Model [$modelId]: HTTP ${testResult.statusCode} in ${durationStr}s\nException: ${testResult.exceptionType}\nMessage: ${testResult.errorMessage}');
        }
      }

      if (selectedActiveModel != null) {
        AiQuotaService.instance.setActiveModel(selectedActiveModel, selectedDuration ?? 0.0);
        logs.add('\nActive Model Selected: $selectedActiveModel (${selectedDuration?.toStringAsFixed(2)}s)');
      }

      return (
        success: overallSuccess,
        statusCode: 200,
        message: logs.join('\n\n'),
        rawResponse: rawA,
      );
    } catch (e) {
      debugPrint("[DoIt] Test connection exception: $e");
      return (
        success: false,
        statusCode: 500,
        message: 'Network exception: $e',
        rawResponse: e.toString(),
      );
    }
  }

  Future<({int statusCode, double durationSeconds, String exceptionType, String errorMessage})> _testSingleModel(
    String apiKey,
    String modelId,
  ) async {
    final generateUrl = '${AppConstants.geminiApiBaseUrl}/models/$modelId:generateContent';
    final payload = {
      'contents': [
        {
          'parts': [
            {'text': 'Reply with the word OK'}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 8,
      }
    };

    final options = Options(
      headers: {
        'x-goog-api-key': apiKey,
        'content-type': 'application/json',
      },
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    );

    int attempt = 0;
    while (attempt < 2) {
      final stopwatch = Stopwatch()..start();
      try {
        final response = await _dio.post(generateUrl, options: options, data: payload);
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds / 1000.0;
        final statusCode = response.statusCode ?? 500;

        if (statusCode == 200) {
          return (statusCode: 200, durationSeconds: duration, exceptionType: 'None', errorMessage: 'OK');
        }

        // Check if timeout or 5xx temporary error
        if ([500, 502, 503, 504].contains(statusCode) && attempt == 0) {
          debugPrint("[DoIt] Model $modelId HTTP $statusCode. Retrying after 3 seconds...");
          await Future.delayed(const Duration(seconds: 3));
          attempt++;
          continue;
        }

        final errDetail = _extractGoogleErrorDetail(response.data);
        return (
          statusCode: statusCode,
          durationSeconds: duration,
          exceptionType: 'HttpException',
          errorMessage: 'status: ${errDetail.status}, message: ${errDetail.message}',
        );
      } on DioException catch (e) {
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds / 1000.0;
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (isTimeout && attempt == 0) {
          debugPrint("[DoIt] Model $modelId Timeout (${e.type}). Retrying after 3 seconds...");
          await Future.delayed(const Duration(seconds: 3));
          attempt++;
          continue;
        }

        return (
          statusCode: e.response?.statusCode ?? 504,
          durationSeconds: duration,
          exceptionType: e.type.toString(),
          errorMessage: e.message ?? e.toString(),
        );
      } catch (e) {
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds / 1000.0;
        return (
          statusCode: 500,
          durationSeconds: duration,
          exceptionType: e.runtimeType.toString(),
          errorMessage: e.toString(),
        );
      }
    }

    return (
      statusCode: 500,
      durationSeconds: 0.0,
      exceptionType: 'MaxRetriesExceeded',
      errorMessage: 'Failed after retry',
    );
  }

  ({String status, String message}) _extractGoogleErrorDetail(dynamic responseData) {
    String errorStatus = 'UNKNOWN';
    String errorMessage = 'No error details returned';

    dynamic parsedData = responseData;
    if (responseData is String && responseData.isNotEmpty) {
      try { parsedData = jsonDecode(responseData); } catch (_) {}
    }

    if (parsedData is Map) {
      final error = parsedData['error'];
      if (error is Map) {
        if (error['status'] != null) errorStatus = error['status'].toString();
        if (error['message'] != null) errorMessage = error['message'].toString();
      } else if (parsedData['message'] != null) {
        errorMessage = parsedData['message'].toString();
      }
    } else if (responseData != null) {
      errorMessage = responseData.toString();
    }

    return (status: errorStatus, message: errorMessage);
  }
}
