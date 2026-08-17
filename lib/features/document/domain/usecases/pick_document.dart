import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class PickDocumentParams {
  final DocumentSourceType sourceType;
  const PickDocumentParams(this.sourceType);
}

/// Opens the camera/gallery/file picker for the requested source and
/// returns the picked file's local path — deliberately stops short of
/// running OCR so the UI can show a review step before committing to it.
class PickDocument implements UseCase<String, PickDocumentParams> {
  final DocumentRepository repository;

  const PickDocument(this.repository);

  @override
  Future<Either<Failure, String>> call(PickDocumentParams params) => switch (params.sourceType) {
        DocumentSourceType.camera => repository.captureFromCamera(),
        DocumentSourceType.gallery => repository.pickFromGallery(),
        DocumentSourceType.pdf => repository.pickPdf(),
        DocumentSourceType.textFile => repository.pickTextFile(),
      };
}
