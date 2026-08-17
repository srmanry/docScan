import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class ExtractDocumentTextParams {
  final String filePath;
  final DocumentSourceType sourceType;
  const ExtractDocumentTextParams({required this.filePath, required this.sourceType});
}

/// Runs OCR/text extraction on an already-picked file — the second half of
/// what [PickDocument] deliberately left undone.
class ExtractDocumentText implements UseCase<ScannedDocument, ExtractDocumentTextParams> {
  final DocumentRepository repository;

  const ExtractDocumentText(this.repository);

  @override
  Future<Either<Failure, ScannedDocument>> call(ExtractDocumentTextParams params) =>
      repository.extractText(filePath: params.filePath, sourceType: params.sourceType);
}
