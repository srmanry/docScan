import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

const _languages = ['English', 'Bangla', 'Hindi', 'Arabic', 'Spanish', 'French'];

enum _Action { summarize, translate, ask }

class AiAssistantPage extends ConsumerStatefulWidget {
  final ScannedDocument document;

  const AiAssistantPage({super.key, required this.document});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _tts = TtsService.instance;
  _Action? _activeAction;
  String? _lastLanguage;
  bool _speaking = false;

  Future<void> _pickLanguageAndSummarize() async {
    final language = await _pickLanguage(title: 'Summarize in which language?');
    if (language == null || !mounted) return;
    setState(() {
      _activeAction = _Action.summarize;
      _lastLanguage = language;
    });
    ref.read(aiProvider.notifier).summarize(widget.document.extractedText, language: language);
  }

  Future<void> _pickLanguageAndTranslate() async {
    final language = await _pickLanguage(title: 'Translate to which language?');
    if (language == null || !mounted) return;
    setState(() {
      _activeAction = _Action.translate;
      _lastLanguage = language;
    });
    ref.read(aiProvider.notifier).translate(widget.document.extractedText, language);
  }

  Future<void> _promptAndAsk() async {
    final question = await _promptQuestion();
    if (question == null || question.isEmpty || !mounted) return;
    setState(() {
      _activeAction = _Action.ask;
      _lastLanguage = null;
    });
    ref.read(aiProvider.notifier).ask(widget.document.extractedText, question);
  }

  Future<String?> _promptQuestion() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask about this document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'e.g. What is the total amount due?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ask'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  IconData _iconFor(_Action? action) => switch (action) {
        _Action.summarize => Icons.summarize_outlined,
        _Action.translate => Icons.translate,
        _Action.ask => Icons.question_answer_outlined,
        null => Icons.psychology_outlined,
      };

  String _labelFor(_Action? action) => switch (action) {
        _Action.summarize => 'Summary',
        _Action.translate => 'Translation',
        _Action.ask => 'Answer',
        null => 'Response',
      };

  /// Turns Gemini's "* bullet" lines into a proper bullet glyph.
  String _tidyBullets(String text) => text.replaceAll(RegExp(r'^\*\s+', multiLine: true), '•  ');

  Future<void> _toggleSpeak(String text) async {
    if (_tts.isSpeaking) {
      await _tts.stop();
    } else {
      await _tts.speak(text, languageOrCode: _lastLanguage);
    }
    if (mounted) setState(() => _speaking = _tts.isSpeaking);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<String?> _pickLanguage({required String title}) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final lang in _languages)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, lang),
              child: Text(lang),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '__other__'),
            child: const Text('Other…'),
          ),
        ],
      ),
    );

    if (choice != '__other__') return choice;
    if (!mounted) return null;
    return _promptCustomLanguage();
  }

  Future<String?> _promptCustomLanguage() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Which language?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Urdu, Japanese'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI'),
        actions: [
          if (state case AiSuccess(:final response))
            IconButton(
              icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              tooltip: _speaking ? 'Stop reading' : 'Read aloud',
              onPressed: () => _toggleSpeak(response.content),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.summarize_outlined,
                    label: 'Summarize',
                    selected: _activeAction == _Action.summarize,
                    onTap: _pickLanguageAndSummarize,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.translate,
                    label: 'Translate',
                    selected: _activeAction == _Action.translate,
                    onTap: _pickLanguageAndTranslate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.question_answer_outlined,
                    label: 'Ask',
                    selected: _activeAction == _Action.ask,
                    onTap: _promptAndAsk,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state) {
              AiIdle() => _EmptyState(theme: theme),
              AiLoading() => const Center(child: CircularProgressIndicator()),
              AiSuccess(:final response) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Icon(_iconFor(_activeAction), size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              _labelFor(_activeAction),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              tooltip: 'Copy',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _copyToClipboard(response.content),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: _MarkdownLiteText(
                          _tidyBullets(response.content),
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              AiError(:final message) => _ErrorState(theme: theme, message: message),
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_outlined, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Choose an action above', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Summarize, translate, or ask a question about this document',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders `**bold**` markers from the AI response as actual bold text,
/// without pulling in a full markdown package for one formatting rule.
class _MarkdownLiteText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _MarkdownLiteText(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    final boldStyle = style?.copyWith(fontWeight: FontWeight.w700);
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return RichText(text: TextSpan(style: style, children: spans));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeData theme;
  final String message;
  const _ErrorState({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
