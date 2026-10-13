class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final BadgeRequirement requirement;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.category,
    required this.rarity,
    required this.requirement,
  });
}

enum BadgeCategory {
  achievement,
  streak,
  mastery,
  special,
  collection,
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class BadgeRequirement {
  final RequirementType type;
  final int targetValue;
  final String? specificItem;

  const BadgeRequirement({
    required this.type,
    required this.targetValue,
    this.specificItem,
  });
}

enum RequirementType {
  starsEarned,
  charactersMastered,
  perfectScores,
  practiceDays,
  streakDays,
  levelsCompleted,
  speedRun,
  noMistakes,
}
