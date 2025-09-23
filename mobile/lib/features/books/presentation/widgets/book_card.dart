import 'package:flutter/material.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool showLibraryActions;
  final bool isInLibrary;
  final bool isFavorite;
  final String userId;
  final bool enableAnimations;

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
    this.enableAnimations = true,
  }) : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableAnimations) {
      _scaleController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ));
      
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ));
      
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimations) {
      _scaleController.dispose();
      _fadeController.dispose();
    }
    super.dispose();
  }

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
    // More granular responsive breakpoints
    if (screenWidth < 320) {
      return screenWidth * 0.45; // Very small phones
    } else if (screenWidth < 360) {
      return screenWidth * 0.42; // Small phones
    } else if (screenWidth < 400) {
      return screenWidth * 0.40; // Medium phones
    } else if (screenWidth < 480) {
      return screenWidth * 0.38; // Large phones
    } else if (screenWidth < 600) {
      return screenWidth * 0.35; // Very large phones
    } else if (screenWidth < 768) {
      return screenWidth * 0.30; // Small tablets
    } else {
      return screenWidth * 0.25; // Large tablets
    }
  }

  double _getResponsiveHeight(double screenHeight) {
    // Content-fitted responsive breakpoints - height adapts to content with overflow prevention
    if (screenHeight < 600) {
      return screenHeight * 0.26; // Very small screens - content fitted with overflow prevention
    } else if (screenHeight < 700) {
      return screenHeight * 0.24; // Small screens - content fitted with overflow prevention
    } else if (screenHeight < 800) {
      return screenHeight * 0.22; // Medium screens - content fitted with overflow prevention
    } else if (screenHeight < 900) {
      return screenHeight * 0.20; // Large screens - content fitted with overflow prevention
    } else if (screenHeight < 1000) {
      return screenHeight * 0.18; // Very large screens - content fitted with overflow prevention
    } else {
      return screenHeight * 0.16; // Extra large screens - content fitted with overflow prevention
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
    print('📚 BookCard: Adding book ${widget.book.id} to library');
    try {
      context.read<LibraryBloc>().add(AddBookToLibrary(
        widget.userId,
        widget.book.id,
        status: 'reading',
        progress: 0.0,
      ));
      
      // Show success message with animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Book added to library!'),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('❌ BookCard: Error adding book to library: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to add book to library'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _toggleFavorite(BuildContext context) {
    print('❤️ BookCard: Toggling favorite for book ${widget.book.id}');
    try {
      context.read<LibraryBloc>().add(ToggleFavorite(widget.userId, widget.book.id));
      
      // Show success message with animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                widget.isFavorite ? Icons.favorite_border : Icons.favorite,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(widget.isFavorite ? 'Removed from favorites' : 'Added to favorites!'),
            ],
          ),
          backgroundColor: const Color(0xFF0466c8),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('❌ BookCard: Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update favorites'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    
    // Responsive sizing based on screen dimensions
    final cardWidth = widget.width ?? _getResponsiveWidth(screenWidth);
    final cardHeight = widget.height ?? _getResponsiveHeight(screenHeight);
    
    Widget cardContent = Container(
      width: cardWidth,
      // height: cardHeight, // REMOVED FIXED HEIGHT - let content determine height
      margin: EdgeInsets.only(right: widget.width != null ? 0 : screenWidth * 0.03), // No margin for grid layout, margin for horizontal scroll
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
        mainAxisSize: MainAxisSize.min, // Let content determine height
        children: [
          // Book Cover - FILLS ENTIRE CARD VERTICALLY
          Stack(
            children: [
              // Cover Image Container - FILLS ENTIRE CARD
              Container(
                width: double.infinity,
                height: cardWidth * 0.8, // Slightly reduced height to prevent overflow - 0.8:1 aspect ratio
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
                child: widget.book.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: CachedNetworkImage(
                          imageUrl: _buildFullImageUrl(widget.book.coverImageUrl!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => _buildGradientBackground(cardWidth),
                          errorWidget: (context, url, error) => _buildGradientBackground(cardWidth),
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 100),
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
                    widget.book.title,
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
                
              // Action buttons removed for cleaner design
              ],
            ),
            
          // Book Info below cover - Dynamic content height
          Container(
            padding: EdgeInsets.fromLTRB(
              cardWidth * 0.03, // Further reduced left padding for grid layout
              cardWidth * 0.03, // Further reduced top padding for grid layout
              cardWidth * 0.03, // Further reduced right padding for grid layout
              cardWidth * 0.01, // Further reduced bottom padding for grid layout
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Take only needed space
              children: [
                // Book title
                Text(
                  widget.book.title,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(cardWidth, 0.07), // Smaller font
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                    height: 1.1, // Tighter line height
                  ),
                  maxLines: 1, // Single line to save space
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: cardWidth * 0.01), // Further reduced spacing for grid layout
                
                // Author name
                if (widget.book.authors != null && widget.book.authors!.isNotEmpty)
                  Text(
                    widget.book.authors!,
                    style: TextStyle(
                      color: const Color(0xFF3B82F6),
                      fontSize: _getResponsiveFontSize(cardWidth, 0.06), // Proper font size
                      fontWeight: FontWeight.w500,
                      height: 1.1, // Proper line height
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                SizedBox(height: cardWidth * 0.01), // Further reduced spacing before info row for grid layout
                
                // Info row with ratings and time - Dynamic layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clock icon with time - Dynamic
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.02, // Further reduced padding for grid layout
                          vertical: cardWidth * 0.005, // Further reduced padding for grid layout
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(cardWidth * 0.08),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: _getResponsiveFontSize(cardWidth, 0.06), // Smaller icon
                              color: Colors.white,
                            ),
                            SizedBox(width: cardWidth * 0.02), // Reduced spacing
                            Flexible(
                              child: Text(
                                _formatDuration(widget.book.duration),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _getResponsiveFontSize(cardWidth, 0.05), // Smaller text
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: cardWidth * 0.02),
                    
                    // Star rating - Dynamic
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.02, // Further reduced padding for grid layout
                          vertical: cardWidth * 0.005, // Further reduced padding for grid layout
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(cardWidth * 0.08),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: _getResponsiveFontSize(cardWidth, 0.06), // Smaller icon
                              color: const Color(0xFF1E3A8A),
                            ),
                            SizedBox(width: cardWidth * 0.02), // Reduced spacing
                            Flexible(
                              child: Text(
                                (widget.book.rating ?? 0.0).toStringAsFixed(1),
                                style: TextStyle(
                                  color: const Color(0xFF1E3A8A),
                                  fontSize: _getResponsiveFontSize(cardWidth, 0.05), // Smaller text
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
        ],
      ),
    );

    // Wrap with animations if enabled
    if (widget.enableAnimations) {
      return GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: cardContent,
              ),
            );
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onTap,
        child: cardContent,
      );
    }
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
