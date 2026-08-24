import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doc_sense/core/router/app_router.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/document_style.dart';
import 'package:doc_sense/core/utils/format.dart';
import 'package:doc_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/presentation/pages/document_viewer_page.dart';
import 'package:doc_sense/features/document/presentation/pages/review_document_page.dart';
import 'package:doc_sense/features/document/presentation/pages/review_photos_page.dart';
import 'package:doc_sense/features/document/presentation/providers/document_provider.dart';
import 'package:doc_sense/features/document/presentation/widgets/scanning_progress_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DocumentState>(documentProvider, (previous, next) {
      // The "previous isn't already this type" guard matters here: adding or
      // removing a page inside the review screens re-emits the same state
      // type, and without the guard that would push a duplicate page on top
      // of itself instead of letting the open review page just rebuild.
      if (next is DocumentReviewing && previous is! DocumentReviewing) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewDocumentPage(
              filePath: next.filePath,
              sourceType: next.sourceType,
            ),
          ),
        );
      } else if (next is DocumentReviewingPhotos &&
          previous is! DocumentReviewingPhotos) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReviewPhotosPage()));
      } else if (next is DocumentReady) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerPage(document: next.document),
          ),
        );
      } else if (next is DocumentError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(documentProvider);

    return Scaffold(
      extendBody: true,
      // bottom: false so the list runs under the frosted nav bar instead of
      // stopping above it.
      body: SafeArea(
        bottom: false,
        child: switch (state) {
          DocumentPicking() => const Center(child: CircularProgressIndicator()),
          DocumentScanning() => const ScanningProgressView(),
          _ => const _HomeContent(),
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /* String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  } */

  /// Fades + slides [child] down-to-up as [_entrance] plays, staggered by
  /// [index] so each section visibly arrives after the previous one instead
  /// of everything blurring together in one quick burst.
  Widget _staggered(int index, Widget child) {
    final start = (index * 0.18).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * -40),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final notifier = ref.read(documentProvider.notifier);
    final documentsAsync = ref.watch(savedDocumentsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _staggered(0, _TopBar(photoUrl: user?.photoUrl)),
          const SizedBox(height: 10),
          /* _staggered(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $firstName 👋',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'What would you like to do today?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15), */
          _staggered(
            2,
            _ScanHeroCard(
              onTap: () => notifier.pick(DocumentSourceType.camera),
            ),
          ),
          const SizedBox(height: 10),
          _staggered(
            3,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final cardWidth = (constraints.maxWidth - (gap * 2)) / 3;

                    return Row(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _QuickActionCard(
                            asset: 'assets/images/gallery.png',
                            title: 'Gallery',
                            subtitle: 'Upload Images',
                            badgeColor: const Color(0xFFFFE4D6),
                            onTap: notifier.pickMultiple,
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: cardWidth,
                          child: _QuickActionCard(
                            asset: 'assets/images/pdf.png',
                            title: 'PDF',
                            subtitle: 'Upload PDF file',
                            badgeColor: const Color(0xFFFFE2E2),
                            onTap: () => notifier.pick(DocumentSourceType.pdf),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: cardWidth,
                          child: _QuickActionCard(
                            asset: 'assets/images/doc.png',
                            title: 'DOCX',
                            subtitle: 'Upload Word file',
                            badgeColor: const Color(0xFFDDEBFF),
                            onTap: () =>
                                notifier.pick(DocumentSourceType.textFile),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _staggered(
              4,
              _RecentDocumentsSection(documentsAsync: documentsAsync),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDocumentsSection extends ConsumerWidget {
  final AsyncValue<List<ScannedDocument>> documentsAsync;
  const _RecentDocumentsSection({required this.documentsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Documents', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () =>
                  ref.read(rootTabIndexProvider.notifier).state = 1,
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: documentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '$error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (documents) {
              if (documents.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Scan or import a document to see it here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final recent = documents.take(3).toList();
              return ListView.separated(
                padding: const EdgeInsets.only(top: 4, bottom: 120),
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _DocumentCard(document: recent[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? photoUrl;
  const _TopBar({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.buntOrange, AppColors.coralGlass],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.folder_special_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Docora',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.buntOrange,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Icon(Icons.person_outline, color: theme.colorScheme.primary)
              : null,
        ),
      ],
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.buntOrange, AppColors.coralGlass],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan a Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Turn paper into clean, searchable text.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon(Icons.camera_alt_outlined, color: AppColors.buntOrange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Scan with Camera',
                            style: TextStyle(
                              color: AppColors.buntOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          /* Icon(Icons.arrow_forward, color: AppColors.buntOrange, size: 18),
                          SizedBox(width: 6), */
                          Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.buntOrange,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          /*   Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 34),
          ), */
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.k2d(
                  color: theme.colorScheme.onSurface,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final ScannedDocument document;
  const _DocumentCard({required this.document});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.warmWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Text(
          'Delete document?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${document.title}" will be permanently removed.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buntOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(documentProvider.notifier).delete(document.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Document deleted' : 'Could not delete document'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = documentIconStyle(document.sourceType);
    final sizeLabel = () {
      try {
        return formatFileSize(File(document.filePath).lengthSync());
      } catch (_) {
        return null;
      }
    }();

    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerPage(document: document),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: icon.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset(icon.asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        ?sizeLabel,
                        formatDocumentTimestamp(document.createdAt),
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    /*  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.peachMist, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        document.detectedLanguage ?? 'English',
                        style: const TextStyle(color: AppColors.buntOrange, fontSize: 11, fontWeight: FontWeight.w600),
                      ), */
                    //),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    position: PopupMenuPosition.under,
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onSelected: (value) async {
                      if (value == 'favorite') {
                        await ref
                            .read(documentProvider.notifier)
                            .updateDocument(
                              document.copyWith(
                                isFavorite: !document.isFavorite,
                              ),
                            );
                      } else if (value == 'important') {
                        await ref
                            .read(documentProvider.notifier)
                            .updateDocument(
                              document.copyWith(
                                isImportant: !document.isImportant,
                              ),
                            );
                      } else if (value == 'delete') {
                        await _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              document.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: document.isFavorite
                                  ? AppColors.buntOrange
                                  : AppColors.ink,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Favorite',
                              style: TextStyle(
                                color: document.isFavorite
                                    ? AppColors.buntOrange
                                    : AppColors.ink,
                                fontWeight: document.isFavorite
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'important',
                        child: Row(
                          children: [
                            Icon(
                              document.isImportant
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: document.isImportant
                                  ? AppColors.buntOrange
                                  : AppColors.ink,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Important',
                              style: TextStyle(
                                color: document.isImportant
                                    ? AppColors.buntOrange
                                    : AppColors.ink,
                                fontWeight: document.isImportant
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
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
