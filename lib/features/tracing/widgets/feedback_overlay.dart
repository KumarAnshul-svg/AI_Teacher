import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'star_rating.dart';

class FeedbackOverlay extends StatelessWidget {
  final double accuracy;
  final int stars;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final String? nextLevelName;
  final VoidCallback? onNextLevel;

  /// Whether the score meets the threshold to move on. When false the
  /// "Next" button is disabled and a hint explains what is needed.
  final bool canProceed;

  const FeedbackOverlay({
    super.key,
    required this.accuracy,
    required this.stars,
    required this.onContinue,
    required this.onRetry,
    this.nextLevelName,
    this.onNextLevel,
    this.canProceed = true,
  });

  @override
  Widget build(BuildContext context) {
    final String title;
    final Color titleColor;
    if (canProceed && stars >= 2) {
      title = AppStrings.greatJob;
      titleColor = AppColors.success;
    } else if (stars >= 1) {
      title = AppStrings.niceTry;
      titleColor = AppColors.warning;
    } else {
      title = AppStrings.keepTrying;
      titleColor = AppColors.warning;
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                )
                    .animate()
                    .scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 16),

                StarRating(stars: stars, maxStars: 3)
                    .animate()
                    .fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                Text(
                  'Accuracy: ${accuracy.round()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                if (!canProceed) ...[
                  Text(
                    'Almost there! Trace it again and reach at least 70% '
                    'accuracy to continue.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Flexible buttons: on narrow windows the labels scale
                    // down instead of overflowing the dialog.
                    Flexible(
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            stars >= 1
                                ? 'Restart'
                                : AppStrings.tryAgain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: canProceed
                            ? (nextLevelName != null ? onNextLevel : onContinue)
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            nextLevelName != null
                                ? 'Next: $nextLevelName'
                                : 'Next',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1);
  }
}
