import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:doc_sense/core/config/api_config.dart';
import 'package:doc_sense/core/error/exceptions.dart';

/// Wraps the OCR engine. Uses Google Cloud Vision's TEXT_DETECTION because,
/// unlike Google ML Kit's on-device recognizer, it supports Bengali script
/// (ML Kit v2 only covers Latin/Chinese/Devanagari/Japanese/Korean) — required
/// for this app's Bangla document reading use case.
abstract class OcrDataSource {
  /// Returns the recognized text from the image at [filePath].
  Future<String> recognizeText(String filePath);

  /// Best-effort language detection over recognized text (e.g. 'bn', 'en').
  Future<String?> detectLanguage(String text);
}

class OcrDataSourceImpl implements OcrDataSource {
  static const _imageEndpoint = 'https://vision.googleapis.com/v1/images:annotate';
  static const _fileEndpoint = 'https://vision.googleapis.com/v1/files:annotate';

  final http.Client _client;
  String? _lastDetectedLanguage;

  OcrDataSourceImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String> recognizeText(String filePath) async {
    if (!ApiConfig.hasCloudVisionKey) {
      throw const OcrException(
        'Cloud Vision API key missing. Run with --dart-define=CLOUD_VISION_API_KEY=...',
      );
    }

    try {
      final bytes = await File(filePath).readAsBytes();
      final isPdf = filePath.toLowerCase().endsWith('.pdf');

      final response = await _client.post(
        Uri.parse('${isPdf ? _fileEndpoint : _imageEndpoint}?key=${ApiConfig.cloudVisionApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            if (isPdf)
              {
                'inputConfig': {
                  'content': base64Encode(bytes),
                  'mimeType': 'application/pdf',
                },
                'features': [
                  {'type': 'DOCUMENT_TEXT_DETECTION'}
                ],
                // Cloud Vision's sync files:annotate caps at 5 pages per
                // request; longer PDFs need the async batch API instead.
                'pages': [1, 2, 3, 4, 5],
                'imageContext': {
                  'languageHints': ['bn', 'en']
                },
              }
            else
              {
                'image': {'content': base64Encode(bytes)},
                'features': [
                  {'type': 'DOCUMENT_TEXT_DETECTION'}
                ],
                // Bengali + English hinting improves recognition accuracy;
                // Cloud Vision still auto-detects other languages present.
                'imageContext': {
                  'languageHints': ['bn', 'en']
                },
              }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw OcrException('Cloud Vision request failed (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = decoded['responses'] as List<dynamic>;
      final result = responses.first as Map<String, dynamic>;

      if (result.containsKey('error')) {
        throw OcrException((result['error'] as Map<String, dynamic>)['message'].toString());
      }

      if (isPdf) {
        final pageResponses = result['responses'] as List<dynamic>? ?? [];
        final texts = <String>[];
        Map<String, dynamic>? firstFullText;
        for (final page in pageResponses) {
          final fullText = (page as Map<String, dynamic>)['fullTextAnnotation']
              as Map<String, dynamic>?;
          firstFullText ??= fullText;
          final text = fullText?['text'] as String?;
          if (text != null && text.isNotEmpty) texts.add(text);
        }
        _lastDetectedLanguage = _extractLanguage(firstFullText);
        return texts.join('\n\n');
      }

      final fullText = result['fullTextAnnotation'] as Map<String, dynamic>?;
      _lastDetectedLanguage = _extractLanguage(fullText);

      return (fullText?['text'] as String?) ?? '';
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException(e.toString());
    }
  }

  @override
  Future<String?> detectLanguage(String text) async => _lastDetectedLanguage;

  String? _extractLanguage(Map<String, dynamic>? fullTextAnnotation) {
    final pages = fullTextAnnotation?['pages'] as List<dynamic>?;
    final property = pages?.firstOrNull as Map<String, dynamic>?;
    final detected = (property?['property']
        as Map<String, dynamic>?)?['detectedLanguages'] as List<dynamic>?;
    final first = detected?.firstOrNull as Map<String, dynamic>?;
    return first?['languageCode'] as String?;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
