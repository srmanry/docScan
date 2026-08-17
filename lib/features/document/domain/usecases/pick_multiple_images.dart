import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

/// Opens the gallery picker for one or more images and returns their local
/// paths, without running OCR — lets the UI show a review grid (add/remove
/// pages) before committing to extraction.
class PickMultipleImages implements UseCase<List<String>, NoParams> {
  final DocumentRepository repository;

  const PickMultipleImages(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) => repository.pickMultipleFromGallery();
}
