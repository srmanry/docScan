import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:doc_sense/core/config/api_config.dart';
import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/chat_turn.dart';

/// Wraps whichever LLM provider is chosen (OpenAI / Gemini / Claude).
/// Keeping this behind an interface means switching providers later is
/// a one-file change, not a rewrite of the AI feature.
abstract class AiRemoteDataSource {
  Future<String> summarize(String text, {String? language});
  Future<String> explain(String text);
  Future<String> translate(String text, String targetLanguage);
  Future<String> answerQuestion(
    String context,
    String question, {
    List<ChatTurn> history,
  });
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final http.Client _client;

  AiRemoteDataSourceImpl({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String> summarize(String text, {String? language}) => _generate(
    'Summarize the following document. Keep it concise.'
    '${language != null ? ' Write the summary in $language.' : ''}\n\n$text',
  );

  @override
  Future<String> explain(String text) =>
      _generate('Explain the following document in simple terms:\n\n$text');

  @override
  Future<String> translate(String text, String targetLanguage) => _generate(
    'Translate the following document to $targetLanguage. '
    'Return only the translation, no extra commentary:\n\n$text',
  );

  @override
  Future<String> answerQuestion(
    String context,
    String question, {
    List<ChatTurn> history = const [],
  }) {
    // The document goes in as the opening turn so the whole conversation
    // after it can be sent as-is, and follow-ups keep their context.
    final contents = [
      _turn(
        'user',
        'Answer the questions that follow using only this document as '
            'context. If the answer is not in it, say so.\n\n'
            'Document:\n$context',
      ),
      _turn('model', 'Understood. Ask me anything about this document.'),
      for (final turn in history)
        _turn(turn.fromUser ? 'user' : 'model', turn.text),
      _turn('user', question),
    ];

    return _generateContents(contents);
  }

  Map<String, dynamic> _turn(String role, String text) => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };

  Future<String> _generate(String prompt) =>
      _generateContents([_turn('user', prompt)]);

  Future<String> _generateContents(List<Map<String, dynamic>> contents) async {
    if (!ApiConfig.hasGeminiKey) {
      throw const AiException(
        'Gemini API key missing. Run with --dart-define=GEMINI_API_KEY=...',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse('$_endpoint?key=${ApiConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final message =
            (decoded['error'] as Map<String, dynamic>?)?['message']
                as String? ??
            'Gemini request failed (${response.statusCode})';
        throw AiException(message);
      }

      final candidates = decoded['candidates'] as List<dynamic>?;
      final content = candidates?.firstOrNull as Map<String, dynamic>?;
      final parts =
          (content?['content'] as Map<String, dynamic>?)?['parts']
              as List<dynamic>?;
      final text =
          (parts?.firstOrNull as Map<String, dynamic>?)?['text'] as String?;

      if (text == null || text.isEmpty) {
        throw const AiException('Gemini returned an empty response');
      }

      return text;
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(e.toString());
    }
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
