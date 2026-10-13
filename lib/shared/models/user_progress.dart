class UserProgress {
  final String userId;
  final Map<String, int> levelStars;
  final Map<String, double> levelAccuracy;
  final int totalStars;
  final DateTime lastPracticed;
  final List<String> practiceDates;
  final Set<String> masteredCharacters;

  UserProgress({
    required this.userId,
    this.levelStars = const {},
    this.levelAccuracy = const {},
    this.totalStars = 0,
    DateTime? lastPracticed,
    this.practiceDates = const [],
    this.masteredCharacters = const {},
  }) : lastPracticed = lastPracticed ?? DateTime.now();

  UserProgress copyWith({
    Map<String, int>? levelStars,
    Map<String, double>? levelAccuracy,
    int? totalStars,
    DateTime? lastPracticed,
    List<String>? practiceDates,
    Set<String>? masteredCharacters,
  }) {
    return UserProgress(
      userId: userId,
      levelStars: levelStars ?? this.levelStars,
      levelAccuracy: levelAccuracy ?? this.levelAccuracy,
      totalStars: totalStars ?? this.totalStars,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      practiceDates: practiceDates ?? this.practiceDates,
      masteredCharacters: masteredCharacters ?? this.masteredCharacters,
    );
  }

  int get charactersMastered => masteredCharacters.length;

  double get averageAccuracy {
    if (levelAccuracy.isEmpty) return 0;
    return levelAccuracy.values.reduce((a, b) => a + b) / levelAccuracy.length;
  }
}
