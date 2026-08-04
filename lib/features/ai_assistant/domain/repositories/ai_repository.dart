import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';

abstract class AiRepository {
  Future<Either<Failure, AiResponse>> summarize(String text, {String? language});
  Future<Either<Failure, AiResponse>> explain(String text);
  Future<Either<Failure, AiResponse>> translate(String text, {required String targetLanguage});
  Future<Either<Failure, AiResponse>> askQuestion(String context, String question);
}
