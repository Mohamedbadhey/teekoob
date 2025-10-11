import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/config/app_router.dart';

class FloatingAudioPlayer extends StatefulWidget {
  const FloatingAudioPlayer({super.key});

  @override
  State<FloatingAudioPlayer> createState() => _FloatingAudioPlayerState();
}

class _FloatingAudioPlayerState extends State<FloatingAudioPlayer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Dragging state
  Offset _position = const Offset(16, 0); // Default position
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start slide animation
    _slideController.forward();
    
    // Listen to audio service changes
    GlobalAudioPlayerService().addListener(_onAudioServiceChanged);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    GlobalAudioPlayerService().removeListener(_onAudioServiceChanged);
    super.dispose();
  }

  void _onAudioServiceChanged() {
    if (mounted) {
      setState(() {});
      
      final audioService = GlobalAudioPlayerService();
      if (audioService.isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _navigateToPlayer() {
    final audioService = GlobalAudioPlayerService();
    if (audioService.currentItem != null) {
      if (audioService.currentItem!.type == AudioType.book) {
        AppRouter.goToAudioPlayer(context, audioService.currentItem!.id);
      } else {
        // For podcasts, navigate to episode page
        // We need to get the podcast ID from the episode
        AppRouter.goToPodcastEpisode(context, '', audioService.currentItem!.id);
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    // Haptic feedback when starting to drag
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      
      // Keep the player within screen bounds
      final screenSize = MediaQuery.of(context).size;
      final playerWidth = 200.0; // Approximate width
      final playerHeight = 80.0; // Approximate height
      
      _position = Offset(
        _position.dx.clamp(0, screenSize.width - playerWidth),
        _position.dy.clamp(0, screenSize.height - playerHeight - 100), // Account for bottom navigation
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    // Haptic feedback when snapping to edge
    HapticFeedback.selectionClick();
    
    // Snap to edges for better UX with animation
    final screenSize = MediaQuery.of(context).size;
    final playerWidth = 200.0;
    
    Offset targetPosition;
    if (_position.dx < screenSize.width / 2) {
      // Snap to left edge
      targetPosition = Offset(16, _position.dy);
    } else {
      // Snap to right edge
      targetPosition = Offset(screenSize.width - playerWidth - 16, _position.dy);
    }
    
    // Animate to target position
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _position = targetPosition;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlobalAudioPlayerService(),
      builder: (context, child) {
        if (!GlobalAudioPlayerService().shouldShowFloatingPlayer) {
          return const SizedBox.shrink();
        }

        final audioService = GlobalAudioPlayerService();
        final currentItem = audioService.currentItem!;

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 200, // Fixed width for better dragging
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(_isDragging ? 0.4 : 0.2),
                      blurRadius: _isDragging ? 16 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToPlayer,
                    borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Cover Image
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            ),
                            child: currentItem.coverImageUrl != null && currentItem.coverImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      currentItem.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          currentItem.type == AudioType.book ? Icons.book : Icons.radio,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          size: 24,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    currentItem.type == AudioType.book ? Icons.book : Icons.radio,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentItem.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentItem.author ?? 'Unknown',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Play/Pause Button
                          GestureDetector(
                            onTap: () {
                              if (audioService.isPlaying) {
                                audioService.pause();
                              } else {
                                audioService.resume();
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Drag Handle
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          
                          // Close Button
                          GestureDetector(
                            onTap: () {
                              audioService.stop();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}