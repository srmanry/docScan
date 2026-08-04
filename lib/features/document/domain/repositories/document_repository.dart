import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

abstract class DocumentRepository {
  /// Opens the camera, captures an image and returns its local file path.
  Future<Either<Failure, String>> captureFromCamera();

  /// Opens the gallery picker and returns the selected file path.
  Future<Either<Failure, String>> pickFromGallery();

  /// Opens the gallery picker allowing selection of one or more images.
  Future<Either<Failure, List<String>>> pickMultipleFromGallery();

  /// Opens the file picker and returns a selected PDF's local path.
  Future<Either<Failure, String>> pickPdf();

  /// Opens the file picker and returns a selected .docx/.txt file's local path.
  Future<Either<Failure, String>> pickTextFile();

  /// Runs OCR on an image file and returns the extracted, language-detected text.
  Future<Either<Failure, ScannedDocument>> extractText({
    required String filePath,
    required DocumentSourceType sourceType,
  });

  Future<Either<Failure, void>> saveDocument(ScannedDocument document);
  Future<Either<Failure, List<ScannedDocument>>> getSavedDocuments();
  Future<Either<Failure, void>> deleteDocument(String id);
}
