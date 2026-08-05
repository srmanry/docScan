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
  final Ref _ref;

  DocumentNotifier(this._scanDocument, this._saveDocument, this._scanMultipleFromGallery, this._ref)
      : super(const DocumentIdle());

  Future<void> scan(DocumentSourceType sourceType) async {
    state = const DocumentScanning();
    final result = await _scanDocument(ScanDocumentParams(sourceType));
    await result.fold(
      (failure) async => state = DocumentError(failure.message),
      _persistAndReady,
    );
  }

  /// Lets the user pick one or more gallery images and combines them (OCR'd)
  /// into a single document.
  Future<void> scanMultipleFromGallery() async {
    state = const DocumentScanning();
    final result = await _scanMultipleFromGallery(const NoParams());
    await result.fold(
      (failure) async => state = DocumentError(failure.message),
      _persistAndReady,
    );
  }

  /// Saves the scanned document to local history so it survives app restarts
  /// and shows up on the History tab.
  Future<void> _persistAndReady(ScannedDocument document) async {
    final result = await _saveDocument(document);
    result.fold(
      (failure) => state = DocumentError(failure.message),
      (_) {
        _ref.invalidate(savedDocumentsProvider);
        state = DocumentReady(document);
      },
    );
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier(sl(), sl(), sl(), ref);
});

final savedDocumentsProvider = FutureProvider<List<ScannedDocument>>((ref) async {
  final result = await sl<GetSavedDocuments>().call(const NoParams());
  return result.fold((failure) => throw Exception(failure.message), (docs) => docs);
});
