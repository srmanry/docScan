import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/document/data/datasources/document_local_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/media_picker_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/ocr_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/text_file_data_source.dart';
import 'package:doc_sense/features/document/data/models/document_model.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final MediaPickerDataSource mediaPicker;
  final OcrDataSource ocr;
  final TextFileDataSource textFile;
  final DocumentLocalDataSource local;

  const DocumentRepositoryImpl({
    required this.mediaPicker,
    required this.ocr,
    required this.textFile,
    required this.local,
  });

  @override
  Future<Either<Failure, String>> captureFromCamera() =>
      _guard(mediaPicker.captureFromCamera);

  @override
  Future<Either<Failure, String>> pickFromGallery() => _guard(mediaPicker.pickFromGallery);

  @override
  Future<Either<Failure, List<String>>> pickMultipleFromGallery() async {
    try {
      return Right(await mediaPicker.pickMultipleFromGallery());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> pickPdf() => _guard(mediaPicker.pickPdf);

  @override
  Future<Either<Failure, String>> pickTextFile() => _guard(mediaPicker.pickTextFile);

  @override
  Future<Either<Failure, ScannedDocument>> extractText({
    required String filePath,
    required DocumentSourceType sourceType,
  }) async {
    try {
      final rawText = sourceType == DocumentSourceType.textFile
          ? await textFile.extractText(filePath)
          : await ocr.recognizeText(filePath);
      final text = _normalizeExtractedText(rawText);
      final language =
          sourceType == DocumentSourceType.textFile ? null : await ocr.detectLanguage(text);
      return Right(DocumentModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: filePath.split('/').last,
        sourceType: sourceType,
        filePath: filePath,
        extractedText: text,
        detectedLanguage: language,
        createdAt: DateTime.now(),
      ));
    } on OcrException catch (e) {
      return Left(OcrFailure(e.message));
    }
  }

  String _normalizeExtractedText(String text) {
    final normalizedNewlines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedNewlines.split('\n');
    final cleaned = lines
        .map((line) => line.replaceAll(RegExp(r'[ \t]+$'), ''))
        .map((line) => line.replaceFirst(RegExp(r'^\s*\*\s+'), '• '))
        .toList();

    return cleaned.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  @override
  Future<Either<Failure, void>> saveDocument(ScannedDocument document) async {
    try {
      await local.save(DocumentModel.fromEntity(document));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ScannedDocument>>> getSavedDocuments() async {
    try {
      return Right(await local.getAll());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String id) async {
    try {
      await local.delete(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Future<Either<Failure, String>> _guard(Future<String> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
