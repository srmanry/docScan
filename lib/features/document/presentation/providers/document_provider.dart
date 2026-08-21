import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/di/injection_container.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/usecases/delete_document.dart';
import 'package:doc_sense/features/document/domain/usecases/extract_document_text.dart';
import 'package:doc_sense/features/document/domain/usecases/extract_multiple_documents_text.dart';
import 'package:doc_sense/features/document/domain/usecases/get_saved_documents.dart';
import 'package:doc_sense/features/document/domain/usecases/pick_document.dart';
import 'package:doc_sense/features/document/domain/usecases/pick_multiple_images.dart';
import 'package:doc_sense/features/document/domain/usecases/save_document.dart';
import 'package:doc_sense/core/usecase/usecase.dart';

sealed class DocumentState {
  const DocumentState();
}

class DocumentIdle extends DocumentState {
  const DocumentIdle();
}

/// Opening the camera/gallery/file picker — brief, but distinct from
/// [DocumentScanning] (which is the OCR step) so the UI can tell them apart.
class DocumentPicking extends DocumentState {
  const DocumentPicking();
}

/// A file has been picked but not yet extracted — the review step lets the
/// user confirm it's the right file (or pick another) before OCR runs.
class DocumentReviewing extends DocumentState {
  final String filePath;
  final DocumentSourceType sourceType;
  const DocumentReviewing({required this.filePath, required this.sourceType});
}

/// One or more gallery images picked but not yet extracted — the review
/// grid lets the user add/remove pages before OCR runs on all of them.
class DocumentReviewingPhotos extends DocumentState {
  final List<String> filePaths;
  const DocumentReviewingPhotos(this.filePaths);
}

class DocumentScanning extends DocumentState {
  const DocumentScanning();
}

class DocumentReady extends DocumentState {
  final ScannedDocument document;
  const DocumentReady(this.document);
}

class DocumentError extends DocumentState {
  final String message;
  const DocumentError(this.message);
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final PickDocument _pickDocument;
  final ExtractDocumentText _extractDocumentText;
  final PickMultipleImages _pickMultipleImages;
  final ExtractMultipleDocumentsText _extractMultipleDocumentsText;
  final SaveDocument _saveDocument;
  final DeleteDocument _deleteDocument;
  final Ref _ref;

  DocumentNotifier(
    this._pickDocument,
    this._extractDocumentText,
    this._pickMultipleImages,
    this._extractMultipleDocumentsText,
    this._saveDocument,
    this._deleteDocument,
    this._ref,
  ) : super(const DocumentIdle());

  /// Opens the picker/camera for [sourceType] and, on success, moves to
  /// [DocumentReviewing] so the user can confirm before OCR runs.
  Future<void> pick(DocumentSourceType sourceType) async {
    state = const DocumentPicking();
    final result = await _pickDocument(PickDocumentParams(sourceType));
    state = result.fold(
      (failure) => DocumentError(failure.message),
      (filePath) =>
          DocumentReviewing(filePath: filePath, sourceType: sourceType),
    );
  }

  /// Runs OCR on the currently-reviewed file. No-op if nothing is under review.
  Future<void> extractReviewed() async {
    final current = state;
    if (current is! DocumentReviewing) return;
    state = const DocumentScanning();
    final result = await _extractDocumentText(
      ExtractDocumentTextParams(
        filePath: current.filePath,
        sourceType: current.sourceType,
      ),
    );
    await result.fold(
      (failure) async => state = DocumentError(failure.message),
      _persistAndReady,
    );
  }

  /// Opens the gallery for a multi-image pick and moves to
  /// [DocumentReviewingPhotos] so the user can add/remove pages before OCR.
  Future<void> pickMultiple() async {
    state = const DocumentPicking();
    final result = await _pickMultipleImages(const NoParams());
    state = result.fold(
      (failure) => DocumentError(failure.message),
      (paths) =>
          paths.isEmpty ? const DocumentIdle() : DocumentReviewingPhotos(paths),
    );
  }

  /// Adds more photos to the current review selection. No-op if nothing is
  /// under review or the picker is cancelled.
  Future<void> addMorePhotos() async {
    final current = state;
    if (current is! DocumentReviewingPhotos) return;
    final result = await _pickMultipleImages(const NoParams());
    result.fold(
      (failure) =>
          null, // cancelling the picker shouldn't disrupt the review grid
      (paths) =>
          state = DocumentReviewingPhotos([...current.filePaths, ...paths]),
    );
  }

  /// Removes one photo from the current review selection.
  void removePhoto(String filePath) {
    final current = state;
    if (current is! DocumentReviewingPhotos) return;
    state = DocumentReviewingPhotos(
      current.filePaths.where((p) => p != filePath).toList(),
    );
  }

  /// Runs OCR on every reviewed photo and combines them into one document.
  /// No-op if nothing is under review.
  Future<void> extractReviewedPhotos() async {
    final current = state;
    if (current is! DocumentReviewingPhotos || current.filePaths.isEmpty) {
      return;
    }
    state = const DocumentScanning();
    final result = await _extractMultipleDocumentsText(
      ExtractMultipleDocumentsTextParams(current.filePaths),
    );
    await result.fold(
      (failure) async => state = DocumentError(failure.message),
      _persistAndReady,
    );
  }

  /// Saves the scanned document to local history so it survives app restarts
  /// and shows up on the History tab.
  Future<void> _persistAndReady(ScannedDocument document) async {
    final result = await _saveDocument(document);
    result.fold((failure) => state = DocumentError(failure.message), (_) {
      _ref.invalidate(savedDocumentsProvider);
      state = DocumentReady(document);
    });
  }

  /// Removes a document from history. Returns whether it succeeded so the
  /// caller (e.g. a delete menu item) can show an error without going
  /// through the global [DocumentState].
  Future<bool> delete(String id) async {
    final result = await _deleteDocument(id);
    return result.fold((failure) => false, (_) {
      _ref.invalidate(savedDocumentsProvider);
      return true;
    });
  }

  /// Persists document metadata changes such as favorite/important state.
  Future<bool> updateDocument(ScannedDocument document) async {
    final result = await _saveDocument(document);
    return result.fold((failure) => false, (_) {
      _ref.invalidate(savedDocumentsProvider);
      return true;
    });
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
  (ref) {
    return DocumentNotifier(sl(), sl(), sl(), sl(), sl(), sl(), ref);
  },
);

final savedDocumentsProvider = FutureProvider<List<ScannedDocument>>((
  ref,
) async {
  final result = await sl<GetSavedDocuments>().call(const NoParams());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (docs) => docs,
  );
});
