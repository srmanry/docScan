import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/chat_turn.dart';
import 'package:doc_sense/features/ai_assistant/domain/repositories/ai_repository.dart';

class AskQuestionParams {
  final String context;
  final String question;
  final List<ChatTurn> history;

  const AskQuestionParams({
    required this.context,
    required this.question,
    this.history = const [],
  });
}

class AskDocumentQuestion implements UseCase<AiResponse, AskQuestionParams> {
  final AiRepository repository;

  const AskDocumentQuestion(this.repository);

  @override
  Future<Either<Failure, AiResponse>> call(AskQuestionParams params) =>
      repository.askQuestion(
        params.context,
        params.question,
        history: params.history,
      );
}
