import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractTextFromImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint("[DoIt] OCR file path does not exist: $imagePath");
        return null;
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final latinRecognized = await _textRecognizer.processImage(inputImage);
      String text = _extractTextInOrder(latinRecognized);

      text = text.trim();
      debugPrint("[DoIt] OCR chars: ${text.length}");

      if (text.length < 5) {
        debugPrint("[DoIt] Text under 5 characters, skipping OCR pipeline");
        return null;
      }
      return text;
    } catch (e) {
      debugPrint("[DoIt] OCR extraction error: $e");
      return null;
    }
  }

  /// Merges text blocks in reading order, preserving line breaks
  String _extractTextInOrder(RecognizedText recognizedText) {
    final List<String> lineTexts = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineStr = line.text.trim();
        if (lineStr.isNotEmpty) {
          lineTexts.add(lineStr);
        }
      }
    }
    return lineTexts.join('\n');
  }

  void dispose() {
    _textRecognizer.close();
  }
}
