import 'stroke_point.dart';

class TracingTemplate {
  final String id;
  final String character;
  final List<StrokePoint> points;
  final List<List<StrokePoint>> strokes;

  const TracingTemplate({
    required this.id,
    required this.character,
    required this.points,
    this.strokes = const [],
  });

  factory TracingTemplate.line({
    required String id,
    required String character,
    required List<StrokePoint> points,
  }) {
    return TracingTemplate(
      id: id,
      character: character,
      points: points,
      strokes: [points],
    );
  }
}
