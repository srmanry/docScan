import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class ScanDocumentParams {
  final DocumentSourceType sourceType;
  const ScanDocumentParams(this.sourceType);
}

/// Orchestrates: pick/capture a file -> run OCR -> return a [ScannedDocument].
class ScanDocument implements UseCase<ScannedDocument, ScanDocumentParams> {
  final DocumentRepository repository;

  const ScanDocument(this.repository);

  @override
  Future<Either<Failure, ScannedDocument>> call(ScanDocumentParams params) async {
    final Either<Failure, String> pathResult = switch (params.sourceType) {
      DocumentSourceType.camera => await repository.captureFromCamera(),
      DocumentSourceType.gallery => await repository.pickFromGallery(),
      DocumentSourceType.pdf => await repository.pickPdf(),
      DocumentSourceType.textFile => await repository.pickTextFile(),
    };

    return pathResult.fold(
      (failure) => Left(failure),
      (filePath) => repository.extractText(filePath: filePath, sourceType: params.sourceType),
    );
  }
}
