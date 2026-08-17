import 'package:flutter/material.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/features/document/domain/entities/scanned_document.dart';

/// Icon asset + tint used to represent a document's source type, shared by
/// the Home and History cards so they stay visually consistent.
({String asset, Color background}) documentIconStyle(DocumentSourceType type) => switch (type) {
      DocumentSourceType.camera ||
      DocumentSourceType.gallery =>
        (asset: 'assets/images/gallery.png', background: AppColors.peachMist),
      DocumentSourceType.pdf => (asset: 'assets/images/pdf.png', background: const Color(0xFFFCE1DD)),
      DocumentSourceType.textFile =>
        (asset: 'assets/images/doc.png', background: const Color(0xFFDCE7FB)),
    };
