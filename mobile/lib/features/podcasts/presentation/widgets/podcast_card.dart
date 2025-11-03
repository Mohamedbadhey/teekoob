import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';

class PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool enableAnimations;
  final bool showLibraryActions;
  final bool isInLibrary;
  final bool isFavorite;
  final bool isDownloaded;
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
    this.isDownloaded = false,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Image Section - Top 65% of card
            Expanded(
              flex: 65,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSmallScreen ? 8 : 12),
                      topRight: Radius.circular(isSmallScreen ? 8 : 12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      child: podcast.coverImageUrl != null && podcast.coverImageUrl!.isNotEmpty
                          ? Image.network(
                              podcast.coverImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.radio,
                                    size: cardWidth * 0.3,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.radio,
                                size: cardWidth * 0.3,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                    ),
                  ),
                  
                  // Favorite button - top right
                  if (showLibraryActions)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleFavorite(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                              color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content Section - Bottom 35% with solid background
            Expanded(
              flex: 35,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isSmallScreen ? 8 : 12),
                    bottomRight: Radius.circular(isSmallScreen ? 8 : 12),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: cardWidth * 0.035,
                  vertical: cardWidth * 0.025,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      podcast.displayTitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: cardWidth * 0.01),
                    
                    // Host
                    if (podcast.displayHost.isNotEmpty)
                      Text(
                        podcast.displayHost,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : (isTablet ? 12 : 10),
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    SizedBox(height: cardWidth * 0.012),
                    
                    // Bottom row - Episodes, Rating, and badges
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Episodes count
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: cardWidth * 0.018,
                                  vertical: cardWidth * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(cardWidth * 0.06),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.headphones,
                                      size: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    SizedBox(width: cardWidth * 0.012),
                                    Flexible(
                                      child: Text(
                                        _formatEpisodeCount(podcast.totalEpisodes ?? 0),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(width: cardWidth * 0.012),
                            
                            // Rating
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: cardWidth * 0.018,
                                vertical: cardWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(cardWidth * 0.06),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: isSmallScreen ? 10 : (isTablet ? 14 : 12),
                                    color: Colors.amber.shade700,
                                  ),
                                  SizedBox(width: cardWidth * 0.012),
                                  Flexible(
                                    child: Text(
                                      (podcast.rating ?? 0.0).toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : (isTablet ? 13 : 11),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Features badges
                        if (podcast.isFeatured || podcast.isPremium)
                          Padding(
                            padding: EdgeInsets.only(top: cardWidth * 0.012),
                            child: Row(
                              children: [
                                if (podcast.isFeatured)
                                  Container(
                                    margin: EdgeInsets.only(right: cardWidth * 0.012),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: cardWidth * 0.018,
                                      vertical: cardWidth * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(cardWidth * 0.06),
                                    ),
                                    child: Text(
                                      '★',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 7 : (isTablet ? 10 : 8),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (podcast.isPremium)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: cardWidth * 0.018,
                                      vertical: cardWidth * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(cardWidth * 0.06),
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
    // Compact responsive height - smaller cards for better fit
    if (screenHeight < 600) {
      return 160; // Small screens - reduced from 180
    } else if (screenHeight < 700) {
      return 170; // Medium screens - reduced from 200
    } else if (screenHeight < 800) {
      return 180; // Large screens - reduced from 220
    } else {
      return 190; // Extra large screens - reduced from 220
    }
  }

  void _toggleFavorite(BuildContext context) {
    context.read<LibraryBloc>().add(
      ToggleFavorite(userId, podcast.id, itemType: 'podcast'),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isFavorite ? Icons.favorite_border : Icons.favorite,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(isFavorite ? 'Removed from favorites' : 'Added to favorites!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
