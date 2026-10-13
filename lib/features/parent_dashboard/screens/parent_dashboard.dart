import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../levels/models/level.dart';
import '../../levels/screens/levels_screen.dart';
import '../../progress/providers/progress_provider.dart';
import '../../tracing/services/template_service.dart';

/// Parents-only view of the child's real progress. Reached through the
/// parent gate; every number here comes from [progressProvider].
class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final levels = LevelsScreen.levels;

    var stars = 0;
    var completed = 0;
    var total = 0;
    var mastered = 0;
    var wholeLevels = 0;
    final struggling = <({String character, String level})>[];
    for (final level in levels) {
      final levelProgress = progress[level.id];
      total += level.templates.length;
      if (levelProgress == null) continue;
      stars += levelProgress.totalStars;
      completed += levelProgress.completedTemplates;
      mastered += levelProgress.templateStars.values.where((s) => s >= 3).length;
      if (levelProgress.completedTemplates >= level.templates.length) {
        wholeLevels++;
      }
      for (final character in level.templates) {
        final templateId =
            TemplateService.generateTemplate(character, level.type).id;
        if (levelProgress.templateStars[templateId] == 1) {
          struggling.add((character: character, level: level.name));
        }
      }
    }

    final recommendations = <String>[];
    if (struggling.isNotEmpty) {
      final chars = struggling.map((s) => s.character).join(', ');
      recommendations.add('Practice these a little more: $chars');
    } else if (completed > 0) {
      recommendations.add('No struggling areas right now — keep going!');
    } else {
      recommendations.add('Your child has not started tracing yet.');
    }
    for (int i = 2; i < levels.length; i++) {
      final previous = levels[i - 1];
      final required = (previous.templates.length / 2).ceil();
      final done = progress[previous.id]?.completedTemplates ?? 0;
      if (done >= required) continue;
      recommendations.add(
        '${levels[i].name} unlocks at half of ${previous.name} '
        '($required tracings) — $done done so far.',
      );
      break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Reset all progress',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChildHeader(),
            const SizedBox(height: 20),
            _OverviewStats(
              stars: stars,
              completed: completed,
              total: total,
              mastered: mastered,
              wholeLevels: wholeLevels,
            ),
            const SizedBox(height: 20),
            _LevelBreakdown(levels: levels, progress: progress),
            const SizedBox(height: 20),
            _StrugglingAreas(items: struggling),
            const SizedBox(height: 20),
            _Recommendations(items: recommendations),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This erases every star, completed tracing, badge and unlock. '
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
      ref.read(progressProvider.notifier).resetAll();
    }
  }
}

class _ChildHeader extends StatelessWidget {
  const _ChildHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 36, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alex',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Child profile',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewStats extends StatelessWidget {
  final int stars;
  final int completed;
  final int total;
  final int mastered;
  final int wholeLevels;

  const _OverviewStats({
    required this.stars,
    required this.completed,
    required this.total,
    required this.mastered,
    required this.wholeLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatTile(
              title: 'Stars earned',
              value: '$stars',
              icon: Icons.star,
              color: Colors.amber,
            ),
            const SizedBox(width: 12),
            _StatTile(
              title: 'Tracings done',
              value: '$completed/$total',
              icon: Icons.draw,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(
              title: 'Mastered (3-star)',
              value: '$mastered',
              icon: Icons.workspace_premium,
              color: Colors.purple,
            ),
            const SizedBox(width: 12),
            _StatTile(
              title: 'Segments done',
              value: '$wholeLevels',
              icon: Icons.emoji_events,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBreakdown extends StatelessWidget {
  final List<Level> levels;
  final Map<int, LevelProgress> progress;

  const _LevelBreakdown({required this.levels, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress by segment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    '${progress[level.id]?.completedTemplates ?? 0}/'
                    '${level.templates.length} • '
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

class _StrugglingAreas extends StatelessWidget {
  final List<({String character, String level})> items;

  const _StrugglingAreas({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Areas needing attention',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                'Nothing to worry about — every started tracing has at '
                'least 2 stars.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              for (final item in items.take(6))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: Text(
                      item.character,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text('${item.level} — "${item.character}"'),
                  subtitle: const Text('Completed with only 1 star'),
                ),
          ],
        ),
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  final List<String> items;

  const _Recommendations({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
