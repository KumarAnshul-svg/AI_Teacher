import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/app.dart';
import 'package:ai_tracer/core/constants/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AiTracerApp()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(AppStrings.welcomeMessage), findsOneWidget);
    expect(find.text(AppStrings.startButton), findsOneWidget);
  });
}
