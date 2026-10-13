import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../progress/providers/progress_provider.dart';
import '../../tracing/screens/tracing_screen.dart';
import '../models/level.dart';

class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  static final List<Level> levels = [
    Level(
      id: 1,
      name: AppStrings.level1Name,
      type: LevelType.lines,
      icon: Icons.horizontal_rule,
      color: Colors.blue,
      isUnlocked: true,
      templates: ['|', '-', '/', '\\', 'V', '^', '~', '⌒'],
    ),
    Level(
      id: 2,
      name: AppStrings.level2Name,
      type: LevelType.shapes,
      icon: Icons.circle,
      color: Colors.green,
      isUnlocked: true,
      templates: ['O', '□', '△', '☆', '♥', '◇', '⬠', '⬡'],
    ),
    Level(
      id: 3,
      name: AppStrings.level3Name,
      type: LevelType.numbers,
      icon: Icons.looks_one,
      color: Colors.orange,
      isUnlocked: false,
      templates: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    ),
    Level(
      id: 4,
      name: AppStrings.level4Name,
      type: LevelType.capitalLetters,
      icon: Icons.text_fields,
      color: Colors.purple,
      isUnlocked: false,
      templates: [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
        'U', 'V', 'W', 'X', 'Y', 'Z'
      ],
    ),
    Level(
      id: 5,
      name: AppStrings.level5Name,
      type: LevelType.smallLetters,
      icon: Icons.text_format,
      color: Colors.pink,
      isUnlocked: false,
      templates: [
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        'u', 'v', 'w', 'x', 'y', 'z'
      ],
    ),
    Level(
      id: 6,
      name: AppStrings.level6Name,
      type: LevelType.sentences,
      icon: Icons.short_text,
      color: Colors.teal,
      isUnlocked: false,
      templates: [
        'Hi', 'Cat', 'Dog', 'Sun', 'Mom', 'Dad', 'Bat', 'Hat',
        'Bug', 'Top', 'Run', 'Box', 'Egg', 'Bus', 'Pig', 'Cow',
        'Bed', 'Pen', 'Fox', 'Ice',
      ],
    ),
  ];

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will erase all stars, completed templates, and unlocked '
          'levels. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress has been reset')),
        );
      }
    }
  }

  Future<void> _confirmLevelReset(
    BuildContext context,
    WidgetRef ref,
    Level level,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset ${level.name} progress?'),
        content: const Text(
          'This will erase this level\'s stars and completed tracings. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).resetLevel(level.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${level.name} progress has been reset')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final overall = notifier.overallProgress(levels);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.selectLevel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Reset progress',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Overall progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(overall * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overall,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final unlocked = notifier.isLevelUnlocked(levels, index);
                final levelProgress = progress[level.id];
                final completed =
                    levelProgress?.completedTemplates ?? 0;
                return _LevelCard(
                  level: level,
                  unlocked: unlocked,
                  completed: completed,
                  total: level.templates.length,
                  stars: levelProgress?.totalStars ?? 0,
                  onTap: () {
                    if (unlocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TracingScreen(level: level),
                        ),
                      );
                    }
                  },
                  onReset: unlocked && completed > 0
                      ? () => _confirmLevelReset(context, ref, level)
                      : null,
                ).animate().fadeIn(delay: (index * 100).ms).scale();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Level level;
  final bool unlocked;
  final int completed;
  final int total;
  final int stars;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.total,
    required this.stars,
    required this.onTap,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: unlocked
                  ? [
                      level.color.withOpacity(0.8),
                      level.color,
                    ]
                  : [
                      Colors.grey.withOpacity(0.7),
                      Colors.grey.shade600,
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      unlocked ? level.icon : Icons.lock,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (unlocked) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$completed/$total traced',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (stars > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star,
                              color: AppColors.starFilled,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$stars',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Complete half of ${LevelsScreen.levels[LevelsScreen.levels.indexOf(level) - 1].name} to unlock',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
                if (onReset != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onReset,
                      child: Tooltip(
                        message: 'Reset ${level.name} progress',
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
