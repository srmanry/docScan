import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

const _languages = ['English', 'Bangla', 'Hindi', 'Arabic', 'Spanish', 'French'];

enum _Action { summarize, translate }

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  avatar: Icon(Icons.summarize_outlined,
                      size: 18,
                      color: _activeAction == _Action.summarize
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary),
                  label: const Text('Summarize'),
                  selected: _activeAction == _Action.summarize,
                  onSelected: (_) => _pickLanguageAndSummarize(),
                ),
                ChoiceChip(
                  avatar: Icon(Icons.translate,
                      size: 18,
                      color: _activeAction == _Action.translate
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary),
                  label: const Text('Translate'),
                  selected: _activeAction == _Action.translate,
                  onSelected: (_) => _pickLanguageAndTranslate(),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(response.content, style: theme.textTheme.bodyLarge),
                    ),
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
              child: Icon(Icons.auto_awesome, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Choose an action above', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Summarize or translate this document with AI',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
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
