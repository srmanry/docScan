import 'package:get_it/get_it.dart';

import 'package:doc_sense/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doc_sense/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:doc_sense/features/auth/domain/repositories/auth_repository.dart';
import 'package:doc_sense/features/auth/domain/usecases/get_current_user.dart';
import 'package:doc_sense/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:doc_sense/features/auth/domain/usecases/sign_out.dart';

import 'package:doc_sense/features/document/data/datasources/document_local_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/media_picker_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/ocr_data_source.dart';
import 'package:doc_sense/features/document/data/datasources/text_file_data_source.dart';
import 'package:doc_sense/features/document/data/repositories/document_repository_impl.dart';
import 'package:doc_sense/features/document/domain/repositories/document_repository.dart';
import 'package:doc_sense/features/document/domain/usecases/delete_document.dart';
import 'package:doc_sense/features/document/domain/usecases/get_saved_documents.dart';
import 'package:doc_sense/features/document/domain/usecases/save_document.dart';
import 'package:doc_sense/features/document/domain/usecases/scan_document.dart';
import 'package:doc_sense/features/document/domain/usecases/scan_multiple_from_gallery.dart';

import 'package:doc_sense/features/ai_assistant/data/datasources/ai_remote_data_source.dart';
import 'package:doc_sense/features/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:doc_sense/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/ask_document_question.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/summarize_document.dart';
import 'package:doc_sense/features/ai_assistant/domain/usecases/translate_document.dart';

/// Service locator. `sl` (service locator) is the conventional short name
/// used throughout the presentation layer's Riverpod providers.
final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- Auth feature ----
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory(() => SignInWithGoogle(sl()));
  sl.registerFactory(() => SignOut(sl()));
  sl.registerFactory(() => GetCurrentUser(sl()));

  // ---- Document feature ----
  sl.registerLazySingleton<MediaPickerDataSource>(() => MediaPickerDataSourceImpl());
  sl.registerLazySingleton<OcrDataSource>(() => OcrDataSourceImpl());
  sl.registerLazySingleton<TextFileDataSource>(() => TextFileDataSourceImpl());
  sl.registerLazySingleton<DocumentLocalDataSource>(() => DocumentLocalDataSourceImpl());
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(mediaPicker: sl(), ocr: sl(), textFile: sl(), local: sl()),
  );
  sl.registerFactory(() => ScanDocument(sl()));
  sl.registerFactory(() => ScanMultipleFromGallery(sl()));
  sl.registerFactory(() => SaveDocument(sl()));
  sl.registerFactory(() => GetSavedDocuments(sl()));
  sl.registerFactory(() => DeleteDocument(sl()));

  // ---- AI assistant feature ----
  sl.registerLazySingleton<AiRemoteDataSource>(() => AiRemoteDataSourceImpl());
  sl.registerLazySingleton<AiRepository>(() => AiRepositoryImpl(sl()));
  sl.registerFactory(() => SummarizeDocument(sl()));
  sl.registerFactory(() => TranslateDocument(sl()));
  sl.registerFactory(() => AskDocumentQuestion(sl()));
}
