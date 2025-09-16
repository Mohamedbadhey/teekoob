import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/library/services/library_service.dart';

// Events
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {
  final String userId;

  const LoadLibrary(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddBookToLibrary extends LibraryEvent {
  final String userId;
  final String bookId;
  final String? status;
  final double? progress;

  const AddBookToLibrary(
    this.userId,
    this.bookId, {
    this.status,
    this.progress,
  });

  @override
  List<Object?> get props => [userId, bookId, status, progress];
}

class RemoveBookFromLibrary extends LibraryEvent {
  final String userId;
  final String bookId;

  const RemoveBookFromLibrary(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class UpdateReadingProgress extends LibraryEvent {
  final String userId;
  final String bookId;
  final double progress;

  const UpdateReadingProgress(this.userId, this.bookId, this.progress);

  @override
  List<Object> get props => [userId, bookId, progress];
}

class UpdateBookStatus extends LibraryEvent {
  final String userId;
  final String bookId;
  final String status;

  const UpdateBookStatus(this.userId, this.bookId, this.status);

  @override
  List<Object> get props => [userId, bookId, status];
}

class ToggleFavorite extends LibraryEvent {
  final String userId;
  final String bookId;

  const ToggleFavorite(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class AddBookmark extends LibraryEvent {
  final String userId;
  final String bookId;
  final String title;
  final String description;
  final int page;
  final String? note;

  const AddBookmark(
    this.userId,
    this.bookId, {
    required this.title,
    required this.description,
    required this.page,
    this.note,
  });

  @override
  List<Object?> get props => [userId, bookId, title, description, page, note];
}

class RemoveBookmark extends LibraryEvent {
  final String userId;
  final String bookId;
  final String bookmarkId;

  const RemoveBookmark(this.userId, this.bookId, this.bookmarkId);

  @override
  List<Object> get props => [userId, bookId, bookmarkId];
}

class AddNote extends LibraryEvent {
  final String userId;
  final String bookId;
  final String content;
  final int? page;
  final String? chapter;

  const AddNote(
    this.userId,
    this.bookId, {
    required this.content,
    this.page,
    this.chapter,
  });

  @override
  List<Object?> get props => [userId, bookId, content, page, chapter];
}

class AddHighlight extends LibraryEvent {
  final String userId;
  final String bookId;
  final String text;
  final int startPage;
  final int endPage;
  final String? color;
  final String? note;

  const AddHighlight(
    this.userId,
    this.bookId, {
    required this.text,
    required this.startPage,
    required this.endPage,
    this.color,
    this.note,
  });

  @override
  List<Object?> get props => [userId, bookId, text, startPage, endPage, color, note];
}

class RemoveHighlight extends LibraryEvent {
  final String userId;
  final String bookId;
  final String highlightId;

  const RemoveHighlight(this.userId, this.bookId, this.highlightId);

  @override
  List<Object> get props => [userId, bookId, highlightId];
}

class SearchLibrary extends LibraryEvent {
  final String userId;
  final String query;

  const SearchLibrary(this.userId, this.query);

  @override
  List<Object> get props => [userId, query];
}

class SyncLibrary extends LibraryEvent {
  final String userId;

  const SyncLibrary(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadReadingStats extends LibraryEvent {
  final String userId;

  const LoadReadingStats(this.userId);

  @override
  List<Object> get props => [userId];
}

// States
abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  final List<Map<String, dynamic>> library;
  final List<Map<String, dynamic>> favorites;
  final List<Map<String, dynamic>> recentlyRead;
  final Map<String, dynamic> stats;

  const LibraryLoaded({
    required this.library,
    required this.favorites,
    required this.recentlyRead,
    required this.stats,
  });

  @override
  List<Object?> get props => [library, favorites, recentlyRead, stats];
}

class LibrarySearchResults extends LibraryState {
  final List<Map<String, dynamic>> results;
  final String query;

  const LibrarySearchResults({
    required this.results,
    required this.query,
  });

  @override
  List<Object> get props => [results, query];
}

class LibraryOperationSuccess extends LibraryState {
  final String message;
  final String operation;

  const LibraryOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object> get props => [message, operation];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryService _libraryService;

  LibraryBloc({required LibraryService libraryService})
      : _libraryService = libraryService,
        super(const LibraryInitial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<AddBookToLibrary>(_onAddBookToLibrary);
    on<RemoveBookFromLibrary>(_onRemoveBookFromLibrary);
    on<UpdateReadingProgress>(_onUpdateReadingProgress);
    on<UpdateBookStatus>(_onUpdateBookStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<AddBookmark>(_onAddBookmark);
    on<RemoveBookmark>(_onRemoveBookmark);
    on<AddNote>(_onAddNote);
    on<AddHighlight>(_onAddHighlight);
    on<RemoveHighlight>(_onRemoveHighlight);
    on<SearchLibrary>(_onSearchLibrary);
    on<SyncLibrary>(_onSyncLibrary);
    on<LoadReadingStats>(_onLoadReadingStats);
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      print('🎯 LibraryBloc: _onLoadLibrary called with userId: ${event.userId}');
      print('🎯 LibraryBloc: Emitting LibraryLoading state');
      emit(const LibraryLoading());

      print('🎯 LibraryBloc: Calling _libraryService.getUserLibrary...');
      final library = _libraryService.getUserLibrary(event.userId);
      print('🎯 LibraryBloc: Library items retrieved: ${library.length}');

      print('🎯 LibraryBloc: Calling _libraryService.getFavoriteBooks...');
      final favorites = _libraryService.getFavoriteBooks(event.userId);
      print('🎯 LibraryBloc: Favorite books retrieved: ${favorites.length}');

      print('🎯 LibraryBloc: Calling _libraryService.getRecentlyReadBooks...');
      final recentlyRead = _libraryService.getRecentlyReadBooks(event.userId);
      print('🎯 LibraryBloc: Recently read books retrieved: ${recentlyRead.length}');

      print('🎯 LibraryBloc: Calling _libraryService.getReadingStats...');
      final stats = _libraryService.getReadingStats(event.userId);
      print('🎯 LibraryBloc: Reading stats retrieved: $stats');

      print('🎯 LibraryBloc: Emitting LibraryLoaded state');
      emit(LibraryLoaded(
        library: library,
        favorites: favorites,
        recentlyRead: recentlyRead,
        stats: stats,
      ));

      print('🎯 LibraryBloc: LibraryLoaded state emitted successfully');
    } catch (e) {
      print('❌ LibraryBloc: Error loading library: $e');
      print('❌ LibraryBloc: Emitting LibraryError state');
      emit(LibraryError('Failed to load library: $e'));
    }
  }

  Future<void> _onAddBookToLibrary(
    AddBookToLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.addBookToLibrary(
        event.userId,
        event.bookId,
        status: event.status,
        progress: event.progress,
      );

      emit(const LibraryOperationSuccess(
        message: 'Book added to library successfully',
        operation: 'add',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to add book to library: $e'));
    }
  }

  Future<void> _onRemoveBookFromLibrary(
    RemoveBookFromLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.removeBookFromLibrary(event.userId, event.bookId);

      emit(const LibraryOperationSuccess(
        message: 'Book removed from library successfully',
        operation: 'remove',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to remove book from library: $e'));
    }
  }

  Future<void> _onUpdateReadingProgress(
    UpdateReadingProgress event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.updateReadingProgress(
        event.userId,
        event.bookId,
        event.progress,
      );

      emit(const LibraryOperationSuccess(
        message: 'Reading progress updated successfully',
        operation: 'progress',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to update reading progress: $e'));
    }
  }

  Future<void> _onUpdateBookStatus(
    UpdateBookStatus event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.updateBookStatus(
        event.userId,
        event.bookId,
        event.status,
      );

      emit(const LibraryOperationSuccess(
        message: 'Book status updated successfully',
        operation: 'status',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to update book status: $e'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.toggleFavorite(event.userId, event.bookId);

      emit(const LibraryOperationSuccess(
        message: 'Favorite status updated successfully',
        operation: 'favorite',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onAddBookmark(
    AddBookmark event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.addBookmark(
        event.userId,
        event.bookId,
        title: event.title,
        description: event.description,
        page: event.page,
        note: event.note,
      );

      emit(const LibraryOperationSuccess(
        message: 'Bookmark added successfully',
        operation: 'bookmark',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to add bookmark: $e'));
    }
  }

  Future<void> _onRemoveBookmark(
    RemoveBookmark event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.removeBookmark(
        event.userId,
        event.bookId,
        event.bookmarkId,
      );

      emit(const LibraryOperationSuccess(
        message: 'Bookmark removed successfully',
        operation: 'bookmark_remove',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to remove bookmark: $e'));
    }
  }

  Future<void> _onAddNote(
    AddNote event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.addNote(
        event.userId,
        event.bookId,
        content: event.content,
        page: event.page,
        chapter: event.chapter,
      );

      emit(const LibraryOperationSuccess(
        message: 'Note added successfully',
        operation: 'note',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to add note: $e'));
    }
  }

  Future<void> _onAddHighlight(
    AddHighlight event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.addHighlight(
        event.userId,
        event.bookId,
        text: event.text,
        startPage: event.startPage,
        endPage: event.endPage,
        color: event.color,
        note: event.note,
      );

      emit(const LibraryOperationSuccess(
        message: 'Highlight added successfully',
        operation: 'highlight',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to add highlight: $e'));
    }
  }

  Future<void> _onRemoveHighlight(
    RemoveHighlight event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _libraryService.removeHighlight(
        event.userId,
        event.bookId,
        event.highlightId,
      );

      emit(const LibraryOperationSuccess(
        message: 'Highlight removed successfully',
        operation: 'highlight_remove',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to remove highlight: $e'));
    }
  }

  Future<void> _onSearchLibrary(
    SearchLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final results = _libraryService.searchLibraryItems(event.userId, event.query);

      emit(LibrarySearchResults(
        results: results,
        query: event.query,
      ));
    } catch (e) {
      emit(LibraryError('Failed to search library: $e'));
    }
  }

  Future<void> _onSyncLibrary(
    SyncLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      emit(const LibraryLoading());

      await _libraryService.syncLibrary(event.userId);

      emit(const LibraryOperationSuccess(
        message: 'Library synced successfully',
        operation: 'sync',
      ));

      // Reload library
      add(LoadLibrary(event.userId));
    } catch (e) {
      emit(LibraryError('Failed to sync library: $e'));
    }
  }

  Future<void> _onLoadReadingStats(
    LoadReadingStats event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final stats = _libraryService.getReadingStats(event.userId);

      // For now, we'll just emit the current state if it's loaded
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        emit(LibraryLoaded(
          library: currentState.library,
          favorites: currentState.favorites,
          recentlyRead: currentState.recentlyRead,
          stats: stats,
        ));
      }
    } catch (e) {
      emit(LibraryError('Failed to load reading stats: $e'));
    }
  }

  // Public method to fetch book by ID
  Future<Book?> fetchBookById(String bookId) async {
    return await _libraryService.fetchBookById(bookId);
  }

  // Public method to fetch multiple books by IDs
  Future<List<Book>> fetchBooksByIds(List<String> bookIds) async {
    return await _libraryService.fetchBooksByIds(bookIds);
  }
}
