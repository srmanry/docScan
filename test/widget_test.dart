import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doc_sense/app.dart';
import 'package:doc_sense/core/di/injection_container.dart' as di;

void main() {
  testWidgets('App shows the login page when signed out', (WidgetTester tester) async {
    await di.initDependencies();

    await tester.pumpWidget(const ProviderScope(child: DocAiApp()));
    await tester.pumpAndSettle();

    expect(find.text('DocAI'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
