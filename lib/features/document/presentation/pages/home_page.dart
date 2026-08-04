import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/presentation/pages/document_viewer_page.dart';
import 'package:doc_sense/features/document/presentation/providers/document_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DocumentState>(documentProvider, (previous, next) {
      if (next is DocumentReady) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentViewerPage(document: next.document)),
        );
      } else if (next is DocumentError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(documentProvider);
    final isScanning = state is DocumentScanning;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('DocAI'),
          ],
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          DocumentScanning() => const Center(child: CircularProgressIndicator()),
          _ => _HomeMenu(isBusy: isScanning),
        },
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });
}

class _HomeMenu extends ConsumerWidget {
  final bool isBusy;
  const _HomeMenu({required this.isBusy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(documentProvider.notifier);

    final actions = [
      _ActionItem(
        icon: Icons.camera_alt_outlined,
        title: 'Scan with Camera',
        subtitle: 'Capture a single page',
        onTap: isBusy ? null : () => notifier.scan(DocumentSourceType.camera),
        primary: true,
      ),
      _ActionItem(
        icon: Icons.image_outlined,
        title: 'Upload from Gallery',
        subtitle: 'Pick one or more photos',
        onTap: isBusy ? null : notifier.scanMultipleFromGallery,
      ),
      _ActionItem(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Open PDF',
        subtitle: 'Read text from a PDF file',
        onTap: isBusy ? null : () => notifier.scan(DocumentSourceType.pdf),
      ),
      _ActionItem(
        icon: Icons.description_outlined,
        title: 'Import DOCX / TXT',
        subtitle: 'Bring in an existing text file',
        onTap: isBusy ? null : () => notifier.scan(DocumentSourceType.textFile),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Welcome back', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'What would you like to read today?',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final action in actions) ...[
          _ActionCard(item: action),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = item.onTap == null;

    return Card(
      color: item.primary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.primary
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.primary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color:
                              item.primary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: item.primary
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: item.primary
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
