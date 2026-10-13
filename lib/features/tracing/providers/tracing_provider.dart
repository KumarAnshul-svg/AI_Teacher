import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke_point.dart';
import '../models/tracing_result.dart';
import '../models/tracing_template.dart';

class TracingState {
  final List<StrokePoint> currentStroke;
  final List<List<StrokePoint>> completedStrokes;
  final double accuracy;
  final int stars;
  final bool isTracing;
  final bool showFeedback;
  final TracingResult? result;

  TracingState({
    this.currentStroke = const [],
    this.completedStrokes = const [],
    this.accuracy = 0,
    this.stars = 0,
    this.isTracing = false,
    this.showFeedback = false,
    this.result,
  });

  TracingState copyWith({
    List<StrokePoint>? currentStroke,
    List<List<StrokePoint>>? completedStrokes,
    double? accuracy,
    int? stars,
    bool? isTracing,
    bool? showFeedback,
    TracingResult? result,
  }) {
    return TracingState(
      currentStroke: currentStroke ?? this.currentStroke,
      completedStrokes: completedStrokes ?? this.completedStrokes,
      accuracy: accuracy ?? this.accuracy,
      stars: stars ?? this.stars,
      isTracing: isTracing ?? this.isTracing,
      showFeedback: showFeedback ?? this.showFeedback,
      result: result ?? this.result,
    );
  }
}

class TracingNotifier extends StateNotifier<TracingState> {
  final TracingTemplate template;
  DateTime? _startTime;

  TracingNotifier(this.template) : super(TracingState());

  void startTracing() {
    _startTime = DateTime.now();
    state = state.copyWith(isTracing: true);
  }

  void updateStroke(List<StrokePoint> points) {
    state = state.copyWith(currentStroke: points);
  }

  void completeStroke(List<StrokePoint> points) {
    final newStrokes = [...state.completedStrokes, points];
    state = state.copyWith(
      currentStroke: [],
      completedStrokes: newStrokes,
    );
  }

  void finishTracing(
      double Function(List<List<StrokePoint>>, TracingTemplate) analyzer) {
    final accuracy = analyzer(state.completedStrokes, template);
    final stars = _calculateStars(accuracy);
    final timeSpent = DateTime.now().difference(_startTime ?? DateTime.now());

    final result = TracingResult(
      templateId: template.id,
      accuracy: accuracy,
      stars: stars,
      timeSpent: timeSpent,
    );

    state = state.copyWith(
      isTracing: false,
      accuracy: accuracy,
      stars: stars,
      showFeedback: true,
      result: result,
    );
  }

  int _calculateStars(double accuracy) {
    // Child-friendly thresholds: reward honest effort, reject scribbles.
    if (accuracy >= 90) return 3;
    if (accuracy >= 63) return 2;
    if (accuracy >= 37) return 1;
    return 0;
  }

  void reset() {
    state = TracingState();
    _startTime = null;
  }

  void hideFeedback() {
    state = state.copyWith(showFeedback: false);
  }
}

final tracingProvider = StateNotifierProvider.family<TracingNotifier,
    TracingState, TracingTemplate>(
  (ref, template) => TracingNotifier(template),
);
