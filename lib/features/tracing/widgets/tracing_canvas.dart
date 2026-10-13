import 'package:flutter/material.dart';

import '../models/stroke_point.dart';
import '../models/tracing_template.dart';
import 'template_painter.dart';
import 'stroke_painter.dart';

class TracingCanvas extends StatefulWidget {
  final TracingTemplate template;
  final Function(List<StrokePoint>) onStrokeComplete;

  const TracingCanvas({
    super.key,
    required this.template,
    required this.onStrokeComplete,
  });

  @override
  TracingCanvasState createState() => TracingCanvasState();
}

class TracingCanvasState extends State<TracingCanvas> {
  List<StrokePoint> _currentStroke = [];
  List<List<StrokePoint>> _completedStrokes = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: TemplatePainter(
          template: widget.template,
        ),
        foregroundPainter: StrokePainter(
          currentStroke: _currentStroke,
          completedStrokes: _completedStrokes,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      final point = StrokePoint(
        x: details.localPosition.dx,
        y: details.localPosition.dy,
      );
      _currentStroke = [point];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      final point = StrokePoint(
        x: details.localPosition.dx,
        y: details.localPosition.dy,
      );
      _currentStroke = List.from(_currentStroke)..add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
      if (_currentStroke.isNotEmpty) {
        _completedStrokes = List.from(_completedStrokes)..add(_currentStroke);
        widget.onStrokeComplete(List.from(_currentStroke));
        _currentStroke = [];
      }
    });
  }

  void clear() {
    setState(() {
      _currentStroke = [];
      _completedStrokes = [];
    });
  }
}
