import 'dart:math' as math;

import 'package:ai_tracer/features/levels/models/level.dart';
import '../models/stroke_point.dart';
import '../models/tracing_template.dart';

class TemplateService {
  static TracingTemplate generateTemplate(String character, LevelType type) {
    switch (type) {
      case LevelType.lines:
        return _generateLineTemplate(character);
      case LevelType.shapes:
        return _generateShapeTemplate(character);
      case LevelType.numbers:
        return _generateNumberTemplate(character);
      case LevelType.capitalLetters:
        return _generateLetterTemplate(character, isCapital: true);
      case LevelType.smallLetters:
        return _generateLetterTemplate(character, isCapital: false);
      case LevelType.sentences:
        return _generateSentenceTemplate(character);
    }
  }

  static TracingTemplate _generateLineTemplate(String character) {
    List<StrokePoint> points = [];

    switch (character) {
      case '|':
        points = [
          StrokePoint(x: 0.5, y: 0.1),
          StrokePoint(x: 0.5, y: 0.9),
        ];
        break;
      case '-':
        points = [
          StrokePoint(x: 0.1, y: 0.5),
          StrokePoint(x: 0.9, y: 0.5),
        ];
        break;
      case '/':
        points = [
          StrokePoint(x: 0.2, y: 0.8),
          StrokePoint(x: 0.8, y: 0.2),
        ];
        break;
      case '\\':
        points = [
          StrokePoint(x: 0.2, y: 0.2),
          StrokePoint(x: 0.8, y: 0.8),
        ];
        break;
      case 'V':
        points = [
          StrokePoint(x: 0.2, y: 0.2),
          StrokePoint(x: 0.5, y: 0.8),
          StrokePoint(x: 0.8, y: 0.2),
        ];
        break;
      case '^':
        points = [
          StrokePoint(x: 0.2, y: 0.8),
          StrokePoint(x: 0.5, y: 0.2),
          StrokePoint(x: 0.8, y: 0.8),
        ];
        break;
      case '~':
        // Gentle wave: down, up, down — like a tilde.
        points = _smooth([
          StrokePoint(x: 0.12, y: 0.42),
          StrokePoint(x: 0.32, y: 0.64),
          StrokePoint(x: 0.5, y: 0.5),
          StrokePoint(x: 0.68, y: 0.36),
          StrokePoint(x: 0.88, y: 0.58),
        ]);
        break;
      case '⌒':
        // Smooth arch from right to left (screen coords: top bulge).
        points = _arcPoints(
          cx: 0.5,
          cy: 0.66,
          rx: 0.34,
          ry: 0.32,
          startAngle: 0,
          endAngle: math.pi,
          segments: 18,
        );
        break;
      default:
        points = [
          StrokePoint(x: 0.5, y: 0.1),
          StrokePoint(x: 0.5, y: 0.9),
        ];
    }

    return TracingTemplate.line(
      id: 'line_$character',
      character: character,
      points: points,
    );
  }

  static TracingTemplate _generateShapeTemplate(String character) {
    switch (character) {
      case 'O':
        return TracingTemplate(
          id: 'shape_O',
          character: character,
          points: _circlePoints(),
        );
      case '□':
        return TracingTemplate(
          id: 'shape_square',
          character: character,
          points: [
            StrokePoint(x: 0.2, y: 0.2),
            StrokePoint(x: 0.8, y: 0.2),
            StrokePoint(x: 0.8, y: 0.8),
            StrokePoint(x: 0.2, y: 0.8),
            StrokePoint(x: 0.2, y: 0.2),
          ],
        );
      case '△':
        return TracingTemplate(
          id: 'shape_triangle',
          character: character,
          points: [
            StrokePoint(x: 0.5, y: 0.15),
            StrokePoint(x: 0.85, y: 0.8),
            StrokePoint(x: 0.15, y: 0.8),
            StrokePoint(x: 0.5, y: 0.15),
          ],
        );
      case '☆':
        return TracingTemplate(
          id: 'shape_star',
          character: character,
          points: _starPoints(),
        );
      case '♥':
        return TracingTemplate(
          id: 'shape_heart',
          character: character,
          points: _heartPoints(),
        );
      case '◇':
        return TracingTemplate(
          id: 'shape_diamond',
          character: character,
          points: _regularPolygonPoints(sides: 4),
        );
      case '⬠':
        return TracingTemplate(
          id: 'shape_pentagon',
          character: character,
          points: _regularPolygonPoints(sides: 5),
        );
      case '⬡':
        return TracingTemplate(
          id: 'shape_hexagon',
          character: character,
          points: _regularPolygonPoints(sides: 6),
        );
      default:
        // Fallback diamond for unknown shape characters.
        return TracingTemplate(
          id: 'shape_$character',
          character: character,
          points: [
            StrokePoint(x: 0.5, y: 0.2),
            StrokePoint(x: 0.8, y: 0.5),
            StrokePoint(x: 0.5, y: 0.8),
            StrokePoint(x: 0.2, y: 0.5),
            StrokePoint(x: 0.5, y: 0.2),
          ],
        );
    }
  }

  static List<StrokePoint> _circlePoints({int segments = 24}) {
    final points = <StrokePoint>[];
    for (int i = 0; i <= segments; i++) {
      final angle = 2 * math.pi * i / segments;
      points.add(StrokePoint(
        x: 0.5 + 0.3 * math.cos(angle),
        y: 0.5 + 0.3 * math.sin(angle),
      ));
    }
    return points;
  }

  /// A closed, centered regular polygon with [sides] vertices, first
  /// vertex at the top, drawn clockwise (screen coords).
  static List<StrokePoint> _regularPolygonPoints({required int sides}) {
    const radius = 0.34;
    final points = <StrokePoint>[];
    for (int i = 0; i <= sides; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / sides;
      points.add(StrokePoint(
        x: 0.5 + radius * math.cos(angle),
        y: 0.52 + radius * math.sin(angle),
      ));
    }
    return points;
  }

  static List<StrokePoint> _starPoints() {
    const outerRadius = 0.34;
    const innerRadius = 0.15;
    final points = <StrokePoint>[];
    for (int i = 0; i <= 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + math.pi * i / 5;
      points.add(StrokePoint(
        x: 0.5 + radius * math.cos(angle),
        y: 0.52 + radius * math.sin(angle),
      ));
    }
    return points;
  }

  static List<StrokePoint> _heartPoints({int segments = 40}) {
    // Parametric heart curve: x = 16sin³t, y = -(13cos t - 5cos 2t
    // - 2cos 3t - cos 4t); normalized below to fit the canvas box.
    final raw = <math.Point<double>>[];
    for (int i = 0; i <= segments; i++) {
      final t = 2 * math.pi * i / segments;
      final sinT = math.sin(t);
      final x = 16 * sinT * sinT * sinT;
      final y = -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t));
      raw.add(math.Point<double>(x, y));
    }

    var minX = raw.first.x, maxX = raw.first.x;
    var minY = raw.first.y, maxY = raw.first.y;
    for (final p in raw) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }

    // Uniform scale preserving aspect, centered on the canvas.
    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final scale = 0.62 / math.max(spanX, spanY);

    return raw.map((p) {
      return StrokePoint(
        x: 0.5 + (p.x - (minX + maxX) / 2) * scale,
        y: 0.5 + (p.y - (minY + maxY) / 2) * scale,
      );
    }).toList();
  }

  static TracingTemplate _generateNumberTemplate(String character) {
    List<StrokePoint> points;
    switch (character) {
      case '0':
        points = _arcPoints(
          cx: 0.5,
          cy: 0.5,
          rx: 0.27,
          ry: 0.33,
          startAngle: 0,
          endAngle: 2 * math.pi,
          segments: 20,
        );
        break;
      case '1':
        points = [
          StrokePoint(x: 0.38, y: 0.28),
          StrokePoint(x: 0.54, y: 0.2),
          StrokePoint(x: 0.52, y: 0.8),
        ];
        break;
      case '2':
        points = [
          StrokePoint(x: 0.35, y: 0.34),
          StrokePoint(x: 0.42, y: 0.22),
          StrokePoint(x: 0.55, y: 0.2),
          StrokePoint(x: 0.64, y: 0.28),
          StrokePoint(x: 0.67, y: 0.42),
          StrokePoint(x: 0.34, y: 0.74),
          StrokePoint(x: 0.66, y: 0.76),
        ];
        break;
      case '3':
        points = [
          StrokePoint(x: 0.36, y: 0.26),
          StrokePoint(x: 0.55, y: 0.2),
          StrokePoint(x: 0.66, y: 0.28),
          StrokePoint(x: 0.64, y: 0.42),
          StrokePoint(x: 0.4, y: 0.5),
          StrokePoint(x: 0.62, y: 0.56),
          StrokePoint(x: 0.66, y: 0.7),
          StrokePoint(x: 0.5, y: 0.78),
          StrokePoint(x: 0.36, y: 0.74),
        ];
        break;
      case '4':
        // Two strokes: diagonal + full crossbar, then the stem on the right
        // side (crossbar extends past the stem, like the printed 4).
        return TracingTemplate(
          id: 'number_4',
          character: character,
          points: [
            StrokePoint(x: 0.55, y: 0.18),
            StrokePoint(x: 0.24, y: 0.47),
            StrokePoint(x: 0.69, y: 0.47),
            StrokePoint(x: 0.56, y: 0.47),
            StrokePoint(x: 0.56, y: 0.82),
          ],
          strokes: [
            [
              StrokePoint(x: 0.55, y: 0.18),
              StrokePoint(x: 0.24, y: 0.47),
              StrokePoint(x: 0.69, y: 0.47),
            ],
            [
              StrokePoint(x: 0.56, y: 0.47),
              StrokePoint(x: 0.56, y: 0.82),
            ],
          ],
        );
      case '5':
        // Three separate strokes: top bar, stem down the left, and a wide
        // oval belly as far across as the bar, touching the stem and
        // reaching the baseline — like the printed 5.
        return TracingTemplate(
          id: 'number_5',
          character: character,
          points: [
            StrokePoint(x: 0.32, y: 0.2),
            StrokePoint(x: 0.68, y: 0.2),
            StrokePoint(x: 0.32, y: 0.2),
            StrokePoint(x: 0.32, y: 0.5),
            ..._arcPoints(
              cx: 0.5,
              cy: 0.62,
              rx: 0.18,
              ry: 0.155,
              startAngle: 0,
              endAngle: 2 * math.pi,
              segments: 20,
            ),
          ],
          strokes: [
            [
              StrokePoint(x: 0.32, y: 0.2),
              StrokePoint(x: 0.68, y: 0.2),
            ],
            [StrokePoint(x: 0.32, y: 0.2), StrokePoint(x: 0.32, y: 0.5)],
            _arcPoints(
              cx: 0.5,
              cy: 0.62,
              rx: 0.18,
              ry: 0.155,
              startAngle: 0,
              endAngle: 2 * math.pi,
              segments: 20,
            ),
          ],
        );
      case '6':
        // A small top hook flowing into one big full loop.
        points = [
          StrokePoint(x: 0.56, y: 0.18),
          StrokePoint(x: 0.46, y: 0.15),
          StrokePoint(x: 0.36, y: 0.22),
          StrokePoint(x: 0.32, y: 0.36),
          StrokePoint(x: 0.3, y: 0.5),
          StrokePoint(x: 0.31, y: 0.58),
          ..._arcPoints(
            cx: 0.5,
            cy: 0.58,
            rx: 0.19,
            ry: 0.19,
            startAngle: math.pi,
            endAngle: 3 * math.pi,
            segments: 20,
          ),
        ];
        break;
      case '7':
        points = [
          StrokePoint(x: 0.34, y: 0.26),
          StrokePoint(x: 0.66, y: 0.26),
          StrokePoint(x: 0.42, y: 0.8),
        ];
        break;
      case '8':
        // Two full round loops, touching at the middle. Each loop is its
        // own stroke, so no straight line cuts through either of them,
        // and they meet without overlapping.
        return TracingTemplate(
          id: 'number_8',
          character: character,
          points: [
            ..._arcPoints(
              cx: 0.5,
              cy: 0.355,
              rx: 0.165,
              ry: 0.165,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
            ..._arcPoints(
              cx: 0.5,
              cy: 0.685,
              rx: 0.165,
              ry: 0.165,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
          ],
          strokes: [
            _arcPoints(
              cx: 0.5,
              cy: 0.355,
              rx: 0.165,
              ry: 0.165,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
            _arcPoints(
              cx: 0.5,
              cy: 0.685,
              rx: 0.165,
              ry: 0.165,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
          ],
        );
      case '9':
        // Two strokes: a round top loop, then a mostly vertical tail
        // descending from the loop's bottom-right to the baseline with
        // only a gentle settle at the end — like the printed 9.
        return TracingTemplate(
          id: 'number_9',
          character: character,
          points: [
            ..._arcPoints(
              cx: 0.5,
              cy: 0.35,
              rx: 0.15,
              ry: 0.15,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
            ..._smooth([
              StrokePoint(x: 0.61, y: 0.46),
              StrokePoint(x: 0.65, y: 0.54),
              StrokePoint(x: 0.665, y: 0.63),
              StrokePoint(x: 0.66, y: 0.72),
              StrokePoint(x: 0.63, y: 0.78),
              StrokePoint(x: 0.58, y: 0.81),
            ]),
          ],
          strokes: [
            _arcPoints(
              cx: 0.5,
              cy: 0.35,
              rx: 0.15,
              ry: 0.15,
              startAngle: math.pi / 2,
              endAngle: math.pi / 2 - 2 * math.pi,
              segments: 20,
            ),
            _smooth([
              StrokePoint(x: 0.61, y: 0.46),
              StrokePoint(x: 0.65, y: 0.54),
              StrokePoint(x: 0.665, y: 0.63),
              StrokePoint(x: 0.66, y: 0.72),
              StrokePoint(x: 0.63, y: 0.78),
              StrokePoint(x: 0.58, y: 0.81),
            ]),
          ],
        );
      default:
        // Fallback: a wide oval so unknown digits are never a plain line.
        points = _arcPoints(
          cx: 0.5,
          cy: 0.5,
          rx: 0.27,
          ry: 0.33,
          startAngle: 0,
          endAngle: 2 * math.pi,
          segments: 20,
        );
    }

    return TracingTemplate.line(
      id: 'number_$character',
      character: character,
      points: points,
    );
  }

  /// Arc from [startAngle] to [endAngle] around (cx, cy). Screen coords:
  /// y grows downward, so angles are measured clockwise from +x.
  static List<StrokePoint> _arcPoints({
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required double startAngle,
    required double endAngle,
    int segments = 16,
  }) {
    final points = <StrokePoint>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = startAngle + (endAngle - startAngle) * t;
      points.add(StrokePoint(
        x: cx + rx * math.cos(angle),
        y: cy - ry * math.sin(angle),
      ));
    }
    return points;
  }

  /// A smooth (Catmull-Rom) spline through [ctrl] points, so hand-placed
  /// control points render as flowing curves instead of polyline kinks.
  static List<StrokePoint> _smooth(List<StrokePoint> ctrl,
      {int samplesPerSeg = 8}) {
    final out = <StrokePoint>[];
    for (int i = 0; i < ctrl.length - 1; i++) {
      final p0 = ctrl[i == 0 ? 0 : i - 1];
      final p2 = ctrl[i + 1];
      final p3 = ctrl[i + 2 < ctrl.length ? i + 2 : ctrl.length - 1];
      for (int s = 0; s < samplesPerSeg; s++) {
        final t = s / samplesPerSeg;
        final t2 = t * t;
        final t3 = t2 * t;
        out.add(StrokePoint(
          x: 0.5 *
              (2 * ctrl[i].x +
                  (-p0.x + p2.x) * t +
                  (2 * p0.x - 5 * ctrl[i].x + 4 * p2.x - p3.x) * t2 +
                  (-p0.x + 3 * ctrl[i].x - 3 * p2.x + p3.x) * t3),
          y: 0.5 *
              (2 * ctrl[i].y +
                  (-p0.y + p2.y) * t +
                  (2 * p0.y - 5 * ctrl[i].y + 4 * p2.y - p3.y) * t2 +
                  (-p0.y + 3 * ctrl[i].y - 3 * p2.y + p3.y) * t3),
        ));
      }
    }
    out.add(ctrl.last);
    return out;
  }

  static TracingTemplate _generateLetterTemplate(
    String character, {
    required bool isCapital,
  }) {
    final strokes =
        isCapital ? _capitalStrokes(character) : _lowercaseStrokes(character);
    final points = [for (final s in strokes) ...s];
    return TracingTemplate(
      id: '${isCapital ? "cap" : "small"}_$character',
      character: character,
      points: points,
      strokes: strokes,
    );
  }

  static List<List<StrokePoint>> _lowercaseStrokes(String character) {
    switch (character) {
      case 'a':
        // Round bowl + right stem, like the printed a.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.14,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
          [
            StrokePoint(x: 0.64, y: 0.5),
            StrokePoint(x: 0.64, y: 0.78),
          ],
        ];
      case 'b':
        // Ascender on the bowl's left edge + round bowl sitting on the
        // baseline (bowl bottom = 0.78, same as every other small letter).
        return [
          [StrokePoint(x: 0.35, y: 0.78), StrokePoint(x: 0.35, y: 0.2)],
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.15,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
        ];
      case 'c':
        // Open circle: starts top-right, flows over the top, around the
        // left and bottom, and ends bottom-right — like the printed c.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.155,
            ry: 0.17,
            startAngle: 55 * math.pi / 180,
            endAngle: 305 * math.pi / 180,
            segments: 18,
          ),
        ];
      case 'd':
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.15,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
          // Ascender on the bowl's right edge.
          [StrokePoint(x: 0.65, y: 0.2), StrokePoint(x: 0.65, y: 0.5)],
        ];
      case 'e':
        // Open circle body (like c) with a horizontal bar across the
        // opening, which is how the printed e is drawn.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.155,
            ry: 0.17,
            startAngle: 55 * math.pi / 180,
            endAngle: 305 * math.pi / 180,
            segments: 18,
          ),
          [
            StrokePoint(x: 0.37, y: 0.64),
            StrokePoint(x: 0.65, y: 0.64),
          ],
        ];
      case 'f':
        // Ascender with a curved top hook + crossbar.
        return [
          [
            StrokePoint(x: 0.44, y: 0.78),
            StrokePoint(x: 0.44, y: 0.3),
            StrokePoint(x: 0.5, y: 0.2),
            StrokePoint(x: 0.6, y: 0.22),
          ],
          [StrokePoint(x: 0.32, y: 0.55), StrokePoint(x: 0.6, y: 0.55)],
        ];
      case 'g':
        // Round bowl + curvy descender loop.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.15,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
          _smooth([
            StrokePoint(x: 0.65, y: 0.62),
            StrokePoint(x: 0.65, y: 0.74),
            StrokePoint(x: 0.6, y: 0.84),
            StrokePoint(x: 0.5, y: 0.88),
            StrokePoint(x: 0.42, y: 0.86),
            StrokePoint(x: 0.38, y: 0.8),
          ]),
        ];
      case 'h':
        return [
          [StrokePoint(x: 0.3, y: 0.78), StrokePoint(x: 0.3, y: 0.2)],
          _smooth([
            StrokePoint(x: 0.3, y: 0.5),
            StrokePoint(x: 0.38, y: 0.44),
            StrokePoint(x: 0.52, y: 0.44),
            StrokePoint(x: 0.6, y: 0.5),
            StrokePoint(x: 0.6, y: 0.78),
          ]),
        ];
      case 'i':
        return [
          [StrokePoint(x: 0.45, y: 0.45), StrokePoint(x: 0.45, y: 0.78)],
          [StrokePoint(x: 0.42, y: 0.28), StrokePoint(x: 0.48, y: 0.28)],
        ];
      case 'j':
        return [
          _smooth([
            StrokePoint(x: 0.5, y: 0.45),
            StrokePoint(x: 0.5, y: 0.72),
            StrokePoint(x: 0.44, y: 0.82),
            StrokePoint(x: 0.36, y: 0.84),
            StrokePoint(x: 0.3, y: 0.78),
          ]),
          [StrokePoint(x: 0.47, y: 0.28), StrokePoint(x: 0.53, y: 0.28)],
        ];
      case 'k':
        // Ascender + arms meeting the stem at the exact middle, with a
        // shorter ascender and narrower span than the capital K.
        return [
          [StrokePoint(x: 0.32, y: 0.78), StrokePoint(x: 0.32, y: 0.26)],
          _smooth([
            StrokePoint(x: 0.56, y: 0.3),
            StrokePoint(x: 0.4, y: 0.46),
            StrokePoint(x: 0.33, y: 0.52),
            StrokePoint(x: 0.44, y: 0.64),
            StrokePoint(x: 0.56, y: 0.78),
          ]),
        ];
      case 'l':
        return [
          _smooth([
            StrokePoint(x: 0.44, y: 0.78),
            StrokePoint(x: 0.44, y: 0.28),
            StrokePoint(x: 0.47, y: 0.22),
            StrokePoint(x: 0.53, y: 0.2),
            StrokePoint(x: 0.6, y: 0.25),
          ]),
        ];
      case 'm':
        // Three stems joined by two round humps.
        return [
          _smooth([
            StrokePoint(x: 0.22, y: 0.78),
            StrokePoint(x: 0.22, y: 0.44),
            StrokePoint(x: 0.33, y: 0.38),
            StrokePoint(x: 0.44, y: 0.46),
            StrokePoint(x: 0.44, y: 0.78),
            StrokePoint(x: 0.55, y: 0.38),
            StrokePoint(x: 0.66, y: 0.46),
            StrokePoint(x: 0.66, y: 0.78),
          ]),
        ];
      case 'n':
        // Stem + one round hump.
        return [
          _smooth([
            StrokePoint(x: 0.24, y: 0.78),
            StrokePoint(x: 0.24, y: 0.44),
            StrokePoint(x: 0.34, y: 0.38),
            StrokePoint(x: 0.46, y: 0.46),
            StrokePoint(x: 0.46, y: 0.78),
          ]),
        ];
      case 'o':
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.15,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
        ];
      case 'p':
        // Bowl at x-height + descender below the baseline.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.14,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
          [
            StrokePoint(x: 0.36, y: 0.615),
            StrokePoint(x: 0.36, y: 0.88),
          ],
        ];
      case 'q':
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.615,
            rx: 0.14,
            ry: 0.165,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 16,
          ),
          _smooth([
            StrokePoint(x: 0.64, y: 0.615),
            StrokePoint(x: 0.64, y: 0.84),
            StrokePoint(x: 0.58, y: 0.9),
            StrokePoint(x: 0.5, y: 0.9),
          ]),
        ];
      case 'r':
        return [
          _smooth([
            StrokePoint(x: 0.26, y: 0.78),
            StrokePoint(x: 0.26, y: 0.46),
            StrokePoint(x: 0.36, y: 0.4),
            StrokePoint(x: 0.48, y: 0.46),
            StrokePoint(x: 0.52, y: 0.55),
          ]),
        ];
      case 's':
        return [
          _smooth([
            StrokePoint(x: 0.6, y: 0.5),
            StrokePoint(x: 0.5, y: 0.44),
            StrokePoint(x: 0.4, y: 0.48),
            StrokePoint(x: 0.36, y: 0.58),
            StrokePoint(x: 0.6, y: 0.66),
            StrokePoint(x: 0.64, y: 0.74),
            StrokePoint(x: 0.56, y: 0.8),
            StrokePoint(x: 0.44, y: 0.78),
          ]),
        ];
      case 't':
        return [
          [
            StrokePoint(x: 0.44, y: 0.78),
            StrokePoint(x: 0.44, y: 0.3),
            StrokePoint(x: 0.5, y: 0.2),
          ],
          [StrokePoint(x: 0.32, y: 0.56), StrokePoint(x: 0.6, y: 0.56)],
        ];
      case 'u':
        return [
          _smooth([
            StrokePoint(x: 0.26, y: 0.46),
            StrokePoint(x: 0.26, y: 0.68),
            StrokePoint(x: 0.34, y: 0.77),
            StrokePoint(x: 0.56, y: 0.77),
            StrokePoint(x: 0.64, y: 0.68),
            StrokePoint(x: 0.64, y: 0.46),
          ]),
        ];
      case 'v':
        return [
          [
            StrokePoint(x: 0.32, y: 0.46),
            StrokePoint(x: 0.5, y: 0.78),
            StrokePoint(x: 0.68, y: 0.46),
          ],
        ];
      case 'w':
        return [
          [
            StrokePoint(x: 0.2, y: 0.46),
            StrokePoint(x: 0.32, y: 0.78),
            StrokePoint(x: 0.44, y: 0.46),
            StrokePoint(x: 0.56, y: 0.78),
            StrokePoint(x: 0.68, y: 0.46),
          ],
        ];
      case 'x':
        return [
          [StrokePoint(x: 0.33, y: 0.46), StrokePoint(x: 0.67, y: 0.78)],
          [StrokePoint(x: 0.67, y: 0.46), StrokePoint(x: 0.33, y: 0.78)],
        ];
      case 'y':
        return [
          [StrokePoint(x: 0.26, y: 0.46), StrokePoint(x: 0.5, y: 0.68)],
          [
            StrokePoint(x: 0.74, y: 0.46),
            StrokePoint(x: 0.5, y: 0.68),
            StrokePoint(x: 0.5, y: 0.8),
            StrokePoint(x: 0.42, y: 0.9),
            StrokePoint(x: 0.32, y: 0.88),
          ],
        ];
      case 'z':
        return [
          [
            StrokePoint(x: 0.32, y: 0.46),
            StrokePoint(x: 0.68, y: 0.46),
            StrokePoint(x: 0.32, y: 0.78),
            StrokePoint(x: 0.68, y: 0.78),
          ],
        ];
      default:
        return [
          [
            StrokePoint(x: 0.3, y: 0.78),
            StrokePoint(x: 0.3, y: 0.46),
            StrokePoint(x: 0.7, y: 0.46),
            StrokePoint(x: 0.7, y: 0.78),
          ],
        ];
    }
  }

  static List<List<StrokePoint>> _capitalStrokes(String character) {
    switch (character) {
      case 'A':
        return [
          [StrokePoint(x: 0.5, y: 0.16), StrokePoint(x: 0.28, y: 0.84)],
          [StrokePoint(x: 0.5, y: 0.16), StrokePoint(x: 0.72, y: 0.84)],
          [StrokePoint(x: 0.36, y: 0.55), StrokePoint(x: 0.64, y: 0.55)],
        ];
      case 'B':
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          _smooth([
            StrokePoint(x: 0.3, y: 0.18),
            StrokePoint(x: 0.56, y: 0.24),
            StrokePoint(x: 0.66, y: 0.36),
            StrokePoint(x: 0.62, y: 0.5),
            StrokePoint(x: 0.3, y: 0.5),
            StrokePoint(x: 0.64, y: 0.6),
            StrokePoint(x: 0.68, y: 0.74),
            StrokePoint(x: 0.5, y: 0.82),
            StrokePoint(x: 0.3, y: 0.82),
          ]),
        ];
      case 'C':
        // Large open circle with the opening on the right, like the
        // printed capital C.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.5,
            rx: 0.21,
            ry: 0.3,
            startAngle: 55 * math.pi / 180,
            endAngle: 305 * math.pi / 180,
            segments: 22,
          ),
        ];
      case 'D':
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          _smooth([
            StrokePoint(x: 0.3, y: 0.18),
            StrokePoint(x: 0.5, y: 0.2),
            StrokePoint(x: 0.66, y: 0.3),
            StrokePoint(x: 0.72, y: 0.5),
            StrokePoint(x: 0.66, y: 0.7),
            StrokePoint(x: 0.5, y: 0.8),
            StrokePoint(x: 0.3, y: 0.82),
          ]),
        ];
      case 'E':
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.68, y: 0.18)],
          [StrokePoint(x: 0.3, y: 0.5), StrokePoint(x: 0.58, y: 0.5)],
          [StrokePoint(x: 0.3, y: 0.82), StrokePoint(x: 0.68, y: 0.82)],
        ];
      case 'F':
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.68, y: 0.18)],
          [StrokePoint(x: 0.3, y: 0.46), StrokePoint(x: 0.56, y: 0.46)],
        ];
      case 'G':
        // Round open circle (like C) plus a spur: a horizontal bar from
        // the left side across to the right edge, turning down.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.5,
            rx: 0.21,
            ry: 0.3,
            startAngle: 55 * math.pi / 180,
            endAngle: 305 * math.pi / 180,
            segments: 22,
          ),
          _smooth([
            StrokePoint(x: 0.3, y: 0.52),
            StrokePoint(x: 0.66, y: 0.52),
            StrokePoint(x: 0.71, y: 0.56),
            StrokePoint(x: 0.71, y: 0.66),
            StrokePoint(x: 0.66, y: 0.7),
          ]),
        ];
      case 'H':
        return [
          [StrokePoint(x: 0.28, y: 0.18), StrokePoint(x: 0.28, y: 0.82)],
          [StrokePoint(x: 0.72, y: 0.18), StrokePoint(x: 0.72, y: 0.82)],
          [StrokePoint(x: 0.28, y: 0.5), StrokePoint(x: 0.72, y: 0.5)],
        ];
      case 'I':
        return [
          [StrokePoint(x: 0.34, y: 0.18), StrokePoint(x: 0.66, y: 0.18)],
          [StrokePoint(x: 0.5, y: 0.18), StrokePoint(x: 0.5, y: 0.82)],
          [StrokePoint(x: 0.34, y: 0.82), StrokePoint(x: 0.66, y: 0.82)],
        ];
      case 'J':
        // Curved stem with a smooth hook at the bottom + top bar.
        return [
          _smooth([
            StrokePoint(x: 0.52, y: 0.18),
            StrokePoint(x: 0.52, y: 0.55),
            StrokePoint(x: 0.5, y: 0.66),
            StrokePoint(x: 0.42, y: 0.74),
            StrokePoint(x: 0.34, y: 0.76),
            StrokePoint(x: 0.3, y: 0.7),
          ]),
          [StrokePoint(x: 0.36, y: 0.18), StrokePoint(x: 0.62, y: 0.18)],
        ];
      case 'K':
        // Vertical + arms that join AT the stem: top arm from the upper
        // right down to the stem middle, then the leg down to baseline.
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          _smooth([
            StrokePoint(x: 0.68, y: 0.18),
            StrokePoint(x: 0.5, y: 0.34),
            StrokePoint(x: 0.33, y: 0.48),
            StrokePoint(x: 0.34, y: 0.52),
            StrokePoint(x: 0.46, y: 0.6),
            StrokePoint(x: 0.68, y: 0.82),
          ]),
        ];
      case 'L':
        return [
          [
            StrokePoint(x: 0.3, y: 0.18),
            StrokePoint(x: 0.3, y: 0.82),
            StrokePoint(x: 0.7, y: 0.82),
          ],
        ];
      case 'M':
        return [
          [
            StrokePoint(x: 0.2, y: 0.82),
            StrokePoint(x: 0.2, y: 0.18),
            StrokePoint(x: 0.5, y: 0.72),
            StrokePoint(x: 0.8, y: 0.18),
            StrokePoint(x: 0.8, y: 0.82),
          ],
        ];
      case 'N':
        return [
          [
            StrokePoint(x: 0.25, y: 0.82),
            StrokePoint(x: 0.25, y: 0.18),
            StrokePoint(x: 0.75, y: 0.82),
            StrokePoint(x: 0.75, y: 0.18),
          ],
        ];
      case 'O':
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.5,
            rx: 0.24,
            ry: 0.3,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 20,
          ),
        ];
      case 'P':
        // Vertical + rounder upper bump.
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          _smooth([
            StrokePoint(x: 0.3, y: 0.18),
            StrokePoint(x: 0.4, y: 0.2),
            StrokePoint(x: 0.54, y: 0.24),
            StrokePoint(x: 0.64, y: 0.32),
            StrokePoint(x: 0.68, y: 0.42),
            StrokePoint(x: 0.64, y: 0.5),
            StrokePoint(x: 0.3, y: 0.52),
          ]),
        ];
      case 'Q':
        // Round O + tail starting at the bottom-right edge.
        return [
          _arcPoints(
            cx: 0.5,
            cy: 0.5,
            rx: 0.24,
            ry: 0.28,
            startAngle: 0,
            endAngle: 2 * math.pi,
            segments: 20,
          ),
          _smooth([
            StrokePoint(x: 0.67, y: 0.68),
            StrokePoint(x: 0.74, y: 0.78),
            StrokePoint(x: 0.75, y: 0.88),
          ]),
        ];
      case 'R':
        // Vertical + rounder upper bump + curvy leg.
        return [
          [StrokePoint(x: 0.3, y: 0.18), StrokePoint(x: 0.3, y: 0.82)],
          _smooth([
            StrokePoint(x: 0.3, y: 0.18),
            StrokePoint(x: 0.4, y: 0.2),
            StrokePoint(x: 0.54, y: 0.24),
            StrokePoint(x: 0.64, y: 0.32),
            StrokePoint(x: 0.68, y: 0.42),
            StrokePoint(x: 0.64, y: 0.5),
            StrokePoint(x: 0.3, y: 0.52),
          ]),
          _smooth([
            StrokePoint(x: 0.3, y: 0.52),
            StrokePoint(x: 0.5, y: 0.6),
            StrokePoint(x: 0.62, y: 0.7),
            StrokePoint(x: 0.68, y: 0.82),
          ]),
        ];
      case 'S':
        return [
          _smooth([
            StrokePoint(x: 0.68, y: 0.28),
            StrokePoint(x: 0.56, y: 0.18),
            StrokePoint(x: 0.42, y: 0.2),
            StrokePoint(x: 0.34, y: 0.3),
            StrokePoint(x: 0.36, y: 0.44),
            StrokePoint(x: 0.58, y: 0.56),
            StrokePoint(x: 0.68, y: 0.68),
            StrokePoint(x: 0.62, y: 0.8),
            StrokePoint(x: 0.48, y: 0.82),
            StrokePoint(x: 0.36, y: 0.72),
          ]),
        ];
      case 'T':
        return [
          [StrokePoint(x: 0.28, y: 0.18), StrokePoint(x: 0.72, y: 0.18)],
          [StrokePoint(x: 0.5, y: 0.18), StrokePoint(x: 0.5, y: 0.82)],
        ];
      case 'U':
        // Two verticals with a round bottom curve.
        return [
          [
            StrokePoint(x: 0.28, y: 0.18),
            StrokePoint(x: 0.28, y: 0.6),
            ..._arcPoints(
              cx: 0.5,
              cy: 0.64,
              rx: 0.22,
              ry: 0.16,
              startAngle: math.pi,
              endAngle: 2 * math.pi,
              segments: 12,
            ),
            StrokePoint(x: 0.72, y: 0.6),
            StrokePoint(x: 0.72, y: 0.18),
          ],
        ];
      case 'V':
        return [
          [
            StrokePoint(x: 0.25, y: 0.18),
            StrokePoint(x: 0.5, y: 0.82),
            StrokePoint(x: 0.75, y: 0.18),
          ],
        ];
      case 'W':
        return [
          [
            StrokePoint(x: 0.15, y: 0.18),
            StrokePoint(x: 0.32, y: 0.82),
            StrokePoint(x: 0.5, y: 0.32),
            StrokePoint(x: 0.68, y: 0.82),
            StrokePoint(x: 0.85, y: 0.18),
          ],
        ];
      case 'X':
        return [
          [StrokePoint(x: 0.25, y: 0.18), StrokePoint(x: 0.75, y: 0.82)],
          [StrokePoint(x: 0.75, y: 0.18), StrokePoint(x: 0.25, y: 0.82)],
        ];
      case 'Y':
        return [
          [StrokePoint(x: 0.25, y: 0.18), StrokePoint(x: 0.5, y: 0.5)],
          [
            StrokePoint(x: 0.75, y: 0.18),
            StrokePoint(x: 0.5, y: 0.5),
            StrokePoint(x: 0.5, y: 0.82),
          ],
        ];
      case 'Z':
        return [
          [
            StrokePoint(x: 0.25, y: 0.18),
            StrokePoint(x: 0.75, y: 0.18),
            StrokePoint(x: 0.25, y: 0.82),
            StrokePoint(x: 0.75, y: 0.82),
          ],
        ];
      default:
        // Fallback: a simple recognizable shape.
        return [
          [
            StrokePoint(x: 0.3, y: 0.8),
            StrokePoint(x: 0.3, y: 0.2),
            StrokePoint(x: 0.7, y: 0.2),
            StrokePoint(x: 0.7, y: 0.8),
          ],
        ];
    }
  }

  static TracingTemplate _generateSentenceTemplate(String sentence) {
    // Compose the word from its letters (first letter capitalized), each
    // scaled and placed side by side in its own slot.
    final n = sentence.length;
    final spacing = 0.8 / n;
    final scale = (spacing * 0.85) / 0.7; // letter natural width is ~0.7
    final strokes = <List<StrokePoint>>[];
    final points = <StrokePoint>[];
    for (int i = 0; i < n; i++) {
      final char = sentence[i];
      final letter = _generateLetterTemplate(char, isCapital: i == 0);
      final cx = 0.5 + (i - (n - 1) / 2) * spacing;
      for (final stroke in letter.strokes) {
        final scaled = stroke
            .map((p) => StrokePoint(
                  x: cx + (p.x - 0.5) * scale,
                  y: p.y,
                ))
            .toList();
        strokes.add(scaled);
        points.addAll(scaled);
      }
    }
    return TracingTemplate(
      id: 'sentence_$sentence',
      character: sentence,
      points: points,
      strokes: strokes,
    );
  }
}
