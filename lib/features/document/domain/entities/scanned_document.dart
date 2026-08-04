import 'package:equatable/equatable.dart';

enum DocumentSourceType { camera, gallery, pdf, textFile }

class ScannedDocument extends Equatable {
  final String id;
  final String title;
  final DocumentSourceType sourceType;
  final String filePath;
  final String extractedText;
  final String? detectedLanguage;
  final DateTime createdAt;

  const ScannedDocument({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.filePath,
    required this.extractedText,
    this.detectedLanguage,
    required this.createdAt,
  });

  ScannedDocument copyWith({String? extractedText, String? detectedLanguage}) => ScannedDocument(
        id: id,
        title: title,
        sourceType: sourceType,
        filePath: filePath,
        extractedText: extractedText ?? this.extractedText,
        detectedLanguage: detectedLanguage ?? this.detectedLanguage,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, sourceType, filePath, extractedText, detectedLanguage, createdAt];
}
