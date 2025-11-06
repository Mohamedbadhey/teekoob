import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:teekoob/core/models/book_model.dart';

/// Enhanced audio handler for background playback with full system media controls
class EnhancedAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Current book/podcast being played
  Book? _currentBook;
  
  // Stream subscriptions
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  
  // Playback state controller
  final _playbackStateController = StreamController<PlaybackState>.broadcast();
  
  EnhancedAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to playback events and update playback state
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final playing = _audioPlayer.playing;
      
      final newState = playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_audioPlayer.processingState]!,
        playing: playing,
        updatePosition: _audioPlayer.position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
        queueIndex: 0,
      );
      
      playbackState.add(newState);
      _playbackStateController.add(newState);
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Auto-stop when completed
        stop();
      }
    });
    
    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        // Update media item with duration
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  /// Load audio from URL with full metadata
  Future<void> loadAudio(Book book, String audioUrl) async {
    try {
      _currentBook = book;
      
      // Create media item with full metadata
      final mediaItem = MediaItem(
        id: book.id,
        album: book.displayCategories.isNotEmpty ? book.displayCategories : 'Audiobook',
        title: book.title,
        artist: book.authors ?? 'Unknown Author',
        artUri: book.coverImageUrl != null ? Uri.parse(book.coverImageUrl!) : null,
        duration: null, // Will be updated when audio loads
        extras: {
          'bookId': book.id,
          'coverUrl': book.coverImageUrl,
          'author': book.authors,
          'category': book.displayCategories,
        },
      );
      
      // Set the media item
      this.mediaItem.add(mediaItem);
      
      // Load the audio source
      await _audioPlayer.setUrl(audioUrl);
      
      // Update media item with duration once loaded
      final duration = _audioPlayer.duration;
      if (duration != null) {
        this.mediaItem.add(mediaItem.copyWith(duration: duration));
      }
      
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await super.stop();
    } catch (e) {
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      // Skip forward 30 seconds
      final position = _audioPlayer.position;
      final duration = _audioPlayer.duration ?? Duration.zero;
      final newPosition = position + const Duration(seconds: 30);
      
      if (newPosition < duration) {
        await _audioPlayer.seek(newPosition);
      } else {
        await _audioPlayer.seek(duration);
      }
    } catch (e) {
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      // Skip backward 10 seconds
      final position = _audioPlayer.position;
      final newPosition = position - const Duration(seconds: 10);
      
      if (newPosition > Duration.zero) {
        await _audioPlayer.seek(newPosition);
      } else {
        await _audioPlayer.seek(Duration.zero);
      }
    } catch (e) {
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
    }
  }
  
  @override
  Future<void> fastForward() async {
    await skipToNext();
  }
  
  @override
  Future<void> rewind() async {
    await skipToPrevious();
  }

  // Get current position
  Duration get position => _audioPlayer.position;
  
  // Get duration
  Duration? get duration => _audioPlayer.duration;
  
  // Get playing state
  bool get playing => _audioPlayer.playing;
  
  // Get current book
  Book? get currentBook => _currentBook;
  
  // Get position stream
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  
  // Get playback state stream
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setSpeed':
        final speed = extras?['speed'] as double? ?? 1.0;
        await setSpeed(speed);
        break;
      case 'seekForward':
        await skipToNext();
        break;
      case 'seekBackward':
        await skipToPrevious();
        break;
      default:
        await super.customAction(name, extras);
    }
  }
  
  /// Resume playback when app reopens
  Future<void> resume() async {
    if (_audioPlayer.processingState == ProcessingState.ready && !_audioPlayer.playing) {
      await play();
    }
  }
  
  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background - audio continues playing
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call)
        break;
      case AppLifecycleState.detached:
        // App is detached
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _playbackEventSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playbackStateController.close();
    await _audioPlayer.dispose();
  }
}

/// Initialize enhanced audio service
Future<EnhancedAudioHandler> initEnhancedAudioService() async {
  return await AudioService.init(
    builder: () => EnhancedAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.teekoob.app.audio',
      androidNotificationChannelName: 'Teekoob Audio Player',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false, // Keep notification when paused
      androidNotificationClickStartsActivity: true,
      androidNotificationChannelDescription: 'Audio playback controls',
      preloadArtwork: true,
      artDownscaleWidth: 800,
      artDownscaleHeight: 800,
      fastForwardInterval: Duration(seconds: 30),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}
