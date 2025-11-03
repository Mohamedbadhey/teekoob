import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async' show Timer;

/// Simple AudioHandler for background playback using just_audio
class TeekoobAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  TeekoobAudioHandler(this._player) {
    // Initialize playback state with default values to ensure notification shows
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
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));
    
    // Listen to player state changes and update playback state
    _playbackSubscription = _player.playbackEventStream.listen((event) {
      final newState = _transformState(event);
      playbackState.add(newState);
      // Log for debugging
      if (event.processingState == ProcessingState.ready && _player.playing) {
        print('🎵 AudioHandler: Playback started, updating notification');
      }
    });
    
    // Also listen to player state for processing state updates
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final newState = _transformStateFromState(state);
      playbackState.add(newState);
    });
    
    // Listen to position stream to update notification position more frequently
    _positionSubscription = _player.positionStream.listen((position) {
      final currentState = playbackState.value;
      if (currentState.playing || currentState.processingState == AudioProcessingState.buffering) {
        playbackState.add(currentState.copyWith(
          updatePosition: position,
          bufferedPosition: _player.bufferedPosition,
        ));
      }
    });
  }

  // Method to update media item
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  PlaybackState _transformState(PlaybackEvent event) {
    final currentState = playbackState.value;
    return currentState.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  PlaybackState _transformStateFromState(PlayerState state) {
    final currentState = playbackState.value;
    return currentState.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[state.processingState] ?? AudioProcessingState.idle,
      playing: state.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

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
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
  
  void dispose() {
    _playbackSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    // Note: Don't dispose _player here as it's managed by GlobalAudioPlayerService
  }
}

