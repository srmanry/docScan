import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/ai_response.dart';
import 'package:doc_sense/features/ai_assistant/domain/repositories/ai_repository.dart';

class SummarizeParams {
  final String text;
  final String? language;
  const SummarizeParams({required this.text, this.language});
}

class SummarizeDocument implements UseCase<AiResponse, SummarizeParams> {
  final AiRepository repository;

  const SummarizeDocument(this.repository);

  @override
  Future<Either<Failure, AiResponse>> call(SummarizeParams params) =>
      repository.summarize(params.text, language: params.language);
}
