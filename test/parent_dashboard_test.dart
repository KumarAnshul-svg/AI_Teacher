import 'package:ai_tracer/features/home/screens/home_screen.dart';
import 'package:ai_tracer/features/parent_dashboard/screens/parent_dashboard.dart';
import 'package:ai_tracer/features/parent_dashboard/screens/parent_gate_screen.dart';
import 'package:ai_tracer/features/progress/providers/progress_provider.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';
import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('parent gate opens only with the right answer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: ParentGateScreen()),
      ),
    );
    await tester.pump();

    // Wrong answer: still on the gate, error shown.
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Parent Area'), findsOneWidget);
    expect(find.textContaining('not right'), findsOneWidget);

    // Right answer: the parent dashboard opens.
    await tester.enterText(find.byType(TextField), '16');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Parent Dashboard'), findsOneWidget);
  });

  testWidgets('home screen has no parent entry (link added separately later)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('Parents'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('parent dashboard shows real progress numbers', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final notifier = container.read(progressProvider.notifier);
    final lineTemplate =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    // 3 stars on the vertical line (mastered), 1 star on the wave.
    notifier.recordTemplate(1, lineTemplate.id, 3);
    final waveTemplate =
        TemplateService.generateTemplate('~', LevelsScreen.levels[0].type);
    notifier.recordTemplate(1, waveTemplate.id, 1);
    container.dispose();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: ParentDashboard()),
      ),
    );
    await tester.pump();

    expect(find.text('Parent Dashboard'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // 4 stars total
    expect(find.text('2/98'), findsOneWidget); // 2 of 98 templates marked done
    expect(find.text('1'), findsWidgets); // mastered count
    expect(find.text('Lines — "~"'), findsOneWidget); // struggling item
    expect(find.textContaining('Practice these a little more: ~'),
        findsOneWidget);
  });
}
