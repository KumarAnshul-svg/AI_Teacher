import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/utils/stroke_analyzer.dart';
import '../../levels/models/level.dart';
import '../../levels/screens/levels_screen.dart';
import '../../progress/providers/progress_provider.dart';
import '../models/tracing_template.dart';
import '../providers/tracing_provider.dart';
import '../services/template_service.dart';
import '../widgets/tracing_canvas.dart';
import '../widgets/feedback_overlay.dart';

class TracingScreen extends ConsumerStatefulWidget {
  final Level level;

  const TracingScreen({super.key, required this.level});

  @override
  ConsumerState<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends ConsumerState<TracingScreen> {
  /// A trace must score at least this to count as completed and allow
  /// moving on to the next tracing/segment.
  static const double _passThreshold = 70;

  late final List<TracingTemplate> _templates;
  int _currentTemplateIndex = 0;
  TracingTemplate get _currentTemplate => _templates[_currentTemplateIndex];
  GlobalKey<TracingCanvasState> _canvasKey = GlobalKey<TracingCanvasState>();
  final ScrollController _chipsController = ScrollController();
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _templates = widget.level.templates
        .map((c) => TemplateService.generateTemplate(c, widget.level.type))
        .toList();
    _speakStart();
  }

  /// Voices the character/word that is currently displayed.
  void _speakStart() {
    if (widget.level.type == LevelType.lines) return; // Lines stays silent.
    ref.read(ttsServiceProvider).speakCharacter(
          _currentTemplate.character,
          widget.level.type,
        );
  }

  @override
  void dispose() {
    _chipsController.dispose();
    super.dispose();
  }

  /// Jumps to the template at [index] in the current segment.
  void _selectTemplate(int index) {
    if (index == _currentTemplateIndex) return;
    setState(() {
      _currentTemplateIndex = index;
    });
    // Fresh canvas state so strokes from the previous template don't carry over.
    _canvasKey = GlobalKey<TracingCanvasState>();
    ref.read(tracingProvider(_currentTemplate).notifier).reset();
    _speakStart();
  }

  void _nextTemplate() {
    if (_currentTemplateIndex < widget.level.templates.length - 1) {
      _selectTemplate(_currentTemplateIndex + 1);
    }
  }

  bool get _isLastTemplate =>
      _currentTemplateIndex == widget.level.templates.length - 1;

  /// The next segment (level) after the current one, if any.
  Level? get _nextLevel {
    final levels = LevelsScreen.levels;
    final index = levels.indexWhere((l) => l.id == widget.level.id);
    if (index < 0 || index >= levels.length - 1) return null;
    return levels[index + 1];
  }

  void _goToNextLevel() {
    final next = _nextLevel;
    if (next == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TracingScreen(level: next)),
    );
  }

  void _finishAndAnalyze() {
    ref.read(tracingProvider(_currentTemplate).notifier).finishTracing(
      (strokes, template) {
        return StrokeAnalyzer.analyzeStroke(
          strokes: strokes,
          template: template,
          canvasWidth: 300,
          canvasHeight: 300,
          // Shapes need a steadier hand: judge them slightly stricter.
          strictness: widget.level.type == LevelType.shapes ? 0.96 : 1.0,
        );
      },
    );
    final result = ref.read(tracingProvider(_currentTemplate));
    // Only attempts that meet the pass threshold count as completed, so a
    // low-accuracy scribble can't unlock the next tracing or segment.
    if (result.accuracy >= _passThreshold) {
      ref
          .read(progressProvider.notifier)
          .recordTemplate(widget.level.id, _currentTemplate.id, result.stars);
    }
    _speakResult(result.accuracy >= _passThreshold);
  }

  /// Voices the outcome after the Done button: praise plus the character
  /// when it passed, otherwise an encouraging retry prompt.
  void _speakResult(bool passed) {
    if (widget.level.type == LevelType.lines) return; // Lines stays silent.
    final tts = ref.read(ttsServiceProvider);
    final character = _currentTemplate.character;
    // Compose the full phrase here so it is one utterance, no pause between
    // the praise and the character name.
    final phrase = passed
        ? 'Great job! ${TtsService.phraseFor(character, widget.level.type) ?? character}'
        : 'Nice try! ${TtsService.phraseFor(character, widget.level.type) ?? character}. Try again';
    tts.speakRaw(phrase);
  }

  Future<void> _confirmSegmentReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reset ${widget.level.name} progress?'),
        content: const Text(
          'This will erase this segment\'s stars and completed tracings. '
          'Other segments are not affected. This cannot be undone.',
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
      ref.read(progressProvider.notifier).resetLevel(widget.level.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.level.name} progress has been reset')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracingState = ref.watch(tracingProvider(_currentTemplate));
    final levelProgress = ref.watch(progressProvider)[widget.level.id];
    final completed =
        (levelProgress?.completedTemplates ?? 0).clamp(0, widget.level.templates.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.name),
        actions: [
          if (widget.level.type != LevelType.lines)
            IconButton(
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              tooltip: _muted ? 'Unmute voice' : 'Mute voice',
              onPressed: () {
                setState(() => _muted = !_muted);
                ref.read(ttsServiceProvider).setMuted(_muted);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset ${widget.level.name} progress',
            onPressed: () => _confirmSegmentReset(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                'v41',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentTemplateIndex + 1}/${widget.level.templates.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Level completion progress.
              LinearProgressIndicator(
                value: completed / widget.level.templates.length,
                minHeight: 4,
                backgroundColor: AppColors.primary.withOpacity(0.2),
              ),
              // Template picker: tap any character in this segment to jump
              // straight to it. Scrolls with mouse wheel on web.
              SizedBox(
                height: 48,
                child: Scrollbar(
                  controller: _chipsController,
                  thumbVisibility: true,
                  child: Listener(
                    onPointerSignal: (PointerSignalEvent event) {
                      if (event is PointerScrollEvent) {
                        _chipsController.jumpTo(
                          (_chipsController.offset +
                                  event.scrollDelta.dy +
                                  event.scrollDelta.dx)
                              .clamp(
                                0.0,
                                _chipsController.position.maxScrollExtent,
                              ),
                        );
                      }
                    },
                    child: ListView.separated(
                      controller: _chipsController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final tpl = _templates[index];
                        final isCurrent = index == _currentTemplateIndex;
                        final isDone =
                            (levelProgress?.templateStars[tpl.id] ?? 0) > 0;
                        return ChoiceChip(
                          label: Text(
                            tpl.character,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          selected: isCurrent,
                          onSelected: (_) => _selectTemplate(index),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isCurrent ? Colors.white : null,
                          ),
                          avatar: isDone
                              ? const Icon(Icons.check, size: 14)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _currentTemplate.character,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ).animate().scale(),

              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: TracingCanvas(
                        key: _canvasKey,
                        template: _currentTemplate,
                        onStrokeComplete: (points) {
                          ref.read(tracingProvider(_currentTemplate).notifier)
                              .completeStroke(points);
                        },
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _canvasKey.currentState?.clear();
                        ref.read(tracingProvider(_currentTemplate).notifier)
                            .reset();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _finishAndAnalyze,
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (tracingState.showFeedback)
            FeedbackOverlay(
              accuracy: tracingState.accuracy,
              stars: tracingState.stars,
              nextLevelName: _isLastTemplate ? _nextLevel?.name : null,
              canProceed: tracingState.accuracy >= _passThreshold,
              onNextLevel: _goToNextLevel,
              onContinue: () {
                ref.read(tracingProvider(_currentTemplate).notifier).hideFeedback();
                _nextTemplate();
              },
              onRetry: () {
                _canvasKey.currentState?.clear();
                ref.read(tracingProvider(_currentTemplate).notifier).hideFeedback();
                ref.read(tracingProvider(_currentTemplate).notifier).reset();
              },
            ),
        ],
      ),
    );
  }
}
