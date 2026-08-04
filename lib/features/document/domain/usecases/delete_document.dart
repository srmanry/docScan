import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class DeleteDocument implements UseCase<void, String> {
  final DocumentRepository repository;

  const DeleteDocument(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) => repository.deleteDocument(id);
}
