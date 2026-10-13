import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/tracing_template.dart';

class TemplatePainter extends CustomPainter {
  final TracingTemplate template;

  TemplatePainter({required this.template});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.templateColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Multi-stroke templates draw each stroke as its own subpath so
    // disconnected parts of a letter are not joined by a straight line.
    final strokes = template.strokes.isNotEmpty
        ? template.strokes
        : [template.points];

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final scaledPoints = stroke.map((point) {
        return Offset(
          point.x * size.width,
          point.y * size.height,
        );
      }).toList();

      final path = Path()..moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
      for (int i = 1; i < scaledPoints.length; i++) {
        path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      }
      canvas.drawPath(path, paint);

      // Start dot: helps the child know where each stroke begins.
      canvas.drawCircle(
        scaledPoints.first,
        12,
        Paint()..color = AppColors.success.withOpacity(0.5),
      );

      // Direction arrows: one near the start and one near the end of the
      // stroke, both pointing along the drawing direction, so the child
      // knows where to begin and which way to go.
      _drawDirectionArrow(canvas, scaledPoints, atStart: true);
      _drawDirectionArrow(canvas, scaledPoints, atStart: false);
    }

    final dotPaint = Paint()..color = AppColors.primary.withOpacity(0.3);
    for (final stroke in strokes) {
      for (final point in stroke) {
        canvas.drawCircle(
          Offset(point.x * size.width, point.y * size.height),
          4,
          dotPaint,
        );
      }
    }
  }

  /// Draws a small triangle arrowhead on the stroke, centered at a point
  /// ~30 px from the start ([atStart] true) or from the end, pointing
  /// along the drawing direction.
  void _drawDirectionArrow(
    Canvas canvas,
    List<Offset> points, {
    required bool atStart,
  }) {
    const arrowLength = 16.0;
    const arrowHalfWidth = 6.5;
    final (position, dir) = _pathPointAndDirection(points, atStart: atStart);
    final tip = position + dir * (arrowLength / 2);
    final back = position - dir * (arrowLength / 2);
    final perpendicular = Offset(-dir.dy, dir.dx);
    final wingLeft = back + perpendicular * arrowHalfWidth;
    final wingRight = back - perpendicular * arrowHalfWidth;

    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(wingLeft.dx, wingLeft.dy)
      ..lineTo(wingRight.dx, wingRight.dy)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = AppColors.primary.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );
  }

  /// Walks the stroke and returns the point (and unit tangent) that sits
  /// [distance] pixels from its start, or from its end when [atStart] is
  /// false. Short strokes fall back to their overall direction.
  (Offset, Offset) _pathPointAndDirection(
    List<Offset> points, {
    required bool atStart,
    double distance = 30.0,
  }) {
    // Walk forward from the start or backward from the end so both
    // arrows share the same distance math.
    var remaining = distance;
    if (atStart) {
      for (int i = 0; i < points.length - 1; i++) {
        final (position, dir) = _walkSegment(points[i], points[i + 1], remaining);
        if (position != null) return (position, dir);
        remaining -= (points[i + 1] - points[i]).distance;
      }
    } else {
      for (int i = points.length - 2; i >= 0; i--) {
        final (position, dir) = _walkSegment(points[i], points[i + 1], remaining);
        if (position != null) return (position, dir);
        remaining -= (points[i + 1] - points[i]).distance;
      }
    }
    // Stroke shorter than the requested distance: use the overall direction.
    final a = points.first;
    final b = points.last;
    final length = (b - a).distance;
    final dir = length > 0.0001 ? (b - a) / length : const Offset(1, 0);
    return (atStart ? a : b, dir);
  }

  /// Returns the point [distance] along the segment a→b with its unit
  /// tangent, or null when the segment is shorter than [distance].
  (Offset?, Offset) _walkSegment(Offset a, Offset b, double distance) {
    final length = (b - a).distance;
    if (length <= 0.0001) return (null, Offset.zero);
    final dir = (b - a) / length;
    if (distance <= length) return (a + dir * distance, dir);
    return (null, dir);
  }


  @override
  bool shouldRepaint(covariant TemplatePainter oldDelegate) =>
      oldDelegate.template != template;
}
