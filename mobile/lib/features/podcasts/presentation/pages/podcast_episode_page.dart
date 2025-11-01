import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/podcasts/bloc/podcasts_bloc.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';

class PodcastEpisodePage extends StatefulWidget {
  final String podcastId;
  final String episodeId;

  const PodcastEpisodePage({
    super.key,
    required this.podcastId,
    required this.episodeId,
  });

  @override
  State<PodcastEpisodePage> createState() => _PodcastEpisodePageState();
}

class _PodcastEpisodePageState extends State<PodcastEpisodePage>
    with TickerProviderStateMixin {
  PodcastEpisode? _episode;
  Podcast? _podcast;
  List<PodcastEpisode> _episodes = [];
  bool _isLoading = true;
  bool _isLoadingPodcast = true;
  bool _isLoadingEpisodes = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Audio player state
  late GlobalAudioPlayerService _audioService;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isRepeatEnabled = false;
  bool _isShuffleEnabled = false;

  @override
  void initState() {
    super.initState();
    _audioService = GlobalAudioPlayerService();
    _audioService.initialize();
    
    // Listen to audio service changes
    _audioService.addListener(_onAudioServiceChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadEpisodeData();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceChanged);
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onAudioServiceChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _currentPosition = _audioService.position;
        _totalDuration = _audioService.duration;
      });
    }
  }

  void _loadEpisodeData() {
    print('🎧 PodcastEpisodePage: Loading episode data for podcast: ${widget.podcastId}, episode: ${widget.episodeId}');
    context.read<PodcastsBloc>().add(LoadPodcastEpisodeById(widget.podcastId, widget.episodeId));
    context.read<PodcastsBloc>().add(LoadPodcastById(widget.podcastId));
    context.read<PodcastsBloc>().add(LoadPodcastEpisodes(podcastId: widget.podcastId));
  }

  void _togglePlayPause() async {
    if (_episode == null) return;
    
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_audioService.currentItem?.id == _episode!.id) {
        await _audioService.resume();
      } else {
        // Use the new queue management functionality
        if (_episodes.isNotEmpty) {
          await _audioService.playPodcastEpisodeWithQueue(_episode!, _episodes, widget.podcastId, podcast: _podcast);
        } else {
          await _audioService.playPodcastEpisode(_episode!, podcast: _podcast);
        }
      }
    }
  }

  void _seekTo(Duration position) async {
    await _audioService.seekTo(position);
  }

  void _skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 30);
    final maxDuration = _totalDuration;
    
    if (newPosition > maxDuration) {
      await _audioService.seekTo(maxDuration);
    } else {
      await _audioService.seekTo(newPosition);
    }
  }

  void _skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 30);
    const minDuration = Duration.zero;
    
    if (newPosition < minDuration) {
      await _audioService.seekTo(minDuration);
    } else {
      await _audioService.seekTo(newPosition);
    }
  }

  void _changePlaybackSpeed() {
    setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 1.25 : 
                      _playbackSpeed == 1.25 ? 1.5 : 
                      _playbackSpeed == 1.5 ? 2.0 : 1.0;
    });
    // TODO: Implement speed change in audio service
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeatEnabled = !_isRepeatEnabled;
    });
    // TODO: Implement repeat functionality
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffleEnabled = !_isShuffleEnabled;
    });
    // TODO: Implement shuffle functionality
  }

  void _skipPrevious() {
    print('🎧 _skipPrevious: Using global audio service queue management');
    
    if (_audioService.hasPreviousEpisode) {
      _audioService.playPreviousEpisode();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No previous episode available')),
      );
    }
  }

  void _skipNext() {
    print('🎧 _skipNext: Using global audio service queue management');
    
    if (_audioService.hasNextEpisode) {
      _audioService.playNextEpisode();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No next episode available')),
      );
    }
  }

  void _navigateToEpisode(PodcastEpisode episode) {
    // Stop current audio if playing
    if (_isPlaying) {
      _audioService.stop();
    }
    
    // Navigate to the new episode
    context.push('/podcast/${widget.podcastId}/episode/${episode.id}');
  }

  Widget _buildDraggableProgressBar() {
    return GestureDetector(
      onTapDown: (details) => _onProgressBarTap(details),
      onPanStart: (details) => _onProgressBarPanStart(details),
      onPanUpdate: (details) => _onProgressBarPanUpdate(details),
      onPanEnd: (details) => _onProgressBarPanEnd(details),
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Background track
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress track
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _totalDuration.inMilliseconds > 0 
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
                  : 0.0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Draggable thumb
            Positioned(
              left: _totalDuration.inMilliseconds > 0 
                  ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds) * 
                    (MediaQuery.of(context).size.width - 32 - 16) - 8 // Account for padding and thumb size
                  : -8,
              top: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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

  void _onProgressBarTap(TapDownDetails details) {
    _seekToPosition(details.localPosition);
  }

  void _onProgressBarPanStart(DragStartDetails details) {
    // Optional: Add haptic feedback
    // HapticFeedback.lightImpact();
  }

  void _onProgressBarPanUpdate(DragUpdateDetails details) {
    _seekToPosition(details.localPosition);
  }

  void _onProgressBarPanEnd(DragEndDetails details) {
    // Optional: Add haptic feedback
    // HapticFeedback.lightImpact();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _handleBackNavigation() {
    print('🎧 PodcastEpisodePage: Back button pressed');
    
    // Check if we can pop (there's something in the navigation stack)
    if (context.canPop()) {
      print('🎧 PodcastEpisodePage: Can pop, navigating back');
      // Navigate back to previous page (podcast detail or episodes list)
      context.pop();
    } else {
      // Nothing to pop, navigate to podcast detail page or home
      print('🎧 PodcastEpisodePage: Nothing to pop, navigating to podcast detail');
      try {
        // Try to navigate to podcast detail page first
        context.go('/podcast/${widget.podcastId}');
      } catch (e) {
        // If that fails, go to home
        print('🎧 PodcastEpisodePage: Failed to navigate to podcast detail, going to home');
        context.go('/home');
      }
    }
  }

  void _seekToPosition(Offset localPosition) {
    if (_totalDuration.inMilliseconds <= 0) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (_totalDuration.inMilliseconds * progress).round(),
    );
    
    _seekTo(newPosition);
  }

  void _shareEpisode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.getComingSoonText),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _addToLibrary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.getComingSoonText),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic popping to handle it manually
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle back navigation manually
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: BlocListener<PodcastsBloc, PodcastsState>(
        listener: (context, state) {
          print('🎧 PodcastEpisodePage: Received state: ${state.runtimeType}');
          if (state is PodcastEpisodeLoaded) {
            print('🎧 PodcastEpisodePage: Episode loaded successfully: ${state.episode.title}');
            setState(() {
              _episode = state.episode;
              _isLoading = false;
            });
            _animationController.forward();
            _slideController.forward();
          } else if (state is PodcastLoaded) {
            print('🎧 PodcastEpisodePage: Podcast loaded successfully: ${state.podcast.title}');
            setState(() {
              _podcast = state.podcast;
              _isLoadingPodcast = false;
            });
          } else if (state is PodcastEpisodesLoaded) {
            print('🎧 PodcastEpisodePage: Episodes loaded successfully: ${state.episodes.length} episodes');
            print('🎧 PodcastEpisodePage: Episode IDs: ${state.episodes.map((e) => e.id).toList()}');
            print('🎧 PodcastEpisodePage: Episode titles: ${state.episodes.map((e) => e.title).toList()}');
            print('🎧 PodcastEpisodePage: Episode numbers: ${state.episodes.map((e) => e.episodeNumber).toList()}');
            
            // Sort episodes by episode number in ascending order for proper navigation
            final sortedEpisodes = List<PodcastEpisode>.from(state.episodes)
              ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
            
            print('🎧 PodcastEpisodePage: Sorted episode numbers: ${sortedEpisodes.map((e) => e.episodeNumber).toList()}');
            
            setState(() {
              _episodes = sortedEpisodes;
              _isLoadingEpisodes = false;
            });
          } else if (state is PodcastsError) {
            print('💥 PodcastEpisodePage: Error state received: ${state.message}');
            setState(() {
              _isLoading = false;
              _isLoadingPodcast = false;
              _isLoadingEpisodes = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is PodcastsLoading) {
            print('🎧 PodcastEpisodePage: Loading state received');
          }
        },
        child: (_isLoading || _isLoadingPodcast || _isLoadingEpisodes) ? _buildLoadingState() : _buildEpisodeContent(),
      ),
    ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading episode...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeContent() {
    if (_episode == null) {
      return _buildErrorState();
    }

    return CustomScrollView(
      slivers: [
        // Hero App Bar with Podcast Cover Image
        SliverAppBar(
          expandedHeight: 400,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: _handleBackNavigation,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _shareEpisode,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.bookmark_add_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _addToLibrary,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Podcast Cover Image Background
                  if (_podcast?.coverImageUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        _podcast!.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Content Overlay
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Episode Number Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Episode ${_episode!.episodeNumber}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Episode Title
                          Text(
                            _episode!.displayTitle,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Episode Duration and Stats
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _episode!.formattedDuration,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.play_circle_outline,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_episode!.playCount} plays',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
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
          ),
        ),

        // Episode Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professional Audio Player Section
                    _buildProfessionalAudioPlayer(),
                    const SizedBox(height: 32),

                    // Episode Description
                    _buildDescriptionSection(),
                    const SizedBox(height: 32),

                    // Episode Details
                    _buildDetailsSection(),
                    const SizedBox(height: 32),

                    // Transcript Section
                    if (_episode!.transcriptContent != null && _episode!.transcriptContent!.isNotEmpty)
                      _buildTranscriptSection(),
                    
                    // Show Notes Section
                    if (_episode!.showNotes != null)
                      _buildShowNotesSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Podcast Cover Image
          if (_podcast?.coverImageUrl != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _podcast!.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.radio,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          
          // Episode Title
          Text(
            _episode!.displayTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Podcast Name
          if (_podcast != null)
            Text(
              _podcast!.displayTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),

          // Draggable Progress Bar
          _buildDraggableProgressBar(),
          const SizedBox(height: 12),

          // Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Episode Button
              IconButton(
                onPressed: _skipPrevious,
                icon: Icon(
                  Icons.skip_previous,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Previous Episode',
              ),
              
              // Skip Backward 30s Button
              IconButton(
                onPressed: _skipBackward,
                icon: Icon(
                  Icons.replay_30,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Skip Backward 30s',
              ),
              
              // Play/Pause Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 36,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              
              // Skip Forward 30s Button
              IconButton(
                onPressed: _skipForward,
                icon: Icon(
                  Icons.forward_30,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Skip Forward 30s',
              ),
              
              // Next Episode Button
              IconButton(
                onPressed: _skipNext,
                icon: Icon(
                  Icons.skip_next,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Next Episode',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Additional Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed Control
              IconButton(
                onPressed: _changePlaybackSpeed,
                icon: Icon(
                  Icons.speed,
                  color: _playbackSpeed != 1.0 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              // Repeat Button
              IconButton(
                onPressed: _toggleRepeat,
                icon: Icon(
                  Icons.repeat,
                  color: _isRepeatEnabled 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              // Shuffle Button
              IconButton(
                onPressed: _toggleShuffle,
                icon: Icon(
                  Icons.shuffle,
                  color: _isShuffleEnabled 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              // More Options
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Episode',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            _episode!.displayDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildDetailRow('Episode Number', '${_episode!.episodeNumber}'),
              _buildDetailRow('Season', '${_episode!.seasonNumber}'),
              _buildDetailRow('Duration', _episode!.formattedDuration),
              _buildDetailRow('Published', _formatDate(_episode!.publishedAt)),
              _buildDetailRow('Plays', '${_episode!.playCount}'),
              _buildDetailRow('Downloads', '${_episode!.downloadCount}'),
              if (_episode!.rating != null && _episode!.rating! > 0)
                _buildDetailRow('Rating', '${_episode!.rating!.toStringAsFixed(1)} ⭐'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transcript',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            _episode!.transcriptContent!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            _episode!.showNotes.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.error.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Episode Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The episode you\'re looking for could not be found.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}