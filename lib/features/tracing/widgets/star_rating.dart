import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class StarRating extends StatelessWidget {
  final int stars;
  final int maxStars;

  const StarRating({
    super.key,
    required this.stars,
    this.maxStars = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxStars, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: 48,
            color: isFilled ? AppColors.starFilled : AppColors.starEmpty,
          )
              .animate(
                delay: Duration(milliseconds: index * 150),
              )
              .scale(
                duration: 300.ms,
                curve: Curves.elasticOut,
              ),
        );
      }),
    );
  }
}
