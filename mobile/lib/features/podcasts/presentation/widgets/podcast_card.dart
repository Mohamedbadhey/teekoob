import 'package:flutter/material.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/services/localization_service.dart';

class PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool enableAnimations;
  final bool showLibraryActions;
  final bool isInLibrary;
  final bool isFavorite;
  final String userId;

  const PodcastCard({
    super.key,
    required this.podcast,
    this.onTap,
    this.width,
    this.height,
    this.enableAnimations = true,
    this.showLibraryActions = true,
    this.isInLibrary = false,
    this.isFavorite = false,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? _getResponsiveCardWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveCardHeight();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: podcast.coverImageUrl != null && podcast.coverImageUrl!.isNotEmpty
                      ? Image.network(
                          podcast.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCover(context);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoadingCover(context);
                          },
                        )
                      : _buildDefaultCover(context),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      podcast.displayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Host
                    if (podcast.displayHost.isNotEmpty)
                      Text(
                        podcast.displayHost,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // Bottom row with episodes count and features
                    Row(
                      children: [
                        // Episodes count
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.headphones,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${podcast.totalEpisodes ?? 0}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Features
                        if (podcast.isFeatured || podcast.isPremium)
                          Row(
                            children: [
                              if (podcast.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '★',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (podcast.isFeatured && podcast.isPremium)
                                const SizedBox(width: 4),
                              if (podcast.isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'P',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radio,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Podcast',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCover(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  double _getResponsiveCardWidth(double screenWidth) {
    if (screenWidth < 360) {
      return screenWidth * 0.40; // Small phones
    } else if (screenWidth < 400) {
      return screenWidth * 0.38; // Medium phones
    } else if (screenWidth < 480) {
      return screenWidth * 0.36; // Large phones
    } else if (screenWidth < 600) {
      return screenWidth * 0.34; // Very large phones
    } else if (screenWidth < 768) {
      return screenWidth * 0.32; // Small tablets
    } else {
      return screenWidth * 0.28; // Large tablets
    }
  }

  double _getResponsiveCardHeight() {
    return 200; // Fixed height for consistency
  }
}

class ShimmerPodcastCard extends StatelessWidget {
  final double? width;
  final double? height;

  const ShimmerPodcastCard({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? _getResponsiveCardWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveCardHeight();

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image Shimmer
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          
          // Content Shimmer
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title shimmer
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Host shimmer
                  Container(
                    height: 12,
                    width: cardWidth * 0.6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bottom row shimmer
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getResponsiveCardWidth(double screenWidth) {
    if (screenWidth < 360) {
      return screenWidth * 0.40;
    } else if (screenWidth < 400) {
      return screenWidth * 0.38;
    } else if (screenWidth < 480) {
      return screenWidth * 0.36;
    } else if (screenWidth < 600) {
      return screenWidth * 0.34;
    } else if (screenWidth < 768) {
      return screenWidth * 0.32;
    } else {
      return screenWidth * 0.28;
    }
  }

  double _getResponsiveCardHeight() {
    return 200;
  }
}
