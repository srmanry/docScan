import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/document_style.dart';
import 'package:doc_sense/core/utils/format.dart';
import 'package:doc_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/presentation/pages/document_viewer_page.dart';
import 'package:doc_sense/features/document/presentation/providers/document_provider.dart';

enum _HistoryFilter { all, scanned, important, favorites }

/// Lists previously scanned documents.
/// Reuses the document feature's domain layer (GetSavedDocuments) rather
/// than duplicating a "history" entity — it's the same data, one read model.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _searchController = TextEditingController();
  _HistoryFilter _filter = _HistoryFilter.all;
  // bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(ScannedDocument doc) => switch (_filter) {
    _HistoryFilter.all => true,
    _HistoryFilter.scanned =>
      doc.sourceType == DocumentSourceType.camera ||
          doc.sourceType == DocumentSourceType.gallery,
    _HistoryFilter.important => doc.isImportant,
    _HistoryFilter.favorites => doc.isFavorite,
  };

  Future<void> _toggleFavorite(ScannedDocument doc) async {
    final ok = await ref
        .read(documentProvider.notifier)
        .updateDocument(doc.copyWith(isFavorite: !doc.isFavorite));
    if (!mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not update favorite')));
  }

  Future<void> _toggleImportant(ScannedDocument doc) async {
    final ok = await ref
        .read(documentProvider.notifier)
        .updateDocument(doc.copyWith(isImportant: !doc.isImportant));
    if (!mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not update important')));
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(savedDocumentsProvider);
    final authState = ref.watch(authProvider);
    final photoUrl = authState is AuthAuthenticated
        ? authState.user.photoUrl
        : null;
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      // bottom: false so the list runs under the frosted nav bar instead of
      // stopping above it.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _Header(photoUrl: photoUrl),
            ),
            const SizedBox(height: 18),
            _FilterChipsRow(
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchAndSortRow(
                controller: _searchController,
                // newestFirst: _newestFirst,
                onSearchChanged: () => setState(() {}),
                // onToggleSort: () =>
                //     setState(() => _newestFirst = !_newestFirst),
              ),
            ),
            Expanded(
              child: documentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (documents) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered =
                      documents.where(_matchesFilter).where((doc) {
                        return query.isEmpty ||
                            doc.title.toLowerCase().contains(query);
                      }).toList()..sort(
                        // Keep newest-first ordering only.
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      );

                  if (documents.isEmpty) {
                    return _EmptyState(
                      icon: Icons.history,
                      title: 'No scanned documents yet',
                      subtitle: 'Documents you scan or save will show up here',
                    );
                  }
                  if (filtered.isEmpty) {
                    return _EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching documents',
                      subtitle: 'Try a different search or filter',
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    children: _buildGroupedList(filtered, theme),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    List<ScannedDocument> documents,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];
    String? currentGroup;
    for (final doc in documents) {
      final group = formatDateGroup(doc.createdAt);
      if (group != currentGroup) {
        if (currentGroup != null) widgets.add(const SizedBox(height: 14));
        currentGroup = group;
        widgets.add(
          Text(
            group,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(
        _HistoryDocumentCard(
          document: doc,
          isFavorite: doc.isFavorite,
          isImportant: doc.isImportant,
          onToggleFavorite: () => _toggleFavorite(doc),
          onToggleImportant: () => _toggleImportant(doc),
        ),
      );
    }
    return widgets;
  }
}

class _Header extends StatelessWidget {
  final String? photoUrl;
  const _Header({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'All your scanned and imported documents',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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

class _FilterChipsRow extends StatelessWidget {
  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onSelected;
  const _FilterChipsRow({required this.selected, required this.onSelected});

  static const _items = [
    (
      filter: _HistoryFilter.all,
      icon: Icons.document_scanner_outlined,
      label: 'All',
    ),
    (
      filter: _HistoryFilter.important,
      icon: Icons.star_rounded,
      label: 'Important',
    ),
    (
      filter: _HistoryFilter.favorites,
      icon: Icons.favorite_border_rounded,
      label: 'Favorites',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  icon: _items[i].icon,
                  label: _items[i].label,
                  selected: _items[i].filter == selected,
                  onTap: () => onSelected(_items[i].filter),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.peachMist : AppColors.warmWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.buntOrange : AppColors.softBorder,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.buntOrange : AppColors.ink,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? AppColors.buntOrange : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchAndSortRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchChanged;
  const _SearchAndSortRow({
    required this.controller,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onSearchChanged(),
      decoration: const InputDecoration(
        hintText: 'Search documents...',
        prefixIcon: Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}

class _HistoryDocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final bool isFavorite;
  final bool isImportant;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleImportant;
  const _HistoryDocumentCard({
    required this.document,
    required this.isFavorite,
    required this.isImportant,
    required this.onToggleFavorite,
    required this.onToggleImportant,
  });

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
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: icon.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(icon.asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        ?sizeLabel,
                        formatDocumentTimestamp(document.createdAt),
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Consumer(
                    builder: (context, ref, _) => PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      position: PopupMenuPosition.under,
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'favorite') {
                          onToggleFavorite();
                        } else if (value == 'important') {
                          onToggleImportant();
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: isFavorite
                                    ? AppColors.buntOrange
                                    : AppColors.ink,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Favorite',
                                style: TextStyle(
                                  color: isFavorite
                                      ? AppColors.buntOrange
                                      : AppColors.ink,
                                  fontWeight: isFavorite
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
                                isImportant
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 18,
                                color: isImportant
                                    ? AppColors.buntOrange
                                    : AppColors.ink,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Important',
                                style: TextStyle(
                                  color: isImportant
                                      ? AppColors.buntOrange
                                      : AppColors.ink,
                                  fontWeight: isImportant
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.peachMist,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.buntOrange),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
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
