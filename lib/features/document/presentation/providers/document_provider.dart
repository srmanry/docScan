import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/di/injection_container.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/domain/usecases/get_saved_documents.dart';
import 'package:doc_sense/features/document/domain/usecases/save_document.dart';
import 'package:doc_sense/features/document/domain/usecases/scan_document.dart';
import 'package:doc_sense/features/document/domain/usecases/scan_multiple_from_gallery.dart';
import 'package:doc_sense/core/usecase/usecase.dart';

sealed class DocumentState {
  const DocumentState();
}

class DocumentIdle extends DocumentState {
  const DocumentIdle();
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
  final ScanDocument _scanDocument;
  final SaveDocument _saveDocument;
  final ScanMultipleFromGallery _scanMultipleFromGallery;

  DocumentNotifier(this._scanDocument, this._saveDocument, this._scanMultipleFromGallery)
      : super(const DocumentIdle());

  Future<void> scan(DocumentSourceType sourceType) async {
    state = const DocumentScanning();
    final result = await _scanDocument(ScanDocumentParams(sourceType));
    result.fold(
      (failure) => state = DocumentError(failure.message),
      (document) => state = DocumentReady(document),
    );
  }

  /// Lets the user pick one or more gallery images and combines them (OCR'd)
  /// into a single document.
  Future<void> scanMultipleFromGallery() async {
    state = const DocumentScanning();
    final result = await _scanMultipleFromGallery(const NoParams());
    result.fold(
      (failure) => state = DocumentError(failure.message),
      (document) => state = DocumentReady(document),
    );
  }

  Future<void> save(ScannedDocument document) async {
    final result = await _saveDocument(document);
    result.fold(
      (failure) => state = DocumentError(failure.message),
      (_) => state = DocumentReady(document),
    );
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier(sl(), sl(), sl());
});

final savedDocumentsProvider = FutureProvider<List<ScannedDocument>>((ref) async {
  final result = await sl<GetSavedDocuments>().call(const NoParams());
  return result.fold((failure) => throw Exception(failure.message), (docs) => docs);
});
