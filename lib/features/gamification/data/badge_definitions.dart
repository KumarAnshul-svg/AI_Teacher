import '../models/badge.dart';

class BadgeDefinitions {
  static const List<Badge> allBadges = [
    Badge(
      id: 'first_star',
      name: 'First Star',
      description: 'Earn your first star',
      iconPath: 'assets/badges/first_star.json',
      category: BadgeCategory.achievement,
      rarity: BadgeRarity.common,
      requirement: BadgeRequirement(
        type: RequirementType.starsEarned,
        targetValue: 1,
      ),
    ),
    Badge(
      id: 'star_collector',
      name: 'Star Collector',
      description: 'Earn 50 stars',
      iconPath: 'assets/badges/star_collector.json',
      category: BadgeCategory.achievement,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(
        type: RequirementType.starsEarned,
        targetValue: 50,
      ),
    ),
    Badge(
      id: 'star_master',
      name: 'Star Master',
      description: 'Earn 100 stars',
      iconPath: 'assets/badges/star_master.json',
      category: BadgeCategory.achievement,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(
        type: RequirementType.starsEarned,
        targetValue: 100,
      ),
    ),
    Badge(
      id: 'letter_learner',
      name: 'Letter Learner',
      description: 'Master all capital letters',
      iconPath: 'assets/badges/letter_learner.json',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(
        type: RequirementType.charactersMastered,
        targetValue: 26,
        specificItem: 'capital',
      ),
    ),
    Badge(
      id: 'number_ninja',
      name: 'Number Ninja',
      description: 'Master all numbers 0-9',
      iconPath: 'assets/badges/number_ninja.json',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(
        type: RequirementType.charactersMastered,
        targetValue: 10,
        specificItem: 'numbers',
      ),
    ),
    Badge(
      id: 'perfect_writer',
      name: 'Perfect Writer',
      description: 'Get 10 perfect scores (100%)',
      iconPath: 'assets/badges/perfect_writer.json',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(
        type: RequirementType.perfectScores,
        targetValue: 10,
      ),
    ),
    Badge(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Practice 7 days in a row',
      iconPath: 'assets/badges/week_warrior.json',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.uncommon,
      requirement: BadgeRequirement(
        type: RequirementType.streakDays,
        targetValue: 7,
      ),
    ),
    Badge(
      id: 'month_master',
      name: 'Month Master',
      description: 'Practice 30 days in a row',
      iconPath: 'assets/badges/month_master.json',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.epic,
      requirement: BadgeRequirement(
        type: RequirementType.streakDays,
        targetValue: 30,
      ),
    ),
    Badge(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Complete a letter in under 3 seconds with 90%+ accuracy',
      iconPath: 'assets/badges/speed_demon.json',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      requirement: BadgeRequirement(
        type: RequirementType.speedRun,
        targetValue: 3,
      ),
    ),
    Badge(
      id: 'flawless',
      name: 'Flawless',
      description: 'Complete 5 characters with no corrections',
      iconPath: 'assets/badges/flawless.json',
      category: BadgeCategory.special,
      rarity: BadgeRarity.legendary,
      requirement: BadgeRequirement(
        type: RequirementType.noMistakes,
        targetValue: 5,
      ),
    ),
  ];
}
