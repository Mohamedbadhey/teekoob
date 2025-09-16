import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/player/services/audio_player_service.dart';

// Events
abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAudioBook extends AudioPlayerEvent {
  final Book book;
  final String? audioUrl;

  const LoadAudioBook(this.book, {this.audioUrl});

  @override
  List<Object?> get props => [book, audioUrl];
}

class PlayAudio extends AudioPlayerEvent {
  const PlayAudio();
}

class PauseAudio extends AudioPlayerEvent {
  const PauseAudio();
}

class StopAudio extends AudioPlayerEvent {
  const StopAudio();
}

class SeekToPosition extends AudioPlayerEvent {
  final Duration position;

  const SeekToPosition(this.position);

  @override
  List<Object> get props => [position];
}

class SkipForward extends AudioPlayerEvent {
  final Duration duration;

  const SkipForward(this.duration);

  @override
  List<Object> get props => [duration];
}

class SkipBackward extends AudioPlayerEvent {
  final Duration duration;

  const SkipBackward(this.duration);

  @override
  List<Object> get props => [duration];
}

class SetPlaybackSpeed extends AudioPlayerEvent {
  final double speed;

  const SetPlaybackSpeed(this.speed);

  @override
  List<Object> get props => [speed];
}

class ToggleShuffle extends AudioPlayerEvent {
  const ToggleShuffle();
}

class ToggleRepeat extends AudioPlayerEvent {
  const ToggleRepeat();
}

class SetVolume extends AudioPlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object> get props => [volume];
}

class SetSleepTimer extends AudioPlayerEvent {
  final Duration duration;

  const SetSleepTimer(this.duration);

  @override
  List<Object> get props => [duration];
}

class ClearSleepTimer extends AudioPlayerEvent {
  const ClearSleepTimer();
}

class JumpToChapter extends AudioPlayerEvent {
  final int chapter;

  const JumpToChapter(this.chapter);

  @override
  List<Object> get props => [chapter];
}

class ResetPlayer extends AudioPlayerEvent {
  const ResetPlayer();
}

// States
abstract class AudioPlayerState extends Equatable {
  const AudioPlayerState();

  @override
  List<Object?> get props => [];
}

class AudioPlayerInitial extends AudioPlayerState {
  const AudioPlayerInitial();
}

class AudioPlayerLoading extends AudioPlayerState {
  const AudioPlayerLoading();
}

class AudioPlayerReady extends AudioPlayerState {
  final Book book;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final bool isShuffled;
  final bool isRepeated;
  final Duration? sleepTimerDuration;
  final int currentChapter;
  final int totalChapters;

  const AudioPlayerReady({
    required this.book,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.playbackSpeed,
    required this.isShuffled,
    required this.isRepeated,
    this.sleepTimerDuration,
    required this.currentChapter,
    required this.totalChapters,
  });

  @override
  List<Object?> get props => [
    book,
    isPlaying,
    currentPosition,
    totalDuration,
    playbackSpeed,
    isShuffled,
    isRepeated,
    sleepTimerDuration,
    currentChapter,
    totalChapters,
  ];

  AudioPlayerReady copyWith({
    Book? book,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    bool? isShuffled,
    bool? isRepeated,
    Duration? sleepTimerDuration,
    int? currentChapter,
    int? totalChapters,
  }) {
    return AudioPlayerReady(
      book: book ?? this.book,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isShuffled: isShuffled ?? this.isShuffled,
      isRepeated: isRepeated ?? this.isRepeated,
      sleepTimerDuration: sleepTimerDuration ?? this.sleepTimerDuration,
      currentChapter: currentChapter ?? this.currentChapter,
      totalChapters: totalChapters ?? this.totalChapters,
    );
  }
}

class AudioPlayerError extends AudioPlayerState {
  final String message;

  const AudioPlayerError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayerService _audioPlayerService;

  AudioPlayerBloc({required AudioPlayerService audioPlayerService})
      : _audioPlayerService = audioPlayerService,
        super(const AudioPlayerInitial()) {
    on<LoadAudioBook>(_onLoadAudioBook);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SeekToPosition>(_onSeekToPosition);
    on<SkipForward>(_onSkipForward);
    on<SkipBackward>(_onSkipBackward);
    on<SetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<ToggleShuffle>(_onToggleShuffle);
    on<ToggleRepeat>(_onToggleRepeat);
    on<SetVolume>(_onSetVolume);
    on<SetSleepTimer>(_onSetSleepTimer);
    on<ClearSleepTimer>(_onClearSleepTimer);
    on<JumpToChapter>(_onJumpToChapter);
    on<ResetPlayer>(_onResetPlayer);

    // Listen to audio player service streams
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    // Listen to playing state changes
    _audioPlayerService.isPlayingStream.listen((isPlaying) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(isPlaying: isPlaying));
      }
    });

    // Listen to position changes
    _audioPlayerService.positionStream.listen((position) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(currentPosition: position));
      }
    });

    // Listen to duration changes
    _audioPlayerService.durationStream.listen((duration) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(totalDuration: duration));
      }
    });

    // Listen to speed changes
    _audioPlayerService.speedStream.listen((speed) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(playbackSpeed: speed));
      }
    });

    // Listen to shuffle changes
    _audioPlayerService.shuffleStream.listen((isShuffled) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(isShuffled: isShuffled));
      }
    });

    // Listen to repeat changes
    _audioPlayerService.repeatStream.listen((isRepeated) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(isRepeated: isRepeated));
      }
    });

    // Listen to sleep timer changes
    _audioPlayerService.sleepTimerStream.listen((sleepTimerDuration) {
      if (state is AudioPlayerReady) {
        final currentState = state as AudioPlayerReady;
        emit(currentState.copyWith(sleepTimerDuration: sleepTimerDuration));
      }
    });
  }

  Future<void> _onLoadAudioBook(
    LoadAudioBook event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      emit(const AudioPlayerLoading());

      await _audioPlayerService.loadAudioBook(event.book, audioUrl: event.audioUrl);

      emit(AudioPlayerReady(
        book: event.book,
        isPlaying: _audioPlayerService.isPlaying,
        currentPosition: _audioPlayerService.currentPosition,
        totalDuration: _audioPlayerService.totalDuration,
        playbackSpeed: _audioPlayerService.playbackSpeed,
        isShuffled: _audioPlayerService.isShuffled,
        isRepeated: _audioPlayerService.isRepeated,
        sleepTimerDuration: _audioPlayerService.sleepTimerDuration,
        currentChapter: _audioPlayerService.currentChapter,
        totalChapters: _audioPlayerService.totalChapters,
      ));
    } catch (e) {
      emit(AudioPlayerError('Failed to load audio book: $e'));
    }
  }

  Future<void> _onPlayAudio(
    PlayAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.play();
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to play audio: $e'));
    }
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.pause();
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to pause audio: $e'));
    }
  }

  Future<void> _onStopAudio(
    StopAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.stop();
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to stop audio: $e'));
    }
  }

  Future<void> _onSeekToPosition(
    SeekToPosition event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.seekTo(event.position);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to seek to position: $e'));
    }
  }

  Future<void> _onSkipForward(
    SkipForward event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.skipForward(event.duration);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to skip forward: $e'));
    }
  }

  Future<void> _onSkipBackward(
    SkipBackward event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.skipBackward(event.duration);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to skip backward: $e'));
    }
  }

  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeed event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.setPlaybackSpeed(event.speed);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to set playback speed: $e'));
    }
  }

  Future<void> _onToggleShuffle(
    ToggleShuffle event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.toggleShuffle();
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to toggle shuffle: $e'));
    }
  }

  Future<void> _onToggleRepeat(
    ToggleRepeat event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.toggleRepeat();
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to toggle repeat: $e'));
    }
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.setVolume(event.volume);
      // Volume changes don't affect the main state
    } catch (e) {
      emit(AudioPlayerError('Failed to set volume: $e'));
    }
  }

  Future<void> _onSetSleepTimer(
    SetSleepTimer event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      _audioPlayerService.setSleepTimer(event.duration);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to set sleep timer: $e'));
    }
  }

  Future<void> _onClearSleepTimer(
    ClearSleepTimer event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      // The service will clear the timer internally
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to clear sleep timer: $e'));
    }
  }

  Future<void> _onJumpToChapter(
    JumpToChapter event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await _audioPlayerService.jumpToChapter(event.chapter);
      // State will be updated via stream listener
    } catch (e) {
      emit(AudioPlayerError('Failed to jump to chapter: $e'));
    }
  }

  Future<void> _onResetPlayer(
    ResetPlayer event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      _audioPlayerService.reset();
      emit(const AudioPlayerInitial());
    } catch (e) {
      emit(AudioPlayerError('Failed to reset player: $e'));
    }
  }

  // Helper methods for UI
  String get currentTimeString {
    if (state is AudioPlayerReady) {
      final currentState = state as AudioPlayerReady;
      return _audioPlayerService.formatTime(currentState.currentPosition);
    }
    return '00:00';
  }

  String get totalTimeString {
    if (state is AudioPlayerReady) {
      final currentState = state as AudioPlayerReady;
      return _audioPlayerService.formatTime(currentState.totalDuration);
    }
    return '00:00';
  }

  String get remainingTimeString {
    if (state is AudioPlayerReady) {
      final currentState = state as AudioPlayerReady;
      return _audioPlayerService.formatTime(
        currentState.totalDuration - currentState.currentPosition,
      );
    }
    return '00:00';
  }

  double get progressPercentage {
    if (state is AudioPlayerReady) {
      final currentState = state as AudioPlayerReady;
      if (currentState.totalDuration == Duration.zero) return 0.0;
      return currentState.currentPosition.inMilliseconds / 
             currentState.totalDuration.inMilliseconds;
    }
    return 0.0;
  }

  bool get isAudioLoaded {
    if (state is AudioPlayerReady) {
      final currentState = state as AudioPlayerReady;
      return currentState.totalDuration > Duration.zero;
    }
    return false;
  }

  @override
  Future<void> close() {
    _audioPlayerService.dispose();
    return super.close();
  }
}
