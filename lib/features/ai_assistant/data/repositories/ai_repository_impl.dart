import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/ai_assistant/data/datasources/ai_remote_data_source.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_action_type.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';
import 'package:doc_sense/features/ai_assistant/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;

  const AiRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AiResponse>> summarize(String text, {String? language}) => _run(
        AiActionType.summary,
        () => remoteDataSource.summarize(text, language: language),
      );

  @override
  Future<Either<Failure, AiResponse>> explain(String text) => _run(
        AiActionType.explain,
        () => remoteDataSource.explain(text),
      );

  @override
  Future<Either<Failure, AiResponse>> translate(String text, {required String targetLanguage}) =>
      _run(
        AiActionType.translate,
        () => remoteDataSource.translate(text, targetLanguage),
      );

  @override
  Future<Either<Failure, AiResponse>> askQuestion(String context, String question) => _run(
        AiActionType.questionAnswer,
        () => remoteDataSource.answerQuestion(context, question),
      );

  Future<Either<Failure, AiResponse>> _run(
    AiActionType type,
    Future<String> Function() action,
  ) async {
    try {
      final content = await action();
      return Right(AiResponse(actionType: type, content: content));
    } on AiException catch (e) {
      return Left(AiFailure(e.message));
    }
  }
}
