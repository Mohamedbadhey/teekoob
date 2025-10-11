import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  factory AudioItem.fromPodcastEpisode(PodcastEpisode episode) {
    return AudioItem(
      id: episode.id,
      title: episode.title,
      host: 'Podcast Host', // Default host since episode doesn't have host info
      coverImageUrl: null, // Episode doesn't have cover image
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
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  AudioItem? _currentItem;
  AudioPlayerState _state = AudioPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

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
      // Initialize system audio controls
      await _initializeSystemAudioControls();

      // Configure for background playback
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
            AVAudioSessionOptions.mixWithOthers,
          ],
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));

      // Listen to position changes
      _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
        _position = position;
        notifyListeners();
      });

      // Listen to duration changes
      _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
        _duration = duration;
        notifyListeners();
      });

      // Listen to player state changes
      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((playerState) {
        switch (playerState) {
          case PlayerState.playing:
            _state = AudioPlayerState.playing;
            _updateSystemAudioControls();
            break;
          case PlayerState.paused:
            _state = AudioPlayerState.paused;
            _updateSystemAudioControls();
            break;
          case PlayerState.stopped:
            _state = AudioPlayerState.stopped;
            _hideSystemAudioControls();
            break;
          case PlayerState.completed:
            _state = AudioPlayerState.stopped;
            _position = Duration.zero;
            _hideSystemAudioControls();
            break;
          case PlayerState.disposed:
            _state = AudioPlayerState.stopped;
            _hideSystemAudioControls();
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
        await _audioPlayer.resume();
        return;
      }

      // Stop current audio if playing different item
      if (_currentItem != null && _currentItem!.id != item.id) {
        await _audioPlayer.stop();
      }

      _currentItem = item;
      
      // Set audio source
      await _audioPlayer.setSourceUrl(item.audioUrl);
      
      // Start playing
      await _audioPlayer.resume();
      
      print('🎵 Playing: ${item.displayTitle}');
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
  Future<void> playPodcastEpisode(PodcastEpisode episode) async {
    final audioItem = AudioItem.fromPodcastEpisode(episode);
    await playItem(audioItem);
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
      await _audioPlayer.resume();
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
      await _audioPlayer.setPlaybackRate(speed);
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

  // Dispose resources
  @override
  // System Audio Controls Methods
  Future<void> _initializeSystemAudioControls() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to player
    print('🎵 System audio control tapped: ${response.actionId}');
  }

  Future<void> _updateSystemAudioControls() async {
    if (_currentItem == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'audio_player',
      'Audio Player',
      channelDescription: 'Audio player controls',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
      actions: [
        AndroidNotificationAction('prev', 'Previous', showsUserInterface: false),
        AndroidNotificationAction('play_pause', 'Play/Pause', showsUserInterface: false),
        AndroidNotificationAction('next', 'Next', showsUserInterface: false),
        AndroidNotificationAction('close', 'Close', showsUserInterface: false),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      1,
      _currentItem!.title,
      _currentItem!.displaySubtitle,
      platformChannelSpecifics,
    );
  }

  Future<void> _hideSystemAudioControls() async {
    await _notifications.cancel(1);
  }

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
