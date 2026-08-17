import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/core/utils/document_style.dart';
import 'package:doc_sense/core/utils/format.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';
import 'package:doc_sense/features/document/presentation/providers/document_provider.dart';

String _typeLabel(DocumentSourceType type) => switch (type) {
      DocumentSourceType.camera || DocumentSourceType.gallery => 'Image',
      DocumentSourceType.pdf => 'PDF document',
      DocumentSourceType.textFile => 'Document',
    };

/// Shown right after a file is picked, before OCR runs — lets the user
/// confirm it's the right file or pick a different one instead of finding
/// out only after extraction.
class ReviewDocumentPage extends ConsumerWidget {
  final String filePath;
  final DocumentSourceType sourceType;

  const ReviewDocumentPage({super.key, required this.filePath, required this.sourceType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = documentIconStyle(sourceType);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final sizeLabel = () {
      try {
        return formatFileSize(File(filePath).lengthSync());
      } catch (_) {
        return null;
      }
    }();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Material(
                  color: AppColors.warmWhite,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Review Document', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Check your file before Docora reads it.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(16),
                        decoration:
                            BoxDecoration(color: icon.background, borderRadius: BorderRadius.circular(18)),
                        child: Image.asset(icon.asset, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [_typeLabel(sourceType), if (sizeLabel != null) sizeLabel].join(' • '),
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: Material(
                    color: AppColors.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.of(context).pop();
                        ref.read(documentProvider.notifier).pick(sourceType);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(documentProvider.notifier).extractReviewed();
              },
              child: const Text('Extract'),
            ),
            const SizedBox(height: 16),
            Text(
              'Your original file stays on your device. Docora extracts text for reading and AI features.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
