import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

enum OCRLanguage { english, urdu }

class _GeminiImagePayload {
  final String mimeType;
  final String base64Data;

  const _GeminiImagePayload({
    required this.mimeType,
    required this.base64Data,
  });
}

class OCRService {
  static const Duration _cooldownDuration = Duration(seconds: 4);
  static const Duration _requestWindow = Duration(minutes: 1);
  final Map<String, List<DateTime>> _recentRequestTimesByModel = {};

  int _maxRequestsPerMinuteForModel(String modelName) {
    switch (modelName) {
      case 'gemini-2.5-flash':
        return 5;
      case 'gemini-2.5-flash-lite':
        return 10;
      default:
        return 10;
    }
  }

  Future<void> _waitForRequestSlot(String modelName) async {
    final modelHistory = _recentRequestTimesByModel.putIfAbsent(
      modelName,
      () => <DateTime>[],
    );

    while (true) {
      final now = DateTime.now();
      modelHistory.removeWhere(
        (timestamp) => now.difference(timestamp) >= _requestWindow,
      );

      final maxRequestsPerMinute = _maxRequestsPerMinuteForModel(modelName);
      final hasWindowCapacity = modelHistory.length < maxRequestsPerMinute;
      final lastRequestTime = modelHistory.isNotEmpty ? modelHistory.last : null;
      final cooldownReady =
          lastRequestTime == null ||
          now.difference(lastRequestTime) >= _cooldownDuration;

      if (hasWindowCapacity && cooldownReady) {
        modelHistory.add(now);
        return;
      }

      final nextWindowOpen = modelHistory.isNotEmpty
          ? modelHistory.first.add(_requestWindow)
          : now;
      final nextCooldownOpen = lastRequestTime == null
          ? now
          : lastRequestTime.add(_cooldownDuration);
      final nextAllowedTime = nextWindowOpen.isAfter(nextCooldownOpen)
          ? nextWindowOpen
          : nextCooldownOpen;
      final waitDuration = nextAllowedTime.difference(now);

      if (waitDuration > Duration.zero) {
        await Future<void>.delayed(waitDuration);
      }
    }
  }

  bool _looksLikeQuotaError(String body) {
    final normalized = body.toLowerCase();
    return normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('429') ||
        normalized.contains('resource_exhausted');
  }

  Future<String?> _generateGeminiText({
    required String apiKey,
    required String modelName,
    required String prompt,
    required List<_GeminiImagePayload> images,
  }) async {
    await _waitForRequestSlot(modelName);

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            ...images
                .map(
                  (image) => {
                    'inline_data': {
                      'mime_type': image.mimeType,
                      'data': image.base64Data,
                    },
                  },
                )
                .toList(),
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

    if (response.statusCode == 429 || _looksLikeQuotaError(response.body)) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('API Error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final parts = data['candidates']?[0]?['content']?['parts'] as List?;
    return (parts?.map((part) => (part['text'] as String? ?? '')).join('') ?? '')
        .trim();
  }

  /// Processes the image and extracts text.
  Future<String> extractText(
    File imageFile,
    OCRLanguage language,
  ) async {
    try {
      if (language == OCRLanguage.urdu) {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
          return "API Key is missing. Please add your GEMINI_API_KEY to the .env file.";
        }

        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final ext = imageFile.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

        const prompt =
            'Extract only the Urdu text from this image. Output the extracted text directly without any extra formatting, markdown, or conversational text. If there is no readable Urdu text, output an empty string.';

        final imagePayload = _GeminiImagePayload(
          mimeType: mimeType,
          base64Data: base64Image,
        );

        final primaryResult = await _generateGeminiText(
          apiKey: apiKey,
          modelName: 'gemini-2.5-flash-lite',
          prompt: prompt,
          images: [imagePayload],
        );

        if (primaryResult != null) {
          if (primaryResult.isEmpty) {
            return "No text detected. Ensure the text is clear and well-lit.";
          }

          return primaryResult;
        }

        final fallbackResult = await _generateGeminiText(
          apiKey: apiKey,
          modelName: 'gemini-2.5-flash',
          prompt: prompt,
          images: [imagePayload],
        );

        if (fallbackResult != null) {
          if (fallbackResult.isEmpty) {
            return "No text detected. Ensure the text is clear and well-lit.";
          }

          return fallbackResult;
        }

        if (primaryResult == null || fallbackResult == null) {
          return "Quota exceeded. Gemini free tier limit reached. Please wait a moment and try again.";
        }
      } else {
        // Use ML Kit for English. Fully offline and very fast.
        final inputImage = InputImage.fromFile(imageFile);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);

        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        textRecognizer.close();

        if (recognizedText.text.trim().isEmpty) {
          return "No text detected. Ensure the text is clear and well-lit.";
        }

        return recognizedText.text;
      }

      return "Error during OCR: unable to process the image.";
    } catch (e) {
      return "Error during OCR: ${e.toString()}";
    }
  }

  /// Renders each PDF page to an image and extracts text from the rendered pages.
  Future<String> extractTextFromPdf(
    File pdfFile,
    OCRLanguage language, {
    void Function(int processedPages, int totalPages)? onProgress,
  }) async {
    // Default: process full document using chunk helper
    return extractTextFromPdfChunk(
      pdfFile,
      language,
      startPage: 1,
      pageCount: 1 << 30,
      onProgress: onProgress,
    );
  }

  /// Extracts text for a chunk of pages from [startPage] for up to [pageCount] pages.
  /// This method adapts render scale based on document length and deletes
  /// per-page temporary images immediately to keep disk usage low.
  Future<String> extractTextFromPdfChunk(
    File pdfFile,
    OCRLanguage language, {
    required int startPage,
    required int pageCount,
    void Function(int processedPages, int totalPages)? onProgress,
  }) async {
    PdfDocument? document;
    Directory? tempDirectory;

    try {
      document = await PdfDocument.openFile(pdfFile.path);

      final totalPages = document.pagesCount;
      if (totalPages <= 0) return '';

      final fromPage = startPage.clamp(1, totalPages);
      final toPage = math.min(fromPage + pageCount - 1, totalPages);
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      // Adaptive render scale: lower scale for very large docs to save time/disk.
      final renderScale = totalPages > 80
          ? 1.15
          : totalPages > 30
              ? 1.3
              : 1.5;

      onProgress?.call(fromPage - 1, totalPages);

      final extractedPages = <String>[];
      const pagesPerRequest = 3;

      for (var batchStart = fromPage; batchStart <= toPage;) {
        final batchEnd = math.min(batchStart + pagesPerRequest - 1, toPage);
        if (language == OCRLanguage.urdu) {
          if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
            return "API Key is missing. Please add your GEMINI_API_KEY to the .env file.";
          }

          final imagePayloads = <_GeminiImagePayload>[];

          for (var pageNumber = batchStart; pageNumber <= batchEnd; pageNumber++) {
            final page = await document.getPage(pageNumber);

            try {
              final renderedPage = await page.render(
                width: page.width * renderScale,
                height: page.height * renderScale,
                format: PdfPageImageFormat.png,
                backgroundColor: '#FFFFFF',
              );

              final renderedBytes = renderedPage?.bytes;
              if (renderedBytes == null || renderedBytes.isEmpty) {
                continue;
              }

              imagePayloads.add(
                _GeminiImagePayload(
                  mimeType: 'image/png',
                  base64Data: base64Encode(renderedBytes),
                ),
              );
            } finally {
              await page.close();
            }

            onProgress?.call(pageNumber, totalPages);
          }

          if (imagePayloads.isEmpty) {
            batchStart = batchEnd + 1;
            continue;
          }

          const prompt =
              'Extract only the Urdu text from these PDF pages. Keep the output in reading order, preserve the text from each page, and do not add any markdown, numbering, or commentary. If a page has no readable Urdu text, skip it.';

          final pageText = await _generateGeminiText(
            apiKey: apiKey,
            modelName: 'gemini-2.5-flash-lite',
            prompt: prompt,
            images: imagePayloads,
          );

          final resolvedText = pageText ??
              await _generateGeminiText(
                    apiKey: apiKey,
                    modelName: 'gemini-2.5-flash',
                    prompt: prompt,
                    images: imagePayloads,
                  ) ??
              '';

          if (resolvedText.trim().isNotEmpty &&
              !resolvedText.startsWith('No text detected') &&
              !resolvedText.startsWith('API Key is missing') &&
              !resolvedText.startsWith('Please wait a few seconds')) {
            extractedPages.add(resolvedText.trim());
          }
        } else {
          tempDirectory ??=
              await Directory.systemTemp.createTemp('textsnap_pdf_ocr_');

          for (var pageNumber = batchStart; pageNumber <= batchEnd; pageNumber++) {
            final page = await document.getPage(pageNumber);
            File? pageImageFile;

            try {
              final renderedPage = await page.render(
                width: page.width * renderScale,
                height: page.height * renderScale,
                format: PdfPageImageFormat.png,
                backgroundColor: '#FFFFFF',
              );

              final renderedBytes = renderedPage?.bytes;
              if (renderedBytes == null || renderedBytes.isEmpty) {
                continue;
              }

              pageImageFile = File(
                  '${tempDirectory.path}${Platform.pathSeparator}page_$pageNumber.png');
              await pageImageFile.writeAsBytes(renderedBytes, flush: true);

              final pageText = await extractText(pageImageFile, language);
              if (pageText.trim().isNotEmpty) {
                extractedPages.add(pageText.trim());
              }
            } finally {
              await page.close();
              if (pageImageFile != null) {
                try {
                  await pageImageFile.delete();
                } catch (_) {}
              }
            }

            onProgress?.call(pageNumber, totalPages);
          }
        }

        batchStart = batchEnd + 1;
      }

      return extractedPages.join('\n\n').trim();
    } catch (e) {
      return "Error during PDF OCR: ${e.toString()}";
    } finally {
      try {
        await document?.close();
      } catch (_) {}

      if (tempDirectory != null) {
        try {
          await tempDirectory.delete(recursive: true);
        } catch (_) {}
      }
    }
  }
}
