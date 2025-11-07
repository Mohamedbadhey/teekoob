import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';

/// DEPRECATED: Audio handler for background playback with media controls
/// This service is deprecated - use GlobalAudioPlayerService instead
/// Kept for backward compatibility only
@Deprecated('Use GlobalAudioPlayerService instead')
class AudioHandlerService extends BaseAudioHandler with QueueHandler, SeekHandler {
  // This service is deprecated - use GlobalAudioPlayerService instead
  // AudioPlayer can be created directly (no just_audio_background needed)
  AudioPlayer? _audioPlayerInstance;
  AudioPlayer get _audioPlayer {
    if (_audioPlayerInstance == null) {
      // AudioPlayer can be created directly (no just_audio_background needed)
      _audioPlayerInstance = AudioPlayer();
    }
    return _audioPlayerInstance!;
  }
  
  // Current book/podcast being played
  Book? _currentBook;
  
  // Stream subscriptions
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  
  AudioHandlerService() {
    _init();
  }

  void _init() {
    // Listen to playback events
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final playing = _audioPlayer.playing;
      
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
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
      ));
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// Load audio from URL
  Future<void> loadAudio(Book book, String audioUrl) async {
    try {
      _currentBook = book;
      
      // Create media item
      final mediaItem = MediaItem(
        id: book.id,
        album: book.displayCategories.isNotEmpty ? book.displayCategories : 'Audiobook',
        title: book.title,
        artist: book.authors ?? 'Unknown Author',
        artUri: book.coverImageUrl != null ? Uri.parse(book.coverImageUrl!) : null,
        duration: null, // Will be updated when audio loads
      );
      
      // Set the media item
      this.mediaItem.add(mediaItem);
      
      // Load the audio source
      await _audioPlayer.setUrl(audioUrl);
      
      // Update media item with duration
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
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    // Skip forward 30 seconds
    final position = _audioPlayer.position;
    final duration = _audioPlayer.duration ?? Duration.zero;
    final newPosition = position + const Duration(seconds: 30);
    
    if (newPosition < duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // Skip backward 10 seconds
    final position = _audioPlayer.position;
    final newPosition = position - const Duration(seconds: 10);
    
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  // Get current position
  Duration get position => _audioPlayer.position;
  
  // Get duration
  Duration? get duration => _audioPlayer.duration;
  
  // Get playing state
  bool get playing => _audioPlayer.playing;
  
  // Get current book
  Book? get currentBook => _currentBook;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setSpeed':
        final speed = extras?['speed'] as double? ?? 1.0;
        await setSpeed(speed);
        break;
      default:
        await super.customAction(name, extras);
    }
  }

  void dispose() {
    _playbackEventSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayerInstance?.dispose();
  }
}

/// DEPRECATED: This function should NOT be called
/// AudioService.init() can only be called ONCE per app lifecycle
/// Use GlobalAudioPlayerService instead
/// 
/// This function is kept for backward compatibility but will throw an error
/// if GlobalAudioPlayerService is already handling AudioService
@Deprecated('Use GlobalAudioPlayerService instead')
Future<AudioHandlerService> initAudioService() async {
  // CRITICAL: Check if GlobalAudioPlayerService is already handling AudioService
  // If so, throw an error to prevent multiple initialization
  if (GlobalAudioPlayerService.isInitializingAudioService || 
      GlobalAudioPlayerService().isAudioServiceInitialized) {
    throw Exception('AudioService is already initialized by GlobalAudioPlayerService. Use GlobalAudioPlayerService instead.');
  }
  
  // Check if AudioService is already initialized
  try {
    // Try to initialize - if it fails with cache manager error, AudioService is already initialized
    return await AudioService.init(
      builder: () => AudioHandlerService(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.teekoob.app.audio',
        androidNotificationChannelName: 'Teekoob Audio Player',
        androidNotificationOngoing: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        notificationColor: null,
      ),
    );
  } catch (e) {
    // If AudioService is already initialized, we can't get a handler
    // This is a fatal error - the old AudioPlayerService won't work
    throw Exception('AudioService already initialized. Use GlobalAudioPlayerService instead. Error: $e');
  }
}
