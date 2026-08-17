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

enum _HistoryFilter { all, scanned, imported, favorites }

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
  bool _newestFirst = true;

  // Favoriting isn't backed by a persisted field on ScannedDocument yet, so
  // this stays in-memory for now (resets on app restart / list refresh).
  final Set<String> _favoriteIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(ScannedDocument doc) => switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.scanned =>
          doc.sourceType == DocumentSourceType.camera || doc.sourceType == DocumentSourceType.gallery,
        _HistoryFilter.imported =>
          doc.sourceType == DocumentSourceType.pdf || doc.sourceType == DocumentSourceType.textFile,
        _HistoryFilter.favorites => _favoriteIds.contains(doc.id),
      };

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(savedDocumentsProvider);
    final authState = ref.watch(authProvider);
    final photoUrl = authState is AuthAuthenticated ? authState.user.photoUrl : null;
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
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
                newestFirst: _newestFirst,
                onSearchChanged: () => setState(() {}),
                onToggleSort: () => setState(() => _newestFirst = !_newestFirst),
              ),
            ),
            Expanded(
              child: documentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (documents) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = documents.where(_matchesFilter).where((doc) {
                    return query.isEmpty || doc.title.toLowerCase().contains(query);
                  }).toList()
                    ..sort((a, b) => _newestFirst
                        ? b.createdAt.compareTo(a.createdAt)
                        : a.createdAt.compareTo(b.createdAt));

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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
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

  List<Widget> _buildGroupedList(List<ScannedDocument> documents, ThemeData theme) {
    final widgets = <Widget>[];
    String? currentGroup;
    for (final doc in documents) {
      final group = formatDateGroup(doc.createdAt);
      if (group != currentGroup) {
        if (currentGroup != null) widgets.add(const SizedBox(height: 20));
        currentGroup = group;
        widgets.add(Text(group, style: theme.textTheme.titleLarge));
        widgets.add(const SizedBox(height: 10));
      } else {
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(_HistoryDocumentCard(
        document: doc,
        isFavorite: _favoriteIds.contains(doc.id),
        onToggleFavorite: () => setState(() {
          if (!_favoriteIds.add(doc.id)) _favoriteIds.remove(doc.id);
        }),
      ));
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
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null ? Icon(Icons.person_outline, color: theme.colorScheme.primary) : null,
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
    (filter: _HistoryFilter.all, icon: Icons.inventory_2_outlined, label: 'All'),
    (filter: _HistoryFilter.scanned, icon: Icons.document_scanner_outlined, label: 'Scanned'),
    (filter: _HistoryFilter.imported, icon: Icons.assignment_turned_in_outlined, label: 'Imported'),
    (filter: _HistoryFilter.favorites, icon: Icons.star_rounded, label: 'Favorites'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _items[i];
          final isSelected = item.filter == selected;
          return _FilterChip(
            icon: item.icon,
            label: item.label,
            selected: isSelected,
            onTap: () => onSelected(item.filter),
          );
        },
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.buntOrange : AppColors.softBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.buntOrange : AppColors.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.buntOrange : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndSortRow extends StatelessWidget {
  final TextEditingController controller;
  final bool newestFirst;
  final VoidCallback onSearchChanged;
  final VoidCallback onToggleSort;
  const _SearchAndSortRow({
    required this.controller,
    required this.newestFirst,
    required this.onSearchChanged,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => onSearchChanged(),
            decoration: const InputDecoration(
              hintText: 'Search documents...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggleSort,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort: ${newestFirst ? 'Newest' : 'Oldest'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.buntOrange),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryDocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  const _HistoryDocumentCard({
    required this.document,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${document.title}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(documentProvider.notifier).delete(document.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Document deleted' : 'Could not delete document')),
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentViewerPage(document: document)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: icon.background, borderRadius: BorderRadius.circular(12)),
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
                        if (sizeLabel != null) sizeLabel,
                        formatDocumentTimestamp(document.createdAt),
                      ].join(' • '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.peachMist,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        document.detectedLanguage ?? 'English',
                        style: const TextStyle(
                          color: AppColors.buntOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.buntOrange,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Consumer(
                    builder: (context, ref, _) => PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant, size: 20),
                      onSelected: (value) {
                        if (value == 'delete') _confirmDelete(context, ref);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ],
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
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

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
              decoration: const BoxDecoration(color: AppColors.peachMist, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.buntOrange),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
