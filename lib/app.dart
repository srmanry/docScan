import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/constants/app_constants.dart';
import 'package:doc_sense/core/router/app_router.dart';
import 'package:doc_sense/core/theme/app_theme.dart';

class DocAiApp extends ConsumerWidget {
  const DocAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
