import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../levels/models/level.dart';
import '../../levels/screens/levels_screen.dart';
import '../../progress/providers/progress_provider.dart';

class ChildDashboard extends ConsumerWidget {
  const ChildDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final levels = LevelsScreen.levels;

    final totalStars = levels.fold<int>(
        0, (sum, level) => sum + (progress[level.id]?.totalStars ?? 0));
    final templatesCompleted = levels.fold<int>(
        0, (sum, level) => sum + (progress[level.id]?.completedTemplates ?? 0));
    final totalTemplates =
        levels.fold<int>(0, (sum, level) => sum + level.templates.length);
    final levelsCompleted = levels
        .where((l) =>
            (progress[l.id]?.completedTemplates ?? 0) >= l.templates.length)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeHeader(
              childName: 'Alex',
              level: levelsCompleted + 1,
            ),

            const SizedBox(height: 24),

            _StatsRow(
              stars: totalStars,
              completed: templatesCompleted,
              total: totalTemplates,
              levelsCompleted: levelsCompleted,
            ),

            const SizedBox(height: 24),

            _BadgeShowcase(
              totalStars: totalStars,
              templatesCompleted: templatesCompleted,
              levelsCompleted: levelsCompleted,
            ),

            const SizedBox(height: 24),

            _LevelBreakdown(levels: levels, progress: progress),

            const SizedBox(height: 24),

            _CharacterGuide(
              message: _encouragement(totalStars, templatesCompleted),
            ),
          ],
        ),
      ),
    );
  }

  String _encouragement(int stars, int completed) {
    if (stars == 0 && completed == 0) {
      return 'Trace your first line to start earning stars!';
    }
    if (completed < 5) return 'Great job today! Keep practicing!';
    if (completed < 20) return 'You are doing amazing! Keep going!';
    return 'Star writer! Your skills are growing fast!';
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String childName;
  final int level;

  const _WelcomeHeader({
    required this.childName,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $childName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Level $level Writer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int stars;
  final int completed;
  final int total;
  final int levelsCompleted;

  const _StatsRow({
    required this.stars,
    required this.completed,
    required this.total,
    required this.levelsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.star,
          value: '$stars',
          label: 'Stars',
          color: AppColors.starFilled,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.draw,
          value: '$completed/$total',
          label: 'Traced',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.emoji_events,
          value: '$levelsCompleted',
          label: 'Levels',
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeShowcase extends StatelessWidget {
  final int totalStars;
  final int templatesCompleted;
  final int levelsCompleted;

  const _BadgeShowcase({
    required this.totalStars,
    required this.templatesCompleted,
    required this.levelsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final earned = <({String name, IconData icon})>[
      if (totalStars >= 1)
        (name: 'First Star', icon: Icons.star),
      if (templatesCompleted >= 10)
        (name: 'Star Collector', icon: Icons.star_half),
      if (totalStars >= 20)
        (name: 'Star Master', icon: Icons.stars),
      if (levelsCompleted >= 1)
        (name: 'Level Up', icon: Icons.military_tech),
      if (levelsCompleted >= 3)
        (name: 'Achiever', icon: Icons.workspace_premium),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges Earned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (earned.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Complete your first trace to earn a badge!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: earned.map((badge) {
                  return Chip(
                    avatar: Icon(badge.icon, color: Colors.amber, size: 20),
                    label: Text(badge.name),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelBreakdown extends StatelessWidget {
  final List<Level> levels;
  final Map<int, LevelProgress> progress;

  const _LevelBreakdown({
    required this.levels,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Level Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final level in levels) ...[
              Row(
                children: [
                  Icon(level.icon, size: 20, color: level.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      level.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${progress[level.id]?.totalStars ?? 0} ⭐',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (progress[level.id]?.completedTemplates ?? 0) /
                      level.templates.length,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CharacterGuide extends StatelessWidget {
  final String message;

  const _CharacterGuide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penny the Pencil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
