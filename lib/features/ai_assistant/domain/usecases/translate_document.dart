import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';
import 'package:doc_sense/features/ai_assistant/domain/repositories/ai_repository.dart';

class TranslateParams {
  final String text;
  final String targetLanguage;
  const TranslateParams({required this.text, required this.targetLanguage});
}

class TranslateDocument implements UseCase<AiResponse, TranslateParams> {
  final AiRepository repository;

  const TranslateDocument(this.repository);

  @override
  Future<Either<Failure, AiResponse>> call(TranslateParams params) =>
      repository.translate(params.text, targetLanguage: params.targetLanguage);
}
