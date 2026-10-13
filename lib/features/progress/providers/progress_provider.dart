import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../levels/models/level.dart';

/// Per-level tracing progress: best stars earned per template id.
class LevelProgress {
  final Map<String, int> templateStars;

  const LevelProgress({this.templateStars = const {}});

  int get completedTemplates =>
      templateStars.values.where((stars) => stars >= 1).length;

  int get totalStars =>
      templateStars.values.fold(0, (sum, stars) => sum + stars);
}

/// Saves/loads [LevelProgress] per level id via shared_preferences.
class ProgressNotifier extends StateNotifier<Map<int, LevelProgress>> {
  ProgressNotifier(this._prefs)
      : _unlockedLevels = _loadUnlocked(_prefs),
        super(_load(_prefs));

  static const _storageKey = 'level_progress_v1';
  static const _unlockedKey = 'unlocked_levels_v1';

  final SharedPreferences _prefs;

  /// Level ids that were ever unlocked. Unlocks are permanent: once a
  /// segment is unlocked it stays unlocked even if earlier segments are
  /// reset (only a full reset clears this).
  final Set<int> _unlockedLevels;

  static Map<int, LevelProgress> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final stars = Map<String, int>.from(
          (value as Map).cast<String, dynamic>(),
        );
        return MapEntry(int.parse(key), LevelProgress(templateStars: stars));
      });
    } catch (_) {
      return {};
    }
  }

  static Set<int> _loadUnlocked(SharedPreferences prefs) {
    final raw = prefs.getString(_unlockedKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
    } catch (_) {
      return {};
    }
  }

  void _persistUnlocked() {
    _prefs.setString(_unlockedKey, jsonEncode(_unlockedLevels.toList()));
  }

  /// Clears all progress (resets everything, including permanent unlocks).
  void resetAll() {
    state = {};
    _unlockedLevels.clear();
    _prefs.setString(_storageKey, '{}');
    _persistUnlocked();
  }

  /// Clears progress for a single level (segment). Unlock status of this
  /// or other segments is not affected.
  void resetLevel(int levelId) {
    final next = Map<int, LevelProgress>.from(state)..remove(levelId);
    state = next;
    _prefs.setString(
      _storageKey,
      jsonEncode(next.map((k, v) => MapEntry(k.toString(), v.templateStars))),
    );
  }

  /// Records the best stars earned for a template in a level.
  void recordTemplate(int levelId, String templateId, int stars) {
    final current = state[levelId] ?? const LevelProgress();
    final previous = current.templateStars[templateId] ?? 0;
    final updated = LevelProgress(
      templateStars: {
        ...current.templateStars,
        templateId: previous > stars ? previous : stars,
      },
    );
    state = {...state, levelId: updated};
    _prefs.setString(
      _storageKey,
      jsonEncode(state.map((k, v) => MapEntry(k.toString(), v.templateStars))),
    );
  }

  LevelProgress? progressFor(int levelId) => state[levelId];

  /// Overall progress across all levels, 0..1.
  double overallProgress(List<Level> levels) {
    final total = levels.fold<int>(
        0, (sum, level) => sum + level.templates.length);
    if (total == 0) return 0;
    final done = levels.fold<int>(
        0,
        (sum, level) =>
            sum + (state[level.id]?.completedTemplates ?? 0));
    return (done / total).clamp(0, 1);
  }

  /// The first two levels (Lines, Shapes) are always unlocked; any further
  /// level unlocks when at least half of the previous segment's templates
  /// have been completed (each earning at least one star). Once unlocked, a
  /// level stays unlocked even if earlier segments are reset later.
  bool isLevelUnlocked(List<Level> levels, int index) {
    if (index <= 1) return true;
    final level = levels[index];
    if (_unlockedLevels.contains(level.id)) return true;
    final previous = levels[index - 1];
    final required = (previous.templates.length / 2).ceil();
    final unlocked = (state[previous.id]?.completedTemplates ?? 0) >= required;
    if (unlocked) {
      // Remember the unlock so it survives later segment resets.
      _unlockedLevels.add(level.id);
      _persistUnlocked();
    }
    return unlocked;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override with a SharedPreferences'),
);

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<int, LevelProgress>>(
  (ref) => ProgressNotifier(ref.watch(sharedPreferencesProvider)),
);
