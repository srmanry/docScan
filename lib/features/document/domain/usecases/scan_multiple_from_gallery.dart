import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

/// Orchestrates: pick one or more gallery images -> OCR each -> combine into
/// a single [ScannedDocument].
class ScanMultipleFromGallery implements UseCase<ScannedDocument, NoParams> {
  final DocumentRepository repository;

  const ScanMultipleFromGallery(this.repository);

  @override
  Future<Either<Failure, ScannedDocument>> call(NoParams params) async {
    final pathsResult = await repository.pickMultipleFromGallery();
    if (pathsResult is Left<Failure, List<String>>) {
      return Left(pathsResult.value);
    }
    final paths = (pathsResult as Right<Failure, List<String>>).value;

    final texts = <String>[];
    String? language;
    var lastPath = '';
    for (final path in paths) {
      final extracted =
          await repository.extractText(filePath: path, sourceType: DocumentSourceType.gallery);
      if (extracted is Left<Failure, ScannedDocument>) {
        return Left(extracted.value);
      }
      final doc = (extracted as Right<Failure, ScannedDocument>).value;
      texts.add(doc.extractedText);
      language ??= doc.detectedLanguage;
      lastPath = doc.filePath;
    }

    return Right(ScannedDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: paths.length == 1 ? paths.first.split('/').last : '${paths.length} imported photos',
      sourceType: DocumentSourceType.gallery,
      filePath: lastPath,
      extractedText: texts.join('\n\n--- Page Break ---\n\n'),
      detectedLanguage: language,
      createdAt: DateTime.now(),
    ));
  }
}
