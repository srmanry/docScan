import 'package:flutter/material.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/text_structure.dart';
import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

class DocumentViewerPage extends StatefulWidget {
  final ScannedDocument document;

  const DocumentViewerPage({super.key, required this.document});

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  final _tts = TtsService.instance;
  bool _speaking = false;

  Future<void> _toggleSpeak() async {
    if (_tts.isSpeaking) {
      await _tts.stop();
    } else {
      await _tts.speak(widget.document.extractedText, languageOrCode: widget.document.detectedLanguage);
    }
    if (mounted) setState(() => _speaking = _tts.isSpeaking);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = widget.document;
    final wordCount = doc.extractedText.trim().isEmpty
        ? 0
        : doc.extractedText.trim().split(RegExp(r'\s+')).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
            tooltip: _speaking ? 'Stop reading' : 'Read aloud',
            onPressed: _toggleSpeak,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Wrap(
              spacing: 8,
              children: [
                if (doc.detectedLanguage != null)
                  Chip(
                    avatar: Icon(Icons.translate, size: 16, color: theme.colorScheme.primary),
                    label: Text(doc.detectedLanguage!.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: Icon(Icons.notes, size: 16, color: theme.colorScheme.primary),
                  label: Text('$wordCount words'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: doc.extractedText.isEmpty
                      ? Text('No text was found in this document.', style: theme.textTheme.bodyLarge)
                      : _StructuredText(text: doc.extractedText, baseStyle: theme.textTheme.bodyLarge),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AiAssistantPage(document: doc)),
        ),
        icon: const Icon(Icons.psychology_outlined),
        label: const Text('Ask'),
      ),
    );
  }
}

/// Renders extracted text with light structure — bullets, "Label: value"
/// pairs, and recognized section headers get styled; everything else stays
/// exactly as plain text so an unrecognized line never loses content.
class _StructuredText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  const _StructuredText({required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final blocks = parseDocumentText(text);
    final spans = <InlineSpan>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      switch (block) {
        case HeadingBlock(:final text):
          if (i != 0) spans.add(const TextSpan(text: '\n'));
          spans.add(TextSpan(
            text: '$text\n',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.buntOrange,
              fontSize: (baseStyle?.fontSize ?? 16) + 2,
            ),
          ));
        case KeyValueBlock(:final label, :final value):
          spans.add(TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)));
          spans.add(TextSpan(text: '$value\n'));
        case BulletBlock(:final text):
          spans.add(TextSpan(text: '•  $text\n'));
        case LineBlock(:final text):
          spans.add(TextSpan(text: '$text\n'));
      }
    }

    return SelectableText.rich(TextSpan(children: spans, style: baseStyle));
  }
}
