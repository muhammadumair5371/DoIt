import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/json_parser.dart';
import '../domain/models/ai_analysis_result.dart';
import 'ai_quota_service.dart';
import 'api_key_service.dart';
import 'model_probe_service.dart';
import 'network_check_service.dart';
import 'ocr_service.dart';

class AICallResult {
  final AIAnalysisResult analysis;
  final bool isSuccess;
  final int? statusCode;
  final String? errorMessage;
  final bool isApiKeyMissing;
  final String rawResponse;
  final String? modelUsed;
  final String? modeUsed;
  final double? durationSeconds;

  AICallResult({
    required this.analysis,
    required this.isSuccess,
    this.statusCode,
    this.errorMessage,
    this.isApiKeyMissing = false,
    this.rawResponse = '',
    this.modelUsed,
    this.modeUsed,
    this.durationSeconds,
  });

  List<AIAnalysisItem> get items => analysis.items;
  bool get actionable => analysis.items.isNotEmpty;
}

class AIService {
  final Dio _dio;
  final ApiKeyService _apiKeyService;
  final OCRService _ocrService;

  AIService({Dio? dio, ApiKeyService? apiKeyService, OCRService? ocrService})
      : _dio = dio ?? Dio(),
        _apiKeyService = apiKeyService ?? ApiKeyService(),
        _ocrService = ocrService ?? OCRService();

  /// Main AI classification supporting both Vision Mode and OCR Text Mode
  Future<AICallResult> classifyScreenshotImage(String imagePath) async {
    final now = DateTime.now();

    // 1. Connectivity Pre-Check (DNS lookup to generativelanguage.googleapis.com)
    final dnsResult = await NetworkCheckService.instance.checkDns();
    if (!dnsResult.success) {
      final networkErrorMsg = "No connection to Google. Check Wi-Fi, mobile data, VPN or Private DNS (${dnsResult.detail})";
      debugPrint("[DoIt] DNS pre-check failed for ${NetworkCheckService.host}: $networkErrorMsg");
      return AICallResult(
        analysis: AIAnalysisResult.empty(rawResponse: networkErrorMsg),
        isSuccess: false,
        statusCode: 0,
        errorMessage: networkErrorMsg,
        rawResponse: networkErrorMsg,
      );
    }

    // Check if quota is currently blocked
    if (AiQuotaService.instance.isQuotaBlocked) {
      debugPrint("[DoIt] AI quota is blocked until ${AiQuotaService.instance.quotaBlockedUntil}");
      return AICallResult(
        analysis: AIAnalysisResult.empty(),
        isSuccess: false,
        statusCode: 429,
        errorMessage: "AI quota reached, will retry later",
      );
    }

    final rawKey = await _apiKeyService.getApiKey();
    final apiKey = rawKey.trim().replaceAll('\r', '').replaceAll('\n', '');

    if (apiKey.isEmpty) {
      debugPrint("[DoIt] API key missing. No task created.");
      return AICallResult(
        analysis: AIAnalysisResult.empty(rawResponse: '{"items": []} (API Key Missing)'),
        isSuccess: false,
        isApiKeyMissing: true,
        errorMessage: "API key missing. Add it in Settings or env.json.",
        rawResponse: '{"items": []} (API Key Missing)',
      );
    }

    // 2. Prepare Base Image / Base64 (max side 1024px, JPEG quality 75)
    String? cleanBase64;
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          img.Image resizedImage = decodedImage;
          const maxSide = 1024;
          if (decodedImage.width > maxSide || decodedImage.height > maxSide) {
            if (decodedImage.width >= decodedImage.height) {
              resizedImage = img.copyResize(decodedImage, width: maxSide);
            } else {
              resizedImage = img.copyResize(decodedImage, height: maxSide);
            }
          }
          final jpegBytes = img.encodeJpg(resizedImage, quality: 75);
          cleanBase64 = base64Encode(jpegBytes);
        }
      }
    } catch (e) {
      debugPrint("[DoIt] Image preprocessing warning: $e");
    }

    // 3. Prepare Model Fallback Chain
    final List<String> modelChain = List.from(AppConstants.geminiModels);

    bool allModels429 = true;
    int lastStatusCode = 500;
    String lastErrorMessage = 'All models failed';

    for (final model in modelChain) {
      debugPrint("[DoIt] Evaluating model capability for: $model");

      // Feature Probe per model (cached)
      final caps = await ModelProbeService.instance.probeModel(model, apiKey, _dio);
      if (!caps.isAvailable) {
        debugPrint("[DoIt] Model $model is unavailable (HTTP ${caps.statusCode}). Path: /v1beta/models/$model:generateContent. Moving to next model.");
        lastStatusCode = caps.statusCode;
        lastErrorMessage = caps.probeLogSummary;
        if (caps.statusCode != 429) allModels429 = false;
        continue;
      }

      final String modeUsed = caps.supportsVision ? "Vision mode" : "OCR text mode";
      debugPrint("[DoIt] Processing screenshot in $modeUsed ($model)");

      // Build payload based on capabilities
      final Map<String, dynamic> payload = await _buildPayload(
        imagePath: imagePath,
        base64Image: cleanBase64,
        now: now,
        caps: caps,
      );

      final res = await _executeModelCallWithRetries(
        apiKey: apiKey,
        modelName: model,
        modeName: modeUsed,
        payload: payload,
        referenceTime: now,
        caps: caps,
      );

      if (res.isSuccess) {
        AiQuotaService.instance.updateLastStatus(200, model: model, durationSeconds: res.durationSeconds);
        return res;
      }

      lastStatusCode = res.statusCode ?? 500;
      lastErrorMessage = res.errorMessage ?? 'Model call failed';
      AiQuotaService.instance.updateLastStatus(lastStatusCode, model: model, durationSeconds: res.durationSeconds);

      if (lastStatusCode != 429) {
        allModels429 = false;
      }

      // On connection error: DO NOT switch models (model is not at fault)
      if (res.statusCode == 0 || res.errorMessage?.contains('ConnectionError') == true || res.errorMessage?.contains('SocketException') == true) {
        debugPrint("[DoIt] Connection error occurred on host ${NetworkCheckService.host}. Halting model chain to show network error.");
        return res;
      }

      // If 400, 401, 403, 404, stop trying further on this model, move to next model
      if ([400, 401, 403, 404].contains(lastStatusCode)) {
        debugPrint("[DoIt] Permanent error HTTP $lastStatusCode on model $model (path: /v1beta/models/$model:generateContent). Moving to next model.");
      }
    }

    if (allModels429) {
      debugPrint("[DoIt] All models in chain failed with HTTP 429. Blocking API for 30 minutes.");
      AiQuotaService.instance.setQuotaBlocked(const Duration(minutes: 30));
      return AICallResult(
        analysis: AIAnalysisResult.empty(rawResponse: lastErrorMessage),
        isSuccess: false,
        statusCode: 429,
        errorMessage: "AI quota reached, will retry later",
      );
    }

    return AICallResult(
      analysis: AIAnalysisResult.empty(rawResponse: lastErrorMessage),
      isSuccess: false,
      statusCode: lastStatusCode,
      errorMessage: lastErrorMessage,
    );
  }

  Future<Map<String, dynamic>> _buildPayload({
    required String imagePath,
    required String? base64Image,
    required DateTime now,
    required ModelCapabilities caps,
  }) async {
    final weekdayName = DateFormat('EEEE').format(now);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(now);
    final timeFormatted = DateFormat('HH:mm').format(now);
    final timeZoneStr = now.timeZoneName;

    final partsList = <Map<String, dynamic>>[];

    if (caps.supportsVision && base64Image != null && base64Image.isNotEmpty) {
      // Vision Mode: Include base64 JPEG in inline_data
      partsList.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image,
        }
      });
      partsList.add({
        'text': "Current local datetime: $dateFormatted $weekdayName $timeFormatted ($timeZoneStr). Analyze this screenshot."
      });
    } else {
      // OCR Text Mode: Run ML Kit OCR on device and send extracted text
      final ocrText = await _ocrService.extractTextFromImage(imagePath) ?? '';
      final promptWithOcr = '''
Current local datetime: $dateFormatted $weekdayName $timeFormatted ($timeZoneStr).

NOTE: Phone status bar clock, battery percentage, and chat bubble timestamps (e.g. 1:27 PM) are unreliable. Ignore them completely.

OCR Text extracted from screenshot:
$ocrText
''';
      partsList.add({'text': promptWithOcr});
    }

    // If systemInstruction is NOT supported, prepend system prompt to first text part
    if (!caps.supportsSystemInstruction && partsList.isNotEmpty) {
      final existingText = partsList.last['text'] as String? ?? '';
      partsList.last['text'] = "${AppConstants.aiSystemPrompt}\n\n$existingText";
    }

    final payload = <String, dynamic>{
      'contents': [
        {'parts': partsList}
      ]
    };

    if (caps.supportsSystemInstruction) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': AppConstants.aiSystemPrompt}
        ]
      };
    }

    final genConfig = <String, dynamic>{
      'temperature': 0.2,
    };

    if (caps.supportsJsonMode) {
      genConfig['responseMimeType'] = 'application/json';
    }

    payload['generationConfig'] = genConfig;

    return payload;
  }

  Future<AICallResult> _executeModelCallWithRetries({
    required String apiKey,
    required String modelName,
    required String modeName,
    required Map<String, dynamic> payload,
    required DateTime referenceTime,
    required ModelCapabilities caps,
  }) async {
    final geminiUrl = '${AppConstants.geminiApiBaseUrl}/models/$modelName:generateContent';
    final random = Random();

    // Connect timeout: 20s, Send timeout: 60s, Receive timeout: 90s (vision) / 60s (text)
    final receiveTimeoutSeconds = caps.supportsVision ? 90 : 60;
    final options = Options(
      headers: {
        'x-goog-api-key': apiKey,
        'content-type': 'application/json',
      },
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: Duration(seconds: receiveTimeoutSeconds),
    );

    int attempt = 0;
    const maxRetries = 3;

    while (attempt <= maxRetries) {
      // Connection error retry check: do NOT count connection error against hourly cap
      if (attempt == 0) {
        final canProceed = await AiQuotaService.instance.prepareApiCall();
        if (!canProceed) {
          return AICallResult(
            analysis: AIAnalysisResult.empty(),
            isSuccess: false,
            statusCode: 429,
            errorMessage: "AI quota reached, will retry later",
          );
        }
      }

      final stopwatch = Stopwatch()..start();
      try {
        final response = await _dio.post(
          geminiUrl,
          options: options,
          data: payload,
        );

        stopwatch.stop();
        final durationSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final statusCode = response.statusCode ?? 500;
        debugPrint("[DoIt] [$modelName] [$modeName] HTTP status: $statusCode in ${durationSeconds.toStringAsFixed(2)}s (attempt ${attempt + 1})");

        if (statusCode == 200 && response.data != null) {
          final candidates = response.data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates.first['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts.first['text'] as String?;
              if (text != null) {
                final parsed = SafeJsonParser.parseAIResult(text, referenceTime: referenceTime);

                if (!parsed.isValidJson) {
                  debugPrint("[DoIt] [$modelName] Response was not valid JSON. Marking call as failed.");
                  return AICallResult(
                    analysis: parsed,
                    isSuccess: false,
                    statusCode: 200,
                    errorMessage: "AI returned invalid JSON response",
                    rawResponse: text,
                    modelUsed: modelName,
                    modeUsed: modeName,
                    durationSeconds: durationSeconds,
                  );
                }

                return AICallResult(
                  analysis: parsed,
                  isSuccess: true,
                  statusCode: 200,
                  rawResponse: text,
                  modelUsed: modelName,
                  modeUsed: modeName,
                  durationSeconds: durationSeconds,
                );
              }
            }
          }
        }

        // Handle 429 (RESOURCE_EXHAUSTED)
        if (statusCode == 429) {
          final retryDelaySeconds = _extractRetryDelayInSeconds(response.data);
          final errDetail = _extractGoogleErrorDetail(response.data);

          debugPrint("[DoIt] [$modelName] 429 Quota Error. Status: ${errDetail.status}, RetryDelay: ${retryDelaySeconds}s. Msg: ${errDetail.message}");

          if (retryDelaySeconds > 0 && retryDelaySeconds <= 60 && !errDetail.message.toLowerCase().contains('daily')) {
            debugPrint("[DoIt] [$modelName] Per-minute rate limit. Waiting ${retryDelaySeconds}s once before retry.");
            await Future.delayed(Duration(seconds: retryDelaySeconds));
            attempt++;
            continue;
          } else {
            return AICallResult(
              analysis: AIAnalysisResult.empty(rawResponse: jsonEncode(response.data)),
              isSuccess: false,
              statusCode: 429,
              errorMessage: "HTTP 429 (${errDetail.status}): ${errDetail.message}",
              rawResponse: response.data != null ? jsonEncode(response.data) : 'HTTP 429',
              modelUsed: modelName,
              modeUsed: modeName,
              durationSeconds: durationSeconds,
            );
          }
        }

        // Handle 500, 502, 503, 504 server errors -> Retry up to 3 times
        if ([500, 502, 503, 504].contains(statusCode)) {
          if (attempt < maxRetries) {
            final baseDelay = attempt == 0 ? 2 : (attempt == 1 ? 5 : 10);
            final jitter = random.nextInt(1000);
            final totalDelayMs = (baseDelay * 1000) + jitter;
            debugPrint("[DoIt] [$modelName] Server $statusCode. Retrying in ${totalDelayMs}ms...");
            await Future.delayed(Duration(milliseconds: totalDelayMs));
            attempt++;
            continue;
          }
        }

        final errDetail = _extractGoogleErrorDetail(response.data);
        final fullErrStr = "HTTP $statusCode (${errDetail.status}): ${errDetail.message}";
        debugPrint("[DoIt] [$modelName] Error: $fullErrStr");

        return AICallResult(
          analysis: AIAnalysisResult.empty(rawResponse: response.data != null ? jsonEncode(response.data) : fullErrStr),
          isSuccess: false,
          statusCode: statusCode,
          errorMessage: fullErrStr,
          rawResponse: response.data != null ? jsonEncode(response.data) : fullErrStr,
          modelUsed: modelName,
          modeUsed: modeName,
          durationSeconds: durationSeconds,
        );
      } on DioException catch (e) {
        stopwatch.stop();
        final durationSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final isConnectionError = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        final errorTypeStr = e.type.toString();
        final runtimeTypeStr = e.error?.runtimeType.toString() ?? 'UnknownError';
        final errorDetailStr = e.error?.toString() ?? e.message ?? 'Connection error on ${NetworkCheckService.host}';

        final fullConnectionErrorLog =
            "DioException ($errorTypeStr) on ${NetworkCheckService.host} | ErrorType: $runtimeTypeStr | Detail: $errorDetailStr";

        debugPrint("[DoIt] [$modelName] $fullConnectionErrorLog in ${durationSeconds.toStringAsFixed(2)}s");

        // Requirement 4: On Connection Errors, retry TWICE: after 5s and after 15s. Do NOT switch models.
        if (isConnectionError) {
          if (attempt == 0) {
            debugPrint("[DoIt] [$modelName] Connection error. Retrying 1/2 after 5s...");
            await Future.delayed(const Duration(seconds: 5));
            attempt++;
            continue;
          } else if (attempt == 1) {
            debugPrint("[DoIt] [$modelName] Connection error. Retrying 2/2 after 15s...");
            await Future.delayed(const Duration(seconds: 15));
            attempt++;
            continue;
          }
        }

        return AICallResult(
          analysis: AIAnalysisResult.empty(rawResponse: fullConnectionErrorLog),
          isSuccess: false,
          statusCode: 0,
          errorMessage: fullConnectionErrorLog,
          rawResponse: fullConnectionErrorLog,
          modelUsed: modelName,
          modeUsed: modeName,
          durationSeconds: durationSeconds,
        );
      } catch (e) {
        stopwatch.stop();
        final durationSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        debugPrint("[DoIt] [$modelName] Exception in ${durationSeconds.toStringAsFixed(2)}s: $e");
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          attempt++;
          continue;
        }
        return AICallResult(
          analysis: AIAnalysisResult.empty(rawResponse: e.toString()),
          isSuccess: false,
          statusCode: 500,
          errorMessage: e.toString(),
          modelUsed: modelName,
          modeUsed: modeName,
          durationSeconds: durationSeconds,
        );
      }
    }

    return AICallResult(
      analysis: AIAnalysisResult.empty(),
      isSuccess: false,
      statusCode: 500,
      errorMessage: "Max retries exceeded on $modelName",
      modelUsed: modelName,
      modeUsed: modeName,
    );
  }

  int _extractRetryDelayInSeconds(dynamic responseData) {
    if (responseData is Map) {
      final error = responseData['error'];
      if (error is Map && error['details'] is List) {
        final details = error['details'] as List;
        for (final item in details) {
          if (item is Map && item['retryDelay'] != null) {
            final delayStr = item['retryDelay'].toString();
            final match = RegExp(r'(\d+)').firstMatch(delayStr);
            if (match != null) {
              return int.tryParse(match.group(1)!) ?? 0;
            }
          }
        }
      }
    }
    return 0;
  }

  ({String status, String message}) _extractGoogleErrorDetail(dynamic responseData) {
    String errorStatus = 'HTTP_ERROR';
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
    } else if (responseData != null && responseData.toString().isNotEmpty) {
      errorMessage = responseData.toString();
    }

    return (status: errorStatus, message: errorMessage);
  }
}
