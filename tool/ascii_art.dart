// Spot-check multi-stroke capital letters. Run: dart tool/ascii_art.dart
import 'dart:math' as math;
import 'dart:io';

class P {
  final double x, y;
  const P(this.x, this.y);
}

void draw(List<List<P>> strokes, String label) {
  const cols = 30, rows = 15;
  final grid = List.generate(rows, (_) => List.filled(cols, ' '));
  void plot(double x, double y) {
    final cx = ((x * (cols - 1)).round()).clamp(0, cols - 1);
    final cy = ((y * (rows - 1)).round()).clamp(0, rows - 1);
    grid[cy][cx] = '#';
  }
  void drawPath(List<P> path) {
    if (path.isEmpty) return;
    plot(path.first.x, path.first.y);
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i], b = path[i + 1];
      final steps = math.max(((b.x - a.x).abs() * 30).round(), ((b.y - a.y).abs() * 15).round()).clamp(1, 200);
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        plot(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
      }
    }
  }
  for (final path in strokes) {
    drawPath(path);
  }
  stdout.writeln('--- $label ---');
  for (final row in grid) {
    stdout.writeln('|${row.join()}');
  }
}

void main() {
  draw([
    [const P(0.5, 0.16), const P(0.28, 0.84)],
    [const P(0.5, 0.16), const P(0.72, 0.84)],
    [const P(0.36, 0.55), const P(0.64, 0.55)],
  ], 'A');

  draw([
    [const P(0.3, 0.18), const P(0.3, 0.82)],
    [const P(0.3, 0.18), const P(0.56, 0.24), const P(0.66, 0.36), const P(0.62, 0.5), const P(0.3, 0.5), const P(0.64, 0.6), const P(0.68, 0.74), const P(0.5, 0.82), const P(0.3, 0.82)],
  ], 'B');

  draw([
    [const P(0.3, 0.18), const P(0.3, 0.82)],
    [const P(0.3, 0.18), const P(0.5, 0.2), const P(0.66, 0.3), const P(0.72, 0.5), const P(0.66, 0.7), const P(0.5, 0.8), const P(0.3, 0.82)],
  ], 'D');

  draw([
    [const P(0.3, 0.18), const P(0.3, 0.82)],
    [const P(0.3, 0.18), const P(0.68, 0.18)],
    [const P(0.3, 0.5), const P(0.58, 0.5)],
    [const P(0.3, 0.82), const P(0.68, 0.82)],
  ], 'E');

  draw([
    [const P(0.66, 0.26), const P(0.5, 0.18), const P(0.36, 0.2), const P(0.3, 0.34), const P(0.3, 0.66), const P(0.36, 0.8), const P(0.5, 0.82)],
    [const P(0.5, 0.55), const P(0.68, 0.55), const P(0.68, 0.72)],
  ], 'G');

  draw([
    [const P(0.28, 0.18), const P(0.28, 0.82)],
    [const P(0.72, 0.18), const P(0.72, 0.82)],
    [const P(0.28, 0.5), const P(0.72, 0.5)],
  ], 'H');

  draw([
    [const P(0.3, 0.18), const P(0.3, 0.82)],
    [const P(0.68, 0.2), const P(0.36, 0.5), const P(0.68, 0.8)],
  ], 'K');

  draw([
    [const P(0.3, 0.18), const P(0.3, 0.82)],
    [const P(0.3, 0.18), const P(0.56, 0.24), const P(0.66, 0.36), const P(0.6, 0.5), const P(0.3, 0.52)],
    [const P(0.3, 0.52), const P(0.68, 0.82)],
  ], 'R');

  draw([
    [const P(0.25, 0.18), const P(0.5, 0.5)],
    [const P(0.75, 0.18), const P(0.5, 0.5), const P(0.5, 0.82)],
  ], 'Y');
}