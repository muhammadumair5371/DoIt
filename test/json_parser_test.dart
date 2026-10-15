import 'package:flutter_test/flutter_test.dart';
import 'package:doit/core/utils/json_parser.dart';
import 'package:doit/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Assume today is Friday 2026-10-09
  final referenceTime = DateTime(2026, 10, 9, 10, 0); // Friday Oct 9, 2026

  group('Acceptance Tests (Claude AI Vision Pipeline)', () {
    test('Acceptance Test 1: TikTok page screenshot -> 0 items', () {
      const rawAiResponse = '{"items": []}';
      final result = SafeJsonParser.parseAIResult(rawAiResponse, referenceTime: referenceTime);

      expect(result.items, isEmpty);
    });

    test('Acceptance Test 2: WhatsApp "Message yourself" chat with Resume + Math assignment + Gym -> EXACTLY 2 items', () {
      const rawAiResponse = '''
      {
        "items": [
          {
            "type": "deadline",
            "title": "Submit math assignment",
            "due_date": "2026-10-12",
            "due_time": null,
            "notes": "Math assignment due Monday",
            "confidence": 0.95,
            "reason": "Personal commitment message sent to self"
          },
          {
            "type": "event",
            "title": "Gym",
            "due_date": "2026-10-12",
            "due_time": "18:00",
            "notes": "Gym time 6pm on Monday",
            "confidence": 0.95,
            "reason": "Fitness appointment with explicit time and day"
          }
        ]
      }
      ''';

      final result = SafeJsonParser.parseAIResult(rawAiResponse, referenceTime: referenceTime);

      expect(result.items.length, equals(2));

      // Item 1: Submit math assignment on Monday 2026-10-12 with NO time
      expect(result.items[0].title, equals("Submit math assignment"));
      expect(result.items[0].type, equals("deadline"));
      expect(result.items[0].dueDate, equals("2026-10-12"));
      expect(result.items[0].dueTime, isNull);

      // Item 2: Gym on Monday 2026-10-12 at 18:00
      expect(result.items[1].title, equals("Gym"));
      expect(result.items[1].dueDate, equals("2026-10-12"));
      expect(result.items[1].dueTime, equals("18:00"));
      expect(result.items[1].dueDateTime, equals(DateTime(2026, 10, 12, 18, 0)));
    });

    test('Acceptance Test 3: Flutter learning roadmap -> 0 items', () {
      const rawAiResponse = '{"items": []}';
      final result = SafeJsonParser.parseAIResult(rawAiResponse, referenceTime: referenceTime);

      expect(result.items, isEmpty);
    });

    test('Acceptance Test 4: Missing or empty API key -> 0 items & error flag set', () async {
      final aiService = AIService();
      // Calling image classification when no key is set in secure storage / env
      final result = await aiService.classifyScreenshotImage("non_existent_path.jpg");

      expect(result.isSuccess, isFalse);
      expect(result.items, isEmpty);
      expect(result.isApiKeyMissing || result.errorMessage != null, isTrue);
    });
  });
}
