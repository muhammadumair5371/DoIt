class AIAnalysisItem {
  final String type; // task | reminder | deadline | event
  final String title;
  final String? dueDate; // YYYY-MM-DD or null
  final String? dueTime; // HH:mm or null
  final DateTime? dueDateTime; // Combined DateTime
  final String notes;
  final double confidence; // 0.0 - 1.0
  final String reason;

  AIAnalysisItem({
    required this.type,
    required this.title,
    this.dueDate,
    this.dueTime,
    this.dueDateTime,
    required this.notes,
    required this.confidence,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'due_date': dueDate,
      'due_time': dueTime,
      'notes': notes,
      'confidence': confidence,
      'reason': reason,
    };
  }
}

class AIAnalysisResult {
  final List<AIAnalysisItem> items;
  final String rawResponse;
  final bool isValidJson;

  AIAnalysisResult({
    required this.items,
    this.rawResponse = '',
    this.isValidJson = true,
  });

  factory AIAnalysisResult.empty({String rawResponse = '', bool isValidJson = true}) {
    return AIAnalysisResult(items: [], rawResponse: rawResponse, isValidJson: isValidJson);
  }
}
