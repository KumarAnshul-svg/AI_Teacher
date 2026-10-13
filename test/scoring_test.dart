// Tests for distinct shape templates and child-friendly stroke scoring.
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/core/utils/stroke_analyzer.dart';
import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/progress/providers/progress_provider.dart';
import 'package:ai_tracer/features/tracing/models/stroke_point.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';
import 'package:ai_tracer/features/tracing/screens/tracing_screen.dart';
import 'package:ai_tracer/features/tracing/widgets/star_rating.dart';
import 'package:ai_tracer/features/tracing/widgets/tracing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _canvasSize = 300.0;

double _wiggle(double t) => sin(t / 12);

/// Simulates a finger trace of a vertical template line at [x] with a
/// deterministic wobble of [wobble] pixels, sampled every ~[step] px.
List<StrokePoint> _wobblyLineTrace({
  required double x,
  required double fromY,
  required double toY,
  required double wobble,
  double step = 6,
}) {
  final points = <StrokePoint>[];
  final direction = toY > fromY ? 1.0 : -1.0;
  var travelled = 0.0;
  while (travelled <= (toY - fromY).abs()) {
    points.add(StrokePoint(
      x: x + wobble * _wiggle(travelled / 3),
      y: fromY + direction * travelled,
    ));
    travelled += step;
  }
  return points;
}

int _starsFor(double accuracy) {
  if (accuracy >= 90) return 3;
  if (accuracy >= 63) return 2;
  if (accuracy >= 37) return 1;
  return 0;
}

void main() {
  test('number templates are real distinct digits, not plain lines', () {
    final numbersLevel = LevelsScreen.levels[2]; // 0-9
    final signatures = numbersLevel.templates
        .map((c) => TemplateService.generateTemplate(c, numbersLevel.type)
            .points
            .map((p) => '${p.x.toStringAsFixed(3)},${p.y.toStringAsFixed(3)}')
            .join('|'))
        .toSet();
    expect(
      signatures.length,
      numbersLevel.templates.length,
      reason: 'Each digit must produce a different template',
    );

    // Every digit must use both axes (a stub would be a thin vertical line).
    for (final c in numbersLevel.templates) {
      final pts = TemplateService.generateTemplate(c, numbersLevel.type).points;
      final xs = pts.map((p) => p.x).toList();
      final ys = pts.map((p) => p.y).toList();
      final spanX = xs.reduce(max) - xs.reduce(min);
      final spanY = ys.reduce(max) - ys.reduce(min);
      expect(spanX, greaterThan(0.1), reason: 'digit $c must use width');
      expect(spanY, greaterThan(0.3), reason: 'digit $c must use height');
    }
  });

  test('capital letter templates are distinct real letters, not one shape',
      () {
    final capLevel = LevelsScreen.levels[3]; // A-Z
    final signatures = capLevel.templates
        .map((c) => TemplateService.generateTemplate(c, capLevel.type)
            .points
            .map((p) => '${p.x.toStringAsFixed(3)},${p.y.toStringAsFixed(3)}')
            .join('|'))
        .toSet();
    expect(
      signatures.length,
      capLevel.templates.length,
      reason: 'Each capital letter must produce a different template',
    );

    // Multi-stroke letters must keep their strokes separate (e.g. A = 3).
    final a = TemplateService.generateTemplate('A', capLevel.type);
    expect(a.strokes.length, 3, reason: 'A is drawn in three strokes');
    final e = TemplateService.generateTemplate('E', capLevel.type);
    expect(e.strokes.length, 4, reason: 'E is drawn in four strokes');

    // Every letter spans the canvas in both directions.
    for (final c in capLevel.templates) {
      final pts = TemplateService.generateTemplate(c, capLevel.type).points;
      final xs = pts.map((p) => p.x).toList();
      final ys = pts.map((p) => p.y).toList();
      expect(xs.reduce(max) - xs.reduce(min), greaterThan(0.2),
          reason: 'letter $c must use width');
      expect(ys.reduce(max) - ys.reduce(min), greaterThan(0.3),
          reason: 'letter $c must use height');
    }
  });

  test('digit 5 is a three-stroke template (bar + stem + belly)', () {
    final numLevel = LevelsScreen.levels[2];
    final five = TemplateService.generateTemplate('5', numLevel.type);
    expect(five.strokes.length, 3, reason: '5 is drawn in three strokes');
  });

  test('strictness < 1 makes the same stroke score lower', () {
    final template =
        TemplateService.generateTemplate('□', LevelsScreen.levels[1].type);
    final trace = <StrokePoint>[];
    void walk(double x0, double y0, double x1, double y1) {
      const steps = 20;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        trace.add(StrokePoint(
          x: x0 + (x1 - x0) * t + 4 * _wiggle(t * 40),
          y: y0 + (y1 - y0) * t + 4 * _wiggle(t * 40 + 3),
        ));
      }
    }

    walk(60, 60, 240, 60);
    walk(240, 60, 240, 240);
    walk(240, 240, 60, 240);
    walk(60, 240, 60, 60);

    final normal = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    final strict = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
      strictness: 0.96,
    );
    expect(strict, closeTo(normal * 0.96, 0.01));
    expect(strict, lessThan(normal));
  });

  test('lowercase letter templates are distinct real letters, not one shape',
      () {
    final smallLevel = LevelsScreen.levels[4]; // a-z
    final signatures = smallLevel.templates
        .map((c) => TemplateService.generateTemplate(c, smallLevel.type)
            .points
            .map((p) => '${p.x.toStringAsFixed(3)},${p.y.toStringAsFixed(3)}')
            .join('|'))
        .toSet();
    expect(
      signatures.length,
      smallLevel.templates.length,
      reason: 'Each lowercase letter must produce a different template',
    );

    // Every letter must use a meaningful amount of the canvas.
    for (final c in smallLevel.templates) {
      final pts = TemplateService.generateTemplate(c, smallLevel.type).points;
      final xs = pts.map((p) => p.x).toList();
      final ys = pts.map((p) => p.y).toList();
      expect(xs.reduce(max) - xs.reduce(min), greaterThan(0.05),
          reason: 'letter $c must use width');
      expect(ys.reduce(max) - ys.reduce(min), greaterThan(0.2),
          reason: 'letter $c must use height');
    }
  });

  test('shape drawn in the wrong place scores low (position penalty)', () {
    final template =
        TemplateService.generateTemplate('□', LevelsScreen.levels[1].type);
    // A correct square outline, but shifted 20px to the right of the
    // template — similar shape, wrong position.
    final trace = <StrokePoint>[];
    void walk(double x0, double y0, double x1, double y1) {
      const steps = 20;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        trace.add(StrokePoint(
          x: x0 + (x1 - x0) * t + 20,
          y: y0 + (y1 - y0) * t,
        ));
      }
    }

    walk(60, 60, 240, 60);
    walk(240, 60, 240, 240);
    walk(240, 240, 60, 240);
    walk(60, 240, 60, 60);

    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(
      accuracy,
      lessThan(60),
      reason: 'A square drawn off to the side must not score well',
    );
  });

  test('every shape template is distinct', () {
    final shapesLevel = LevelsScreen.levels[1]; // O, square, triangle, star, heart
    final signatures = shapesLevel.templates
        .map((c) => TemplateService.generateTemplate(c, shapesLevel.type)
            .points
            .map((p) => '${p.x.toStringAsFixed(3)},${p.y.toStringAsFixed(3)}')
            .join('|'))
        .toSet();
    expect(
      signatures.length,
      shapesLevel.templates.length,
      reason: 'Each shape character must produce a different template',
    );
  });

  test('heart template is heart-shaped (pointed bottom, centered)', () {
    final heart = TemplateService.generateTemplate('♥', LevelsScreen.levels[1].type);
    var lowest = heart.points.first;
    for (final p in heart.points) {
      if (p.y > lowest.y) lowest = p;
    }
    expect(lowest.y, greaterThan(0.6));
    expect(lowest.x, inInclusiveRange(0.4, 0.6));
  });

  test('near-perfect line trace earns 3 stars', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = _wobblyLineTrace(x: 150, fromY: 32, toY: 268, wobble: 6);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(accuracy, greaterThanOrEqualTo(80));
    expect(_starsFor(accuracy), 3);
  });

  test('wobbly child line trace still earns 2+ stars', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = _wobblyLineTrace(x: 150, fromY: 40, toY: 260, wobble: 25);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(accuracy, greaterThanOrEqualTo(55));
    expect(_starsFor(accuracy), greaterThanOrEqualTo(2));
  });

  // Real stroke extracted from a user screenshot (canvas-relative logical
  // coords, sampled): hugged the template within ~3px for its full length.
  // The pre-fix analyzer scored this 36%; it must now score ~99%.
  const _userReplay =
      '148.7,26.7;148,30.1;148.7,32.7;148.7,36.1;148.7,39.4;148.7,42.8;'
      '148.7,46.1;148.7,49.4;148.7,52.8;148.7,56.1;148.7,59.5;148.7,62.8;'
      '148.7,66.1;148.7,69.5;148.7,72.8;148.7,76.2;148.7,79.5;148.7,82.9;'
      '148.7,86.2;148.7,89.5;148.7,92.9;148.7,96.2;148.7,99.6;148.7,102.9;'
      '148.7,106.2;148.7,109.6;148.7,112.9;148.7,116.3;148.7,119.6;148.7,122.9;'
      '148.7,126.3;148.7,129.6;148.7,133;148.7,136.3;148,139.6;148,143;'
      '148,146.3;148,149.7;148,153;148,156.3;148,159.7;148,163;148,166.4;'
      '148,169.7;148,173.1;148,176.4;148,179.7;148,183.1;148,186.4;148,189.8;'
      '148,193.1;148,196.4;148,199.8;148,203.1;148,206.5;148,209.8;148,213.1;'
      '148,216.5;148,219.8;148,223.2;150.7,225.8;148,227.8;151.3,230.5;'
      '146.7,233.9;146.7,237.2;146.7,240.5;146.7,243.9;146.7,247.2;146.7,250.6;'
      '146.7,253.9;146.7,257.2;146.7,260.6;146.7,263.9;146,267.3;148.7,269.9';

  test('the real near-perfect trace from the bug report scores ~99%', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = _userReplay
        .split(';')
        .map((pair) {
          final parts = pair.split(',');
          return StrokePoint(
            x: double.parse(parts[0]),
            y: double.parse(parts[1]),
          );
        })
        .toList();
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(accuracy, greaterThanOrEqualTo(90));
    expect(_starsFor(accuracy), 3);
  });

  test('short wobbly trace near one end still earns 1+ star', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = _wobblyLineTrace(x: 150, fromY: 100, toY: 220, wobble: 30);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(_starsFor(accuracy), greaterThanOrEqualTo(1));
  });

  test('random scribble far from the shape earns 0 stars', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final scribble = List.generate(30, (i) {
      return StrokePoint(x: 10.0 + i * 2, y: 10.0 + (i % 3) * 5.0);
    });
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [scribble],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(accuracy, lessThan(30));
    expect(_starsFor(accuracy), 0);
  });

  test('stroke perpendicular to the template (wrong direction) is rejected', () {
    // Template is a vertical line at x=150; user draws a horizontal line
    // across the middle. Only the short crossing section is near the path.
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = List.generate(60, (i) {
      return StrokePoint(x: 20.0 + i * 4.4, y: 150.0 + _wiggle(i.toDouble()));
    });
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(_starsFor(accuracy), lessThanOrEqualTo(1));
  });

  test('off-shape circle squiggle on a square template is rejected', () {
    // Square template is a 180px box; user scribbles a small circle in the
    // middle, far from every side of the square.
    final template =
        TemplateService.generateTemplate('□', LevelsScreen.levels[1].type);
    final trace = <StrokePoint>[];
    for (int i = 0; i <= 40; i++) {
      final t = 2 * 3.14159 * i / 40;
      trace.add(StrokePoint(
        x: 150 + 15 * _wiggle(t * 10),
        y: 150 + 15 * _wiggle(t * 10 + 2),
      ));
    }
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(_starsFor(accuracy), lessThanOrEqualTo(1));
  });

  test('traced square scores well (path-based coverage works for shapes)', () {
    final template =
        TemplateService.generateTemplate('□', LevelsScreen.levels[1].type);
    // Walk the drawn square outline (normalized coords * 300) with a wobble.
    final trace = <StrokePoint>[];
    void walk(double x0, double y0, double x1, double y1) {
      const steps = 20;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        trace.add(StrokePoint(
          x: x0 + (x1 - x0) * t + 4 * _wiggle(t * 40),
          y: y0 + (y1 - y0) * t + 4 * _wiggle(t * 40 + 3),
        ));
      }
    }

    walk(60, 60, 240, 60);
    walk(240, 60, 240, 240);
    walk(240, 240, 60, 240);
    walk(60, 240, 60, 60);

    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    expect(accuracy, greaterThanOrEqualTo(60));
  });

  // Recreates the multi-stroke scribble from the user's screenshot on the
  // backslash (\) template: a corner scribble, a horizontal line across the
  // middle, and several wobbly vertical strokes. It crosses the diagonal
  // repeatedly but does not trace it, so it must NOT get a good score.
  List<List<StrokePoint>> _scribbleMess() {
    List<StrokePoint> stroke(List<(double, double)> pts) =>
        pts.map((p) => StrokePoint(x: p.$1, y: p.$2)).toList();
    return [
      stroke([(47, 70), (50, 80), (55, 90), (60, 98), (58, 70)]),
      stroke([(46, 128), (80, 130), (120, 130), (160, 131), (193, 133)]),
      stroke([(130, 134), (140, 150), (146, 170), (150, 195)]),
      stroke([(193, 140), (198, 160), (200, 180), (202, 210)]),
      stroke([(188, 170), (185, 190), (178, 210), (176, 220)]),
      stroke([(220, 222), (230, 240), (236, 246)]),
    ];
  }

  test('multi-stroke scribble over the template does not get a good score',
      () {
    final template =
        TemplateService.generateTemplate('\\', LevelsScreen.levels[0].type);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: _scribbleMess(),
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    // ignore: avoid_print
    print('scribble-mess accuracy: ${accuracy.round()}');
    expect(accuracy, lessThan(60), reason: 'Scribbles must not score high');
    expect(_starsFor(accuracy), lessThanOrEqualTo(1));
  });

  // The user's U-curve stroke from the screenshot: a diagonally-drawn
  // curve that sags ~60px away from the straight line in the middle.
  // It should get at most 1 star; the user expected ~35% accuracy.
  const _uCurve =
      '239.9,57.9;238.4,60.9;240.6,62.3;243.5,63.8;242.8,66;247.2,67.5;245,69.7;242.8,71.9;239.9,74.1;243.5,75.6;241.'
      '3,77.8;241.3,80;241.3,82.2;241.3,84.4;239.9,86.6;239.9,88.8;239.9,91;238.4,93.2;238.4,95.4;238.4,97.6;238.4,99'
      '.8;238.4,102;236.9,104.2;236.2,106.4;236.2,108.6;236.2,110.8;236.2,113;234,115.2;236.9,116.6;234,118.8;234,121'
      ';234,123.2;232.5,125.4;232.5,127.6;232.5,129.8;232.5,132;232.5,134.2;231.1,136.4;230.3,138.6;227.4,140.8;225.2'
      ',143;229.6,144.5;228.9,146.7;223.7,149.6;221.5,151.8;225.9,153.3;223,155.5;218.6,157.7;221.5,159.2;219.3,161.4'
      ';217.1,163.6;220,165;219.3,166.5;214.9,168;209.8,169.4;215.6,170.2;211.2,171.6;203.9,173.1;206.8,173.8;207.6,1'
      '74.6;192.2,176;192.2,176.8;190,177.5;187.8,178.2;186.3,179;184.8,179.7;180.4,180.4;176.8,181.2;170.2,181.9;187'
      '.8,181.9;181.2,182.6;170.9,183.4;160.6,184.1;178.2,184.1;162.8,184.8;180.4,184.8;165.8,185.6;154,186.3;171.6,1'
      '86.3;162.1,187;148.9,187.8;166.5,187.8;154,188.5;137.2,189.2;154.8,189.2;142.3,190;129.1,190.7;146.7,190.7;135'
      ',191.4;152.6,191.4;140.8,192.2;129.1,192.9;146.7,192.9;137.2,193.6;129.1,194.4;122.5,195.1;121,195.8;118.8,196'
      '.6;116.6,197.3;113,198;110.8,198.8;109.3,199.5;108.6,200.2;109.3,201;110.8,201.7;98.3,203.2;102.7,203.9;106.4,'
      '204.6;96.1,206.1;100.5,206.8;93.2,208.3;89.5,209.8;88.8,211.2;90.2,212.7;88.8,214.2;87.3,215.6;84.4,217.1;81.4'
      ',218.6;78.5,220;75.6,221.5;71.9,223;77,223.7;68.2,225.2;72.6,225.9;64.5,227.4;69.7,228.1;65.3,229.6;65.3,231.1'
      ';66.7,232.5;62.3,234.7;60.1,236.9;58.7,239.1;58.7,241.3;61.6,243.5;';

  test('U-curve stroke (sagging ~60px) does not get a good score', () {
    // The drawn curve roughly follows the '/' diagonal but sags ~60px below
    // it in the middle — too different to deserve high accuracy.
    final template =
        TemplateService.generateTemplate('/', LevelsScreen.levels[0].type);
    final trace = _uCurve
        .split(';')
        .where((s) => s.isNotEmpty)
        .map((p) {
          final parts = p.split(',');
          return StrokePoint(
            x: double.parse(parts[0]),
            y: double.parse(parts[1]),
          );
        })
        .toList();
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvasSize,
      canvasHeight: _canvasSize,
    );
    // ignore: avoid_print
    print('U-curve accuracy: ${accuracy.round()}');
    expect(accuracy, lessThan(50));
    expect(_starsFor(accuracy), lessThanOrEqualTo(1));
  });

  testWidgets('decent stroke on canvas earns at least 2 stars end-to-end',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(home: TracingScreen(level: LevelsScreen.levels[0])),
    ));
    await tester.pump(const Duration(seconds: 2));

    // Draw a straight-ish vertical stroke down the middle of the canvas.
    final topLeft = tester.getTopLeft(find.byType(TracingCanvas));
    final gesture = await tester.startGesture(
      topLeft + const Offset(150, 40),
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveBy(const Offset(1, 30));
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(i.isEven ? 2 : -2, 18));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();

    // Finish and check the star rating in the feedback overlay.
    await tester.tap(find.text('Done'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final rating = tester.widget<StarRating>(find.byType(StarRating));
    expect(
      rating.stars,
      greaterThanOrEqualTo(2),
      reason: 'A decent vertical trace should reward the child',
    );
  });
}
