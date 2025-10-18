import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/services/audio_handler_service.dart';

class AudioPlayerService {
  AudioHandlerService? _audioHandler;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  
  // Current book being played
  Book? _currentBook;
  
  // Playback state
  bool _isPlaying = false;
  bool _isShuffled = false;
  bool _isRepeated = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Sleep timer
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;
  
  // Streams for UI updates
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _speedController = StreamController<double>.broadcast();
  final StreamController<bool> _shuffleController = StreamController<bool>.broadcast();
  final StreamController<bool> _repeatController = StreamController<bool>.broadcast();
  final StreamController<Duration?> _sleepTimerController = StreamController<Duration?>.broadcast();

  // Getters for streams
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<bool> get repeatStream => _repeatController.stream;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  // Getters for current state
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  bool get isRepeated => _isRepeated;
  double get playbackSpeed => _playbackSpeed;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Book? get currentBook => _currentBook;
  Duration? get sleepTimerDuration => _sleepTimerDuration;

  AudioPlayerService() {
    _initializeAudioSession();
    _setupStreams();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      _audioHandler = await initAudioService();
      
      // Listen to audio handler playback state
      _playbackStateSubscription = _audioHandler?.playbackState.listen((state) {
        _isPlaying = state.playing;
        _isPlayingController.add(state.playing);
        
        if (state.updatePosition != Duration.zero) {
          _currentPosition = state.updatePosition;
          _positionController.add(state.updatePosition);
        }
      });
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    } catch (e) {
      print('Failed to configure audio session: $e');
    }
  }

  void _setupStreams() {
    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isPlayingController.add(_isPlaying);
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (position != null) {
        _currentPosition = position;
        _positionController.add(position);
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        _durationController.add(duration);
      }
    });
  }

  // Helper method to build full audio URL
  String _buildFullAudioUrl(String url) {
    // If URL is already a full URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If URL is relative, build full URL
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${AppConfig.mediaBaseUrl}/$cleanUrl';
  }

  // Load and play audio book
  Future<void> loadAudioBook(Book book, {String? audioUrl}) async {
    try {
      _currentBook = book;
      
      final url = audioUrl ?? book.audioUrl;
      if (url == null) {
        throw Exception('No audio URL available for this book');
      }

      // Build full audio URL
      final fullAudioUrl = _buildFullAudioUrl(url);
      print('🎵 AudioPlayerService: Loading audio from: $fullAudioUrl');

      // Load audio through audio handler for background playback
      if (_audioHandler != null) {
        await _audioHandler!.loadAudio(book, fullAudioUrl);
      }
      
      // Set audio source
      await _audioPlayer.setUrl(fullAudioUrl);
      
      // Set initial playback speed
      await _audioPlayer.setSpeed(_playbackSpeed);
      
      // Reset sleep timer
      _clearSleepTimer();
      
      // Emit initial state
      _durationController.add(_totalDuration);
      _speedController.add(_playbackSpeed);
      
    } catch (e) {
      throw Exception('Failed to load audio book: $e');
    }
  }

  // Play audio
  Future<void> play() async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.play();
      }
      await _audioPlayer.play();
      _isPlaying = true;
      _isPlayingController.add(true);
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  // Pause audio
  Future<void> pause() async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.pause();
      }
      await _audioPlayer.pause();
      _isPlaying = false;
      _isPlayingController.add(false);
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }

  // Stop audio
  Future<void> stop() async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.stop();
      }
      await _audioPlayer.stop();
      _isPlaying = false;
      _isPlayingController.add(false);
      _currentPosition = Duration.zero;
      _positionController.add(Duration.zero);
    } catch (e) {
      throw Exception('Failed to stop audio: $e');
    }
  }

  // Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      if (_audioHandler != null) {
        await _audioHandler!.seek(position);
      }
      await _audioPlayer.seek(position);
      _currentPosition = position;
      _positionController.add(position);
    } catch (e) {
      throw Exception('Failed to seek to position: $e');
    }
  }

  // Skip forward
  Future<void> skipForward(Duration duration) async {
    try {
      final newPosition = _currentPosition + duration;
      if (newPosition <= _totalDuration) {
        await seekTo(newPosition);
      }
    } catch (e) {
      throw Exception('Failed to skip forward: $e');
    }
  }

  // Skip backward
  Future<void> skipBackward(Duration duration) async {
    try {
      final newPosition = _currentPosition - duration;
      if (newPosition >= Duration.zero) {
        await seekTo(newPosition);
      }
    } catch (e) {
      throw Exception('Failed to skip backward: $e');
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      if (speed >= 0.5 && speed <= 2.0) {
        if (_audioHandler != null) {
          await _audioHandler!.setSpeed(speed);
        }
        await _audioPlayer.setSpeed(speed);
        _playbackSpeed = speed;
        _speedController.add(speed);
      }
    } catch (e) {
      throw Exception('Failed to set playback speed: $e');
    }
  }

  // Toggle shuffle
  Future<void> toggleShuffle() async {
    try {
      _isShuffled = !_isShuffled;
      await _audioPlayer.setShuffleModeEnabled(_isShuffled);
      _shuffleController.add(_isShuffled);
    } catch (e) {
      throw Exception('Failed to toggle shuffle: $e');
    }
  }

  // Toggle repeat
  Future<void> toggleRepeat() async {
    try {
      _isRepeated = !_isRepeated;
      if (_isRepeated) {
        await _audioPlayer.setLoopMode(LoopMode.one);
      } else {
        await _audioPlayer.setLoopMode(LoopMode.off);
      }
      _repeatController.add(_isRepeated);
    } catch (e) {
      throw Exception('Failed to toggle repeat: $e');
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    try {
      if (volume >= 0.0 && volume <= 1.0) {
        await _audioPlayer.setVolume(volume);
      }
    } catch (e) {
      throw Exception('Failed to set volume: $e');
    }
  }

  // Get current volume
  double get volume => _audioPlayer.volume;

  // Set sleep timer
  void setSleepTimer(Duration duration) {
    _clearSleepTimer();
    
    if (duration > Duration.zero) {
      _sleepTimerDuration = duration;
      _sleepTimerController.add(duration);
      
      _sleepTimer = Timer(duration, () {
        pause();
        _clearSleepTimer();
      });
    }
  }

  // Clear sleep timer
  void _clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    _sleepTimerController.add(null);
  }

  // Get current chapter (if available)
  int get currentChapter {
    if (_currentBook == null || _totalDuration == Duration.zero) return 1;
    
    // Calculate chapter based on position and total duration
    // This is a simple calculation - in a real app, you'd have chapter markers
    final progress = _currentPosition.inSeconds / _totalDuration.inSeconds;
    return (progress * 10).ceil(); // Assuming 10 chapters
  }

  // Get total chapters (if available)
  int get totalChapters {
    // In a real app, this would come from the book metadata
    return 10;
  }

  // Jump to specific chapter
  Future<void> jumpToChapter(int chapter) async {
    try {
      if (chapter >= 1 && chapter <= totalChapters) {
        final progress = (chapter - 1) / totalChapters;
        final position = Duration(
          milliseconds: (progress * _totalDuration.inMilliseconds).round(),
        );
        await seekTo(position);
      }
    } catch (e) {
      throw Exception('Failed to jump to chapter: $e');
    }
  }

  // Get formatted time string
  String formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Get progress percentage
  double get progressPercentage {
    if (_totalDuration == Duration.zero) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  // Check if audio is loaded
  bool get isAudioLoaded => _currentBook != null && _totalDuration > Duration.zero;

  // Get remaining time
  Duration get remainingTime {
    if (_totalDuration == Duration.zero) return Duration.zero;
    return _totalDuration - _currentPosition;
  }

  // Get remaining time string
  String get remainingTimeString => formatTime(remainingTime);

  // Get current time string
  String get currentTimeString => formatTime(_currentPosition);

  // Get total time string
  String get totalTimeString => formatTime(_totalDuration);

  // Dispose resources
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _sleepTimer?.cancel();
    
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _speedController.close();
    _shuffleController.close();
    _repeatController.close();
    _sleepTimerController.close();
    
    _audioHandler?.dispose();
    _audioPlayer.dispose();
  }

  // Reset player state
  void reset() {
    _currentBook = null;
    _isPlaying = false;
    _isShuffled = false;
    _isRepeated = false;
    _playbackSpeed = 1.0;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    
    _clearSleepTimer();
    
    // Emit reset state
    _isPlayingController.add(false);
    _positionController.add(Duration.zero);
    _durationController.add(Duration.zero);
    _speedController.add(1.0);
    _shuffleController.add(false);
    _repeatController.add(false);
    _sleepTimerController.add(null);
  }
}
