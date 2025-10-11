import 'package:flutter/material.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = width ?? _getResponsiveCardWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveCardHeight(screenHeight);
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth > 768;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: isSmallScreen ? 6 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Play Button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
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
                ],
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      podcast.displayTitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    
                    // Host
                    if (podcast.displayHost.isNotEmpty)
                      Text(
                        podcast.displayHost,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : (isTablet ? 14 : 12),
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
                                size: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Flexible(
                                child: Text(
                                  _formatEpisodeCount(podcast.totalEpisodes ?? 0),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 3 : 4, 
                                    vertical: isSmallScreen ? 1 : 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                                  ),
                                  child: Text(
                                    '★',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 7 : (isTablet ? 10 : 8),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (podcast.isFeatured && podcast.isPremium)
                                SizedBox(width: isSmallScreen ? 2 : 4),
                              if (podcast.isPremium)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 3 : 4, 
                                    vertical: isSmallScreen ? 1 : 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                                  ),
                                  child: Text(
                                    'P',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 7 : (isTablet ? 10 : 8),
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
      return screenWidth * 0.42; // Small phones - slightly larger for better visibility
    } else if (screenWidth < 400) {
      return screenWidth * 0.40; // Medium phones
    } else if (screenWidth < 480) {
      return screenWidth * 0.38; // Large phones
    } else if (screenWidth < 600) {
      return screenWidth * 0.36; // Very large phones
    } else if (screenWidth < 768) {
      return screenWidth * 0.34; // Small tablets
    } else if (screenWidth < 1024) {
      return screenWidth * 0.30; // Medium tablets
    } else {
      return screenWidth * 0.26; // Large tablets/desktop
    }
  }

  double _getResponsiveCardHeight(double screenHeight) {
    if (screenHeight < 600) {
      return 180; // Small screens
    } else if (screenHeight < 800) {
      return 200; // Medium screens
    } else {
      return 220; // Large screens
    }
  }

  String _formatEpisodeCount(int count) {
    if (count == 0) {
      return '0 episodes';
    } else if (count == 1) {
      return '1 episode';
    } else if (count < 1000) {
      return '$count episodes';
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K episodes';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M episodes';
    }
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
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = width ?? _getResponsiveCardWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveCardHeight(screenHeight);
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
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
      return screenWidth * 0.42; // Small phones - slightly larger for better visibility
    } else if (screenWidth < 400) {
      return screenWidth * 0.40; // Medium phones
    } else if (screenWidth < 480) {
      return screenWidth * 0.38; // Large phones
    } else if (screenWidth < 600) {
      return screenWidth * 0.36; // Very large phones
    } else if (screenWidth < 768) {
      return screenWidth * 0.34; // Small tablets
    } else if (screenWidth < 1024) {
      return screenWidth * 0.30; // Medium tablets
    } else {
      return screenWidth * 0.26; // Large tablets/desktop
    }
  }

  double _getResponsiveCardHeight(double screenHeight) {
    if (screenHeight < 600) {
      return 180; // Small screens
    } else if (screenHeight < 800) {
      return 200; // Medium screens
    } else {
      return 220; // Large screens
    }
  }
}
