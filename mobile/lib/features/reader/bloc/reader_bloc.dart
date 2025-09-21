import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/reader/services/reader_service.dart';

// Events
abstract class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookContent extends ReaderEvent {
  final Book book;

  const LoadBookContent(this.book);

  @override
  List<Object> get props => [book];
}

class LoadReadingPosition extends ReaderEvent {
  final String userId;
  final String bookId;

  const LoadReadingPosition(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class LoadReadingPreferences extends ReaderEvent {
  final String userId;

  const LoadReadingPreferences(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadBookmarks extends ReaderEvent {
  final String userId;
  final String bookId;

  const LoadBookmarks(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class LoadNotes extends ReaderEvent {
  final String userId;
  final String bookId;

  const LoadNotes(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class LoadHighlights extends ReaderEvent {
  final String userId;
  final String bookId;

  const LoadHighlights(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class UpdateReadingProgress extends ReaderEvent {
  final String userId;
  final String bookId;
  final double progress;

  const UpdateReadingProgress(this.userId, this.bookId, this.progress);

  @override
  List<Object> get props => [userId, bookId, progress];
}

class AddBookmark extends ReaderEvent {
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

class RemoveBookmark extends ReaderEvent {
  final String userId;
  final String bookId;
  final String bookmarkId;

  const RemoveBookmark(this.userId, this.bookId, this.bookmarkId);

  @override
  List<Object> get props => [userId, bookId, bookmarkId];
}

class AddNote extends ReaderEvent {
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

class UpdateNote extends ReaderEvent {
  final String userId;
  final String bookId;
  final int noteIndex;
  final String newContent;

  const UpdateNote(
    this.userId,
    this.bookId,
    this.noteIndex,
    this.newContent,
  );

  @override
  List<Object> get props => [userId, bookId, noteIndex, newContent];
}

class RemoveNote extends ReaderEvent {
  final String userId;
  final String bookId;
  final int noteIndex;

  const RemoveNote(this.userId, this.bookId, this.noteIndex);

  @override
  List<Object> get props => [userId, bookId, noteIndex];
}

class AddHighlight extends ReaderEvent {
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

class RemoveHighlight extends ReaderEvent {
  final String userId;
  final String bookId;
  final String highlightId;

  const RemoveHighlight(this.userId, this.bookId, this.highlightId);

  @override
  List<Object> get props => [userId, bookId, highlightId];
}

class UpdateReadingPreferences extends ReaderEvent {
  final String userId;
  final Map<String, dynamic> preferences;

  const UpdateReadingPreferences(this.userId, this.preferences);

  @override
  List<Object> get props => [userId, preferences];
}

class SaveReadingPosition extends ReaderEvent {
  final String userId;
  final String bookId;
  final double position;

  const SaveReadingPosition(this.userId, this.bookId, this.position);

  @override
  List<Object> get props => [userId, bookId, position];
}

class GetBookStatistics extends ReaderEvent {
  final String userId;
  final String bookId;

  const GetBookStatistics(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class SearchInBook extends ReaderEvent {
  final String userId;
  final String bookId;
  final String query;

  const SearchInBook(this.userId, this.bookId, this.query);

  @override
  List<Object> get props => [userId, bookId, query];
}

class ExportBookData extends ReaderEvent {
  final String userId;
  final String bookId;

  const ExportBookData(this.userId, this.bookId);

  @override
  List<Object> get props => [userId, bookId];
}

class ImportBookData extends ReaderEvent {
  final String userId;
  final String bookId;
  final Map<String, dynamic> data;

  const ImportBookData(this.userId, this.bookId, this.data);

  @override
  List<Object> get props => [userId, bookId, data];
}

// States
abstract class ReaderState extends Equatable {
  const ReaderState();

  @override
  List<Object?> get props => [];
}

class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

class ReaderReady extends ReaderState {
  final Book book;
  final String? content;
  final double readingPosition;
  final Map<String, dynamic> preferences;
  final List<Map<String, dynamic>> bookmarks;
  final List<String> notes;
  final List<Map<String, dynamic>> highlights;
  final Map<String, dynamic> statistics;

  const ReaderReady({
    required this.book,
    this.content,
    required this.readingPosition,
    required this.preferences,
    required this.bookmarks,
    required this.notes,
    required this.highlights,
    required this.statistics,
  });

  @override
  List<Object?> get props => [
    book,
    content,
    readingPosition,
    preferences,
    bookmarks,
    notes,
    highlights,
    statistics,
  ];

  ReaderReady copyWith({
    Book? book,
    String? content,
    double? readingPosition,
    Map<String, dynamic>? preferences,
    List<Map<String, dynamic>>? bookmarks,
    List<String>? notes,
    List<Map<String, dynamic>>? highlights,
    Map<String, dynamic>? statistics,
  }) {
    return ReaderReady(
      book: book ?? this.book,
      content: content ?? this.content,
      readingPosition: readingPosition ?? this.readingPosition,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
      notes: notes ?? this.notes,
      highlights: highlights ?? this.highlights,
      statistics: statistics ?? this.statistics,
    );
  }
}

class ReaderSearchResults extends ReaderState {
  final List<Map<String, dynamic>> results;
  final String query;

  const ReaderSearchResults({
    required this.results,
    required this.query,
  });

  @override
  List<Object> get props => [results, query];
}

class ReaderOperationSuccess extends ReaderState {
  final String message;
  final String operation;

  const ReaderOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object> get props => [message, operation];
}

class ReaderError extends ReaderState {
  final String message;

  const ReaderError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final ReaderService _readerService;

  ReaderBloc({required ReaderService readerService})
      : _readerService = readerService,
        super(const ReaderInitial()) {
    on<LoadBookContent>(_onLoadBookContent);
    on<LoadReadingPosition>(_onLoadReadingPosition);
    on<LoadReadingPreferences>(_onLoadReadingPreferences);
    on<LoadBookmarks>(_onLoadBookmarks);
    on<LoadNotes>(_onLoadNotes);
    on<LoadHighlights>(_onLoadHighlights);
    on<UpdateReadingProgress>(_onUpdateReadingProgress);
    on<AddBookmark>(_onAddBookmark);
    on<RemoveBookmark>(_onRemoveBookmark);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<RemoveNote>(_onRemoveNote);
    on<AddHighlight>(_onAddHighlight);
    on<RemoveHighlight>(_onRemoveHighlight);
    on<UpdateReadingPreferences>(_onUpdateReadingPreferences);
    on<SaveReadingPosition>(_onSaveReadingPosition);
    on<GetBookStatistics>(_onGetBookStatistics);
    on<SearchInBook>(_onSearchInBook);
    on<ExportBookData>(_onExportBookData);
    on<ImportBookData>(_onImportBookData);
  }

  Future<void> _onLoadBookContent(
    LoadBookContent event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      emit(const ReaderLoading());

      final content = await _readerService.getBookContent(event.book);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(content: content));
      } else {
        emit(ReaderReady(
          book: event.book,
          content: content,
          readingPosition: 0.0,
          preferences: {},
          bookmarks: [],
          notes: [],
          highlights: [],
          statistics: {},
        ));
      }
    } catch (e) {
      emit(ReaderError('Failed to load book content: $e'));
    }
  }

  Future<void> _onLoadReadingPosition(
    LoadReadingPosition event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final position = await _readerService.loadReadingPosition(event.userId, event.bookId);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(readingPosition: position));
      }
    } catch (e) {
      emit(ReaderError('Failed to load reading position: $e'));
    }
  }

  Future<void> _onLoadReadingPreferences(
    LoadReadingPreferences event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final preferences = await _readerService.loadReadingPreferences(event.userId);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(preferences: preferences));
      }
    } catch (e) {
      emit(ReaderError('Failed to load reading preferences: $e'));
    }
  }

  Future<void> _onLoadBookmarks(
    LoadBookmarks event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final bookmarks = await _readerService.loadBookmarks(event.userId, event.bookId);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(bookmarks: bookmarks));
      }
    } catch (e) {
      emit(ReaderError('Failed to load bookmarks: $e'));
    }
  }

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final notes = await _readerService.loadNotes(event.userId, event.bookId);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(notes: notes));
      }
    } catch (e) {
      emit(ReaderError('Failed to load notes: $e'));
    }
  }

  Future<void> _onLoadHighlights(
    LoadHighlights event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final highlights = await _readerService.loadHighlights(event.userId, event.bookId);

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(highlights: highlights));
      }
    } catch (e) {
      emit(ReaderError('Failed to load highlights: $e'));
    }
  }

  Future<void> _onUpdateReadingProgress(
    UpdateReadingProgress event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.updateReadingProgress(
        event.userId,
        event.bookId,
        event.progress,
      );

      emit(const ReaderOperationSuccess(
        message: 'Reading progress updated successfully',
        operation: 'progress',
      ));

      // Reload reading position
      add(LoadReadingPosition(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to update reading progress: $e'));
    }
  }

  Future<void> _onAddBookmark(
    AddBookmark event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.addBookmark(
        event.userId,
        event.bookId,
        title: event.title,
        description: event.description,
        page: event.page,
        note: event.note,
      );

      emit(const ReaderOperationSuccess(
        message: 'Bookmark added successfully',
        operation: 'bookmark',
      ));

      // Reload bookmarks
      add(LoadBookmarks(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to add bookmark: $e'));
    }
  }

  Future<void> _onRemoveBookmark(
    RemoveBookmark event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.removeBookmark(
        event.userId,
        event.bookId,
        event.bookmarkId,
      );

      emit(const ReaderOperationSuccess(
        message: 'Bookmark removed successfully',
        operation: 'bookmark_remove',
      ));

      // Reload bookmarks
      add(LoadBookmarks(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to remove bookmark: $e'));
    }
  }

  Future<void> _onAddNote(
    AddNote event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.addNote(
        event.userId,
        event.bookId,
        content: event.content,
        page: event.page,
        // chapter: event.chapter, // Removed - not supported in ReaderService
      );

      emit(const ReaderOperationSuccess(
        message: 'Note added successfully',
        operation: 'note',
      ));

      // Reload notes
      add(LoadNotes(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to add note: $e'));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.updateNote(
        event.userId,
        event.bookId,
        event.noteIndex,
        event.newContent,
      );

      emit(const ReaderOperationSuccess(
        message: 'Note updated successfully',
        operation: 'note_update',
      ));

      // Reload notes
      add(LoadNotes(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to update note: $e'));
    }
  }

  Future<void> _onRemoveNote(
    RemoveNote event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.removeNote(
        event.userId,
        event.bookId,
        event.noteIndex,
      );

      emit(const ReaderOperationSuccess(
        message: 'Note removed successfully',
        operation: 'note_remove',
      ));

      // Reload notes
      add(LoadNotes(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to remove note: $e'));
    }
  }

  Future<void> _onAddHighlight(
    AddHighlight event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.addHighlight(
        event.userId,
        event.bookId,
        startPosition: 0, // Default position since we don't have page-based positioning
        endPosition: event.text.length, // Use text length as end position
        text: event.text,
        note: event.note,
      );

      emit(const ReaderOperationSuccess(
        message: 'Highlight added successfully',
        operation: 'highlight',
      ));

      // Reload highlights
      add(LoadHighlights(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to add highlight: $e'));
    }
  }

  Future<void> _onRemoveHighlight(
    RemoveHighlight event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.removeHighlight(
        event.userId,
        event.bookId,
        event.highlightId,
      );

      emit(const ReaderOperationSuccess(
        message: 'Highlight removed successfully',
        operation: 'highlight_remove',
      ));

      // Reload highlights
      add(LoadHighlights(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to remove highlight: $e'));
    }
  }

  Future<void> _onUpdateReadingPreferences(
    UpdateReadingPreferences event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.updateReadingPreferences(
        event.userId,
        event.preferences,
      );

      emit(const ReaderOperationSuccess(
        message: 'Reading preferences updated successfully',
        operation: 'preferences',
      ));

      // Reload preferences
      add(LoadReadingPreferences(event.userId));
    } catch (e) {
      emit(ReaderError('Failed to update reading preferences: $e'));
    }
  }

  Future<void> _onSaveReadingPosition(
    SaveReadingPosition event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.saveReadingPosition(
        event.userId,
        event.bookId,
        event.position,
      );

      emit(const ReaderOperationSuccess(
        message: 'Reading position saved successfully',
        operation: 'position',
      ));

      // Reload reading position
      add(LoadReadingPosition(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to save reading position: $e'));
    }
  }

  Future<void> _onGetBookStatistics(
    GetBookStatistics event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final statistics = await _readerService.getBookStatistics(
        event.userId,
        event.bookId,
      );

      if (state is ReaderReady) {
        final currentState = state as ReaderReady;
        emit(currentState.copyWith(statistics: statistics));
      }
    } catch (e) {
      emit(ReaderError('Failed to get book statistics: $e'));
    }
  }

  Future<void> _onSearchInBook(
    SearchInBook event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final results = await _readerService.searchInBook(
        event.bookId,
        event.query,
      );

      emit(ReaderSearchResults(
        results: results,
        query: event.query,
      ));
    } catch (e) {
      emit(ReaderError('Failed to search in book: $e'));
    }
  }

  Future<void> _onExportBookData(
    ExportBookData event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      final data = await _readerService.exportBookData(
        event.userId,
        event.bookId,
      );

      emit(const ReaderOperationSuccess(
        message: 'Book data exported successfully',
        operation: 'export',
      ));
    } catch (e) {
      emit(ReaderError('Failed to export book data: $e'));
    }
  }

  Future<void> _onImportBookData(
    ImportBookData event,
    Emitter<ReaderState> emit,
  ) async {
    try {
      await _readerService.importBookData(
        event.userId,
        event.bookId,
        event.data,
      );

      emit(const ReaderOperationSuccess(
        message: 'Book data imported successfully',
        operation: 'import',
      ));

      // Reload all data
      add(LoadBookmarks(event.userId, event.bookId));
      add(LoadNotes(event.userId, event.bookId));
      add(LoadHighlights(event.userId, event.bookId));
    } catch (e) {
      emit(ReaderError('Failed to import book data: $e'));
    }
  }
}
