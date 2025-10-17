import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';
import 'package:teekoob/core/services/localization_service.dart';

class BookAudioPlayerPage extends StatefulWidget {
  final String bookId;

  const BookAudioPlayerPage({
    super.key,
    required this.bookId,
  });

  @override
  State<BookAudioPlayerPage> createState() => _BookAudioPlayerPageState();
}

class _BookAudioPlayerPageState extends State<BookAudioPlayerPage>
    with TickerProviderStateMixin {
  Book? _book;
  bool _isLoading = true;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookData();
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

  void _loadBookData() {
    // Get book from route extra
    final book = GoRouterState.of(context).extra as Book?;
    if (book != null) {
      setState(() {
        _book = book;
        _isLoading = false;
      });
      _animationController.forward();
      _slideController.forward();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePlayPause() async {
    if (_book == null) return;
    
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_audioService.currentItem?.id == _book!.id) {
        await _audioService.resume();
      } else {
        await _audioService.playBook(_book!);
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

  void _navigateToReadPage() {
    if (_book != null) {
      context.push('/home/books/${_book!.id}/read', extra: _book);
    }
  }

  void _handleBackNavigation() {
    // Check if we can pop (there's something in the navigation stack)
    if (context.canPop()) {
      // If audio is playing, show floating player instead of closing
      if (_audioService.isPlaying || _audioService.isPaused) {
        // Navigate back to book detail page, floating player will show
        context.pop();
      } else {
        // No audio playing, normal navigation
        context.pop();
      }
    } else {
      // Nothing to pop, navigate to home page instead
      print('🎧 BookAudioPlayerPage: Nothing to pop, navigating to home');
      context.go('/home');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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

  Widget _buildDraggableProgressBar() {
    return GestureDetector(
      onTapDown: (details) => _seekToPosition(details.localPosition),
      onPanStart: (details) => {},
      onPanUpdate: (details) => _seekToPosition(details.localPosition),
      onPanEnd: (details) => {},
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
                    (MediaQuery.of(context).size.width - 32 - 16) - 8
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
            onPressed: _handleBackNavigation,
          ),
        title: Text(
          LocalizationService.getNowPlayingText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
        body: _isLoading ? _buildLoadingState() : _buildPlayerContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.getLoadingText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_book == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Book not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    final coverImageUrl = _book!.coverImageUrl != null && _book!.coverImageUrl!.isNotEmpty
        ? (_book!.coverImageUrl!.startsWith('http')
            ? _book!.coverImageUrl
            : '${AppConfig.mediaBaseUrl}${_book!.coverImageUrl}')
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (coverImageUrl != null)
                  Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(Icons.book, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(Icons.book, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Theme.of(context).colorScheme.background.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                          ),
                          child: Text(
                            LocalizationService.getAudiobookText,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _book!.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_book!.authors ?? 'Unknown Author'} • ${_formatDuration(Duration(seconds: _book!.duration ?? 0))}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0.5, 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Audio Player Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildAudioPlayerSection(),
                    ),
                    const SizedBox(height: 24),

                    // About This Book
                    _buildSectionTitle(LocalizationService.getAboutText),
                    const SizedBox(height: 8),
                    Text(
                      _book!.description ?? 'No description available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // Book Details
                    _buildSectionTitle(LocalizationService.getBookDetailsText),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      LocalizationService.getAuthorText,
                      _book!.authors ?? 'Unknown Author',
                    ),
                    _buildDetailRow(
                      LocalizationService.getDurationText,
                      _formatDuration(Duration(seconds: _book!.duration ?? 0)),
                    ),
                    _buildDetailRow(
                      LocalizationService.getLanguageText,
                      _book!.language ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      LocalizationService.getFormatText,
                      _book!.format ?? 'Unknown',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayerSection() {
    final coverImageUrl = _book?.coverImageUrl != null && _book!.coverImageUrl!.isNotEmpty
        ? (_book!.coverImageUrl!.startsWith('http')
            ? _book!.coverImageUrl
            : '${AppConfig.mediaBaseUrl}${_book!.coverImageUrl}')
        : null;

    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                child: coverImageUrl != null
                    ? Image.network(
                        coverImageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 120,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(Icons.book, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(Icons.book, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _book!.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _book!.authors ?? 'Unknown Author',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
            ],
          ),
          const SizedBox(height: 20),

          // Read Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToReadPage,
              icon: Icon(Icons.menu_book, size: 20),
              label: Text(
                LocalizationService.getReadText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
                ),
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
