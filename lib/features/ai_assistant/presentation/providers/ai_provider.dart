import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/di/injection_container.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/ask_document_question.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/summarize_document.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/translate_document.dart';

sealed class AiState {
  const AiState();
}

class AiIdle extends AiState {
  const AiIdle();
}

class AiLoading extends AiState {
  const AiLoading();
}

class AiSuccess extends AiState {
  final AiResponse response;
  const AiSuccess(this.response);
}

class AiError extends AiState {
  final String message;
  const AiError(this.message);
}

class AiNotifier extends StateNotifier<AiState> {
  final SummarizeDocument _summarize;
  final TranslateDocument _translate;
  final AskDocumentQuestion _askQuestion;

  AiNotifier(this._summarize, this._translate, this._askQuestion) : super(const AiIdle());

  Future<void> summarize(String text, {String? language}) =>
      _dispatch(() => _summarize(SummarizeParams(text: text, language: language)));

  Future<void> translate(String text, String targetLanguage) => _dispatch(
        () => _translate(TranslateParams(text: text, targetLanguage: targetLanguage)),
      );

  Future<void> ask(String context, String question) => _dispatch(
        () => _askQuestion(AskQuestionParams(context: context, question: question)),
      );

  Future<void> _dispatch(Future<dynamic> Function() call) async {
    state = const AiLoading();
    final result = await call();
    result.fold(
      (failure) => state = AiError(failure.message),
      (response) => state = AiSuccess(response),
    );
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(sl(), sl(), sl());
});
