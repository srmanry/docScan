import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // The palette is a fixed light brand palette, so the app stays light
      // whatever the phone is set to.
      themeMode: ThemeMode.light,
      builder: (context, child) {
        final theme = Theme.of(context);
        final overlayStyle = theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: theme.scaffoldBackgroundColor,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: theme.scaffoldBackgroundColor,
                statusBarBrightness: Brightness.light,
              );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
