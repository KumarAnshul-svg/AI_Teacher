import 'dart:math';
import 'package:ai_tracer/features/tracing/models/tracing_result.dart';
import '../models/badge.dart';
import '../data/badge_definitions.dart';

class ProgressionService {
  final Map<String, double> characterAccuracy;
  final List<String> practiceDates;
  final List<TracingResult> recentResults;
  final int totalStars;

  ProgressionService({
    this.characterAccuracy = const {},
    this.practiceDates = const [],
    this.recentResults = const [],
    this.totalStars = 0,
  });

  List<Badge> checkForNewBadges(List<String> earnedBadgeIds) {
    final newBadges = <Badge>[];

    for (final badge in BadgeDefinitions.allBadges) {
      if (earnedBadgeIds.contains(badge.id)) continue;

      if (_meetsRequirement(badge.requirement)) {
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  bool _meetsRequirement(BadgeRequirement requirement) {
    switch (requirement.type) {
      case RequirementType.starsEarned:
        return totalStars >= requirement.targetValue;
      case RequirementType.charactersMastered:
        return _charactersMastered() >= requirement.targetValue;
      case RequirementType.perfectScores:
        return _perfectScoreCount() >= requirement.targetValue;
      case RequirementType.streakDays:
        return _currentStreak() >= requirement.targetValue;
      case RequirementType.levelsCompleted:
        return false;
      case RequirementType.speedRun:
        return _hasSpeedRun(requirement.targetValue);
      case RequirementType.noMistakes:
        return _consecutivePerfectScores() >= requirement.targetValue;
      default:
        return false;
    }
  }

  int _charactersMastered() {
    return characterAccuracy.entries.where((e) => e.value >= 90).length;
  }

  int _perfectScoreCount() {
    return characterAccuracy.entries.where((e) => e.value >= 100).length;
  }

  int _currentStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (practiceDates.contains(dateKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  bool _hasSpeedRun(int seconds) {
    return recentResults
        .any((r) => r.timeSpent.inSeconds <= seconds && r.accuracy >= 90);
  }

  int _consecutivePerfectScores() {
    int count = 0;
    for (final result in recentResults.reversed) {
      if (result.accuracy >= 95) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int calculateCoinsEarned(TracingResult result) {
    int coins = 5;

    if (result.accuracy >= 90)
      coins += 10;
    else if (result.accuracy >= 70) coins += 5;

    coins += result.stars * 3;

    if (result.timeSpent.inSeconds < 5) coins += 5;

    return coins;
  }

  int xpForLevel(int currentLevel) {
    return (100 * pow(1.5, currentLevel - 1)).round();
  }

  int calculateLevel(int totalXp) {
    int level = 1;
    int xpNeeded = 100;
    int accumulatedXp = 0;

    while (accumulatedXp + xpNeeded <= totalXp) {
      accumulatedXp += xpNeeded;
      level++;
      xpNeeded = xpForLevel(level);
    }

    return level;
  }
}
