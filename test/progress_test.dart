// Tests for level progress, unlock logic, and persistence.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_tracer/core/constants/app_strings.dart';
import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/progress/providers/progress_provider.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('records best stars per template and counts completions', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordTemplate(1, 'line_|', 1);
    notifier.recordTemplate(1, 'line_-', 3);
    notifier.recordTemplate(1, 'line_|', 2); // keep the best (2 > 1)
    notifier.recordTemplate(1, 'line_/', 0); // 0 stars = not completed

    final progress = container.read(progressProvider);
    expect(progress[1]!.templateStars['line_|'], 2);
    expect(progress[1]!.templateStars['line_-'], 3);
    expect(progress[1]!.templateStars['line_/'], 0);
    expect(progress[1]!.completedTemplates, 2);
    expect(progress[1]!.totalStars, 5);
  });

  test('first two levels start unlocked; rest unlock by completion', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);
    final levels = LevelsScreen.levels;

    // Lines and Shapes are always unlocked.
    expect(notifier.isLevelUnlocked(levels, 0), isTrue);
    expect(notifier.isLevelUnlocked(levels, 1), isTrue);
    expect(notifier.isLevelUnlocked(levels, 2), isFalse);

    // Completing Shapes unlocks Numbers.
    for (final template in levels[1].templates) {
      notifier.recordTemplate(levels[1].id, template, 1);
    }
    expect(notifier.isLevelUnlocked(levels, 2), isTrue);
    expect(notifier.isLevelUnlocked(levels, 3), isFalse);
  });

  test('unlock is permanent: resetting the previous segment keeps it unlocked',
      () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);
    final levels = LevelsScreen.levels;

    // Complete Shapes so Numbers unlocks.
    for (final template in levels[1].templates) {
      notifier.recordTemplate(levels[1].id, template, 1);
    }
    expect(notifier.isLevelUnlocked(levels, 2), isTrue);

    // Reset Shapes — Numbers must stay unlocked.
    notifier.resetLevel(levels[1].id);
    expect(notifier.isLevelUnlocked(levels, 2), isTrue,
        reason: 'Once unlocked, a segment must stay unlocked after a reset');

    // A full reset does clear everything.
    notifier.resetAll();
    expect(notifier.isLevelUnlocked(levels, 2), isFalse);
  });

  test('half of the previous segment unlocks the next one', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);
    final levels = LevelsScreen.levels;

    final shapes = levels[1];
    final required = (shapes.templates.length / 2).ceil();

    // One short of half: Numbers stays locked.
    for (final template in shapes.templates.take(required - 1)) {
      notifier.recordTemplate(shapes.id, template, 1);
    }
    expect(notifier.isLevelUnlocked(levels, 2), isFalse);

    // Reaching half unlocks Numbers.
    notifier.recordTemplate(shapes.id, shapes.templates[required - 1], 1);
    expect(notifier.isLevelUnlocked(levels, 2), isTrue);
  });

  test('overall progress is the share of all templates completed', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);

    // Trace 3 of the 6 Lines templates.
    for (final template in LevelsScreen.levels[0].templates.take(3)) {
      notifier.recordTemplate(1, template, 1);
    }
    final overall = notifier.overallProgress(LevelsScreen.levels);
    final total = LevelsScreen.levels
        .fold<int>(0, (sum, l) => sum + l.templates.length);
    expect(overall, closeTo(3 / total, 0.001));
  });

  test('progress survives a reload (persisted via shared_preferences)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    first.read(progressProvider.notifier).recordTemplate(1, 'line_|', 3);
    first.dispose();

    // A new container over the same prefs should restore the progress.
    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    final progress = second.read(progressProvider);
    expect(progress[1]!.templateStars['line_|'], 3);
    expect(progress[1]!.completedTemplates, 1);
  });

  test('resetAll clears progress and persists the cleared state', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordTemplate(1, 'line_|', 3);
    expect(container.read(progressProvider)[1]!.completedTemplates, 1);

    notifier.resetAll();
    expect(container.read(progressProvider), isEmpty);

    // Persisted cleared state survives a reload.
    final prefs = container.read(sharedPreferencesProvider);
    final reloaded = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reloaded.dispose);
    expect(reloaded.read(progressProvider), isEmpty);
  });

  test('resetLevel clears only that level and keeps the rest', () async {
    final container = await _container();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordTemplate(1, 'line_|', 3);
    notifier.recordTemplate(2, 'shape_O', 2);
    expect(container.read(progressProvider).length, 2);

    notifier.resetLevel(1);
    final state = container.read(progressProvider);
    expect(state[1], isNull, reason: 'level 1 should be cleared');
    expect(state[2]!.completedTemplates, 1, reason: 'level 2 should remain');
  });

  testWidgets('levels screen shows progress bars and unlocks next level',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Pre-record 3 completed templates for Lines and unlock shapes partially.
    final seed = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final templates = LevelsScreen.levels[0].templates;
    for (final t in templates.take(3)) {
      seed.read(progressProvider.notifier).recordTemplate(1, t, 2);
    }
    seed.dispose();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: LevelsScreen()),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('3/8 traced'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    // Finish the remaining Lines templates -> Shapes card unlocks.
    final notifier = ProviderScope.containerOf(
      tester.element(find.text(AppStrings.level1Name)),
    ).read(progressProvider.notifier);
    for (final t in templates.skip(3)) {
      notifier.recordTemplate(1, t, 1);
    }
    await tester.pump();

    final shapesCard = find.text(AppStrings.level2Name);
    expect(shapesCard, findsOneWidget);
    expect(find.text('0/8 traced'), findsOneWidget);
  });
}
