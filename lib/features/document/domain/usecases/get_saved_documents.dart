import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class GetSavedDocuments implements UseCase<List<ScannedDocument>, NoParams> {
  final DocumentRepository repository;

  const GetSavedDocuments(this.repository);

  @override
  Future<Either<Failure, List<ScannedDocument>>> call(NoParams params) {
    return repository.getSavedDocuments();
  }
}
