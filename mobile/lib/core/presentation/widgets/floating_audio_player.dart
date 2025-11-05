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
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  // Dragging state
  Offset _position = const Offset(16, 0); // Default position
  bool _isDragging = false;
  bool _isExpanded = false;
  
  // Audio controls state
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isSeeking = false;

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
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
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
    _expandController.dispose();
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
        // Get the podcast ID from the service
        final podcastId = audioService.currentPodcastId ?? '';
        if (podcastId.isNotEmpty) {
          AppRouter.goToPodcastEpisode(context, podcastId, audioService.currentItem!.id);
        } else {
          // Fallback: try to navigate to podcast detail if we can't find episode
          print('⚠️ No podcast ID available, cannot navigate to episode');
        }
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
    
    HapticFeedback.lightImpact();
  }

  void _skipBackward() {
    final audioService = GlobalAudioPlayerService();
    final newPosition = audioService.position - const Duration(seconds: 15);
    audioService.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    HapticFeedback.lightImpact();
  }

  void _skipForward() {
    final audioService = GlobalAudioPlayerService();
    final newPosition = audioService.position + const Duration(seconds: 15);
    final maxPosition = audioService.duration;
    audioService.seekTo(newPosition > maxPosition ? maxPosition : newPosition);
    HapticFeedback.lightImpact();
  }

  void _playPreviousEpisode() {
    final audioService = GlobalAudioPlayerService();
    if (audioService.hasPreviousEpisode) {
      audioService.playPreviousEpisode();
      HapticFeedback.lightImpact();
    }
  }

  void _playNextEpisode() {
    final audioService = GlobalAudioPlayerService();
    if (audioService.hasNextEpisode) {
      audioService.playNextEpisode();
      HapticFeedback.lightImpact();
    }
  }

  void _changePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    
    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });
    
    GlobalAudioPlayerService().setPlaybackSpeed(_playbackSpeed);
    HapticFeedback.lightImpact();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
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
        final progress = audioService.progress;

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _getResponsiveWidth(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(_isDragging ? 0.4 : 0.15),
                      blurRadius: _isDragging ? 20 : 15,
                      offset: const Offset(0, 8),
                      spreadRadius: _isDragging ? 2 : 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      // Main content
                      InkWell(
                        onTap: _navigateToPlayer,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Top row with cover, info, and controls
                              Row(
                                children: [
                                  // Cover Image with pulse animation
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: audioService.isPlaying ? _pulseAnimation.value : 1.0,
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: currentItem.coverImageUrl != null && currentItem.coverImageUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    currentItem.coverImageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        currentItem.type == AudioType.book ? Icons.book : Icons.radio,
                                                        color: Theme.of(context).colorScheme.primary,
                                                        size: 28,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  currentItem.type == AudioType.book ? Icons.book : Icons.radio,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 28,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentItem.title,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentItem.displaySubtitle,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatDuration(audioService.position)} / ${_formatDuration(audioService.duration)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Play/Pause Button
                                  GestureDetector(
                                    onTap: () {
                                      if (audioService.isPlaying) {
                                        audioService.pause();
                                      } else {
                                        audioService.resume();
                                      }
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        audioService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Expand/Collapse Button
                                  GestureDetector(
                                    onTap: _toggleExpanded,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: AnimatedRotation(
                                        turns: _isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.expand_more_rounded,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 8),
                                  
                                  // Close Button
                                  GestureDetector(
                                    onTap: () {
                                      audioService.stop();
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Theme.of(context).colorScheme.error,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Expandable controls section
                              AnimatedBuilder(
                                animation: _expandAnimation,
                                builder: (context, child) {
                                  return SizeTransition(
                                    sizeFactor: _expandAnimation,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Episode navigation controls (for podcasts)
                                          if (currentItem.type == AudioType.podcast) ...[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                // Previous episode
                                                _buildControlButton(
                                                  icon: Icons.skip_previous_rounded,
                                                  onTap: _playPreviousEpisode,
                                                  tooltip: 'Previous episode',
                                                ),
                                                
                                                // Next episode
                                                _buildControlButton(
                                                  icon: Icons.skip_next_rounded,
                                                  onTap: _playNextEpisode,
                                                  tooltip: 'Next episode',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          
                                          // Skip controls and speed
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Skip backward
                                              _buildControlButton(
                                                icon: Icons.replay_10_rounded,
                                                onTap: _skipBackward,
                                                tooltip: 'Skip 15s back',
                                              ),
                                              
                                              // Speed control
                                              _buildControlButton(
                                                icon: Icons.speed_rounded,
                                                onTap: _changePlaybackSpeed,
                                                tooltip: '${_playbackSpeed}x speed',
                                                child: Text(
                                                  '${_playbackSpeed}x',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              
                                              // Skip forward
                                              _buildControlButton(
                                                icon: Icons.forward_10_rounded,
                                                onTap: _skipForward,
                                                tooltip: 'Skip 15s forward',
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Seek bar
                                          Row(
                                            children: [
                                              Text(
                                                _formatDuration(audioService.position),
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                              Expanded(
                                                child: SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                    activeTrackColor: Theme.of(context).colorScheme.primary,
                                                    inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                                    thumbColor: Theme.of(context).colorScheme.primary,
                                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                                    trackHeight: 3,
                                                  ),
                                                  child: Slider(
                                                    value: progress.clamp(0.0, 1.0),
                                                    onChanged: (value) {
                                                      if (!_isSeeking) {
                                                        setState(() {
                                                          _isSeeking = true;
                                                        });
                                                      }
                                                    },
                                                    onChangeEnd: (value) {
                                                      final newPosition = Duration(
                                                        milliseconds: (value * audioService.duration.inMilliseconds).round(),
                                                      );
                                                      audioService.seekTo(newPosition);
                                                      setState(() {
                                                        _isSeeking = false;
                                                      });
                                                      HapticFeedback.lightImpact();
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(audioService.duration),
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getResponsiveWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isExpanded) {
      // Expanded width: responsive but with max limit
      if (screenWidth < 360) {
        return screenWidth - 32; // Full width minus padding on small phones
      } else if (screenWidth < 600) {
        return screenWidth * 0.85; // 85% on medium phones
      } else {
        return 400; // Fixed max width on tablets/desktop
      }
    } else {
      // Collapsed width: responsive
      if (screenWidth < 360) {
        return screenWidth - 32; // Full width minus padding on small phones
      } else if (screenWidth < 600) {
        return screenWidth * 0.75; // 75% on medium phones
      } else {
        return 320; // Fixed width on tablets/desktop
      }
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Widget? child,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: child ?? Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }
}