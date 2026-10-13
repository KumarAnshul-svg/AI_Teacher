class TracingResult {
  final String templateId;
  final double accuracy;
  final int stars;
  final Duration timeSpent;
  final DateTime completedAt;

  TracingResult({
    required this.templateId,
    required this.accuracy,
    required this.stars,
    required this.timeSpent,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  int get starCount {
    if (accuracy >= 90) return 3;
    if (accuracy >= 70) return 2;
    if (accuracy >= 50) return 1;
    return 0;
  }
}
