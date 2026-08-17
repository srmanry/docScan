import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class ExtractMultipleDocumentsTextParams {
  final List<String> filePaths;
  const ExtractMultipleDocumentsTextParams(this.filePaths);
}

/// Runs OCR on each already-picked image and combines the results into a
/// single [ScannedDocument] — the second half of what [PickMultipleImages]
/// deliberately left undone.
class ExtractMultipleDocumentsText
    implements UseCase<ScannedDocument, ExtractMultipleDocumentsTextParams> {
  final DocumentRepository repository;

  const ExtractMultipleDocumentsText(this.repository);

  @override
  Future<Either<Failure, ScannedDocument>> call(ExtractMultipleDocumentsTextParams params) async {
    final texts = <String>[];
    String? language;
    var lastPath = '';

    for (final path in params.filePaths) {
      final extracted =
          await repository.extractText(filePath: path, sourceType: DocumentSourceType.gallery);
      if (extracted is Left<Failure, ScannedDocument>) return Left(extracted.value);
      final doc = (extracted as Right<Failure, ScannedDocument>).value;
      texts.add(doc.extractedText);
      language ??= doc.detectedLanguage;
      lastPath = doc.filePath;
    }

    return Right(ScannedDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: params.filePaths.length == 1
          ? params.filePaths.first.split('/').last
          : '${params.filePaths.length} imported photos',
      sourceType: DocumentSourceType.gallery,
      filePath: lastPath,
      extractedText: texts.join('\n\n--- Page Break ---\n\n'),
      detectedLanguage: language,
      createdAt: DateTime.now(),
    ));
  }
}
