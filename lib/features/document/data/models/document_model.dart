import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

class DocumentModel extends ScannedDocument {
  const DocumentModel({
    required super.id,
    required super.title,
    required super.sourceType,
    required super.filePath,
    required super.extractedText,
    super.detectedLanguage,
    required super.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as String,
        title: json['title'] as String,
        sourceType: DocumentSourceType.values.byName(json['sourceType'] as String),
        filePath: json['filePath'] as String,
        extractedText: json['extractedText'] as String,
        detectedLanguage: json['detectedLanguage'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceType': sourceType.name,
        'filePath': filePath,
        'extractedText': extractedText,
        'detectedLanguage': detectedLanguage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DocumentModel.fromEntity(ScannedDocument doc) => DocumentModel(
        id: doc.id,
        title: doc.title,
        sourceType: doc.sourceType,
        filePath: doc.filePath,
        extractedText: doc.extractedText,
        detectedLanguage: doc.detectedLanguage,
        createdAt: doc.createdAt,
      );
}
