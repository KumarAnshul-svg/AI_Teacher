// Verifies the multi-stroke scoring fix: drawing a letter correctly in
// its expected number of strokes must score well.
// Run: flutter test test/multistroke_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/core/utils/stroke_analyzer.dart';
import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/tracing/models/stroke_point.dart';
import 'package:ai_tracer/features/tracing/models/tracing_template.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';

const _canvas = 300.0;

/// Densify a stroke by sampling every ~6px along it (like a real finger).
List<StrokePoint> _densify(List<StrokePoint> pts) {
  final out = <StrokePoint>[pts.first];
  for (int i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final len = (b.x - a.x).abs() + (b.y - a.y).abs();
    final steps = (len / 6).ceil();
    for (int s = 1; s <= steps; s++) {
      final t = s / steps;
      out.add(StrokePoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t));
    }
  }
  return out;
}

List<List<StrokePoint>> _trace(TracingTemplate tpl) =>
    tpl.strokes
        .map((s) => s
            .map((p) => StrokePoint(x: p.x * _canvas, y: p.y * _canvas))
            .toList())
        .map(_densify)
        .toList();

void main() {
  test('A traced correctly in its 3 strokes scores well', () {
    final tpl =
        TemplateService.generateTemplate('A', LevelsScreen.levels[3].type);
    final strokes = _trace(tpl);
    expect(strokes.length, 3);

    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: strokes,
      template: tpl,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    // ignore: avoid_print
    print('A in 3 strokes: ${accuracy.toStringAsFixed(1)}');
    expect(accuracy, greaterThanOrEqualTo(90),
        reason: 'A perfect multi-stroke A must score well');
  });

  test('E traced correctly in its 4 strokes scores well', () {
    final tpl =
        TemplateService.generateTemplate('E', LevelsScreen.levels[3].type);
    final strokes = _trace(tpl);
    expect(strokes.length, 4);

    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: strokes,
      template: tpl,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    // ignore: avoid_print
    print('E in 4 strokes: ${accuracy.toStringAsFixed(1)}');
    expect(accuracy, greaterThanOrEqualTo(90));
  });

  test('word "Cat" traced correctly scores well (passes 70% gate)', () {
    final tpl =
        TemplateService.generateTemplate('Cat', LevelsScreen.levels[5].type);
    final strokes = _trace(tpl);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: strokes,
      template: tpl,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    // ignore: avoid_print
    print('Cat in ${strokes.length} strokes: ${accuracy.toStringAsFixed(1)}');
    expect(accuracy, greaterThanOrEqualTo(70),
        reason: 'A perfect word trace must pass the 70% gate');
  });

  test('a single leg of A does not score well', () {
    final tpl =
        TemplateService.generateTemplate('A', LevelsScreen.levels[3].type);
    final stroke = _densify(tpl.strokes[0]
        .map((p) => StrokePoint(x: p.x * _canvas, y: p.y * _canvas))
        .toList());
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [stroke],
      template: tpl,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    // ignore: avoid_print
    print('one leg of A: ${accuracy.toStringAsFixed(1)}');
    expect(accuracy, lessThan(70),
        reason: 'Tracing just one leg must not pass');
  });
}
