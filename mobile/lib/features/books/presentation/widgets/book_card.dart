import 'package:flutter/material.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';

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
  final bool compact;
  final Color? backgroundColor;

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
    this.compact = false,
    this.backgroundColor,
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
          backgroundColor: Theme.of(context).colorScheme.error,
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
      context.read<LibraryBloc>().add(ToggleFavorite(widget.userId, widget.book.id, itemType: 'book'));
      
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
          backgroundColor: Theme.of(context).colorScheme.primary,
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
    final cardWidth = widget.width ?? (widget.compact
        ? (screenWidth - (screenWidth * 0.10))
        : _getResponsiveWidth(screenWidth));
    final cardHeight = widget.height ?? _getResponsiveHeight(screenHeight);
    
    Widget cardContent = widget.compact
        ? _buildCompactContent(cardWidth)
        : Container(
      width: cardWidth,
      // height: cardHeight, // REMOVED FIXED HEIGHT - let content determine height
      margin: widget.compact
          ? const EdgeInsets.symmetric(vertical: 6)
          : EdgeInsets.zero, // No margin for grid layout
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.compact ? 12 : 20),
        boxShadow: widget.compact
            ? [
                BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
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
                height: widget.compact ? cardWidth * 0.35 : cardWidth * 0.8, // More compact cover in list mode
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(widget.compact ? 12 : 20)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary, // Primary color
                      Theme.of(context).colorScheme.secondary, // Secondary color
                      Theme.of(context).colorScheme.primary.withOpacity(0.7), // Light primary
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: widget.book.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.compact ? 12 : 20)),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(widget.compact ? 12 : 20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Theme.of(context).shadowColor.withOpacity(0.7),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.all(widget.compact ? cardWidth * 0.04 : cardWidth * 0.08),
                  child: Text(
                    widget.book.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.055 : 0.075),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Theme.of(context).shadowColor,
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
              cardWidth * (widget.compact ? 0.025 : 0.03),
              cardWidth * (widget.compact ? 0.02 : 0.03),
              cardWidth * (widget.compact ? 0.025 : 0.03),
              cardWidth * (widget.compact ? 0.005 : 0.01),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Take only needed space
              children: [
                // Book title
                Text(
                  widget.book.title,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.06 : 0.07), // Smaller font
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1, // Tighter line height
                  ),
                  maxLines: 1, // Single line to save space
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: cardWidth * (widget.compact ? 0.006 : 0.01)),
                
                // Author name
                if (widget.book.authors != null && widget.book.authors!.isNotEmpty)
                  Text(
                    widget.book.authors!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.05 : 0.06),
                      fontWeight: FontWeight.w500,
                      height: 1.1, // Proper line height
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                SizedBox(height: cardWidth * (widget.compact ? 0.006 : 0.01)),
                
                // Free book badge
                if (widget.book.isFree)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardWidth * 0.02,
                      vertical: cardWidth * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(cardWidth * 0.08),
                    ),
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.04 : 0.045),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                SizedBox(height: cardWidth * (widget.compact ? 0.006 : 0.01)),
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
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(cardWidth * 0.08),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                              size: _getResponsiveFontSize(cardWidth, widget.compact ? 0.05 : 0.06),
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            SizedBox(width: cardWidth * (widget.compact ? 0.015 : 0.02)),
                            Flexible(
                              child: Text(
                                _formatDuration(widget.book.duration),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.045 : 0.05),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: cardWidth * (widget.compact ? 0.015 : 0.02)),
                    
                    // Star rating - Dynamic
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.02, // Further reduced padding for grid layout
                          vertical: cardWidth * 0.005, // Further reduced padding for grid layout
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(cardWidth * 0.08),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: _getResponsiveFontSize(cardWidth, widget.compact ? 0.05 : 0.06),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: cardWidth * (widget.compact ? 0.015 : 0.02)),
                            Flexible(
                              child: Text(
                                (widget.book.rating ?? 0.0).toStringAsFixed(1),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: _getResponsiveFontSize(cardWidth, widget.compact ? 0.045 : 0.05),
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

  Widget _buildCompactContent(double cardWidth) {
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 96,
                color: Theme.of(context).colorScheme.surface,
                child: widget.book.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _buildFullImageUrl(widget.book.coverImageUrl!),
                        fit: BoxFit.cover,
                        width: 72,
                        height: 96,
                        placeholder: (context, url) => _buildGradientBackground(72),
                        errorWidget: (context, url, error) => _buildGradientBackground(72),
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      )
                    : _buildGradientBackground(72),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.title,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(cardWidth, 0.06),
                      fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.book.authors != null && widget.book.authors!.isNotEmpty)
                    Text(
                      widget.book.authors!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: _getResponsiveFontSize(cardWidth, 0.05),
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  
                  // Free book badge for compact mode
                  if (widget.book.isFree)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Theme.of(context).colorScheme.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(widget.book.duration),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              (widget.book.rating ?? 0.0).toStringAsFixed(1),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground(double cardWidth) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
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
