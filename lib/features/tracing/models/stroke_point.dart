class StrokePoint {
  final double x;
  final double y;
  final double pressure;
  final DateTime timestamp;

  StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
