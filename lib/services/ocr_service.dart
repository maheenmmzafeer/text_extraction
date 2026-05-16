import 'dart:io';
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum OCRLanguage { english, urdu }

class OCRService {
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const int _maxRequestsPerMinute = 15;
  static const Duration _cooldownDuration = Duration(seconds: 4);

  bool _canMakeRequest() {
    final now = DateTime.now();
    if (_lastRequestTime == null) {
      _requestCount = 1;
      _lastRequestTime = now;
      return true;
    }

    if (now.difference(_lastRequestTime!) < _cooldownDuration) {
      return false; // Cooldown active — prevent spam
    }

    if (now.difference(_lastRequestTime!).inMinutes >= 1) {
      // Reset window after a full minute
      _requestCount = 1;
      _lastRequestTime = now;
      return true;
    }

    if (_requestCount >= _maxRequestsPerMinute) {
      return false; // Rate limit reached
    }

    _requestCount++;
    _lastRequestTime = now;
    return true;
  }

  /// Processes the image and extracts text.
  Future<String> extractText(File imageFile, OCRLanguage language) async {
    try {
      if (language == OCRLanguage.urdu) {
        if (!_canMakeRequest()) {
          return "Please wait a few seconds before trying again.";
        }

        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
          return "API Key is missing. Please add your GEMINI_API_KEY to the .env file.";
        }

        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final ext = imageFile.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

        // Gemini multimodal endpoint for image-to-text extraction
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        );

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Extract only the Urdu text from this image. Output the extracted text directly without any extra formatting, markdown, or conversational text. If there is no readable Urdu text, output an empty string.',
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          },
        });

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: requestBody,
        );

        if (response.statusCode == 429) {
          return "Quota exceeded. Gemini free tier limit reached. Please wait a moment and try again.";
        }

        if (response.statusCode != 200) {
          return "API Error (${response.statusCode}): ${response.body}";
        }

        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        final extractedText = (parts
              ?.map((part) => (part['text'] as String? ?? ''))
              .join('') ??
            '')
          .trim();

        if (extractedText.isEmpty) {
          return "No text detected. Ensure the text is clear and well-lit.";
        }

        return extractedText;

      } else {
        // Use ML Kit for English — fully offline and very fast
        final inputImage = InputImage.fromFile(imageFile);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        textRecognizer.close();

        if (recognizedText.text.trim().isEmpty) {
          return "No text detected. Ensure the text is clear and well-lit.";
        }

        return recognizedText.text;
      }
    } catch (e) {
      return "Error during OCR: ${e.toString()}";
    }
  }
}
