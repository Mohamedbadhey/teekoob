import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
// Removed just_audio_background - using audio_service directly with just_audio
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/services/download_service.dart';
import 'package:teekoob/core/services/teekoob_audio_handler.dart';
import 'dart:io';

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

  factory AudioItem.fromBook(Book book, {String? localAudioPath}) {
    return AudioItem(
      id: book.id,
      title: book.title,
      author: book.authors ?? 'Unknown Author',
      coverImageUrl: book.coverImageUrl,
      audioUrl: localAudioPath ?? _buildFullUrl(book.audioUrl),
      type: AudioType.book,
    );
  }
  
  bool get isLocalFile {
    // Local files don't start with http/https and are absolute paths
    return !audioUrl.startsWith('http') && 
           !audioUrl.startsWith('https') && 
           audioUrl.isNotEmpty;
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

/// Global audio player service for managing audio playback across the app.
/// 
/// CRITICAL REQUIREMENTS:
/// 1. Only ONE AudioService.init() call exists - this is the ONLY place that calls it
/// 2. Only ONE global AudioPlayer() instance is created and reused (lazy-initialized)
/// 
/// This service ensures:
/// - Single AudioService instance (prevents "already initialized" errors)
/// - Single AudioPlayer instance (prevents "single player instance" errors)
/// - AudioPlayer can be created directly without just_audio_background
class GlobalAudioPlayerService extends ChangeNotifier {
  static final GlobalAudioPlayerService _instance = GlobalAudioPlayerService._internal();
  factory GlobalAudioPlayerService() {
    // Ensure instance handler is synced with global handler
    if (_globalAudioHandler != null && _instance._audioHandler == null) {
      _instance._audioHandler = _globalAudioHandler;
      print('[AUDIO DEBUG] ✅ Synced instance handler from global handler in factory');
    }
    return _instance;
  }
  GlobalAudioPlayerService._internal();

  // Lazy initialization - AudioPlayer can be created directly (no just_audio_background needed)
  AudioPlayer? _audioPlayerInstance;
  
  AudioPlayer get _audioPlayer {
    if (_audioPlayerInstance == null) {
      print('[AUDIO DEBUG] Creating AudioPlayer instance (lazy initialization)');
      _audioPlayerInstance = AudioPlayer();
    }
    return _audioPlayerInstance!;
  }
  final DownloadService _downloadService = DownloadService();
  
  AudioItem? _currentItem;
  Book? _currentBook; // Store the current book being played
  AudioPlayerState _state = AudioPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  AudioHandler? _audioHandler;
  
  // Setter to directly set the handler (for recovery scenarios)
  void setAudioHandler(AudioHandler handler) {
    _audioHandler = handler;
    _globalAudioHandler = handler; // Always update global when setting instance
    print('[AUDIO DEBUG] ✅ Set handler on both instance and global');
  }
  StreamSubscription<Duration>? _positionSubscription;
  
  // Public getter for audio handler
  AudioHandler? get audioHandler => _audioHandler;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  
  // Episode queue management
  List<PodcastEpisode> _episodeQueue = [];
  int _currentEpisodeIndex = -1;
  String? _currentPodcastId;
  Podcast? _currentPodcast; // Store podcast for episode queue playback

  // Getters
  AudioItem? get currentItem => _currentItem;
  Book? get currentBook => _currentBook; // Get the current book being played
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

  // Static flag to track if AudioService has been initialized
  static bool _audioServiceInitialized = false;
  static AudioHandler? _globalAudioHandler;
  static bool _isInitializing = false;
  
  // Get the global AudioHandler (for checking initialization status)
  static AudioHandler? getGlobalHandler() => _globalAudioHandler;
  
  // Check if AudioService is initialized (instance getter)
  bool get isAudioServiceInitialized => _audioServiceInitialized;

  // Initialize audio handler for background playback (public for main.dart access)
  Future<void> initializeAudioHandler() async {
    print('[AUDIO DEBUG] initializeAudioHandler() called');
    print('[AUDIO DEBUG] _audioHandler is null: ${_audioHandler == null}');
    print('[AUDIO DEBUG] _audioServiceInitialized: $_audioServiceInitialized');
    print('[AUDIO DEBUG] _isInitializing: $_isInitializing');
    print('[AUDIO DEBUG] _globalAudioHandler is null: ${_globalAudioHandler == null}');
    
    // ALWAYS check global handler first - this is the single source of truth
    if (_globalAudioHandler != null) {
      print('[AUDIO DEBUG] ✅ Using existing global AudioHandler');
      _audioHandler = _globalAudioHandler;
      _audioServiceInitialized = true;
      _isInitializing = false;
      return;
    }
    
    // If we already initialized but don't have handler, we can't recover
    if (_audioServiceInitialized && _audioHandler == null && _globalAudioHandler == null) {
      print('[AUDIO DEBUG] ❌ AudioService was initialized but handler was lost');
      print('[AUDIO DEBUG] ❌ Cannot recover - audio will play but without background controls');
      _isInitializing = false;
      return;
    }
    
    // If already initializing, wait for it to complete
    if (_isInitializing) {
      print('[AUDIO DEBUG] ⏳ Waiting for ongoing initialization...');
      int attempts = 0;
      while (_isInitializing && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
        if (_globalAudioHandler != null) {
          print('[AUDIO DEBUG] ✅ Got handler from concurrent initialization');
          _audioHandler = _globalAudioHandler;
          _audioServiceInitialized = true;
          _isInitializing = false;
          return;
        }
      }
      if (_globalAudioHandler == null) {
        print('[AUDIO DEBUG] ⚠️ Timeout waiting for initialization');
        _isInitializing = false;
      }
      return;
    }
    
    // If we have an instance handler but no global, store it globally
    if (_audioHandler != null && _globalAudioHandler == null) {
      print('[AUDIO DEBUG] ✅ Storing instance handler globally');
      _globalAudioHandler = _audioHandler;
      _audioServiceInitialized = true;
      _isInitializing = false;
      return;
    }
    
    // CRITICAL: Only initialize if NOT already initialized
    // AudioService.init() can only be called ONCE per app lifecycle
    if (!_audioServiceInitialized && _globalAudioHandler == null) {
      // Mark that we're starting initialization
      _isInitializing = true;
      print('[AUDIO DEBUG] ✅ Initializing AudioService (first time only - on-demand when audio is played)...');
      print('[AUDIO DEBUG] Waiting for FlutterEngine to be ready...');
      
      // CRITICAL: Ensure WidgetsBinding is initialized and app is in foreground
      // This prevents "wrong Activity or FlutterEngine" errors from audio_service
      // Note: WidgetsFlutterBinding.ensureInitialized() is safe to call multiple times
      print('[AUDIO DEBUG] Ensuring WidgetsFlutterBinding is initialized...');
      WidgetsFlutterBinding.ensureInitialized();
      print('[AUDIO DEBUG] ✅ WidgetsFlutterBinding is initialized');
      
      // CRITICAL: Wait for the FIRST FRAME to be rendered
      // This guarantees that the FlutterEngine is fully attached and ready
      // Without this, audio_service can't find the FlutterEngine
      print('[AUDIO DEBUG] Waiting for first frame to be rendered (ensures FlutterEngine is ready)...');
      await WidgetsBinding.instance.endOfFrame;
      print('[AUDIO DEBUG] ✅ First frame rendered - FlutterEngine is ready');
      
      // Additional small delay to ensure everything is settled
      await Future.delayed(const Duration(milliseconds: 200));
      
      try {
        // Initialize AudioService - AudioPlayer will be created in the builder
        print('[AUDIO DEBUG] Initializing AudioService (AudioPlayer will be created in builder)...');
        
        _audioHandler = await AudioService.init(
          builder: () {
            // Create AudioPlayer instance if it doesn't exist
            // No need for just_audio_background - AudioPlayer can be created directly
            if (_audioPlayerInstance == null) {
              print('[AUDIO DEBUG] Creating AudioPlayer instance in AudioService builder...');
              _audioPlayerInstance = AudioPlayer();
              print('[AUDIO DEBUG] ✅ AudioPlayer instance created in builder');
            }
            
            print('[AUDIO DEBUG] Creating TeekoobAudioHandler with AudioPlayer');
            return TeekoobAudioHandler(_audioPlayerInstance!);
          },
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.teekoob.app.audio',
            androidNotificationChannelName: 'Teekoob Audio Player',
            androidNotificationChannelDescription: 'Audio playback controls for audiobooks and podcasts',
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidShowNotificationBadge: true,
            androidStopForegroundOnPause: false, // Keep notification when paused - allows controls to persist
            androidNotificationClickStartsActivity: true, // Open app when notification clicked
            androidResumeOnClick: true,
            androidNotificationOngoing: false, // Allow dismissing when stopped
            fastForwardInterval: Duration(seconds: 30),
            rewindInterval: Duration(seconds: 10),
            preloadArtwork: true, // Preload artwork for faster notification display
            artDownscaleWidth: 512, // High quality artwork for notification
            artDownscaleHeight: 512,
          ),
        );
        print('[AUDIO DEBUG] ✅ AudioService initialized successfully!');
        print('[AUDIO DEBUG] Handler exists: ${_audioHandler != null}');
        _audioServiceInitialized = true;
        
        // CRITICAL: Store handler globally immediately after successful initialization
        if (_audioHandler != null) {
          _globalAudioHandler = _audioHandler;
          print('[AUDIO DEBUG] ✅ Stored AudioHandler globally');
          print('[AUDIO DEBUG] ✅ Global handler verified: ${_globalAudioHandler != null}');
          print('[AUDIO DEBUG] ✅ Handler type: ${_audioHandler.runtimeType}');
          
          // Now set up AudioPlayer listeners since AudioService is ready
          // AudioPlayer was created in the builder, so we can now set up listeners
          _setupAudioPlayerListeners();
        } else {
          print('[AUDIO DEBUG] ❌ ERROR: Handler is null after initialization!');
          _isInitializing = false;
          _audioServiceInitialized = false; // Allow retry
        }
      } catch (e, stackTrace) {
        print('[AUDIO DEBUG] ❌ ERROR initializing AudioService: $e');
        print('[AUDIO DEBUG] Stack trace: $stackTrace');
        
        // CRITICAL: ANY error from AudioService.init() means it has already set internal state
        // Even if it errors out, AudioService has been partially initialized
        // We CANNOT call AudioService.init() again after ANY error
        print('[AUDIO DEBUG] ❌ CRITICAL: AudioService.init() failed - cannot retry');
        print('[AUDIO DEBUG] ❌ Even failed init() calls set internal AudioService state');
        
        // Check if we somehow have a global handler from a previous successful init
        if (_globalAudioHandler != null) {
          print('[AUDIO DEBUG] ✅ Found existing global handler! Using it...');
          _audioHandler = _globalAudioHandler;
          _audioServiceInitialized = true;
          _isInitializing = false;
          print('[AUDIO DEBUG] ✅ Recovered handler from global storage');
          return; // Don't mark as error - we have a handler!
        }
        
        // Mark as initialized to prevent ANY retry attempts
        // This is critical: AudioService.init() can only be called once, even if it fails
        _audioServiceInitialized = true;
        _audioHandler = null;
        _isInitializing = false;
        
        print('[AUDIO DEBUG] ❌ Cannot recover - audio will play WITHOUT background controls/notification');
        print('[AUDIO DEBUG] ❌ To fix: Restart the app and ensure AudioService initializes correctly on first try');
        return; // Exit early - NO retries allowed
      }
      
      _isInitializing = false;
      
      // Store handler globally after successful initialization
      if (_audioHandler != null && _globalAudioHandler == null) {
        _globalAudioHandler = _audioHandler;
        print('[AUDIO DEBUG] ✅ Stored AudioHandler globally for reuse');
      }
    } else {
      // Already initialized or initialization in progress
      print('[AUDIO DEBUG] ℹ️ AudioService initialization skipped - already initialized or in progress');
      _isInitializing = false;
    }
  }


  // Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - audio should continue playing
        break;
      case AppLifecycleState.paused:
        // App went to background - audio should continue playing
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop audio
        stop();
        break;
      case AppLifecycleState.inactive:
        // App is inactive - keep audio playing
        break;
      case AppLifecycleState.hidden:
        // App is hidden - keep audio playing
        break;
    }
  }

  // Initialize the audio player
  /// Set up AudioPlayer listeners after AudioService is initialized
  /// This must be called AFTER AudioService.init() completes successfully
  void _setupAudioPlayerListeners() {
    if (_audioPlayerInstance == null) {
      print('[AUDIO DEBUG] ⚠️ AudioPlayer not created yet, cannot set up listeners');
      return;
    }
    
    print('[AUDIO DEBUG] Setting up AudioPlayer listeners...');
    
    // Listen to position changes
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
    
    // Listen to duration changes and update MediaItem
    _durationSubscription?.cancel();
    _durationSubscription = _audioPlayer.durationStream.listen((duration) async {
      if (duration != null && duration != Duration.zero) {
        print('[AUDIO DEBUG] Duration updated: ${duration.inSeconds}s');
        _duration = duration;
        notifyListeners();
        
        // Update MediaItem with duration once it's available
        if (_audioHandler != null && 
            _audioHandler is TeekoobAudioHandler && 
            _currentItem != null) {
          print('[AUDIO DEBUG] Updating MediaItem with duration...');
          try {
            // Build cover image URL for MediaItem
            String? coverImageUrl;
            if (_currentItem!.coverImageUrl != null && _currentItem!.coverImageUrl!.isNotEmpty) {
              if (_currentItem!.coverImageUrl!.startsWith('http')) {
                coverImageUrl = _currentItem!.coverImageUrl;
              } else {
                coverImageUrl = '${AppConfig.mediaBaseUrl}${_currentItem!.coverImageUrl}';
              }
            }
            
            final updatedMediaItem = MediaItem(
              id: _currentItem!.id,
              title: _currentItem!.title,
              artist: _currentItem!.type == AudioType.book 
                  ? (_currentItem!.author ?? 'Unknown Author') 
                  : (_currentItem!.host ?? 'Podcast'),
              album: _currentItem!.type == AudioType.book ? 'Audiobook' : 'Podcast',
              artUri: coverImageUrl != null ? Uri.parse(coverImageUrl) : null,
              duration: duration,
              extras: {
                'type': _currentItem!.type == AudioType.book ? 'book' : 'podcast',
                'id': _currentItem!.id,
              },
            );
            
            await (_audioHandler as TeekoobAudioHandler).updateMediaItem(updatedMediaItem);
            print('[AUDIO DEBUG] MediaItem updated with duration successfully');
          } catch (e) {
            print('[AUDIO DEBUG] Error updating MediaItem with duration: $e');
          }
        }
      }
    });
    
    // Listen to player state changes
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      print('[AUDIO DEBUG] Player state changed: ${playerState.processingState}, playing: ${playerState.playing}');
      switch (playerState.processingState) {
        case ProcessingState.idle:
          if (!playerState.playing) {
            _state = AudioPlayerState.stopped;
            print('[AUDIO DEBUG] State: STOPPED');
          }
          break;
        case ProcessingState.loading:
          _state = AudioPlayerState.loading;
          print('[AUDIO DEBUG] State: LOADING');
          break;
        case ProcessingState.buffering:
          _state = AudioPlayerState.loading;
          print('[AUDIO DEBUG] State: BUFFERING');
          break;
        case ProcessingState.ready:
          if (playerState.playing) {
            _state = AudioPlayerState.playing;
            print('[AUDIO DEBUG] State: PLAYING');
          } else {
            _state = AudioPlayerState.paused;
            print('[AUDIO DEBUG] State: PAUSED');
          }
          break;
        case ProcessingState.completed:
          _state = AudioPlayerState.stopped;
          _position = Duration.zero;
          print('[AUDIO DEBUG] State: COMPLETED');
          _handleEpisodeCompletion();
          break;
      }
      notifyListeners();
    });
    
    print('[AUDIO DEBUG] ✅ AudioPlayer listeners set up successfully');
  }

  Future<void> initialize() async {
    print('[AUDIO DEBUG] initialize() called, _isInitialized: $_isInitialized');
    if (_isInitialized) {
      print('[AUDIO DEBUG] Already initialized, returning early');
      return;
    }

    try {
      print('[AUDIO DEBUG] Starting audio player initialization...');
      
      // AudioPlayer can be created directly (no just_audio_background needed)
      print('[AUDIO DEBUG] Proceeding with AudioPlayer setup...');
      
      // Configure audio session for background playback
      print('[AUDIO DEBUG] Configuring AudioSession...');
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
      print('[AUDIO DEBUG] AudioSession configured successfully');

      // CRITICAL: Don't access _audioPlayer here - it will be created when AudioService.init() is called
      // AudioPlayer is created lazily in the builder when AudioService.init() is called
      // Listeners will be set up AFTER AudioService is initialized
      print('[AUDIO DEBUG] AudioPlayer listeners will be set up after AudioService is initialized');

      _isInitialized = true;
      print('[AUDIO DEBUG] Audio player initialized successfully');
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ERROR initializing audio player: $e');
      print('[AUDIO DEBUG] Stack trace: $stackTrace');
      _state = AudioPlayerState.error;
      notifyListeners();
    }
  }

  // Play audio item
  Future<void> playItem(AudioItem item) async {
    print('[AUDIO DEBUG] ========== playItem() called ==========');
    print('[AUDIO DEBUG] Item ID: ${item.id}');
    print('[AUDIO DEBUG] Item Title: ${item.title}');
    print('[AUDIO DEBUG] Item Type: ${item.type}');
    print('[AUDIO DEBUG] Audio URL: ${item.audioUrl}');
    print('[AUDIO DEBUG] Is Local File: ${item.isLocalFile}');
    print('[AUDIO DEBUG] Current State: $_state');
    print('[AUDIO DEBUG] Is Initialized: $_isInitialized');
    print('[AUDIO DEBUG] AudioHandler exists: ${_audioHandler != null}');
    
    try {
      // CRITICAL: Initialize AudioService FIRST before creating AudioPlayer
      // AudioPlayer can be created directly without just_audio_background
      if (!_audioServiceInitialized || _audioHandler == null) {
        print('[AUDIO DEBUG] AudioService not initialized yet, initializing AudioService first...');
        
        await initializeAudioHandler();
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify handler was created
        if (_audioHandler == null && _globalAudioHandler != null) {
          _audioHandler = _globalAudioHandler;
          print('[AUDIO DEBUG] ✅ Using global handler after initialization');
        }
      }
      
      // Now initialize audio player AFTER AudioService is ready
      if (!_isInitialized) {
        print('[AUDIO DEBUG] Audio player not initialized, calling initialize() AFTER AudioService is ready...');
        await initialize();
      }

      // For local files, verify the file exists before playing
      if (item.isLocalFile) {
        print('[AUDIO DEBUG] Checking local file existence...');
        final file = File(item.audioUrl);
        if (!await file.exists()) {
          print('[AUDIO DEBUG] ERROR: Local file does not exist: ${item.audioUrl}');
          throw Exception('Audio file not found: ${item.audioUrl}');
        }
        print('[AUDIO DEBUG] Local file exists: ${item.audioUrl}');
      }

      _state = AudioPlayerState.loading;
      notifyListeners();
      print('[AUDIO DEBUG] State set to LOADING');

      // If it's the same item, just resume
      if (_currentItem?.id == item.id && _state == AudioPlayerState.paused) {
        print('[AUDIO DEBUG] Same item paused, resuming playback...');
        try {
          // Use AudioHandler if available, otherwise use AudioPlayer directly
          if (_audioHandler != null) {
            print('[AUDIO DEBUG] Resuming via AudioHandler');
            await _audioHandler!.play();
          } else {
            print('[AUDIO DEBUG] Resuming via AudioPlayer directly');
            await _audioPlayer.play();
          }
          _state = AudioPlayerState.playing;
          notifyListeners();
          print('[AUDIO DEBUG] Resume successful, state: PLAYING');
          return;
        } catch (e) {
          print('[AUDIO DEBUG] Resume failed: $e');
          // If resume fails due to initialization, continue to set new source
          if (e.toString().contains('_audioHandler') || e.toString().contains('not been initialized')) {
            print('[AUDIO DEBUG] Resume failed due to initialization, will set new source');
            // Continue to set audio source below
          } else {
            rethrow;
          }
        }
      }

      // Stop current audio if playing different item
      if (_currentItem != null && _currentItem!.id != item.id) {
        print('[AUDIO DEBUG] Different item, stopping current playback...');
        await _audioPlayer.stop();
      }

      _currentItem = item;
      // Clear book if item is not a book
      if (item.type != AudioType.book) {
        _currentBook = null;
      }
      
      // Build cover image URL for MediaItem - CRITICAL: Must be full URL for notification artwork
      String? coverImageUrl;
      if (item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty) {
        if (item.coverImageUrl!.startsWith('http://') || item.coverImageUrl!.startsWith('https://')) {
          coverImageUrl = item.coverImageUrl;
        } else {
          // Ensure proper URL formatting
          final baseUrl = AppConfig.mediaBaseUrl.endsWith('/') 
              ? AppConfig.mediaBaseUrl.substring(0, AppConfig.mediaBaseUrl.length - 1)
              : AppConfig.mediaBaseUrl;
          final imagePath = item.coverImageUrl!.startsWith('/') 
              ? item.coverImageUrl 
              : '/${item.coverImageUrl}';
          coverImageUrl = '$baseUrl$imagePath';
        }
        print('[AUDIO DEBUG] Cover image URL: $coverImageUrl');
      } else {
        print('[AUDIO DEBUG] No cover image URL provided');
      }
      
      // Create MediaItem for lock screen controls with ALL metadata
      // This ensures notification shows title, artist, artwork, and controls properly
      final mediaItem = MediaItem(
        id: item.id,
        title: item.title.isNotEmpty ? item.title : 'Unknown Title',
        artist: item.type == AudioType.book 
            ? (item.author?.isNotEmpty == true ? item.author! : 'Unknown Author')
            : (item.host?.isNotEmpty == true ? item.host! : 'Podcast'),
        album: item.type == AudioType.book ? 'Audiobook' : 'Podcast',
        artUri: coverImageUrl != null ? Uri.parse(coverImageUrl) : null,
        duration: item.duration,
        displayTitle: item.title.isNotEmpty ? item.title : 'Unknown Title',
        displaySubtitle: item.type == AudioType.book 
            ? (item.author?.isNotEmpty == true ? item.author! : 'Unknown Author')
            : (item.host?.isNotEmpty == true ? item.host! : 'Podcast'),
        extras: {
          'type': item.type == AudioType.book ? 'book' : 'podcast',
          'id': item.id,
          'coverUrl': coverImageUrl,
          'author': item.author,
          'host': item.host,
        },
      );
      
      print('[AUDIO DEBUG] MediaItem created:');
      print('[AUDIO DEBUG]   - ID: ${mediaItem.id}');
      print('[AUDIO DEBUG]   - Title: ${mediaItem.title}');
      print('[AUDIO DEBUG]   - Artist: ${mediaItem.artist}');
      print('[AUDIO DEBUG]   - Album: ${mediaItem.album}');
      print('[AUDIO DEBUG]   - Art URI: ${mediaItem.artUri}');
      print('[AUDIO DEBUG]   - Duration: ${mediaItem.duration}');
      
      // Create AudioSource with MediaItem tag for audio_service
      // Handle local files vs network URLs
      final Uri audioUri;
      if (item.isLocalFile) {
        // Local file - use file:// URI
        final file = File(item.audioUrl);
        if (!await file.exists()) {
          throw Exception('Audio file does not exist: ${item.audioUrl}');
        }
        audioUri = Uri.file(item.audioUrl);
      } else {
        // Network URL - check if we're offline
        audioUri = Uri.parse(item.audioUrl);
      }
      
      final audioSource = AudioSource.uri(audioUri);
      
      // Initialize audio handler for background playback FIRST
      // This is critical - handler must be ready before setting media item
      print('[AUDIO DEBUG] Initializing audio handler for background playback...');
      
      // Check global handler FIRST before trying to initialize
      print('[AUDIO DEBUG] Checking for global handler before initialization...');
      print('[AUDIO DEBUG] _globalAudioHandler is null: ${_globalAudioHandler == null}');
      print('[AUDIO DEBUG] _audioServiceInitialized: $_audioServiceInitialized');
      print('[AUDIO DEBUG] Static _globalAudioHandler address: ${_globalAudioHandler?.hashCode}');
      
      if (_globalAudioHandler != null) {
        print('[AUDIO DEBUG] ✅ Found global handler, using it');
        print('[AUDIO DEBUG] Handler type: ${_globalAudioHandler.runtimeType}');
        _audioHandler = _globalAudioHandler;
        _audioServiceInitialized = true;
        print('[AUDIO DEBUG] ✅ Instance handler set from global handler');
      } else {
        // Try to initialize if we don't have a global handler
        await initializeAudioHandler();
        
        // Ensure audio handler is ready before proceeding
        if (_audioHandler == null) {
          print('[AUDIO DEBUG] AudioHandler still null after initialization, checking global handler...');
          if (_globalAudioHandler != null) {
            print('[AUDIO DEBUG] Found global handler after initialization, using it');
            _audioHandler = _globalAudioHandler;
          } else {
            print('[AUDIO DEBUG] No global handler, waiting and retrying initialization...');
            await Future.delayed(const Duration(milliseconds: 500));
            await initializeAudioHandler();
            
            // Check global handler again after initialization attempt
            if (_audioHandler == null && _globalAudioHandler != null) {
              print('[AUDIO DEBUG] Using global handler after retry');
              _audioHandler = _globalAudioHandler;
            }
          }
        }
      }
      
      print('[AUDIO DEBUG] AudioHandler status: ${_audioHandler != null}');
      print('[AUDIO DEBUG] Global AudioHandler status: ${_globalAudioHandler != null}');
      
      // CRITICAL: Update audio handler with media item BEFORE setting audio source
      // This ensures the notification shows immediately with all metadata (title, artist, artwork)
      // The notification will appear as soon as media item is set, even before playback starts
      if (_audioHandler != null && _audioHandler is TeekoobAudioHandler) {
        print('[AUDIO DEBUG] ✅ Updating MediaItem in AudioHandler for immediate notification display...');
        final handler = _audioHandler as TeekoobAudioHandler;
        await handler.updateMediaItem(mediaItem);
        print('[AUDIO DEBUG] ✅ MediaItem updated successfully - notification should appear now');
        
        // Update playback state to "loading" to trigger notification display immediately
        // This makes the notification appear right away, even before audio starts playing
        handler.playbackState.add(handler.playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
          playing: false,
        ));
        print('[AUDIO DEBUG] ✅ Playback state set to loading - notification visible');
        
        // Give the system a moment to display the notification with metadata
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        print('[AUDIO DEBUG] ⚠️ WARNING: AudioHandler is null or not TeekoobAudioHandler');
        print('[AUDIO DEBUG] ⚠️ Notification may not appear properly');
      }
      
      // Set audio source (this will trigger lock screen controls via audio_service)
      // Retry logic with better error handling
      int retryCount = 0;
      const maxRetries = 3; // Reduced retries since we have better initialization
      bool sourceSet = false;
      String? lastError;
      
      print('[AUDIO DEBUG] Setting audio source (max retries: $maxRetries)...');
      while (!sourceSet && retryCount < maxRetries) {
        print('[AUDIO DEBUG] Attempt ${retryCount + 1}/$maxRetries to set audio source...');
        try {
          
          // Ensure audio handler is ready before setting source
          if (_audioHandler == null && retryCount == 0) {
            print('[AUDIO DEBUG] AudioHandler null on first attempt, initializing...');
            await initializeAudioHandler();
            await Future.delayed(const Duration(milliseconds: 300));
          }
          
          // Stop any current playback before setting new source
          if (retryCount > 0) {
            print('[AUDIO DEBUG] Retry attempt, stopping current playback...');
            try {
              await _audioPlayer.stop();
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (_) {}
          }
          
          print('[AUDIO DEBUG] Calling setAudioSource with URI: $audioUri');
          // Add timeout for slow network connections (60 seconds for URL loading)
          // Large audio files (especially 30+ minute files) need more time to buffer
          // This prevents indefinite hanging when loading audio from slow URLs or large files
          print('[AUDIO DEBUG] ⏳ Buffering audio... This may take up to 60 seconds for large files');
          try {
            await _audioPlayer.setAudioSource(audioSource).timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                print('[AUDIO DEBUG] Timeout: Audio source loading took too long (>60s)');
                throw TimeoutException(
                  'Audio URL loading timeout: The audio file took too long to load (>60s). Please check your internet connection or try a different network.',
                  const Duration(seconds: 60),
                );
              },
            );
            print('[AUDIO DEBUG] Audio source set successfully');
            sourceSet = true;
          } on TimeoutException catch (timeoutError) {
            // Re-throw timeout exceptions immediately
            lastError = timeoutError.toString();
            print('[AUDIO DEBUG] Timeout error: $timeoutError');
            throw timeoutError;
          }
        } catch (e, stackTrace) {
          lastError = e.toString();
          print('[AUDIO DEBUG] ERROR setting audio source: $e');
          print('[AUDIO DEBUG] Stack trace: $stackTrace');
          
          // Check if it's a timeout error
          final isTimeoutError = e is TimeoutException || 
                                e.toString().contains('TimeoutException') ||
                                e.toString().contains('timeout');
          
          // Check if it's a source error (network/file not found)
          final isSourceError = e.toString().contains('Source error') ||
                                e.toString().contains('Failed to load') ||
                                e.toString().contains('Not Found') ||
                                e.toString().contains('NetworkError') ||
                                e.toString().contains('(0)');
          
          // Check if it's an initialization error
          final isInitError = e.toString().contains('_audioHandler') || 
                             e.toString().contains('not been initialized') ||
                             e.toString().contains('LateInitializationError');
          
          print('[AUDIO DEBUG] Error type - Timeout: $isTimeoutError, Source: $isSourceError, Init: $isInitError');
          
          // Handle timeout errors - retry with longer timeout for slow connections
          if (isTimeoutError && retryCount < maxRetries - 1) {
            retryCount++;
            final waitTime = 2000 * retryCount; // 2s, 4s, 6s
            print('[AUDIO DEBUG] Timeout error, retrying in ${waitTime}ms...');
            await Future.delayed(Duration(milliseconds: waitTime));
          } else if (isSourceError && retryCount < maxRetries - 1) {
            // For source errors, wait longer before retry
            retryCount++;
            final waitTime = 1000 * retryCount; // 1s, 2s, 3s
            print('[AUDIO DEBUG] Source error, retrying in ${waitTime}ms...');
            await Future.delayed(Duration(milliseconds: waitTime));
          } else if (isInitError && retryCount < maxRetries - 1) {
            // For initialization errors, reinitialize
            retryCount++;
            final waitTime = 500 + (500 * retryCount);
            
            try {
              await _audioPlayer.stop();
              await Future.delayed(const Duration(milliseconds: 200));
              
              // Reinitialize audio handler if needed
              if (_audioHandler == null) {
                await initializeAudioHandler();
                await Future.delayed(const Duration(milliseconds: 300));
              }
            } catch (reinitError) {
            }
            
            await Future.delayed(Duration(milliseconds: waitTime));
          } else {
            // Last attempt or unknown error
            if (retryCount == maxRetries - 1) {
              // On final attempt, throw the error
              throw Exception('Failed to load audio source: $lastError');
            }
          }
        }
      }
      
      if (!sourceSet) {
        throw Exception('Failed to set audio source after $maxRetries attempts: $lastError');
      }
      
      // Wait for audio source to be fully loaded before playing
      // Update duration in MediaItem once audio is loaded
      // Give large audio files more time to load (especially from remote URLs)
      print('[AUDIO DEBUG] Waiting for audio to load and updating duration...');
      print('[AUDIO DEBUG] ⏳ This may take time for large files, please wait...');
      
      // Wait up to 15 seconds for audio to load completely
      int waitAttempts = 0;
      const maxWaitAttempts = 50; // 50 * 300ms = 15 seconds
      while (waitAttempts < maxWaitAttempts && _audioPlayer.duration == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        waitAttempts++;
        if (waitAttempts % 10 == 0) {
          print('[AUDIO DEBUG] ⏳ Still loading audio... (${waitAttempts * 300}ms elapsed)');
        }
      }
      
      // Update MediaItem with actual duration once audio is loaded
      final actualDuration = _audioPlayer.duration;
      if (actualDuration != null && actualDuration != Duration.zero) {
        print('[AUDIO DEBUG] Audio loaded, duration: $actualDuration');
        final updatedMediaItem = mediaItem.copyWith(duration: actualDuration);
        
        if (_audioHandler != null && _audioHandler is TeekoobAudioHandler) {
          await (_audioHandler as TeekoobAudioHandler).updateMediaItem(updatedMediaItem);
          print('[AUDIO DEBUG] ✅ MediaItem updated with duration');
        }
      }
      
      // Start playing - use AudioHandler if available, otherwise use AudioPlayer directly
      print('[AUDIO DEBUG] Starting playback...');
      
      if (_audioHandler != null) {
        print('[AUDIO DEBUG] ✅ Playing via AudioHandler (background controls enabled)');
        // Use AudioHandler to play - this ensures notification shows play state
        await _audioHandler!.play();
        print('[AUDIO DEBUG] ✅ AudioHandler.play() called successfully');
        
        // Ensure notification is fully updated after playback starts
        // Update playback state to "ready" and "playing" for proper notification display
        if (_audioHandler is TeekoobAudioHandler) {
          final handler = _audioHandler as TeekoobAudioHandler;
          handler.playbackState.add(handler.playbackState.value.copyWith(
            processingState: AudioProcessingState.ready,
            playing: true,
          ));
          print('[AUDIO DEBUG] ✅ Playback state updated to playing - notification should show play controls');
        }
      } else {
        print('[AUDIO DEBUG] ⚠️ WARNING: Playing via AudioPlayer directly (no background controls)');
        // Fallback to direct AudioPlayer if handler not available
        await _audioPlayer.play();
        print('[AUDIO DEBUG] AudioPlayer.play() called successfully');
      }
      
      print('[AUDIO DEBUG] ========== playItem() completed successfully ==========');
      
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ========== ERROR in playItem() ==========');
      print('[AUDIO DEBUG] Error: $e');
      print('[AUDIO DEBUG] Stack trace: $stackTrace');
      
      // Update MediaItem with error - shows in notification/lock screen
      if (_audioHandler != null && _audioHandler is TeekoobAudioHandler && _currentItem != null) {
        try {
          final errorMessage = _getUserFriendlyErrorMessage(e);
          await (_audioHandler as TeekoobAudioHandler).updateMediaItemWithError(errorMessage);
          print('[AUDIO DEBUG] Error displayed in notification/lock screen');
        } catch (updateError) {
          print('[AUDIO DEBUG] Failed to update MediaItem with error: $updateError');
        }
      }
      
      _state = AudioPlayerState.error;
      notifyListeners();
    }
  }

  // Play book - checks for local file first
  Future<void> playBook(Book book) async {
    try {
      // Check if audio is downloaded locally (offline mode)
      final localAudioPath = await _downloadService.getBookAudioPath(book.id);
      
      if (localAudioPath != null) {
        final file = File(localAudioPath);
        if (await file.exists()) {
          final audioItem = AudioItem.fromBook(
            book,
            localAudioPath: localAudioPath,
          );
          await playItem(audioItem);
          return;
        } else {
        }
      }
      
      // Fall back to network if no local file
      if (book.audioUrl == null || book.audioUrl!.isEmpty) {
        throw Exception('No audio URL available for this book');
      }
      
      // Build the full audio URL
      final fullAudioUrl = AudioItem._buildFullUrl(book.audioUrl);
      
      if (fullAudioUrl.isEmpty) {
        throw Exception('No valid audio URL available for this book');
      }
      
      // Create a copy of the book with the full URL
      final bookWithFullUrl = Book(
        id: book.id,
        title: book.title,
        titleSomali: book.titleSomali,
        description: book.description,
        descriptionSomali: book.descriptionSomali,
        authors: book.authors,
        authorsSomali: book.authorsSomali,
        categories: book.categories,
        categoryNames: book.categoryNames,
        language: book.language,
        format: book.format,
        coverImageUrl: book.coverImageUrl,
        audioUrl: fullAudioUrl,
        ebookUrl: book.ebookUrl,
        sampleUrl: book.sampleUrl,
        ebookContent: book.ebookContent,
        duration: book.duration,
        pageCount: book.pageCount,
        rating: book.rating,
        reviewCount: book.reviewCount,
        isFeatured: book.isFeatured,
        isNewRelease: book.isNewRelease,
        isPremium: book.isPremium,
        isFree: book.isFree,
        metadata: book.metadata,
        createdAt: book.createdAt,
        updatedAt: book.updatedAt,
      );
      
      final audioItem = AudioItem.fromBook(bookWithFullUrl);
      _currentBook = bookWithFullUrl; // Store the book object
      await playItem(audioItem);
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Play podcast episode - checks for local file first
  Future<void> playPodcastEpisode(PodcastEpisode episode, {Podcast? podcast}) async {
    try {
      // Check if episode is downloaded locally (offline mode)
      final localAudioPath = await _downloadService.getPodcastEpisodePath(episode.id);
      
      if (localAudioPath != null) {
        final file = File(localAudioPath);
        if (await file.exists()) {
          final audioItem = AudioItem(
            id: episode.id,
            title: episode.title,
            host: podcast?.host ?? podcast?.displayHost ?? 'Podcast',
            coverImageUrl: podcast?.coverImageUrl,
            audioUrl: localAudioPath, // Local file path
            type: AudioType.podcast,
            duration: episode.duration != null 
                ? Duration(minutes: episode.duration!) 
                : null,
          );
          await playItem(audioItem);
          return;
        } else {
        }
      }
      
      // Fall back to network if no local file
      if (episode.audioUrl == null || episode.audioUrl!.isEmpty) {
        throw Exception('No audio URL available for this episode');
      }
      
      final audioItem = AudioItem.fromPodcastEpisode(episode, podcast: podcast);
      await playItem(audioItem);
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Set episode queue for a podcast
  void setEpisodeQueue(List<PodcastEpisode> episodes, String podcastId) {
    _episodeQueue = List.from(episodes);
    _currentPodcastId = podcastId;
    _currentEpisodeIndex = -1;
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
      _currentEpisodeIndex = 0; // Fallback to first episode
    }
    
    
    // Play the episode with podcast metadata
    await playPodcastEpisode(episode, podcast: podcast);
  }
  
  // Play next episode
  Future<void> playNextEpisode() async {
    if (!hasNextEpisode) {
      return;
    }
    
    final nextEpisodeData = nextEpisode!;
    
    _currentEpisodeIndex++;
    await playPodcastEpisode(nextEpisodeData, podcast: _currentPodcast);
  }

  // Play previous episode
  Future<void> playPreviousEpisode() async {
    if (!hasPreviousEpisode) {
      return;
    }
    
    final previousEpisodeData = previousEpisode!;
    
    _currentEpisodeIndex--;
    await playPodcastEpisode(previousEpisodeData, podcast: _currentPodcast);
  }

  // Pause audio
  Future<void> pause() async {
    print('[AUDIO DEBUG] pause() called');
    try {
      // If not initialized, just update state
      if (!_isInitialized) {
        print('[AUDIO DEBUG] Not initialized, setting state to paused');
        _state = AudioPlayerState.paused;
        notifyListeners();
        return;
      }
      
      // Use AudioHandler if available, otherwise use AudioPlayer directly
      if (_audioHandler != null) {
        print('[AUDIO DEBUG] Pausing via AudioHandler');
        await _audioHandler!.pause();
      } else {
        print('[AUDIO DEBUG] Pausing via AudioPlayer directly');
        await _audioPlayer.pause();
      }
      
      _state = AudioPlayerState.paused;
      notifyListeners();
      print('[AUDIO DEBUG] Pause successful');
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ERROR pausing: $e');
      // Update state even if pause fails
      _state = AudioPlayerState.paused;
      notifyListeners();
    }
  }

  // Resume audio
  Future<void> resume() async {
    print('[AUDIO DEBUG] resume() called');
    try {
      // Ensure service is initialized before resuming
      if (!_isInitialized) {
        print('[AUDIO DEBUG] Not initialized, calling initialize()...');
        await initialize();
      }
      
      // Check if there's a current item to resume
      if (_currentItem == null) {
        print('[AUDIO DEBUG] No current item to resume');
        return;
      }
      
      print('[AUDIO DEBUG] Resuming: ${_currentItem!.title}');
      
      // Use AudioHandler if available, otherwise use AudioPlayer directly
      if (_audioHandler != null) {
        print('[AUDIO DEBUG] Resuming via AudioHandler');
        await _audioHandler!.play();
      } else {
        print('[AUDIO DEBUG] Resuming via AudioPlayer directly');
        await _audioPlayer.play();
      }
      
      _state = AudioPlayerState.playing;
      notifyListeners();
      print('[AUDIO DEBUG] Resume successful');
    } catch (e, stackTrace) {
      print('[AUDIO DEBUG] ERROR resuming: $e');
      
      // If it's an initialization error, try to reinitialize and retry
      if (e.toString().contains('_audioHandler') || e.toString().contains('not been initialized')) {
        try {
          _isInitialized = false;
          await initialize();
          await initializeAudioHandler();
          // Retry after a short delay
          await Future.delayed(const Duration(milliseconds: 300));
          if (_audioHandler != null) {
            await _audioHandler!.play();
          } else {
            await _audioPlayer.play();
          }
          _state = AudioPlayerState.playing;
          notifyListeners();
        } catch (retryError) {
          _state = AudioPlayerState.error;
          notifyListeners();
        }
      } else {
        _state = AudioPlayerState.error;
        notifyListeners();
      }
    }
  }

  // Stop audio
  Future<void> stop() async {
    try {
      // If not initialized, just reset state
      if (!_isInitialized) {
        _position = Duration.zero;
        _currentItem = null;
        _currentBook = null;
        _state = AudioPlayerState.stopped;
        notifyListeners();
        return;
      }
      
      await _audioPlayer.stop();
      _position = Duration.zero;
      _currentItem = null;
      _currentBook = null;
      _state = AudioPlayerState.stopped;
      notifyListeners();
    } catch (e, stackTrace) {
      // Reset state even if stop fails
      _position = Duration.zero;
      _currentItem = null;
      _currentBook = null;
      _state = AudioPlayerState.stopped;
      notifyListeners();
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      // If not initialized, just update position state
      if (!_isInitialized) {
        _position = position;
        notifyListeners();
        return;
      }
      
      // Use AudioHandler if available, otherwise use AudioPlayer directly
      if (_audioHandler != null) {
        await _audioHandler!.seek(position);
      } else {
        await _audioPlayer.seek(position);
      }
      
      _position = position;
      notifyListeners();
    } catch (e, stackTrace) {
      // Update position state even if seek fails
      _position = position;
      notifyListeners();
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
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

  /// Get user-friendly error message from exception
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Audio file not found.';
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return 'Unsupported audio format.';
    } else if (errorStr.contains('source error')) {
      return 'Failed to load audio. Please try again.';
    } else {
      return 'Playback error occurred. Please try again.';
    }
  }

  // Handle episode completion and auto-advance to next episode
  void _handleEpisodeCompletion() {
    
    // Only auto-advance for podcast episodes
    if (_currentItem?.type == AudioType.podcast && hasNextEpisode) {
      // Use a small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 500), () {
        playNextEpisode();
      });
    } else {
    }
  }

  // Note: Lock screen controls are automatically handled by audio_service
  // when using AudioSource.uri() with MediaItem tags

  // Dispose resources
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayerInstance?.dispose();
    super.dispose();
  }
}
