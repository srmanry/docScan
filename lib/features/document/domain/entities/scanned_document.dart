// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';

enum DocumentSourceType { camera, gallery, pdf, textFile }

class ScannedDocument extends Equatable {
  final String id;
  final String title;
  final DocumentSourceType sourceType;
  final String filePath;
  final String extractedText;
  final String? detectedLanguage;
  final bool? _isFavorite;
  final bool? _isImportant;
  final DateTime createdAt;

  bool get isFavorite => _isFavorite ?? false;
  bool get isImportant => _isImportant ?? false;

  const ScannedDocument({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.filePath,
    required this.extractedText,
    this.detectedLanguage,
    bool? isFavorite = false,
    bool? isImportant = false,
    required this.createdAt,
  }) : _isFavorite = isFavorite,
       _isImportant = isImportant;

  ScannedDocument copyWith({
    String? extractedText,
    String? detectedLanguage,
    bool? isFavorite,
    bool? isImportant,
  }) => ScannedDocument(
    id: id,
    title: title,
    sourceType: sourceType,
    filePath: filePath,
    extractedText: extractedText ?? this.extractedText,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    isFavorite: isFavorite ?? this.isFavorite,
    isImportant: isImportant ?? this.isImportant,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    sourceType,
    filePath,
    extractedText,
    detectedLanguage,
    isFavorite,
    isImportant,
    createdAt,
  ];
}
