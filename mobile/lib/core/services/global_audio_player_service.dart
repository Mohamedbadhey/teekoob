import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
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

class GlobalAudioPlayerService extends ChangeNotifier {
  static final GlobalAudioPlayerService _instance = GlobalAudioPlayerService._internal();
  factory GlobalAudioPlayerService() => _instance;
  GlobalAudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final DownloadService _downloadService = DownloadService();
  
  AudioItem? _currentItem;
  AudioPlayerState _state = AudioPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  AudioHandler? _audioHandler;
  Completer<AudioHandler>? _audioHandlerCompleter;
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
  static final Completer<AudioHandler>? _globalInitCompleter = null;

  // Initialize audio handler for background playback (public for main.dart access)
  Future<void> initializeAudioHandler() async {
    if (_audioHandler != null) {
      print('🎵 AudioHandler already initialized');
      return;
    }

    // Check if AudioService has already been initialized (prevents multiple init calls)
    if (_audioServiceInitialized) {
      print('⚠️ AudioService already initialized elsewhere, skipping reinitialization');
      // If already initialized but we don't have a handler reference, 
      // we can't recover it - will need to reinitialize if needed
      return;
    }

    if (_audioHandlerCompleter != null && !_audioHandlerCompleter!.isCompleted) {
      print('⏳ Waiting for AudioHandler initialization...');
      try {
        _audioHandler = await _audioHandlerCompleter!.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ AudioHandler init timeout, continuing without background support...');
            throw TimeoutException('AudioHandler initialization timeout');
          },
        );
        if (_audioHandler != null) {
          print('✅ AudioHandler initialized successfully');
          _audioServiceInitialized = true;
          return;
        }
      } catch (e) {
        print('⚠️ AudioHandler init error: $e');
      }
    }
    
    // Try to initialize directly if completer didn't work AND AudioService hasn't been initialized
    if (_audioHandler == null && !_audioServiceInitialized) {
      try {
        print('🎵 Initializing AudioHandler directly...');
        _audioHandler = await AudioService.init(
          builder: () => TeekoobAudioHandler(_audioPlayer),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.teekoob.app.audio',
            androidNotificationChannelName: 'Teekoob Audio Player',
            androidNotificationOngoing: false,
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidShowNotificationBadge: true,
            androidStopForegroundOnPause: true,
          ),
        );
        _audioServiceInitialized = true;
        print('✅ AudioHandler initialized successfully');
      } catch (e) {
        print('⚠️ Failed to initialize AudioHandler: $e');
        print('⚠️ Continuing without background support - audio will still play');
        _audioHandler = null;
        // Don't set _audioServiceInitialized = true on error, allow retry
      }
    } else if (_audioServiceInitialized && _audioHandler == null) {
      print('⚠️ AudioService was initialized but handler not found, audio will play without background controls');
    }
  }

  // Set the AudioHandler completer from main.dart
  void setAudioHandlerCompleter(Completer<AudioHandler> completer) {
    _audioHandlerCompleter = completer;
    print('🎵 Set AudioHandler completer');
  }

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
    if (_isInitialized) {
      print('🎵 GlobalAudioPlayerService already initialized');
      return;
    }

    try {
      print('🎵 Initializing GlobalAudioPlayerService...');
      
      // Give JustAudioBackground a moment to fully initialize if needed
      // This is a workaround for the late initialization error
      await Future.delayed(const Duration(milliseconds: 200));
      
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

      // Listen to position changes and update AudioHandler
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        _position = position;
        notifyListeners();
        // Update AudioHandler playback state with position (for notification updates)
        if (_audioHandler != null && _audioHandler is TeekoobAudioHandler) {
          // Position updates are handled automatically by the handler's stream listeners
        }
      });

      // Listen to duration changes and update MediaItem
      _durationSubscription = _audioPlayer.durationStream.listen((duration) async {
        if (duration != null && duration != Duration.zero) {
          _duration = duration;
          notifyListeners();
          
          // Update MediaItem with duration once it's available
          if (_audioHandler != null && 
              _audioHandler is TeekoobAudioHandler && 
              _currentItem != null) {
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
              print('📱 MediaItem duration updated: ${duration.inMinutes} minutes');
            } catch (e) {
              print('⚠️ Error updating MediaItem duration: $e');
            }
          }
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
      // Ensure service is initialized before playing
      if (!_isInitialized) {
        print('🎵 Service not initialized, initializing now...');
        await initialize();
      }
      
      // Double-check initialization after delay (in case JustAudioBackground wasn't ready)
      if (!_isInitialized) {
        print('⚠️ Initialization failed, retrying...');
        await Future.delayed(const Duration(milliseconds: 300));
        await initialize();
      }

      // For local files, verify the file exists before playing
      if (item.isLocalFile) {
        final file = File(item.audioUrl);
        if (!await file.exists()) {
          throw Exception('Audio file not found: ${item.audioUrl}');
        }
        print('✅ Local audio file verified: ${item.audioUrl}');
        print('✅ File size: ${await file.length()} bytes');
      }

      _state = AudioPlayerState.loading;
      notifyListeners();

      // If it's the same item, just resume
      if (_currentItem?.id == item.id && _state == AudioPlayerState.paused) {
        try {
          // Use AudioHandler if available, otherwise use AudioPlayer directly
          if (_audioHandler != null) {
            await _audioHandler!.play();
          } else {
            await _audioPlayer.play();
          }
          _state = AudioPlayerState.playing;
          notifyListeners();
          print('▶️ Resumed existing audio item');
          return;
        } catch (e) {
          // If resume fails due to initialization, continue to set new source
          if (e.toString().contains('_audioHandler') || e.toString().contains('not been initialized')) {
            print('⚠️ Resume failed, will set new audio source instead');
            // Continue to set audio source below
          } else {
            rethrow;
          }
        }
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
      // Handle local files vs network URLs
      final Uri audioUri;
      if (item.isLocalFile) {
        // Local file - use file:// URI
        final file = File(item.audioUrl);
        if (!await file.exists()) {
          throw Exception('Audio file does not exist: ${item.audioUrl}');
        }
        audioUri = Uri.file(item.audioUrl);
        print('📁 Using local file: ${item.audioUrl}');
      } else {
        // Network URL - check if we're offline
        audioUri = Uri.parse(item.audioUrl);
        print('🌐 Using network URL: ${item.audioUrl}');
      }
      
      final audioSource = AudioSource.uri(audioUri);
      
      // Initialize audio handler for background playback
      await initializeAudioHandler();
      
      // Update audio handler with media item BEFORE setting audio source
      // This ensures the notification shows the correct metadata immediately
      if (_audioHandler != null && _audioHandler is TeekoobAudioHandler) {
        await (_audioHandler as TeekoobAudioHandler).updateMediaItem(mediaItem);
        print('📱 MediaItem set for background playback: ${mediaItem.title}');
        print('📱 MediaItem artist: ${mediaItem.artist}');
        print('📱 MediaItem album: ${mediaItem.album}');
        print('📱 MediaItem artUri: ${mediaItem.artUri}');
        
        // Give the handler a moment to process the media item
        await Future.delayed(const Duration(milliseconds: 150));
      } else {
        print('⚠️ AudioHandler not available - background controls will not work');
      }
      
      // Additional delay to ensure audio handler is ready
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Set audio source (this will trigger lock screen controls via audio_service)
      // Retry logic with better error handling
      int retryCount = 0;
      const maxRetries = 3; // Reduced retries since we have better initialization
      bool sourceSet = false;
      String? lastError;
      
      while (!sourceSet && retryCount < maxRetries) {
        try {
          print('🎵 Attempting to set audio source (attempt ${retryCount + 1}/$maxRetries)...');
          print('🎵 Audio URI: ${audioUri.toString().substring(0, audioUri.toString().length > 100 ? 100 : audioUri.toString().length)}...');
          
          // Ensure audio handler is ready before setting source
          if (_audioHandler == null && retryCount == 0) {
            print('🎵 AudioHandler not ready, initializing...');
            await initializeAudioHandler();
            await Future.delayed(const Duration(milliseconds: 300));
          }
          
          // Stop any current playback before setting new source
          if (retryCount > 0) {
            try {
              await _audioPlayer.stop();
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (_) {}
          }
          
          await _audioPlayer.setAudioSource(audioSource);
          print('✅ Audio source set successfully');
          sourceSet = true;
        } catch (e, stackTrace) {
          lastError = e.toString();
          print('❌ Error setting audio source (attempt ${retryCount + 1}/$maxRetries): $e');
          
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
          
          if (isSourceError && retryCount < maxRetries - 1) {
            // For source errors, wait longer before retry
            retryCount++;
            final waitTime = 1000 * retryCount; // 1s, 2s, 3s
            print('⚠️ Source error detected, retrying in ${waitTime}ms...');
            await Future.delayed(Duration(milliseconds: waitTime));
          } else if (isInitError && retryCount < maxRetries - 1) {
            // For initialization errors, reinitialize
            retryCount++;
            final waitTime = 500 + (500 * retryCount);
            print('⚠️ Initialization error, reinitializing and retrying in ${waitTime}ms...');
            
            try {
              await _audioPlayer.stop();
              await Future.delayed(const Duration(milliseconds: 200));
              
              // Reinitialize audio handler if needed
              if (_audioHandler == null) {
                await initializeAudioHandler();
                await Future.delayed(const Duration(milliseconds: 300));
              }
            } catch (reinitError) {
              print('⚠️ Reinitialization error: $reinitError');
            }
            
            await Future.delayed(Duration(milliseconds: waitTime));
          } else {
            // Last attempt or unknown error
            print('❌ Failed to set audio source after $maxRetries attempts');
            print('❌ Final error: $e');
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
      
      // Start playing - use AudioHandler if available, otherwise use AudioPlayer directly
      print('▶️ Starting audio playback...');
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (_audioHandler != null) {
        // Use AudioHandler to play - this will show background controls
        await _audioHandler!.play();
        print('✅ Audio playback started via AudioHandler');
        print('🎵 Lock screen controls enabled via audio_service');
      } else {
        // Fallback to direct AudioPlayer if handler not available
        await _audioPlayer.play();
        print('✅ Audio playback started (no background controls - AudioHandler not available)');
      }
      
      print('🎵 Playing: ${item.displayTitle}');
    } catch (e) {
      print('❌ Error playing audio: $e');
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
          print('📥 Playing book from local file: $localAudioPath');
          print('📥 File size: ${await file.length()} bytes');
          final audioItem = AudioItem.fromBook(
            book,
            localAudioPath: localAudioPath,
          );
          await playItem(audioItem);
          return;
        } else {
          print('⚠️ Local file path exists in DB but file not found: $localAudioPath');
        }
      }
      
      // Fall back to network if no local file
      if (book.audioUrl == null || book.audioUrl!.isEmpty) {
        throw Exception('No audio URL available for this book');
      }
      
      // Build the full audio URL
      final fullAudioUrl = AudioItem._buildFullUrl(book.audioUrl);
      print('📥 Playing book from network');
      print('📥 Original audioUrl: ${book.audioUrl}');
      print('📥 Full audioUrl: $fullAudioUrl');
      
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
      print('📥 AudioItem created with URL: ${audioItem.audioUrl}');
      await playItem(audioItem);
    } catch (e, stackTrace) {
      print('❌ Error playing book: $e');
      print('❌ Stack trace: $stackTrace');
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
          print('📥 Playing podcast episode from local file: $localAudioPath');
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
          print('⚠️ Local file path exists in DB but file not found: $localAudioPath');
        }
      }
      
      // Fall back to network if no local file
      if (episode.audioUrl == null || episode.audioUrl!.isEmpty) {
        throw Exception('No audio URL available for this episode');
      }
      
      print('📥 Playing podcast episode from network: ${episode.audioUrl}');
      final audioItem = AudioItem.fromPodcastEpisode(episode, podcast: podcast);
      await playItem(audioItem);
    } catch (e, stackTrace) {
      print('❌ Error playing podcast episode: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
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
      // If not initialized, just update state
      if (!_isInitialized) {
        _state = AudioPlayerState.paused;
        notifyListeners();
        print('⏸️ Audio paused (service not initialized)');
        return;
      }
      
      // Use AudioHandler if available, otherwise use AudioPlayer directly
      if (_audioHandler != null) {
        await _audioHandler!.pause();
      } else {
        await _audioPlayer.pause();
      }
      
      _state = AudioPlayerState.paused;
      notifyListeners();
      print('⏸️ Audio paused');
    } catch (e, stackTrace) {
      print('❌ Error pausing audio: $e');
      print('❌ Stack trace: $stackTrace');
      // Update state even if pause fails
      _state = AudioPlayerState.paused;
      notifyListeners();
    }
  }

  // Resume audio
  Future<void> resume() async {
    try {
      // Ensure service is initialized before resuming
      if (!_isInitialized) {
        print('🎵 Service not initialized, initializing now...');
        await initialize();
      }
      
      // Check if there's a current item to resume
      if (_currentItem == null) {
        print('⚠️ No current audio item to resume');
        return;
      }
      
      // Use AudioHandler if available, otherwise use AudioPlayer directly
      if (_audioHandler != null) {
        await _audioHandler!.play();
      } else {
        await _audioPlayer.play();
      }
      
      _state = AudioPlayerState.playing;
      notifyListeners();
      print('▶️ Audio resumed');
    } catch (e, stackTrace) {
      print('❌ Error resuming audio: $e');
      print('❌ Stack trace: $stackTrace');
      
      // If it's an initialization error, try to reinitialize and retry
      if (e.toString().contains('_audioHandler') || e.toString().contains('not been initialized')) {
        print('⚠️ Audio handler not ready, attempting to reinitialize...');
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
          print('✅ Audio resumed after reinitialization');
        } catch (retryError) {
          print('❌ Failed to resume after reinitialization: $retryError');
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
        _state = AudioPlayerState.stopped;
        notifyListeners();
        print('⏹️ Audio stopped (service not initialized)');
        return;
      }
      
      await _audioPlayer.stop();
      _position = Duration.zero;
      _currentItem = null;
      _state = AudioPlayerState.stopped;
      notifyListeners();
      print('⏹️ Audio stopped');
    } catch (e, stackTrace) {
      print('❌ Error stopping audio: $e');
      print('❌ Stack trace: $stackTrace');
      // Reset state even if stop fails
      _position = Duration.zero;
      _currentItem = null;
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
        print('⏩ Position updated (service not initialized): ${position.inSeconds}s');
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
      print('⏩ Seeked to: ${position.inSeconds}s');
    } catch (e, stackTrace) {
      print('❌ Error seeking audio: $e');
      print('❌ Stack trace: $stackTrace');
      // Update position state even if seek fails
      _position = position;
      notifyListeners();
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
