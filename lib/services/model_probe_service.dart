import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';

class ModelCapabilities {
  final String modelName;
  final bool isAvailable;
  final bool supportsSystemInstruction;
  final bool supportsJsonMode;
  final bool supportsVision;
  final String probeLogSummary;
  final int statusCode;

  ModelCapabilities({
    required this.modelName,
    required this.isAvailable,
    required this.supportsSystemInstruction,
    required this.supportsJsonMode,
    required this.supportsVision,
    required this.probeLogSummary,
    this.statusCode = 200,
  });

  factory ModelCapabilities.unavailable(String modelName, {int statusCode = 500, String reason = ''}) {
    return ModelCapabilities(
      modelName: modelName,
      isAvailable: false,
      supportsSystemInstruction: false,
      supportsJsonMode: false,
      supportsVision: false,
      probeLogSummary: 'Unavailable (HTTP $statusCode: $reason)',
      statusCode: statusCode,
    );
  }
}

class ModelProbeService {
  static final ModelProbeService instance = ModelProbeService._internal();
  ModelProbeService._internal();

  final Map<String, ModelCapabilities> _cachedCapabilities = {};

  ModelCapabilities? getCapabilities(String modelName) => _cachedCapabilities[modelName];

  void cacheCapabilities(ModelCapabilities caps) {
    _cachedCapabilities[caps.modelName] = caps;
  }

  void clearCache() {
    _cachedCapabilities.clear();
  }

  String _generateTinyBase64Jpeg() {
    final image = img.Image(width: 10, height: 10);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final jpegBytes = img.encodeJpg(image, quality: 75);
    return base64Encode(jpegBytes);
  }

  /// Probe a specific model ONCE across the 4 feature steps:
  /// a. Plain text
  /// b. System instruction
  /// c. JSON mode
  /// d. Vision
  Future<ModelCapabilities> probeModel(String modelName, String apiKey, Dio dio) async {
    if (_cachedCapabilities.containsKey(modelName)) {
      return _cachedCapabilities[modelName]!;
    }

    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ModelCapabilities.unavailable(modelName, statusCode: 400, reason: 'API key is empty');
    }

    final generateUrl = '${AppConstants.geminiApiBaseUrl}/models/$modelName:generateContent';
    final optionsText = Options(
      headers: {
        'x-goog-api-key': cleanKey,
        'content-type': 'application/json',
      },
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    );

    final optionsVision = Options(
      headers: {
        'x-goog-api-key': cleanKey,
        'content-type': 'application/json',
      },
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
    );

    final logs = <String>[];

    // --- STEP a: Plain text probe ---
    final payloadA = {
      'contents': [
        {
          'parts': [
            {'text': 'Reply with the word OK'}
          ]
        }
      ]
    };

    final resA = await dio.post(generateUrl, options: optionsText, data: payloadA);
    final statusA = resA.statusCode ?? 500;
    logs.add('a. Plain Text: HTTP $statusA');

    if (statusA != 200) {
      final errDetail = _extractGoogleErrorDetail(resA.data);
      logs.add('Error: ${errDetail.status} - ${errDetail.message}');
      final caps = ModelCapabilities.unavailable(modelName, statusCode: statusA, reason: errDetail.message);
      _cachedCapabilities[modelName] = caps;
      return caps;
    }

    // --- STEP b: System Instruction probe ---
    bool supportsSystem = true;
    final payloadB = {
      'contents': [
        {
          'parts': [
            {'text': 'Reply with the word OK'}
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': 'System prompt test'}
        ]
      }
    };

    final resB = await dio.post(generateUrl, options: optionsText, data: payloadB);
    final statusB = resB.statusCode ?? 500;
    if (statusB != 200) {
      supportsSystem = false;
      final errDetail = _extractGoogleErrorDetail(resB.data);
      logs.add('b. SystemInstruction: HTTP $statusB (Not Supported: ${errDetail.message})');
    } else {
      logs.add('b. SystemInstruction: HTTP 200 (Supported)');
    }

    // --- STEP c: JSON mode probe ---
    bool supportsJson = true;
    final payloadC = {
      'contents': [
        {
          'parts': [
            {'text': 'Return JSON: {"status":"OK"}'}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    };

    final resC = await dio.post(generateUrl, options: optionsText, data: payloadC);
    final statusC = resC.statusCode ?? 500;
    if (statusC != 200) {
      supportsJson = false;
      final errDetail = _extractGoogleErrorDetail(resC.data);
      logs.add('c. JSON Mode: HTTP $statusC (Not Supported: ${errDetail.message})');
    } else {
      logs.add('c. JSON Mode: HTTP 200 (Supported)');
    }

    // --- STEP d: Vision probe ---
    bool supportsVision = true;
    final tinyBase64 = _generateTinyBase64Jpeg();
    final payloadD = {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': tinyBase64,
              }
            },
            {'text': 'Is this an image?'}
          ]
        }
      ]
    };

    final resD = await dio.post(generateUrl, options: optionsVision, data: payloadD);
    final statusD = resD.statusCode ?? 500;
    if (statusD != 200) {
      supportsVision = false;
      final errDetail = _extractGoogleErrorDetail(resD.data);
      logs.add('d. Vision: HTTP $statusD (Not Supported: ${errDetail.message})');
    } else {
      logs.add('d. Vision: HTTP 200 (Supported)');
    }

    final caps = ModelCapabilities(
      modelName: modelName,
      isAvailable: true,
      supportsSystemInstruction: supportsSystem,
      supportsJsonMode: supportsJson,
      supportsVision: supportsVision,
      probeLogSummary: logs.join(' | '),
      statusCode: 200,
    );

    _cachedCapabilities[modelName] = caps;
    debugPrint("[DoIt] Probed $modelName: Vision=$supportsVision, System=$supportsSystem, Json=$supportsJson");
    return caps;
  }

  ({String status, String message}) _extractGoogleErrorDetail(dynamic responseData) {
    String errorStatus = 'UNKNOWN';
    String errorMessage = 'No error message returned';

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
