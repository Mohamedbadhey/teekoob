import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/player/services/audio_player_service.dart';
import 'package:teekoob/features/player/services/audio_state_manager.dart';

class AudioPlayerPage extends StatefulWidget {
  final String bookId;

  const AudioPlayerPage({
    super.key,
    required this.bookId,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  Book? book;
  bool isLoading = true;
  String? error;
  bool isPlaying = false;
  double currentProgress = 0.0;
  Duration currentTime = Duration.zero;
  Duration totalDuration = const Duration(minutes: 12);
  
  // Audio state manager
  final AudioStateManager _audioStateManager = AudioStateManager();

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
    _setupAudioStreams();
  }

  void _setupAudioStreams() {
    // Listen to playback state changes
    _audioStateManager.audioPlayerService.isPlayingStream.listen((playing) {
      setState(() {
        isPlaying = playing;
      });
    });

    // Listen to position changes
    _audioStateManager.audioPlayerService.positionStream.listen((position) {
      setState(() {
        currentTime = position;
        if (totalDuration.inSeconds > 0) {
          currentProgress = position.inSeconds / totalDuration.inSeconds;
        }
      });
    });

    // Listen to duration changes
    _audioStateManager.audioPlayerService.durationStream.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
  }

  void _loadBookDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // TODO: Fetch book details from the backend
      // For now, we'll create a placeholder book
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get book from route extra
      final args = GoRouterState.of(context).extra;
      if (args != null && args is Book) {
        setState(() {
          book = args;
          isLoading = false;
        });
      } else {
        // If no book data in route, fetch from backend using bookId
        try {
          // TODO: Implement book fetching from backend
          // For now, show error
          setState(() {
            error = 'No book provided';
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            error = 'Failed to load book: $e';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load book: $e';
        isLoading = false;
      });
    }
  }

  // Create placeholder book for testing - REMOVED: No more hardcoded books
  Book _createPlaceholderBook() {
    throw Exception('No placeholder books - use real database data');
  }

  void _togglePlayPause() async {
    try {
      if (book == null) return;
      
      await _audioStateManager.togglePlayPause(book!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${isPlaying ? 'pause' : 'play'} audio: $e')),
      );
    }
  }

  void _skipBackward() async {
    try {
      await _audioStateManager.audioPlayerService.skipBackward(const Duration(seconds: 10));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to skip backward: $e')),
      );
    }
  }

  void _skipForward() async {
    try {
      await _audioStateManager.audioPlayerService.skipForward(const Duration(seconds: 10));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to skip forward: $e')),
      );
    }
  }

  void _onProgressChanged(double value) async {
    try {
      final newPosition = Duration(seconds: (value * totalDuration.inSeconds).round());
      await _audioStateManager.audioPlayerService.seekTo(newPosition);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to seek: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBookDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (book == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Book not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Author
                    _buildTitleSection(),
                    
                    // Reading Time & Rating
                    _buildTimeAndRating(),
                    
                    // Rating Section
                    _buildRatingSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Audio Playback Controls
                    _buildAudioControls(),
                  ],
                ),
              ),
            ),
            
            // Footer Action Buttons
            _buildFooterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFF56C23), // Orange - same as home page top bar
      child: Column(
        children: [
          // Status Bar (simulated)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '11:40',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white, // White text on orange background
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.wifi, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full, size: 16, color: Colors.white),
                    Text(
                      '98%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white, // White text on orange background
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Header Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white), // White on orange
                ),
                Expanded(
                  child: Text(
                    (book?.titleSomali?.isNotEmpty ?? false) ? book!.titleSomali! : book?.title ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on orange background
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download started...')),
                    );
                  },
                  icon: const Icon(Icons.download, color: Colors.white), // White on orange
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          (book?.titleSomali?.isNotEmpty ?? false) ? book!.titleSomali! : book?.title ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book?.authors != null && book!.authors!.isNotEmpty ? book!.authors!.first : 'Unknown Author',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reading Time
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${book?.duration ?? 12} min',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 32),
        
        // Rating
        Row(
          children: [
            Icon(Icons.star, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${book?.rating?.toStringAsFixed(1) ?? '0.0'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left Side - Add Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) => 
                    Icon(
                      Icons.star_border,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Vertical Divider
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[300],
          ),
          
          // Right Side - Language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book?.language == 'somali' ? 'Somali' : 'English',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        // Progress Bar
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDuration(totalDuration),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF1E3A8A), // Dark blue
                inactiveTrackColor: Colors.grey[300],
                thumbColor: const Color(0xFF1E3A8A), // Dark blue
                overlayColor: const Color(0xFF1E3A8A).withOpacity(0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: currentProgress,
                onChanged: _onProgressChanged,
                min: 0.0,
                max: 1.0,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Playback Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Skip Backward
            IconButton(
              onPressed: _skipBackward,
              icon: const Icon(
                Icons.skip_previous,
                size: 32,
                color: Colors.black87,
              ),
            ),
            
            // Play/Pause
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4D6), // Light orange
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: Colors.black87,
                ),
                iconSize: 40,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            // Skip Forward
            IconButton(
              onPressed: _skipForward,
              icon: const Icon(
                Icons.skip_next,
                size: 32,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Read Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (book != null) {
                  context.push('/home/books/${book!.id}/read', extra: book);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF56C23), // Orange - same as home page
                foregroundColor: Colors.white, // White text on orange background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Read',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Back to Home Button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                context.go('/home');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A), // Dark blue text
                side: const BorderSide(color: Color(0xFF1E3A8A), width: 2), // Dark blue border
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Back to home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
