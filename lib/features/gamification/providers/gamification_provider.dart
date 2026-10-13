import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import '../models/reward.dart';
import '../data/reward_definitions.dart';
import '../services/progression_service.dart';
import 'package:ai_tracer/features/tracing/models/tracing_result.dart';

class GamificationState {
  final int coins;
  final int totalXp;
  final int level;
  final int totalStars;
  final List<String> earnedBadgeIds;
  final List<String> unlockedRewardIds;
  final List<String> activeRewardIds;
  final int currentStreak;
  final List<String> practiceDates;
  final List<TracingResult> recentResults;

  GamificationState({
    this.coins = 0,
    this.totalXp = 0,
    this.level = 1,
    this.totalStars = 0,
    this.earnedBadgeIds = const [],
    this.unlockedRewardIds = const [],
    this.activeRewardIds = const [],
    this.currentStreak = 0,
    this.practiceDates = const [],
    this.recentResults = const [],
  });

  GamificationState copyWith({
    int? coins,
    int? totalXp,
    int? level,
    int? totalStars,
    List<String>? earnedBadgeIds,
    List<String>? unlockedRewardIds,
    List<String>? activeRewardIds,
    int? currentStreak,
    List<String>? practiceDates,
    List<TracingResult>? recentResults,
  }) {
    return GamificationState(
      coins: coins ?? this.coins,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      totalStars: totalStars ?? this.totalStars,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      unlockedRewardIds: unlockedRewardIds ?? this.unlockedRewardIds,
      activeRewardIds: activeRewardIds ?? this.activeRewardIds,
      currentStreak: currentStreak ?? this.currentStreak,
      practiceDates: practiceDates ?? this.practiceDates,
      recentResults: recentResults ?? this.recentResults,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(GamificationState());

  Future<List<Badge>> processActivity(TracingResult result) async {
    final progressionService = ProgressionService(
      totalStars: state.totalStars + result.stars,
      practiceDates: [...state.practiceDates, _today()],
      recentResults: [...state.recentResults, result],
    );

    final coinsEarned = progressionService.calculateCoinsEarned(result);
    final xpEarned = result.accuracy.round() + (result.stars * 10);

    state = state.copyWith(
      coins: state.coins + coinsEarned,
      totalXp: state.totalXp + xpEarned,
      level: progressionService.calculateLevel(state.totalXp + xpEarned),
    );

    final newBadges =
        progressionService.checkForNewBadges(state.earnedBadgeIds);

    if (newBadges.isNotEmpty) {
      state = state.copyWith(
        earnedBadgeIds: [
          ...state.earnedBadgeIds,
          ...newBadges.map((b) => b.id),
        ],
      );
    }

    return newBadges;
  }

  Future<bool> purchaseReward(Reward reward) async {
    if (state.coins < reward.cost) return false;
    if (state.unlockedRewardIds.contains(reward.id)) return false;

    state = state.copyWith(
      coins: state.coins - reward.cost,
      unlockedRewardIds: [...state.unlockedRewardIds, reward.id],
    );

    return true;
  }

  Future<void> equipReward(String rewardId) async {
    if (!state.unlockedRewardIds.contains(rewardId)) return;

    final reward =
        RewardDefinitions.allRewards.firstWhere((r) => r.id == rewardId);

    final newActive = state.activeRewardIds.where((id) {
      final existing =
          RewardDefinitions.allRewards.firstWhere((r) => r.id == id);
      return existing.type != reward.type;
    }).toList();

    state = state.copyWith(
      activeRewardIds: [...newActive, rewardId],
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>(
  (ref) => GamificationNotifier(),
);
