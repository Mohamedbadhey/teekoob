import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/config/app_config.dart';

enum AudioPlayerState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

enum AudioType {
  book,
  podcast,
}

class AudioItem {
  final String id;
  final String title;
  final String? author;
  final String? host;
  final String? coverImageUrl;
  final String audioUrl;
  final AudioType type;
  final Duration? duration;
  final int? currentPosition;

  AudioItem({
    required this.id,
    required this.title,
    this.author,
    this.host,
    this.coverImageUrl,
    required this.audioUrl,
    required this.type,
    this.duration,
    this.currentPosition,
  });

  factory AudioItem.fromBook(Book book) {
    return AudioItem(
      id: book.id,
      title: book.title,
      author: book.authors ?? 'Unknown Author',
      coverImageUrl: book.coverImageUrl,
      audioUrl: _buildFullUrl(book.audioUrl),
      type: AudioType.book,
    );
  }

  factory AudioItem.fromPodcastEpisode(PodcastEpisode episode, {Podcast? podcast}) {
    return AudioItem(
      id: episode.id,
      title: episode.title,
      host: podcast?.host ?? podcast?.displayHost ?? 'Podcast',
      coverImageUrl: podcast?.coverImageUrl,
      audioUrl: _buildFullUrl(episode.audioUrl),
      type: AudioType.podcast,
      duration: episode.duration != null 
          ? Duration(minutes: episode.duration!) 
          : null,
    );
  }

  String get displayTitle => title;
  String get displaySubtitle => type == AudioType.book ? (author ?? '') : (host ?? '');
  
  static String _buildFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // If URL already starts with http, return as is
    if (url.startsWith('http')) return url;
    
    // Otherwise, prepend the media base URL
    return '${AppConfig.mediaBaseUrl}$url';
  }
}

class GlobalAudioPlayerService extends ChangeNotifier {
  static final GlobalAudioPlayerService _instance = GlobalAudioPlayerService._internal();
  factory GlobalAudioPlayerService() => _instance;
  GlobalAudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  AudioItem? _currentItem;
  AudioPlayerState _state = AudioPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  
  // Episode queue management
  List<PodcastEpisode> _episodeQueue = [];
  int _currentEpisodeIndex = -1;
  String? _currentPodcastId;
  Podcast? _currentPodcast; // Store podcast for episode queue playback

  // Getters
  AudioItem? get currentItem => _currentItem;
  AudioPlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == AudioPlayerState.playing;
  bool get isPaused => _state == AudioPlayerState.paused;
  bool get isLoading => _state == AudioPlayerState.loading;
  bool get hasItem => _currentItem != null;
  bool get shouldShowFloatingPlayer => hasItem && (_state == AudioPlayerState.playing || _state == AudioPlayerState.paused);
  
  // Episode queue getters
  List<PodcastEpisode> get episodeQueue => _episodeQueue;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  String? get currentPodcastId => _currentPodcastId;
  bool get hasNextEpisode => _currentEpisodeIndex < _episodeQueue.length - 1;
  bool get hasPreviousEpisode => _currentEpisodeIndex > 0;
  PodcastEpisode? get nextEpisode => hasNextEpisode ? _episodeQueue[_currentEpisodeIndex + 1] : null;
  PodcastEpisode? get previousEpisode => hasPreviousEpisode ? _episodeQueue[_currentEpisodeIndex - 1] : null;

  // Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - audio should continue playing
        print('🎵 App resumed - audio should continue');
        break;
      case AppLifecycleState.paused:
        // App went to background - audio should continue playing
        print('🎵 App paused - audio continues in background');
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop audio
        print('🎵 App detached - stopping audio');
        stop();
        break;
      case AppLifecycleState.inactive:
        // App is inactive - keep audio playing
        print('🎵 App inactive - keeping audio playing');
        break;
      case AppLifecycleState.hidden:
        // App is hidden - keep audio playing
        print('🎵 App hidden - keeping audio playing');
        break;
    }
  }

  // Initialize the audio player
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      // Listen to position changes
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      });

      // Listen to duration changes
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          _duration = duration;
          notifyListeners();
        }
      });

      // Listen to player state changes
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
        switch (playerState.processingState) {
          case ProcessingState.idle:
            if (!playerState.playing) {
              _state = AudioPlayerState.stopped;
            }
            break;
          case ProcessingState.loading:
            _state = AudioPlayerState.loading;
            break;
          case ProcessingState.buffering:
            _state = AudioPlayerState.loading;
            break;
          case ProcessingState.ready:
            if (playerState.playing) {
              _state = AudioPlayerState.playing;
            } else {
              _state = AudioPlayerState.paused;
            }
            break;
          case ProcessingState.completed:
            _state = AudioPlayerState.stopped;
            _position = Duration.zero;
            _handleEpisodeCompletion();
            break;
        }
        notifyListeners();
      });

      _isInitialized = true;
      print('🎵 GlobalAudioPlayerService initialized');
    } catch (e) {
      print('❌ Error initializing GlobalAudioPlayerService: $e');
      _state = AudioPlayerState.error;
      notifyListeners();
    }
  }

  // Play audio item
  Future<void> playItem(AudioItem item) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      _state = AudioPlayerState.loading;
      notifyListeners();

      // If it's the same item, just resume
      if (_currentItem?.id == item.id && _state == AudioPlayerState.paused) {
        await _audioPlayer.play();
        return;
      }

      // Stop current audio if playing different item
      if (_currentItem != null && _currentItem!.id != item.id) {
        await _audioPlayer.stop();
      }

      _currentItem = item;
      
      // Build cover image URL for MediaItem
      String? coverImageUrl;
      if (item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty) {
        if (item.coverImageUrl!.startsWith('http')) {
          coverImageUrl = item.coverImageUrl;
        } else {
          coverImageUrl = '${AppConfig.mediaBaseUrl}${item.coverImageUrl}';
        }
      }
      
      // Create MediaItem for lock screen controls
      final mediaItem = MediaItem(
        id: item.id,
        title: item.title,
        artist: item.type == AudioType.book ? (item.author ?? 'Unknown Author') : (item.host ?? 'Podcast'),
        album: item.type == AudioType.book ? 'Audiobook' : 'Podcast',
        artUri: coverImageUrl != null ? Uri.parse(coverImageUrl) : null,
        duration: item.duration,
        extras: {
          'type': item.type == AudioType.book ? 'book' : 'podcast',
          'id': item.id,
        },
      );
      
      // Create AudioSource with MediaItem tag for just_audio_background
      final audioSource = AudioSource.uri(
        Uri.parse(item.audioUrl),
        tag: mediaItem,
      );
      
      // Set audio source (this will trigger lock screen controls via just_audio_background)
      await _audioPlayer.setAudioSource(audioSource);
      
      // Start playing
      await _audioPlayer.play();
      
      print('🎵 Playing: ${item.displayTitle}');
      print('🎵 Lock screen controls enabled via just_audio_background');
    } catch (e) {
      print('❌ Error playing audio: $e');
      _state = AudioPlayerState.error;
      notifyListeners();
    }
  }

  // Play book
  Future<void> playBook(Book book) async {
    final audioItem = AudioItem.fromBook(book);
    await playItem(audioItem);
  }

  // Play podcast episode
  Future<void> playPodcastEpisode(PodcastEpisode episode, {Podcast? podcast}) async {
    final audioItem = AudioItem.fromPodcastEpisode(episode, podcast: podcast);
    await playItem(audioItem);
  }

  // Set episode queue for a podcast
  void setEpisodeQueue(List<PodcastEpisode> episodes, String podcastId) {
    _episodeQueue = List.from(episodes);
    _currentPodcastId = podcastId;
    _currentEpisodeIndex = -1;
    print('🎧 Episode queue set: ${_episodeQueue.length} episodes for podcast $podcastId');
  }

  // Play podcast episode with queue management
  Future<void> playPodcastEpisodeWithQueue(PodcastEpisode episode, List<PodcastEpisode> episodes, String podcastId, {Podcast? podcast}) async {
    // Store podcast for queue navigation
    _currentPodcast = podcast;
    
    // Set the episode queue
    setEpisodeQueue(episodes, podcastId);
    
    // Find the current episode index
    _currentEpisodeIndex = _episodeQueue.indexWhere((e) => e.id == episode.id);
    
    if (_currentEpisodeIndex == -1) {
      print('❌ Episode not found in queue: ${episode.id}');
      _currentEpisodeIndex = 0; // Fallback to first episode
    }
    
    print('🎧 Playing episode ${_currentEpisodeIndex + 1}/${_episodeQueue.length}: ${episode.title}');
    
    // Play the episode with podcast metadata
    await playPodcastEpisode(episode, podcast: podcast);
  }
  
  // Play next episode
  Future<void> playNextEpisode() async {
    if (!hasNextEpisode) {
      print('❌ No next episode available');
      return;
    }
    
    final nextEpisodeData = nextEpisode!;
    print('🎧 Playing next episode: ${nextEpisodeData.title}');
    
    _currentEpisodeIndex++;
    await playPodcastEpisode(nextEpisodeData, podcast: _currentPodcast);
  }

  // Play previous episode
  Future<void> playPreviousEpisode() async {
    if (!hasPreviousEpisode) {
      print('❌ No previous episode available');
      return;
    }
    
    final previousEpisodeData = previousEpisode!;
    print('🎧 Playing previous episode: ${previousEpisodeData.title}');
    
    _currentEpisodeIndex--;
    await playPodcastEpisode(previousEpisodeData, podcast: _currentPodcast);
  }

  // Pause audio
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      print('⏸️ Audio paused');
    } catch (e) {
      print('❌ Error pausing audio: $e');
    }
  }

  // Resume audio
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
      print('▶️ Audio resumed');
    } catch (e) {
      print('❌ Error resuming audio: $e');
    }
  }

  // Stop audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _currentItem = null;
      print('⏹️ Audio stopped');
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      print('⏩ Seeked to: ${position.inSeconds}s');
    } catch (e) {
      print('❌ Error seeking audio: $e');
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      print('⚡ Playback speed set to: ${speed}x');
    } catch (e) {
      print('❌ Error setting playback speed: $e');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_state == AudioPlayerState.playing) {
      await pause();
    } else if (_state == AudioPlayerState.paused) {
      await resume();
    }
  }

  // Get formatted time string
  String getFormattedTime(Duration duration) {
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

  // Get progress percentage
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  // Handle episode completion and auto-advance to next episode
  void _handleEpisodeCompletion() {
    print('🎧 Episode completed: ${_currentItem?.title}');
    
    // Only auto-advance for podcast episodes
    if (_currentItem?.type == AudioType.podcast && hasNextEpisode) {
      print('🎧 Auto-advancing to next episode...');
      // Use a small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 500), () {
        playNextEpisode();
      });
    } else {
      print('🎧 No next episode available or not a podcast episode');
    }
  }

  // Note: Lock screen controls are automatically handled by just_audio_background
  // when using AudioSource.uri() with MediaItem tags

  // Dispose resources
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
