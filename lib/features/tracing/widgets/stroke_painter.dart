import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/stroke_point.dart';

class StrokePainter extends CustomPainter {
  final List<StrokePoint> currentStroke;
  final List<List<StrokePoint>> completedStrokes;

  StrokePainter({
    required this.currentStroke,
    required this.completedStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final completedPaint = Paint()
      ..color = AppColors.activeStrokeColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in completedStrokes) {
      _drawStroke(canvas, stroke, completedPaint, size);
    }

    if (currentStroke.isNotEmpty) {
      final currentPaint = Paint()
        ..color = AppColors.activeStrokeColor.withOpacity(0.7)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, currentStroke, currentPaint, size);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<StrokePoint> stroke,
    Paint paint,
    Size size,
  ) {
    if (stroke.length < 2) return;

    final path = Path();
    path.moveTo(stroke.first.x, stroke.first.y);

    for (int i = 1; i < stroke.length; i++) {
      if (i < stroke.length - 1) {
        final midX = (stroke[i].x + stroke[i + 1].x) / 2;
        final midY = (stroke[i].y + stroke[i + 1].y) / 2;
        path.quadraticBezierTo(
          stroke[i].x,
          stroke[i].y,
          midX,
          midY,
        );
      } else {
        path.lineTo(stroke[i].x, stroke[i].y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
