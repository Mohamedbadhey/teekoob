import 'dart:async';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/player/services/audio_player_service.dart';

class AudioStateManager {
  static final AudioStateManager _instance = AudioStateManager._internal();
  factory AudioStateManager() => _instance;
  AudioStateManager._internal() {
    _audioPlayerService = AudioPlayerService();
    _setupStreams();
  }

  late final AudioPlayerService _audioPlayerService;
  Book? _currentBook;
  bool _isPlaying = false;

  // Stream controllers
  final _isPlayingController = StreamController<bool>.broadcast();
  final _currentBookController = StreamController<Book?>.broadcast();

  // Getters
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Book?> get currentBookStream => _currentBookController.stream;
  bool get isPlaying => _isPlaying;
  Book? get currentBook => _currentBook;
  AudioPlayerService get audioPlayerService => _audioPlayerService;

  void _setupStreams() {
    _audioPlayerService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      _isPlayingController.add(playing);
    });
  }

  Future<void> playBook(Book book) async {
    try {
      if (_currentBook?.id != book.id) {
        _currentBook = book;
        _currentBookController.add(book);
        await _audioPlayerService.loadAudioBook(book);
      }
      await _audioPlayerService.play();
    } catch (e) {
      print('Error playing book: $e');
      rethrow;
    }
  }

  Future<void> togglePlayPause(Book book) async {
    try {
      if (_currentBook?.id != book.id) {
        await playBook(book);
      } else {
        if (_isPlaying) {
          await _audioPlayerService.pause();
        } else {
          await _audioPlayerService.play();
        }
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayerService.pause();
    } catch (e) {
      print('Error pausing: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayerService.stop();
      _currentBook = null;
      _currentBookController.add(null);
    } catch (e) {
      print('Error stopping: $e');
      rethrow;
    }
  }

  void dispose() {
    _isPlayingController.close();
    _currentBookController.close();
    _audioPlayerService.dispose();
  }
}
