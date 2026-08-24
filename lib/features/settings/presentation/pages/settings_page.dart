import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doc_sense/core/constants/app_constants.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/tts_service.dart';
import 'package:doc_sense/core/widgets/animated_speaker_icon.dart';
import 'package:doc_sense/core/widgets/app_dialogs.dart';
import 'package:doc_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:doc_sense/features/document/presentation/providers/document_provider.dart';
import 'package:doc_sense/features/settings/domain/entities/app_settings.dart';
import 'package:doc_sense/features/settings/presentation/providers/settings_provider.dart';
import 'package:doc_sense/features/subscription/presentation/pages/subscription_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final documentsAsync = ref.watch(savedDocumentsProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _ProfileCard(
            name: user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : 'Google account',
            email: user?.email.isNotEmpty == true
                ? user!.email
                : 'Sign in with Google to keep billing and usage synced',
            photoUrl: user?.photoUrl,
            isPremium: user?.isPremium ?? false,
            onManagePlan: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SubscriptionPage())),
          ),
          const _SectionLabel('AI & LANGUAGE'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Default language',
                subtitle: settings.defaultLanguage == null
                    ? 'Ask me every time I translate or summarize'
                    : 'Translate and summarize in '
                          '${settings.defaultLanguage}',
                trailing: settings.defaultLanguage == null
                    ? const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.buntOrange,
                      )
                    : IconButton(
                        tooltip: 'Ask every time',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.buntOrange,
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setDefaultLanguage(null),
                      ),
                onTap: () async {
                  final language = await pickLanguage(
                    context,
                    title: 'Default language',
                    subtitle: 'Used for translate and summarize.',
                  );
                  if (language == null) return;
                  await ref
                      .read(settingsProvider.notifier)
                      .setDefaultLanguage(language);
                },
              ),
            ],
          ),
          const _SectionLabel('READING'),
          _SettingsCard(
            children: [
              _SelectorTile<ReadingTextSize>(
                icon: Icons.format_size_rounded,
                title: 'Text size',
                subtitle: 'Applies to document and AI text',
                value: settings.textSize,
                values: ReadingTextSize.values,
                labelOf: (size) => size.label,
                onChanged: (size) =>
                    ref.read(settingsProvider.notifier).setTextSize(size),
              ),
              const _CardDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'The quick brown fox reads your document.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize:
                        (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                        settings.textSize.scale,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const _CardDivider(),
              _SelectorTile<ReadingSpeed>(
                icon: Icons.record_voice_over_outlined,
                title: 'Read-aloud speed',
                subtitle: 'Speed of the speaker button',
                value: settings.readingSpeed,
                values: ReadingSpeed.values,
                labelOf: (speed) => speed.label,
                onChanged: (speed) =>
                    ref.read(settingsProvider.notifier).setReadingSpeed(speed),
              ),
              const _CardDivider(),
              _SettingsTile(
                icon: Icons.play_circle_outline_rounded,
                leading: ValueListenableBuilder<bool>(
                  valueListenable: TtsService.instance.speakingListenable,
                  builder: (context, speaking, _) => AnimatedSpeakerIcon(
                    speaking: speaking,
                    color: AppColors.buntOrange,
                    size: 22,
                  ),
                ),
                title: 'Test the voice',
                subtitle: 'Hear how the current speed sounds',
                onTap: () {
                  final tts = TtsService.instance;
                  if (tts.isSpeaking) {
                    tts.stop();
                    return;
                  }
                  tts.speak(
                    'This is how your documents will be read aloud.',
                    languageOrCode: settings.defaultLanguage ?? 'english',
                  );
                },
              ),
            ],
          ),
          const _SectionLabel('STORAGE'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.folder_copy_outlined,
                title: 'Saved documents',
                subtitle: documentsAsync.when(
                  data: (docs) =>
                      '${docs.length} document'
                      '${docs.length == 1 ? '' : 's'} stored on this phone',
                  loading: () => 'Counting...',
                  error: (_, _) => 'Could not read the saved documents',
                ),
              ),
              const _CardDivider(),
              _SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear all documents',
                subtitle: 'Deletes every scan saved on this phone',
                destructive: true,
                onTap: () => _clearAllDocuments(context, ref),
              ),
            ],
          ),
          const _SectionLabel('ACCOUNT'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About ${AppConstants.appName}',
                subtitle: 'Version 1.0.0',
                onTap: () => showInfoDialog(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: '${AppConstants.appName} 1.0.0',
                  message:
                      'Scan a document, read it, and let AI translate, '
                      'summarize or answer questions about it.',
                ),
              ),
              const _CardDivider(),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'You will need to sign in again',
                destructive: true,
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Sign out?',
                    message:
                        'Your saved documents stay on this phone, but you '
                        'will need to sign in again to use the app.',
                    confirmLabel: 'Sign out',
                    destructive: true,
                  );
                  if (!confirmed) return;
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllDocuments(BuildContext context, WidgetRef ref) async {
    final documents = ref.read(savedDocumentsProvider).valueOrNull ?? [];
    final messenger = ScaffoldMessenger.of(context);

    if (documents.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('There is nothing to clear'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.delete_sweep_outlined,
      title: 'Clear all documents?',
      message:
          'All ${documents.length} saved documents will be deleted from this '
          'phone. This cannot be undone.',
      confirmLabel: 'Delete all',
      destructive: true,
    );
    if (!confirmed) return;

    final notifier = ref.read(documentProvider.notifier);
    var failed = 0;
    for (final document in documents) {
      final deleted = await notifier.delete(document.id);
      if (!deleted) failed++;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? 'All documents deleted'
              : 'Deleted ${documents.length - failed} of ${documents.length}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isPremium;
  final VoidCallback onManagePlan;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isPremium,
    required this.onManagePlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = photoUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.buntOrange, AppColors.coralGlass],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: photo != null && photo.isNotEmpty
                    ? Image.network(photo, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPremium ? 'Paid' : 'Starter',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onManagePlan,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.buntOrange,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: Text(
                isPremium ? 'Manage billing' : 'See weekly and monthly plans',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.45),
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.softBorder,
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  /// Replaces the plain icon inside the tinted square, for tiles that show
  /// something live instead — such as the speaker while it is reading.
  final Widget? leading;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = destructive ? theme.colorScheme.error : AppColors.buntOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: leading ?? Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: destructive ? accent : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings row whose value is picked from a few options shown as a
/// segmented control underneath — no extra screen to open.
class _SelectorTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _SelectorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.buntOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppColors.buntOrange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Row(
              children: [
                for (final option in values)
                  Expanded(
                    child: Material(
                      color: option == value
                          ? AppColors.buntOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onChanged(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Text(
                            labelOf(option),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: option == value
                                  ? Colors.white
                                  : AppColors.buntOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
