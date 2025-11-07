import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Enhanced AudioHandler for background playback with professional media controls
/// This handler ensures media controls work even when the app is closed or minimized
class TeekoobAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  Timer? _positionUpdateTimer;

  TeekoobAudioHandler(this._player) {
    print('[AUDIO HANDLER DEBUG] ✅ TeekoobAudioHandler created');
    // Initialize playback state with default values to ensure notification shows immediately
    // This ensures the notification appears as soon as MediaItem is set
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2], // Show controls in compact notification
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      queueIndex: null, // Will be set when MediaItem is added
    ));
    print('[AUDIO HANDLER DEBUG] ✅ Initial playback state set - notification ready to display');
    
    // Listen to player state changes and update playback state
    print('[AUDIO HANDLER DEBUG] Setting up playback event stream listener...');
    _playbackSubscription = _player.playbackEventStream.listen((event) {
      print('[AUDIO HANDLER DEBUG] Playback event: ${event.processingState}, playing: ${_player.playing}');
      
      // DON'T show immediate error on idle state
      // Large audio files take time to load (especially from remote URLs)
      // Let the audio player's own error handling take care of actual errors
      // The idle state is normal during initial loading phase
      
      final newState = _transformState(event);
      playbackState.add(newState);
      if (event.processingState == ProcessingState.ready && _player.playing) {
        print('[AUDIO HANDLER DEBUG] Starting position updates');
        _startPositionUpdates();
      } else if (event.processingState == ProcessingState.idle || 
                 event.processingState == ProcessingState.completed) {
        print('[AUDIO HANDLER DEBUG] Stopping position updates');
        _stopPositionUpdates();
      }
    });
    
    // Listen to player state for processing state updates (like Spotify)
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final newState = _transformStateFromState(state);
      playbackState.add(newState);
      
      // Start/stop position updates based on playing state
      if (state.playing && state.processingState == ProcessingState.ready) {
        _startPositionUpdates();
      } else if (!state.playing || state.processingState == ProcessingState.idle) {
        _stopPositionUpdates();
      }
    });
    
    // Listen to duration changes and update MediaItem (critical for notification progress bar)
    // This ensures the notification shows the full duration once audio loads (like Spotify)
    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null && duration != Duration.zero && mediaItem.value != null) {
        final currentItem = mediaItem.value!;
        // Only update if duration changed (avoid unnecessary updates)
        if (currentItem.duration != duration) {
          print('[AUDIO HANDLER DEBUG] ✅ Duration updated: $duration');
          final updatedItem = currentItem.copyWith(duration: duration);
          mediaItem.add(updatedItem);
          queue.value = [updatedItem]; // Update queue too
          print('[AUDIO HANDLER DEBUG] ✅ MediaItem updated with duration - notification progress bar will show full duration');
        }
      }
    });
    
    // Listen to position stream to update notification position in real-time (like Spotify)
    // This ensures smooth progress bar updates in the notification
    _positionSubscription = _player.positionStream.listen((position) {
      final currentState = playbackState.value;
      // Update position whenever audio is ready, playing, or buffering
      // This keeps the notification progress bar in sync with playback
      if (currentState.processingState == AudioProcessingState.ready ||
          currentState.processingState == AudioProcessingState.buffering ||
          currentState.playing) {
        playbackState.add(currentState.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
        ));
      }
    });
  }

  // Start periodic position updates for smooth notification progress bar (like Spotify)
  // Updates every second to keep notification in perfect sync
  void _startPositionUpdates() {
    _stopPositionUpdates(); // Cancel any existing timer
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = playbackState.value;
      // Update position continuously while playing or buffering
      // This ensures the progress bar in notification moves smoothly
      if (_player.playing || 
          _player.processingState == ProcessingState.buffering ||
          currentState.processingState == AudioProcessingState.ready) {
        playbackState.add(currentState.copyWith(
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
        ));
      } else {
        // Stop updates when not playing
        timer.cancel();
      }
    });
  }

  // Stop position updates
  void _stopPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
  }

  // Method to update media item - ensures notification shows properly
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    print('[AUDIO HANDLER DEBUG] ✅ updateMediaItem() called');
    print('[AUDIO HANDLER DEBUG] MediaItem ID: ${item.id}');
    print('[AUDIO HANDLER DEBUG] MediaItem Title: ${item.title}');
    print('[AUDIO HANDLER DEBUG] MediaItem Artist: ${item.artist ?? "N/A"}');
    print('[AUDIO HANDLER DEBUG] MediaItem Album: ${item.album ?? "N/A"}');
    print('[AUDIO HANDLER DEBUG] MediaItem Art URI: ${item.artUri}');
    print('[AUDIO HANDLER DEBUG] MediaItem Duration: ${item.duration}');
    
    // CRITICAL: Set the queue FIRST before setting mediaItem
    // This ensures the notification has all the context it needs
    queue.value = [item];
    print('[AUDIO HANDLER DEBUG] ✅ Queue set with 1 item');
    
    // Set the media item - this triggers notification update
    mediaItem.add(item);
    print('[AUDIO HANDLER DEBUG] ✅ MediaItem added to stream');
    
    // Update playback state with queue index and ensure notification is visible
    // Setting queueIndex tells the system this is the current playing item
    final currentState = playbackState.value;
    playbackState.add(currentState.copyWith(
      queueIndex: 0,
      // Ensure notification shows even if not playing yet
      processingState: currentState.processingState == AudioProcessingState.idle
          ? AudioProcessingState.loading
          : currentState.processingState,
    ));
    print('[AUDIO HANDLER DEBUG] ✅ Queue index set to 0, playback state updated');
    print('[AUDIO HANDLER DEBUG] ✅ Notification should now be visible with all metadata');
  }

  PlaybackState _transformState(PlaybackEvent event) {
    final currentState = playbackState.value;
    final newProcessingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState] ?? AudioProcessingState.idle;
    
    // Update playback state with current player state (like Spotify)
    // This keeps notification controls and progress in perfect sync
    return currentState.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: newProcessingState,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queue.value.isNotEmpty ? 0 : null,
    );
  }

  PlaybackState _transformStateFromState(PlayerState state) {
    final currentState = playbackState.value;
    final newProcessingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[state.processingState] ?? AudioProcessingState.idle;
    
    // Update playback state from player state (like Spotify)
    // Ensures notification reflects exact player state
    return currentState.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: newProcessingState,
      playing: state.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queue.value.isNotEmpty ? 0 : null,
    );
  }

  /// Update MediaItem with error state - shows error in notification/lock screen
  /// Professional apps like Spotify/YouTube Music show errors in the artist field (which acts as subtitle)
  Future<void> updateMediaItemWithError(String errorMessage) async {
    print('[AUDIO HANDLER DEBUG] updateMediaItemWithError() called: $errorMessage');
    final currentItem = mediaItem.value;
    if (currentItem != null) {
      // Update MediaItem with error in artist field - this shows prominently in notification/lock screen
      // Format: "Original Artist • Error: [message]"
      final originalArtist = currentItem.artist ?? currentItem.album ?? '';
      final errorArtist = originalArtist.isNotEmpty 
          ? '$originalArtist • Error: $errorMessage'
          : 'Error: $errorMessage';
      
      final errorMediaItem = currentItem.copyWith(
        artist: errorArtist,
        // Add error to extras for tracking
        extras: {
          ...?currentItem.extras,
          'error': errorMessage,
          'hasError': true,
          'originalArtist': originalArtist, // Store original for recovery
        },
      );
      mediaItem.add(errorMediaItem);
      print('[AUDIO HANDLER DEBUG] MediaItem updated with error - will show in notification/lock screen');
      
      // Update playback state to show error - this updates the notification
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
    }
  }

  @override
  Future<void> play() async {
    print('[AUDIO HANDLER DEBUG] play() called');
    try {
      await _player.play();
      print('[AUDIO HANDLER DEBUG] Player.play() completed');
      // Ensure playback state is updated immediately
      playbackState.add(_transformStateFromState(_player.playerState));
      print('[AUDIO HANDLER DEBUG] Playback state updated');
    } catch (e) {
      print('[AUDIO HANDLER DEBUG] ERROR in play(): $e');
      // Update MediaItem with error - this will show in notification/lock screen
      final errorMessage = _getUserFriendlyErrorMessage(e);
      await updateMediaItemWithError(errorMessage);
      rethrow;
    }
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

  @override
  Future<void> pause() async {
    print('[AUDIO HANDLER DEBUG] pause() called');
    try {
      await _player.pause();
      print('[AUDIO HANDLER DEBUG] Player.pause() completed');
      // Ensure playback state is updated immediately
      playbackState.add(_transformStateFromState(_player.playerState));
      print('[AUDIO HANDLER DEBUG] Playback state updated');
    } catch (e) {
      print('[AUDIO HANDLER DEBUG] ERROR in pause(): $e');
      // Update MediaItem with error
      final errorMessage = _getUserFriendlyErrorMessage(e);
      await updateMediaItemWithError(errorMessage);
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    // Update position immediately
    final currentState = playbackState.value;
    playbackState.add(currentState.copyWith(updatePosition: position));
  }

  @override
  Future<void> skipToNext() async {
    final duration = _player.duration ?? Duration.zero;
    final position = _player.position;
    final newPosition = position + const Duration(seconds: 30);
    await _player.seek(newPosition < duration ? newPosition : duration);
  }

  @override
  Future<void> skipToPrevious() async {
    final position = _player.position;
    final newPosition = position - const Duration(seconds: 10);
    await _player.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  @override
  Future<void> stop() async {
    _stopPositionUpdates();
    await _player.stop();
    // Update playback state to stopped
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      updatePosition: Duration.zero,
    ));
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    print('[AUDIO HANDLER DEBUG] onTaskRemoved() called - keeping playback alive');
    // Don't stop playback when task is removed - keep playing in background
    // This ensures media controls continue to work even when app is swiped away
  }
  
  void dispose() {
    _stopPositionUpdates();
    _playbackSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    // Note: Don't dispose _player here as it's managed by GlobalAudioPlayerService
  }
}

