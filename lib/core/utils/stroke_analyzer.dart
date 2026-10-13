import 'dart:math';
import 'package:ai_tracer/features/tracing/models/stroke_point.dart';
import 'package:ai_tracer/features/tracing/models/tracing_template.dart';

/// Scores how closely a set of drawn strokes follows the template path.
///
/// The template is a *reference*, not a dot-to-dot target: a stroke that
/// follows the same line with a bit of wobble scores well, while strokes
/// that are too far away, cross the line, or don't cover the template
/// score low. Only the best stroke counts; extra strokes add a small
/// penalty so scribbling over the canvas doesn't inflate the score.
class StrokeAnalyzer {
  /// Tolerances tuned for young children: the template is a *reference* —
  /// a stroke that is similar (roughly the same shape, with a bit of wobble
  /// or offset) scores well; strokes that are a different shape, direction,
  /// or far away still score low.
  static const double _distanceFalloff = 36.0; // px off-path where distance score reaches 0
  static const double _matchRadius = 26.0; // px band that counts as "on the path"
  static const double _templateSampleStep = 8.0; // px between template samples
  static const double _extraStrokePenalty = 5.0; // per extra stroke
  static const double _maxExtraStrokePenalty = 20.0;

  static const double _distanceWeight = 0.45;
  static const double _userCoverageWeight = 0.15;
  static const double _templateCoverageWeight = 0.4;

  static double analyzeStroke({
    required List<List<StrokePoint>> strokes,
    required TracingTemplate template,
    required double canvasWidth,
    required double canvasHeight,
    double strictness = 1.0,
  }) {
    if (strokes.isEmpty || template.points.length < 2) {
      return 0.0;
    }

    final templatePaths = _scaleTemplate(template, canvasWidth, canvasHeight);
    if (templatePaths.isEmpty) return 0.0;
    final templateSamples = <StrokePoint>[];
    for (final path in templatePaths) {
      templateSamples.addAll(_samplePath(path, _templateSampleStep));
    }
    if (templateSamples.isEmpty) return 0.0;

    // Shape quality: score the best single stroke's distance + on-path
    // fraction.  (A single clean stroke = good.  Scribbles that never
    // touch the path score low.)
    var bestShape = 0.0;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      bestShape = max(bestShape, _shapeScore(stroke, templatePaths));
    }
    if (bestShape == 0) return 0.0;

    // Template coverage: how much of the template the drawing covers.
    // For multi-stroke letters (e.g. A = 3 strokes) any child stroke may
    // contribute to covering the full letter. For single-stroke templates
    // only the best stroke counts, so several scribbles cannot combine to
    // "cover" the shape.
    final double templateCoverage;
    if (templatePaths.length > 1) {
      templateCoverage = _templateCoverageAll(strokes, templateSamples);
    } else {
      var bestCoverage = 0.0;
      for (final stroke in strokes) {
        if (stroke.length < 2) continue;
        bestCoverage =
            max(bestCoverage, _templateCoverageAll([stroke], templateSamples));
      }
      templateCoverage = bestCoverage;
    }

    // Combine: bestShape is already on a 0‑60 scale (0.45+0.15), coverage
    // adds the remaining 0.4 weight.
    var raw = (bestShape + templateCoverage * _templateCoverageWeight)
        .clamp(0, 100);

    // Extra strokes beyond the template's own stroke count are scribbles.
    // For multi‑stroke letters this correctly allows the expected number of
    // strokes without penalty.
    final extra = max(0, strokes.length - templatePaths.length);
    final penalty = min(extra * _extraStrokePenalty, _maxExtraStrokePenalty);
    raw = max(0.0, raw - penalty).clamp(0, 100);

    // A shape drawn in the wrong place (e.g. a heart shifted sideways) must
    // not score well just because its outline is similar. Compare where the
    // whole drawing sits against where the template sits.
    final positionPenalty = _positionPenalty(strokes, templatePaths);
    final adjusted = max(0.0, raw - positionPenalty).clamp(0, 100);

    // strictness < 1.0 makes some levels (e.g. shapes) harder to ace.
    return (adjusted * strictness).clamp(0, 100);
  }

  /// distanceScore * _distanceWeight + userCoverage * _userCoverageWeight,
  /// i.e. how well a single stroke follows the template shape (0‑60 scale).
  static double _shapeScore(
    List<StrokePoint> stroke,
    List<List<StrokePoint>> paths,
  ) {
    double totalDistance = 0;
    var onPathCount = 0;
    for (final point in stroke) {
      final distance = _distanceToPaths(point, paths);
      totalDistance += distance;
      if (distance <= _matchRadius) onPathCount++;
    }
    final avgDistance = totalDistance / stroke.length;
    final distanceScore = max(0.0, 100 * (1 - avgDistance / _distanceFalloff));
    final userCoverage = (onPathCount / stroke.length) * 100;
    return distanceScore * _distanceWeight +
        userCoverage * _userCoverageWeight;
  }

  /// Fraction of the template samples covered by ANY user stroke.
  static double _templateCoverageAll(
    List<List<StrokePoint>> strokes,
    List<StrokePoint> templateSamples,
  ) {
    if (strokes.isEmpty || templateSamples.isEmpty) return 0.0;
    var covered = 0;
    for (final sample in templateSamples) {
      hit:
      for (final stroke in strokes) {
        for (final point in stroke) {
          final dx = point.x - sample.x;
          final dy = point.y - sample.y;
          if (dx * dx + dy * dy <= _matchRadius * _matchRadius) {
            covered++;
            break hit;
          }
        }
      }
    }
    return (covered / templateSamples.length) * 100;
  }

  /// Penalty (0..30) when the drawing sits clearly off-center from the
  /// template. Compares the bounding-box centers (not the mean point, which
  /// a partial trace would bias). Small offsets — a bit of wobble or sloppy
  /// placement — are free; a clearly misplaced drawing loses points.
  static double _positionPenalty(
    List<List<StrokePoint>> strokes,
    List<List<StrokePoint>> templatePaths,
  ) {
    double? sMinX, sMaxX, sMinY, sMaxY;
    for (final stroke in strokes) {
      for (final p in stroke) {
        sMinX = sMinX == null ? p.x : min(sMinX, p.x);
        sMaxX = sMaxX == null ? p.x : max(sMaxX, p.x);
        sMinY = sMinY == null ? p.y : min(sMinY, p.y);
        sMaxY = sMaxY == null ? p.y : max(sMaxY, p.y);
      }
    }
    double? tMinX, tMaxX, tMinY, tMaxY;
    for (final path in templatePaths) {
      for (final p in path) {
        tMinX = tMinX == null ? p.x : min(tMinX, p.x);
        tMaxX = tMaxX == null ? p.x : max(tMaxX, p.x);
        tMinY = tMinY == null ? p.y : min(tMinY, p.y);
        tMaxY = tMaxY == null ? p.y : max(tMaxY, p.y);
      }
    }
    if (sMinX == null || tMinX == null) return 0.0;

    final dx = (sMinX + sMaxX!) / 2 - (tMinX + tMaxX!) / 2;
    final dy = (sMinY! + sMaxY!) / 2 - (tMinY! + tMaxY!) / 2;
    final offset = sqrt(dx * dx + dy * dy);
    // Up to ~10px of sloppiness is free; beyond that, 3 points per px.
    return (max(0.0, offset - 10) * 3).clamp(0, 30);
  }

  /// Distance from a point to the nearest segment of any template stroke.
  static double _distanceToPaths(
    StrokePoint p,
    List<List<StrokePoint>> paths,
  ) {
    var minDistance = double.infinity;
    for (final path in paths) {
      for (int i = 0; i < path.length - 1; i++) {
        final distance = _distanceToSegment(p, path[i], path[i + 1]);
        if (distance < minDistance) minDistance = distance;
      }
    }
    return minDistance;
  }

  static double _distanceToSegment(
      StrokePoint p, StrokePoint a, StrokePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    var t = lengthSquared == 0
        ? 0.0
        : ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);
    final cx = a.x + t * dx;
    final cy = a.y + t * dy;
    return sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
  }

  /// Evenly spaced points along the template path.
  static List<StrokePoint> _samplePath(List<StrokePoint> path, double step) {
    final samples = <StrokePoint>[path.first];
    var remaining = step;
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final length = sqrt(dx * dx + dy * dy);
      if (length == 0) continue;
      var walked = 0.0;
      while (walked + remaining <= length) {
        walked += remaining;
        final t = walked / length;
        samples.add(StrokePoint(x: a.x + dx * t, y: a.y + dy * t));
        remaining = step;
      }
      remaining -= (length - walked);
    }
    if (samples.length == 1 && path.length > 1) {
      samples.add(path.last);
    }
    return samples;
  }

  /// Same mapping TemplatePainter uses, so the child is judged against
  /// exactly what is drawn on screen. Multi-stroke templates keep their
  /// strokes separate so jump segments are never part of the judged path.
  static List<List<StrokePoint>> _scaleTemplate(
    TracingTemplate template,
    double width,
    double height,
  ) {
    List<StrokePoint> scale(List<StrokePoint> points) => points
        .map((point) => StrokePoint(x: point.x * width, y: point.y * height))
        .toList();
    if (template.strokes.isNotEmpty) {
      return template.strokes.map(scale).toList();
    }
    return [scale(template.points)];
  }
}
