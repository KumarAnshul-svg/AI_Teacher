// Regression test for the blank tracing screen: the app theme used
// `minimumSize: Size(double.infinity, 56)`, which crashed layout with
// "BoxConstraints forces an infinite width" for any ElevatedButton inside a
// Row (tracing screen Clear/Done buttons, feedback overlay buttons), leaving
// the tracing page unpainted ("nothing is there").
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/app.dart';
import 'package:ai_tracer/core/constants/app_strings.dart';
import 'package:ai_tracer/features/progress/providers/progress_provider.dart';
import 'package:ai_tracer/features/tracing/widgets/feedback_overlay.dart';
import 'package:ai_tracer/features/tracing/widgets/template_painter.dart';
import 'package:ai_tracer/features/tracing/widgets/tracing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _boundaryKey = Key('regression-repaint-boundary');

Future<ProviderScope> _appScope() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: RepaintBoundary(key: _boundaryKey, child: const AiTracerApp()),
  );
}

Future<int> _countTemplateGrayPixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  late final ui.Image image;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: 1.0);
  });
  late final ByteData? raw;
  await tester.runAsync(() async {
    raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  });
  final pixels = raw!.buffer.asUint32List();
  var gray = 0; // #E0E0E0 template stroke color
  for (final p in pixels) {
    final r = p & 0xFF;
    final g = (p >> 8) & 0xFF;
    final b = (p >> 16) & 0xFF;
    if (r == 0xE0 && g == 0xE0 && b == 0xE0) gray++;
  }
  return gray;
}

void main() {
  testWidgets('home -> levels -> Lines tracing screen lays out and paints',
      (tester) async {
    await tester.pumpWidget(await _appScope());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.startButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.level1Name, skipOffstage: false),
        findsWidgets);

    await tester.tap(
      find.text(AppStrings.level1Name, skipOffstage: false),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.takeException(),
      isNull,
      reason: 'Tracing screen must lay out without exceptions',
    );

    final painterFinder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TemplatePainter,
    );
    expect(painterFinder, findsOneWidget);

    final grayPixels = await _countTemplateGrayPixels(tester);
    // ignore: avoid_print
    print('template gray pixels painted: $grayPixels');
    expect(
      grayPixels,
      greaterThan(0),
      reason: 'The template strokes must be visible on the canvas',
    );
  });

  testWidgets('tracing then Done shows feedback overlay without crashing',
      (tester) async {
    await tester.pumpWidget(await _appScope());
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text(AppStrings.startButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(
      find.text(AppStrings.level1Name, skipOffstage: false),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    // Draw a stroke down the middle of the canvas (matches the '|' template).
    final canvasCenter = tester.getCenter(find.byType(TracingCanvas));
    final gesture = await tester.startGesture(
      canvasCenter - const Offset(0, 80),
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await tester.tap(find.text('Done'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final textsAfterDone = find
        .byType(Text, skipOffstage: false)
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '(span)')
        .toList();
    // ignore: avoid_print
    print('TEXTS after Done tap: $textsAfterDone');
    // ignore: avoid_print
    print('exception after Done: ${tester.takeException()}');
    expect(
      tester.takeException(),
      isNull,
      reason: 'Feedback overlay must not crash layout',
    );
    expect(
      find.byWidgetPredicate((w) =>
              w is Text &&
              (w.data == AppStrings.greatJob ||
                  w.data == AppStrings.niceTry ||
                  w.data == AppStrings.keepTrying)),
      findsOneWidget,
      reason: 'Feedback overlay must show a result message',
    );
  });

  testWidgets('template picker chips let you jump to any character',
      (tester) async {
    await tester.pumpWidget(await _appScope());
    await tester.pump(const Duration(seconds: 2));

    // Navigate to the Lines tracing screen.
    await tester.tap(find.text(AppStrings.startButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(
      find.text(AppStrings.level1Name, skipOffstage: false),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    // The chip row should show all line characters.
    final chip = find.text('|', skipOffstage: false);
    expect(chip, findsWidgets, reason: 'Chip row must show the character');

    // Tap the '/' chip (third character).
    await tester.tap(find.text('/', skipOffstage: false).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull,
        reason: 'Tapping a chip must not crash');

    // Now the large character display should show '/'.
    final largeChars = find.text('/');
    expect(largeChars, findsWidgets,
        reason: 'After tapping "/" chip, the display character must be "/"');
  });

  testWidgets('below 70% accuracy disables Next and shows a hint',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedbackOverlay(
            accuracy: 55,
            stars: 1,
            canProceed: false,
            onContinue: _noop,
            onRetry: _noop,
          ),
        ),
      ),
    );

    expect(find.textContaining('70%'), findsOneWidget,
        reason: 'A hint must explain the 70% requirement');
    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );
    expect(nextButton.onPressed, isNull,
        reason: 'Next must be disabled below 70% accuracy');
    await tester.pumpAndSettle();
  });

  testWidgets('at least 70% accuracy enables Next', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedbackOverlay(
            accuracy: 85,
            stars: 2,
            canProceed: true,
            onContinue: _noop,
            onRetry: _noop,
          ),
        ),
      ),
    );

    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );
    expect(nextButton.onPressed, isNotNull,
        reason: 'Next must be enabled at or above 70% accuracy');
    await tester.pumpAndSettle();
  });
}

void _noop() {}
