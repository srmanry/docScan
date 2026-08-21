import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/core/widgets/app_dialogs.dart';
import 'package:doc_sense/features/ai_assistant/domain/entities/chat_turn.dart';
import 'package:doc_sense/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

enum _Action { summarize, translate, ask }

enum AiAssistantEntryAction { summarize, translate, ask }

class AiAssistantPage extends ConsumerStatefulWidget {
  final ScannedDocument document;
  final AiAssistantEntryAction? initialAction;
  final String? initialLanguage;
  final String? initialQuestion;

  const AiAssistantPage({
    super.key,
    required this.document,
    this.initialAction,
    this.initialLanguage,
    this.initialQuestion,
  });

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _tts = TtsService.instance;
  final _resultScrollController = ScrollController();
  final _chatScrollController = ScrollController();
  final _askController = TextEditingController();
  final _askFocusNode = FocusNode();
  final _chat = <_ChatTurn>[];
  _Action? _activeAction;
  String? _lastLanguage;
  bool _speaking = false;
  bool _asking = false;

  /// Questions are answered from the document unless the user asks straight
  /// from a summary or translation — then that result is the context.
  String? _askContext;
  String _askContextLabel = 'document';

  static const _askSuggestions = <({IconData icon, String text})>[
    (icon: Icons.summarize_outlined, text: 'Give me a short summary'),
    (icon: Icons.lightbulb_outline, text: 'Explain this in simpler words'),
    (
      icon: Icons.format_list_bulleted_rounded,
      text: 'What are the key points?',
    ),
    (
      icon: Icons.event_note_outlined,
      text: 'Find the important dates and numbers',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(aiProvider.notifier).reset();
      final action = widget.initialAction;
      if (action == null || !mounted) return;
      switch (action) {
        case AiAssistantEntryAction.summarize:
          final language = widget.initialLanguage;
          if (language == null || language.isEmpty) {
            await _pickLanguageAndSummarize();
          } else {
            await _runSummarize(language);
          }
        case AiAssistantEntryAction.translate:
          final language = widget.initialLanguage;
          if (language == null || language.isEmpty) {
            await _pickLanguageAndTranslate();
          } else {
            await _runTranslate(language);
          }
        case AiAssistantEntryAction.ask:
          final question = widget.initialQuestion;
          if (question == null || question.isEmpty) {
            _enterAskMode();
          } else {
            await _runAsk(question);
          }
      }
    });
  }

  Future<void> _pickLanguageAndSummarize() async {
    final language = await pickLanguage(
      context,
      title: 'Summarize document',
      subtitle: 'Choose the language for the summary.',
    );
    if (language == null || !mounted) return;
    await _runSummarize(language);
  }

  Future<void> _runSummarize(String language) async {
    if (!mounted) return;
    setState(() {
      _activeAction = _Action.summarize;
      _lastLanguage = language;
    });
    await ref
        .read(aiProvider.notifier)
        .summarize(widget.document.extractedText, language: language);
  }

  Future<void> _pickLanguageAndTranslate() async {
    final language = await pickLanguage(
      context,
      title: 'Translate document',
      subtitle: 'Choose the language to translate into.',
    );
    if (language == null || !mounted) return;
    await _runTranslate(language);
  }

  Future<void> _runTranslate(String language) async {
    if (!mounted) return;
    setState(() {
      _activeAction = _Action.translate;
      _lastLanguage = language;
    });
    await ref
        .read(aiProvider.notifier)
        .translate(widget.document.extractedText, language);
  }

  void _enterAskMode() {
    setState(() {
      _activeAction = _Action.ask;
      _lastLanguage = null;
    });
    _askFocusNode.requestFocus();
  }

  Future<void> _sendTypedQuestion() async {
    final question = _askController.text.trim();
    if (question.isEmpty) return;

    final state = ref.read(aiProvider);
    if (_activeAction != _Action.ask && state is AiSuccess) {
      final result = state.response.content;
      setState(() {
        _askContext = result;
        _askContextLabel = _activeAction == _Action.summarize
            ? 'summary'
            : 'translation';
        // Keep the result on screen as the first thing in the conversation.
        if (_chat.isEmpty) {
          _chat.add(
            _ChatTurn(text: result, kind: _TurnKind.answer, inHistory: false),
          );
        }
      });
    }

    await _runAsk(question);
  }

  Future<void> _runAsk(String question) async {
    if (!mounted || _asking) return;
    // Built before the new question is added, so it holds only what was
    // already said. Trimmed to the recent turns to keep the prompt small.
    final history = _chat
        .where((turn) => turn.inHistory && turn.kind != _TurnKind.error)
        .map(
          (turn) =>
              ChatTurn(fromUser: turn.kind == _TurnKind.user, text: turn.text),
        )
        .toList();
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    _askController.clear();
    setState(() {
      _activeAction = _Action.ask;
      _lastLanguage = null;
      _asking = true;
      _chat.add(_ChatTurn(text: question, kind: _TurnKind.user));
    });
    _scrollChatToEnd();

    await ref
        .read(aiProvider.notifier)
        .ask(
          _askContext ?? widget.document.extractedText,
          question,
          history: recentHistory,
        );
    if (!mounted) return;

    final state = ref.read(aiProvider);
    setState(() {
      _asking = false;
      if (state is AiSuccess) {
        _chat.add(
          _ChatTurn(text: state.response.content, kind: _TurnKind.answer),
        );
      } else if (state is AiError) {
        _chat.add(_ChatTurn(text: state.message, kind: _TurnKind.error));
      }
    });
    _scrollChatToEnd();
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Turns Gemini's "* bullet" lines into a proper bullet glyph.
  String _tidyBullets(String text) =>
      text.replaceAll(RegExp(r'^\*\s+', multiLine: true), '•  ');

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
    _resultScrollController.dispose();
    _chatScrollController.dispose();
    _askController.dispose();
    _askFocusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);
    final theme = Theme.of(context);
    final entryAction =
        _activeAction ??
        switch (widget.initialAction) {
          AiAssistantEntryAction.summarize => _Action.summarize,
          AiAssistantEntryAction.translate => _Action.translate,
          AiAssistantEntryAction.ask => _Action.ask,
          null => null,
        };

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (entryAction) {
          _Action.summarize => 'Summarize',
          _Action.translate => 'Translate',
          _Action.ask => 'Ask',
          null => 'Ask',
        }),
        actions: [
          if (state case AiSuccess(:final response))
            IconButton(
              icon: Icon(
                _speaking
                    ? Icons.stop_circle_outlined
                    : Icons.volume_up_outlined,
              ),
              tooltip: _speaking ? 'Stop reading' : 'Read aloud',
              onPressed: () => _toggleSpeak(response.content),
            ),
        ],
      ),
      body: Column(
        children: [
          if (entryAction == _Action.ask)
            Expanded(child: _buildAskChat(theme))
          else
            Expanded(
              child: switch (state) {
                AiIdle() => _EmptyState(theme: theme),
                AiLoading() => const Center(child: CircularProgressIndicator()),
                AiSuccess(:final response) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_lastLanguage case final language?)
                                _LanguageButton(
                                  language: language,
                                  onTap: () => _changeLanguage(
                                    entryAction ?? _Action.summarize,
                                  ),
                                ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () =>
                                    _copyToClipboard(response.content),
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
                              controller: _resultScrollController,
                              thumbVisibility: true,
                              interactive: true,
                              radius: const Radius.circular(999),
                              thickness: 3,
                              minThumbLength: 48,
                              crossAxisMargin: 2,
                              thumbColor: AppColors.buntOrange,
                              child: SingleChildScrollView(
                                controller: _resultScrollController,
                                padding: const EdgeInsets.only(right: 12),
                                child: _MarkdownLiteText(
                                  _tidyBullets(response.content),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AiError(:final message) => _ErrorState(
                  theme: theme,
                  message: message,
                ),
              },
            ),
          if (entryAction == _Action.ask || state is AiSuccess)
            _buildComposer(theme),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(_Action action) async {
    if (action == _Action.summarize) {
      await _pickLanguageAndSummarize();
    } else if (action == _Action.translate) {
      await _pickLanguageAndTranslate();
    }
  }

  Widget _buildAskChat(ThemeData theme) {
    if (_chat.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Hello there',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.buntOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How can I help with this $_askContextLabel?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            for (final suggestion in _askSuggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SuggestionChip(
                  icon: suggestion.icon,
                  label: suggestion.text,
                  onTap: () => _runAsk(suggestion.text),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _chat.length + (_asking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _chat.length) return const _ThinkingBubble();
        final turn = _chat[index];
        return _ChatBubble(
          turn: turn,
          tidyBullets: _tidyBullets,
          wordCount: _wordCount,
          onCopy: () => _copyToClipboard(turn.text),
        );
      },
    );
  }

  Widget _buildComposer(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.softBorder),
          ),
          padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _askController,
                  focusNode: _askFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  cursorColor: AppColors.buntOrange,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTypedQuestion(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: 'Ask about this $_askContextLabel',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _askController,
                builder: (context, value, _) {
                  final enabled = value.text.trim().isNotEmpty && !_asking;
                  return Material(
                    color: enabled ? AppColors.buntOrange : AppColors.peachMist,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: enabled ? _sendTypedQuestion : null,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: enabled
                              ? Colors.white
                              : AppColors.buntOrange.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The language the result is in, and the way to run it again in another.
class _LanguageButton extends StatelessWidget {
  final String language;
  final VoidCallback onTap;

  const _LanguageButton({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.peachMist,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 16,
                color: AppColors.buntOrange,
              ),
              const SizedBox(width: 8),
              Text(
                language,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.buntOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.buntOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TurnKind { user, answer, error }

class _ChatTurn {
  final String text;
  final _TurnKind kind;

  /// False for the summary/translation shown at the top of a chat: it is
  /// already the context, so sending it again would only repeat it.
  final bool inHistory;

  const _ChatTurn({
    required this.text,
    required this.kind,
    this.inHistory = true,
  });
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.buntOrange),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatTurn turn;
  final String Function(String) tidyBullets;
  final int Function(String) wordCount;
  final VoidCallback onCopy;

  const _ChatBubble({
    required this.turn,
    required this.tidyBullets,
    required this.wordCount,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (turn.kind == _TurnKind.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.buntOrange,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            turn.text,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    final isError = turn.kind == _TurnKind.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, right: 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: isError ? AppColors.peachMist : AppColors.warmWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isError)
            Text(
              turn.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.buntOrange,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            _MarkdownLiteText(
              tidyBullets(turn.text),
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: AppColors.ink,
              ),
            ),
          if (!isError)
            Row(
              children: [
                Text(
                  'Total words: ${wordCount(turn.text)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopy,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.buntOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.buntOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
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
              child: Icon(
                Icons.psychology_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose an action above', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Summarize, translate, or ask a question about this document',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
    return RichText(
      text: TextSpan(style: style, children: spans),
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
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
