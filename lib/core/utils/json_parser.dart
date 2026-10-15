import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/models/ai_analysis_result.dart';

class SafeJsonParser {
  /// Safely extracts and parses JSON containing {"items": [...]} from raw LLM output
  static AIAnalysisResult parseAIResult(String rawResponse, {DateTime? referenceTime}) {
    referenceTime ??= DateTime.now();
    try {
      String cleanText = rawResponse.trim();

      // Strip markdown code fences if present
      if (cleanText.contains('```')) {
        final regExp = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
        final match = regExp.firstMatch(cleanText);
        if (match != null && match.group(1) != null) {
          cleanText = match.group(1)!.trim();
        } else {
          cleanText = cleanText.replaceAll('```json', '').replaceAll('```', '').trim();
        }
      }

      // Find first '{' and last '}'
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        debugPrint("[DoIt] No JSON object braces found in response");
        return AIAnalysisResult.empty(rawResponse: rawResponse, isValidJson: false);
      }

      cleanText = cleanText.substring(start, end + 1);

      final Map<String, dynamic> map = jsonDecode(cleanText);
      final List<AIAnalysisItem> parsedItems = [];

      final itemsList = map['items'] as List?;
      if (itemsList != null) {
        for (final itemRaw in itemsList) {
          if (itemRaw is! Map) continue;

          final item = Map<String, dynamic>.from(itemRaw);
          final typeStr = (item['type'] as String?)?.toLowerCase().trim() ?? 'task';
          if (!['task', 'reminder', 'deadline', 'event'].contains(typeStr)) continue;

          final title = (item['title'] as String?)?.trim() ?? '';
          if (title.isEmpty || title.length > 80) continue;

          final dueDateStr = (item['due_date'] as String?)?.trim();
          final dueTimeStr = (item['due_time'] as String?)?.trim();
          final notes = (item['notes'] as String?)?.trim() ?? '';
          final reason = (item['reason'] as String?)?.trim() ?? '';

          double confidence = 0.8;
          if (item['confidence'] is num) {
            confidence = (item['confidence'] as num).toDouble();
          } else if (item['confidence'] is String) {
            confidence = double.tryParse(item['confidence'] as String) ?? 0.8;
          }

          DateTime? combinedDue = _combineDateAndTime(dueDateStr, dueTimeStr, referenceTime: referenceTime);

          parsedItems.add(
            AIAnalysisItem(
              type: typeStr,
              title: title,
              dueDate: dueDateStr,
              dueTime: dueTimeStr,
              dueDateTime: combinedDue,
              notes: notes,
              confidence: confidence.clamp(0.0, 1.0),
              reason: reason,
            ),
          );
        }
      }

      return AIAnalysisResult(items: parsedItems, rawResponse: rawResponse, isValidJson: true);
    } catch (e) {
      debugPrint("[DoIt] SafeJsonParser JSON decode error: $e");
      return AIAnalysisResult.empty(rawResponse: rawResponse, isValidJson: false);
    }
  }

  static DateTime? _combineDateAndTime(String? dateStr, String? timeStr, {required DateTime referenceTime}) {
    if ((dateStr == null || dateStr.isEmpty || dateStr.toLowerCase() == 'null') &&
        (timeStr == null || timeStr.isEmpty || timeStr.toLowerCase() == 'null')) {
      return null;
    }

    DateTime? baseDate;
    if (dateStr != null && dateStr.isNotEmpty && dateStr.toLowerCase() != 'null') {
      baseDate = DateTime.tryParse(dateStr);
    }

    int hour = 9;
    int minute = 0;
    bool hasTime = false;

    if (timeStr != null && timeStr.isNotEmpty && timeStr.toLowerCase() != 'null') {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        hour = int.tryParse(parts[0]) ?? 9;
        minute = int.tryParse(parts[1]) ?? 0;
        hasTime = true;
      }
    }

    if (baseDate != null) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } else if (hasTime) {
      final today = DateTime(referenceTime.year, referenceTime.month, referenceTime.day, hour, minute);
      if (today.isAfter(referenceTime)) {
        return today;
      } else {
        return today.add(const Duration(days: 1));
      }
    }

    return null;
  }

  static DateTime getNextWeekday(int targetWeekday, {DateTime? referenceTime, int hour = 9, int minute = 0}) {
    referenceTime ??= DateTime.now();
    int daysAhead = targetWeekday - referenceTime.weekday;

    if (daysAhead < 0) {
      daysAhead += 7;
    } else if (daysAhead == 0) {
      final todayWithTime = DateTime(referenceTime.year, referenceTime.month, referenceTime.day, hour, minute);
      if (referenceTime.isAfter(todayWithTime)) {
        daysAhead = 7;
      }
    }

    final targetDate = referenceTime.add(Duration(days: daysAhead));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }
}
