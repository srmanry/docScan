import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class SaveDocument implements UseCase<void, ScannedDocument> {
  final DocumentRepository repository;

  const SaveDocument(this.repository);

  @override
  Future<Either<Failure, void>> call(ScannedDocument params) {
    return repository.saveDocument(params);
  }
}
