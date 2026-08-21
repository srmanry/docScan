import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/text_structure.dart';
import 'package:doc_sense/core/widgets/app_dialogs.dart';
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
  final _documentScrollController = ScrollController();
  bool _speaking = false;
  Future<void> _toggleSpeak() async {
    if (_tts.isSpeaking) {
      await _tts.stop();
    } else {
      await _tts.speak(
        widget.document.extractedText,
        languageOrCode: widget.document.detectedLanguage,
      );
    }
    if (mounted) setState(() => _speaking = _tts.isSpeaking);
  }

  @override
  void dispose() {
    _documentScrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startSummarize(ScannedDocument doc) async {
    final language = await pickLanguage(
      context,
      title: 'Summarize document',
      subtitle: 'Choose the language for the summary.',
    );
    if (language == null || language.isEmpty || !mounted) return;
    _openAiScreen(
      context,
      doc,
      initialAction: AiAssistantEntryAction.summarize,
      initialLanguage: language,
    );
  }

  Future<void> _startTranslate(ScannedDocument doc) async {
    final language = await pickLanguage(
      context,
      title: 'Translate document',
      subtitle: 'Choose the language to translate into.',
    );
    if (language == null || language.isEmpty || !mounted) return;
    _openAiScreen(
      context,
      doc,
      initialAction: AiAssistantEntryAction.translate,
      initialLanguage: language,
    );
  }

  void _startAsk(ScannedDocument doc) {
    _openAiScreen(context, doc, initialAction: AiAssistantEntryAction.ask);
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: AppColors.peachMist,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _toggleSpeak,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    _speaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    color: AppColors.buntOrange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ViewerActionTile(
                    icon: Icons.translate,
                    label: 'Translate',
                    onTap: () => _startTranslate(doc),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ViewerActionTile(
                    icon: Icons.summarize_outlined,
                    label: 'Summarize',
                    onTap: () => _startSummarize(doc),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ViewerActionTile(
                    icon: Icons.question_answer_outlined,
                    label: 'Ask',
                    onTap: () => _startAsk(doc),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total words: $wordCount',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.buntOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _copyText(doc.extractedText),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.buntOrange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: RawScrollbar(
                          controller: _documentScrollController,
                          thumbVisibility: true,
                          interactive: true,
                          radius: const Radius.circular(999),
                          thickness: 3,
                          minThumbLength: 48,
                          crossAxisMargin: 2,
                          thumbColor: AppColors.buntOrange,
                          child: SingleChildScrollView(
                            controller: _documentScrollController,
                            padding: const EdgeInsets.only(right: 12),
                            child: doc.extractedText.isEmpty
                                ? Text(
                                    'No text was found in this document.',
                                    style: theme.textTheme.bodyLarge,
                                  )
                                : _StructuredText(
                                    text: doc.extractedText,
                                    baseStyle: theme.textTheme.bodyLarge,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAiScreen(
    BuildContext context,
    ScannedDocument doc, {
    AiAssistantEntryAction? initialAction,
    String? initialLanguage,
    String? initialQuestion,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiAssistantPage(
          document: doc,
          initialAction: initialAction,
          initialLanguage: initialLanguage,
          initialQuestion: initialQuestion,
        ),
      ),
    );
  }
}

class _ViewerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.buntOrange),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.buntOrange,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          spans.add(
            TextSpan(
              text: '$text\n',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.buntOrange,
                fontSize: (baseStyle?.fontSize ?? 16) + 2,
              ),
            ),
          );
        case KeyValueBlock(:final label, :final value):
          spans.add(
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
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
