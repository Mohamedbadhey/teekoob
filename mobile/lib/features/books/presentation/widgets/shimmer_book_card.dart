import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBookCard extends StatelessWidget {
  final double? width;
  final double? height;
  final bool compact;

  const ShimmerBookCard({
    Key? key,
    this.width,
    this.height,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen dimensions
    final cardWidth = width ?? _getResponsiveWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveHeight(screenHeight);
    
    Widget cardContent = compact
        ? _buildCompactShimmer(cardWidth)
        : _buildGridShimmer(cardWidth, cardHeight);

    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface,
      highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      child: cardContent,
    );
  }

  Widget _buildGridShimmer(double cardWidth, double cardHeight) {
    return Container(
      width: cardWidth,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book Cover Shimmer
          Container(
            width: double.infinity,
            height: cardWidth * 0.8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          
          // Book Info Shimmer
          Container(
            padding: EdgeInsets.fromLTRB(
              cardWidth * 0.03,
              cardWidth * 0.03,
              cardWidth * 0.03,
              cardWidth * 0.01,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title shimmer
                Container(
                  height: cardWidth * 0.07,
                  width: cardWidth * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                SizedBox(height: cardWidth * 0.01),
                
                // Author shimmer
                Container(
                  height: cardWidth * 0.06,
                  width: cardWidth * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                SizedBox(height: cardWidth * 0.01),
                
                // Bottom row shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time shimmer
                    Container(
                      height: cardWidth * 0.05,
                      width: cardWidth * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(cardWidth * 0.08),
                      ),
                    ),
                    
                    // Rating shimmer
                    Container(
                      height: cardWidth * 0.05,
                      width: cardWidth * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(cardWidth * 0.08),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactShimmer(double cardWidth) {
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover shimmer
            Container(
              width: 72,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title shimmer
                  Container(
                    height: 16,
                    width: cardWidth * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Author shimmer
                  Container(
                    height: 14,
                    width: cardWidth * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Free badge shimmer for compact mode
                  Container(
                    height: 24,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Bottom row shimmer
                  Row(
                    children: [
                      Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 24,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth < 320) {
      return screenWidth * 0.45;
    } else if (screenWidth < 360) {
      return screenWidth * 0.42;
    } else if (screenWidth < 400) {
      return screenWidth * 0.40;
    } else if (screenWidth < 480) {
      return screenWidth * 0.38;
    } else if (screenWidth < 600) {
      return screenWidth * 0.35;
    } else if (screenWidth < 768) {
      return screenWidth * 0.30;
    } else {
      return screenWidth * 0.25;
    }
  }

  double _getResponsiveHeight(double screenHeight) {
    if (screenHeight < 600) {
      return screenHeight * 0.26;
    } else if (screenHeight < 700) {
      return screenHeight * 0.24;
    } else if (screenHeight < 800) {
      return screenHeight * 0.22;
    } else if (screenHeight < 900) {
      return screenHeight * 0.20;
    } else if (screenHeight < 1000) {
      return screenHeight * 0.18;
    } else {
      return screenHeight * 0.16;
    }
  }
}
