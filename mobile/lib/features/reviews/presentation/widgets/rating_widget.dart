import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double? size;
  final Color? color;
  final bool showRatingText;
  final int? reviewCount;
  final bool allowInteraction;
  final ValueChanged<double>? onRatingChanged;
  final double? userRating;

  const RatingWidget({
    super.key,
    required this.rating,
    this.size,
    this.color,
    this.showRatingText = true,
    this.reviewCount,
    this.allowInteraction = false,
    this.onRatingChanged,
    this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    final starSize = size ?? 18.0;
    final starColor = color ?? Colors.amber.shade700;
    final displayRating = userRating ?? rating;
    final fullStars = displayRating.floor();
    final hasHalfStar = (displayRating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allowInteraction)
          _buildInteractiveStars(context, starSize, starColor)
        else
          _buildDisplayStars(context, starSize, starColor, fullStars, hasHalfStar, emptyStars),
        if (showRatingText) ...[
          const SizedBox(width: 8),
          Text(
            displayRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.7,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: starSize * 0.6,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDisplayStars(BuildContext context, double starSize, Color starColor, 
      int fullStars, bool hasHalfStar, int emptyStars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => Icon(
          Icons.star_rounded,
          size: starSize,
          color: starColor,
        )),
        if (hasHalfStar)
          Icon(
            Icons.star_half_rounded,
            size: starSize,
            color: starColor,
          ),
        ...List.generate(emptyStars, (_) => Icon(
          Icons.star_outline_rounded,
          size: starSize,
          color: starColor.withOpacity(0.3),
        )),
      ],
    );
  }

  Widget _buildInteractiveStars(BuildContext context, double starSize, Color starColor) {
    return StatefulBuilder(
      builder: (context, setState) {
        final currentRating = userRating ?? 0.0;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= currentRating;
            final isHalf = starIndex - 0.5 <= currentRating && starIndex > currentRating;
            
            return GestureDetector(
              onTap: () {
                if (onRatingChanged != null) {
                  onRatingChanged!(starIndex.toDouble());
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled 
                      ? Icons.star_rounded 
                      : isHalf 
                          ? Icons.star_half_rounded 
                          : Icons.star_outline_rounded,
                  size: starSize,
                  color: starColor,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

