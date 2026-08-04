import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:doc_sense/core/error/exceptions.dart';

/// Extracts text directly from files that already contain text (.txt, .docx),
/// skipping OCR entirely — no Cloud Vision call, no API key needed.
abstract class TextFileDataSource {
  Future<String> extractText(String filePath);
}

class TextFileDataSourceImpl implements TextFileDataSource {
  @override
  Future<String> extractText(String filePath) async {
    try {
      if (filePath.toLowerCase().endsWith('.docx')) {
        return _extractDocx(await File(filePath).readAsBytes());
      }
      return await File(filePath).readAsString();
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Could not read file: $e');
    }
  }

  String _extractDocx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.files
        .where((f) => f.name == 'word/document.xml')
        .firstOrNull;

    if (documentFile == null) {
      throw const OcrException('Not a valid .docx file');
    }

    final xmlString = utf8.decode(documentFile.content as List<int>);
    final document = XmlDocument.parse(xmlString);

    final paragraphs = <String>[];
    for (final paragraph in document.findAllElements('w:p')) {
      final text = paragraph.findAllElements('w:t').map((e) => e.innerText).join();
      paragraphs.add(text);
    }

    return paragraphs.join('\n').trim();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
