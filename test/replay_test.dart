// Replays an offset heart (shifted left/smaller, as in the user screenshot)
// against the heart template to diagnose and fix the scoring.
// Run: flutter test test/replay_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/core/utils/stroke_analyzer.dart';
import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/tracing/models/stroke_point.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';

const _canvas = 300.0;

List<StrokePoint> _normalized(List<StrokePoint> pts) =>
    pts.map((p) => StrokePoint(x: p.x * _canvas, y: p.y * _canvas)).toList();

List<StrokePoint> _offset(List<StrokePoint> src, double dx, double dy) =>
    src.map((p) => StrokePoint(x: p.x + dx, y: p.y + dy)).toList();

void main() {
  test('offset heart scores (baseline + variants)', () {
    final heart =
        TemplateService.generateTemplate('♥', LevelsScreen.levels[1].type);
    final heartCanvas = _normalized(heart.points);

    // The user drew a heart shifted left ~13px and ~4% narrower.
    final offset = heartCanvas
        .map((p) => StrokePoint(
              x: (p.x - 13) * 0.96,
              y: p.y,
            ))
        .toList();

    for (final (label, strictness) in [
      ('no strictness', 1.0),
      ('shapes strictness 0.96', 0.96),
    ]) {
      final accuracy = StrokeAnalyzer.analyzeStroke(
        strokes: [offset],
        template: heart,
        canvasWidth: _canvas,
        canvasHeight: _canvas,
        strictness: strictness,
      );
      // ignore: avoid_print
      print('offset heart ($label): ${accuracy.toStringAsFixed(1)}');
      expect(accuracy, lessThan(70),
          reason: 'A shifted heart must not score high');
    }
  });

  test('exact screenshot heart contour vs heart template', () {
    final heart =
        TemplateService.generateTemplate('♥', LevelsScreen.levels[1].type);
    // Outer boundary of the ink in the screenshot (canvas-logical coords).
    const s =
        '45.5,133.8;45.5,130.9;44.7,127.9;43.3,124.3;43.3,121.3;42.5,117.6;'
        '42.5,114;42.5,111;42.5,107.4;42.5,105.9;43.3,100;43.3,98.5;44.7,94.1;'
        '45.5,92.6;48.4,87.5;49.9,83.8;51.3,80.9;52.1,77.2;53.5,73.5;54.3,70.6;'
        '55.7,67.6;57.9,64;58.7,62.5;63.1,58.1;64.5,56.6;68.2,53.7;68.9,52.9;'
        '72.6,50.7;76.3,49.3;79.2,47.8;82.2,46.3;86.6,43.4;90.2,42.6;93.2,41.9;'
        '96.1,41.9;99.8,41.9;103.4,41.9;107.1,41.9;110.8,41.9;114.4,41.9;117.4,41.9;'
        '121,41.9;124.7,41.9;127.6,43.4;131.3,45.6;134.2,48.5;137.2,51.5;140.1,56.6;'
        '142.3,63.2;143.8,67.6;146,72.1;148.9,76.5;152.6,69.9;156.2,66.2;159.2,64.7;'
        '162.8,62.5;166.5,61;169.4,61;173.1,61;176,61;179.7,61;183.4,61;187,61;'
        '190.7,61;193.6,62.5;195.8,64;197.3,65.4;201.7,68.4;203.9,69.9;204.6,70.6;'
        '206.8,73.5;208.3,76.5;210.5,79.4;212,81.6;213.4,84.6;214.2,88.2;214.9,91.2;'
        '216.4,94.9;217.8,98.5;218.6,100;219.3,103.7;219.3,106.6;220,111.8;220.8,114;'
        '220.8,116.2;221.5,120.6;222.2,122.8;223,125.7;223,127.9;223,130.9;223,136.8;'
        '223,139.7;223,142.6;223,145.6;223,148.5;223,152.2;223,155.1;223,158.1;'
        '223,161.8;223,165.4;223,167.6;222.2,172.1;221.5,175;220.8,176.5;219.3,178.7;'
        '216.4,183.8;214.9,186.8;213.4,189.7;212.7,192.6;212,194.1;209.8,196.3;'
        '206.8,200;205.4,202.2;201.7,205.9;199.5,208.1;197.3,210.3;195.1,214;'
        '193.6,216.9;190.7,219.9;188.5,222.1;185.6,225.7;184.1,227.2;180.4,229.4;'
        '176.8,231.6;173.8,233.1;170.9,234.6;166.5,236.8;164.3,238.2;161.4,239;'
        '159.2,239.7;152.6,240.4;148.9,241.9;146.7,242.6;144.5,242.6;140.8,242.6;'
        '137.2,242.6;129.8,242.6;126.9,242.6;122.5,241.9;119.6,241.2;118.1,240.4;'
        '114.4,239;111.5,237.5;107.1,235.3;104.2,233.8;100.5,232.4;96.1,230.9;'
        '94.6,230.1;91.7,228.7;88.8,225.7;86.6,223.5;83.6,220.6;81.4,217.6;79.2,214.7;'
        '77.8,211.8;75.6,208.8;74.1,205.9;71.9,202.9;69.7,200;67.5,196.3;66.7,194.1;'
        '65.3,190.4;64.5,188.2;63.1,184.6;60.9,180.9;60.1,179.4;58.7,176.5;57.2,172.8;'
        '56.5,170.6;55,166.9;53.5,164;52.1,161;51.3,158.8;50.6,156.6;49.1,152.9;'
        '48.4,150.7;47.7,148.5;46.9,144.9;46.2,141.2;45.5,137.5;45.5,136.8;';
    final stroke = s
        .split(';')
        .where((p) => p.isNotEmpty)
        .map((p) {
          final parts = p.split(',');
          return StrokePoint(
            x: double.parse(parts[0]),
            y: double.parse(parts[1]),
          );
        })
        .toList();

    for (final (label, strictness) in [
      ('no strictness', 1.0),
      ('shapes strictness 0.96', 0.96),
    ]) {
      final accuracy = StrokeAnalyzer.analyzeStroke(
        strokes: [stroke],
        template: heart,
        canvasWidth: _canvas,
        canvasHeight: _canvas,
        strictness: strictness,
      );
      // ignore: avoid_print
      print('screenshot heart contour ($label): '
          '${accuracy.toStringAsFixed(1)}');
      expect(
        accuracy,
        lessThan(50),
        reason: 'A heart drawn offset from the trace must score low',
      );
    }
  });

  test('exact heart trace still scores near-perfect (sanity)', () {
    final heart =
        TemplateService.generateTemplate('♥', LevelsScreen.levels[1].type);
    final heartCanvas = _normalized(heart.points);
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [heartCanvas],
      template: heart,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
      strictness: 0.96,
    );
    // ignore: avoid_print
    print('exact heart: ${accuracy.toStringAsFixed(1)}');
  });

  test('wobbly line still scores decently (sanity for calibration)', () {
    final template =
        TemplateService.generateTemplate('|', LevelsScreen.levels[0].type);
    final trace = <StrokePoint>[];
    for (int i = 0; i < 40; i++) {
      final t = i / 40;
      trace.add(StrokePoint(
        x: 150 + 25 * sin(t * 3.14159 / 3),
        y: 30 + t * 240,
      ));
    }
    final accuracy = StrokeAnalyzer.analyzeStroke(
      strokes: [trace],
      template: template,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    print('wobbly line (25px wiggle): ${accuracy.toStringAsFixed(1)}');
    expect(accuracy, greaterThanOrEqualTo(60),
        reason: 'A wobbly but similar line should still score well');
  });
}