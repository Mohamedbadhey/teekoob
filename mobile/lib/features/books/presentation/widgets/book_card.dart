import 'package:flutter/material.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool showLibraryActions;
  final bool isInLibrary;
  final bool isFavorite;
  final String userId;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
    this.width,
    this.height,
    this.showLibraryActions = false,
    this.isInLibrary = false,
    this.isFavorite = false,
    this.userId = 'current_user',
  }) : super(key: key);

  String _buildFullImageUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    return '${AppConfig.mediaBaseUrl}$relativeUrl';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '0 sec';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth < 360) {
      return screenWidth * 0.42; // Small phones: 42% of screen width
    } else if (screenWidth < 400) {
      return screenWidth * 0.40; // Medium phones: 40% of screen width
    } else if (screenWidth < 480) {
      return screenWidth * 0.38; // Large phones: 38% of screen width
    } else {
      return screenWidth * 0.35; // Very large phones/tablets: 35% of screen width
    }
  }

  double _getResponsiveHeight(double screenHeight) {
    if (screenHeight < 700) {
      return screenHeight * 0.35; // Small screens: 35% of screen height
    } else if (screenHeight < 800) {
      return screenHeight * 0.32; // Medium screens: 32% of screen height
    } else if (screenHeight < 900) {
      return screenHeight * 0.30; // Large screens: 30% of screen height
    } else {
      return screenHeight * 0.28; // Very large screens: 28% of screen height
    }
  }

  double _getResponsiveFontSize(double cardWidth, double baseRatio) {
    final baseFontSize = cardWidth * baseRatio;
    // Ensure minimum and maximum font sizes for readability
    if (baseFontSize < 10) return 10;
    if (baseFontSize > 18) return 18;
    return baseFontSize;
  }

  void _addToLibrary(BuildContext context) {
    print('📚 BookCard: Adding book ${book.id} to library');
    try {
      context.read<LibraryBloc>().add(AddBookToLibrary(
        userId,
        book.id,
        status: 'reading',
        progress: 0.0,
      ));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book added to library!'),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ BookCard: Error adding book to library: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book to library'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleFavorite(BuildContext context) {
    print('❤️ BookCard: Toggling favorite for book ${book.id}');
    try {
      context.read<LibraryBloc>().add(ToggleFavorite(userId, book.id));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites!'),
          backgroundColor: const Color(0xFFF56C23),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ BookCard: Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen dimensions
    final cardWidth = width ?? _getResponsiveWidth(screenWidth);
    final cardHeight = height ?? _getResponsiveHeight(screenHeight);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.only(right: screenWidth * 0.04), // 4% of screen width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover - FULLY VISIBLE IMAGE
            Stack(
              children: [
                // Cover Image Container - FULLY VISIBLE
                Container(
                  width: double.infinity,
                  height: cardHeight * 0.65, // 65% of card height for image
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E3A8A), // Dark blue
                        Color(0xFF3B82F6), // Medium blue
                        Color(0xFF60A5FA), // Light blue
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: book.coverImageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            _buildFullImageUrl(book.coverImageUrl!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildGradientBackground(cardWidth);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildGradientBackground(cardWidth);
                            },
                          ),
                        )
                      : _buildGradientBackground(cardWidth),
                ),
                
                // Title overlay - positioned to not cover image content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    padding: EdgeInsets.all(cardWidth * 0.08),
                    child: Text(
                      book.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(cardWidth, 0.075),
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Library and Favorite Action Buttons
                if (showLibraryActions)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add to Library Button
                        if (!isInLibrary)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.library_add_rounded,
                                color: const Color(0xFF1E3A8A),
                                size: cardWidth * 0.06,
                              ),
                              onPressed: () => _addToLibrary(context),
                              padding: EdgeInsets.all(cardWidth * 0.02),
                              constraints: BoxConstraints(
                                minWidth: cardWidth * 0.1,
                                minHeight: cardWidth * 0.1,
                              ),
                            ),
                          ),
                        
                        SizedBox(width: cardWidth * 0.02),
                        
                        // Favorite Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? const Color(0xFFF56C23) : const Color(0xFF1E3A8A),
                              size: cardWidth * 0.06,
                            ),
                            onPressed: () => _toggleFavorite(context),
                            padding: EdgeInsets.all(cardWidth * 0.02),
                            constraints: BoxConstraints(
                              minWidth: cardWidth * 0.1,
                              minHeight: cardWidth * 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Book Info below cover
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(cardWidth * 0.06), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book title
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(cardWidth, 0.08), // Slightly smaller
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: cardWidth * 0.03), // Reduced spacing
                    
                    // Author name
                    if (book.authors != null && book.authors!.isNotEmpty)
                      Text(
                        book.authors!,
                        style: TextStyle(
                          color: const Color(0xFF3B82F6),
                          fontSize: _getResponsiveFontSize(cardWidth, 0.07), // Slightly smaller
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // Info row with ratings and time - More compact layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Clock icon with time - More compact
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: cardWidth * 0.04, // Reduced padding
                              vertical: cardWidth * 0.03, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(cardWidth * 0.08), // Smaller radius
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                  blurRadius: 6, // Reduced blur
                                  offset: const Offset(0, 2), // Reduced offset
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: _getResponsiveFontSize(cardWidth, 0.08), // Smaller icon
                                  color: Colors.white,
                                ),
                                SizedBox(width: cardWidth * 0.025), // Reduced spacing
                                Flexible(
                                  child: Text(
                                    _formatDuration(book.duration),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _getResponsiveFontSize(cardWidth, 0.06), // Smaller text
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: cardWidth * 0.02), // Small spacing between elements
                        
                        // Star rating - More compact
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: cardWidth * 0.04, // Reduced padding
                              vertical: cardWidth * 0.03, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(cardWidth * 0.08), // Smaller radius
                              border: Border.all(
                                color: const Color(0xFF1E3A8A),
                                width: 1.0, // Thinner border
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: _getResponsiveFontSize(cardWidth, 0.08), // Smaller icon
                                  color: const Color(0xFF1E3A8A),
                                ),
                                SizedBox(width: cardWidth * 0.025), // Reduced spacing
                                Flexible(
                                  child: Text(
                                    (book.rating ?? 0.0).toStringAsFixed(1),
                                    style: TextStyle(
                                      color: const Color(0xFF1E3A8A),
                                      fontSize: _getResponsiveFontSize(cardWidth, 0.07), // Smaller text
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildGradientBackground(double cardWidth) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book,
          size: cardWidth * 0.25,
          color: Colors.white,
        ),
      ),
    );
  }
}
