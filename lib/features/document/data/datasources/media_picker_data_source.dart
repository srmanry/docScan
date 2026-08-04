import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doc_sense/core/error/exceptions.dart';

/// Wraps camera / gallery / file-picker plugins. Each method throws
/// [ServerException] if the user cancels or the platform denies permission.
abstract class MediaPickerDataSource {
  Future<String> captureFromCamera();
  Future<String> pickFromGallery();

  /// Lets the user select one or more images at once.
  Future<List<String>> pickMultipleFromGallery();

  Future<String> pickPdf();
  Future<String> pickTextFile();
}

class MediaPickerDataSourceImpl implements MediaPickerDataSource {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<String> captureFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.camera);
      if (file == null) throw const ServerException('Camera capture cancelled');
      return file.path;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> pickFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) throw const ServerException('Gallery selection cancelled');
      return file.path;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> pickMultipleFromGallery() async {
    try {
      final files = await _imagePicker.pickMultiImage();
      if (files.isEmpty) throw const ServerException('Gallery selection cancelled');
      return files.map((f) => f.path).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) throw const ServerException('PDF selection cancelled');
      return path;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> pickTextFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'txt'],
      );
      final path = result?.files.single.path;
      if (path == null) throw const ServerException('File selection cancelled');
      return path;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
