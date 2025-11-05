import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/services/download_service.dart';
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
  final String itemId;
  final String itemType; // 'book' or 'podcast'

  const ToggleFavorite(this.userId, this.itemId, {this.itemType = 'book'});

  @override
  List<Object> get props => [userId, itemId, itemType];
}

class LoadFavorites extends LibraryEvent {
  final String? type; // 'book', 'podcast', or null for all

  const LoadFavorites({this.type});

  @override
  List<Object?> get props => [type];
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

class DownloadBook extends LibraryEvent {
  final Book book; // Use Book object instead of separate URLs

  const DownloadBook(this.book);

  @override
  List<Object?> get props => [book];
}

class DownloadPodcastEpisode extends LibraryEvent {
  final String episodeId;
  final String audioUrl;
  final String? podcastId;

  const DownloadPodcastEpisode(this.episodeId, this.audioUrl, {this.podcastId});

  @override
  List<Object?> get props => [episodeId, audioUrl, podcastId];
}

class DownloadCompletePodcast extends LibraryEvent {
  final Podcast podcast;
  final List<PodcastEpisode> episodes;

  const DownloadCompletePodcast(this.podcast, this.episodes);

  @override
  List<Object> get props => [podcast, episodes];
}

class DeleteDownload extends LibraryEvent {
  final String downloadId;
  final String itemId;
  final String type; // 'bookAudio', 'bookEbook', 'podcastEpisode'

  const DeleteDownload(this.downloadId, this.itemId, this.type);

  @override
  List<Object> get props => [downloadId, itemId, type];
}

class LoadDownloads extends LibraryEvent {
  const LoadDownloads();

  @override
  List<Object> get props => [];
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
  final List<Map<String, dynamic>> downloads;
  final List<Map<String, dynamic>> downloadedBooks;
  final List<Map<String, dynamic>> downloadedPodcasts;

  const LibraryLoaded({
    required this.library,
    required this.favorites,
    required this.recentlyRead,
    required this.stats,
    this.downloads = const [],
    this.downloadedBooks = const [],
    this.downloadedPodcasts = const [],
  });

  LibraryLoaded copyWith({
    List<Map<String, dynamic>>? library,
    List<Map<String, dynamic>>? favorites,
    List<Map<String, dynamic>>? recentlyRead,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? downloads,
    List<Map<String, dynamic>>? downloadedBooks,
    List<Map<String, dynamic>>? downloadedPodcasts,
  }) {
    return LibraryLoaded(
      library: library ?? this.library,
      favorites: favorites ?? this.favorites,
      recentlyRead: recentlyRead ?? this.recentlyRead,
      stats: stats ?? this.stats,
      downloads: downloads ?? this.downloads,
      downloadedBooks: downloadedBooks ?? this.downloadedBooks,
      downloadedPodcasts: downloadedPodcasts ?? this.downloadedPodcasts,
    );
  }

  @override
  List<Object?> get props => [library, favorites, recentlyRead, stats, downloads, downloadedBooks, downloadedPodcasts];
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
  final DownloadService _downloadService = DownloadService();

  LibraryBloc({required LibraryService libraryService})
      : _libraryService = libraryService,
        super(const LibraryInitial()) {
    _downloadService.initialize();
    on<LoadLibrary>(_onLoadLibrary);
    on<AddBookToLibrary>(_onAddBookToLibrary);
    on<RemoveBookFromLibrary>(_onRemoveBookFromLibrary);
    on<UpdateReadingProgress>(_onUpdateReadingProgress);
    on<UpdateBookStatus>(_onUpdateBookStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<AddBookmark>(_onAddBookmark);
    on<RemoveBookmark>(_onRemoveBookmark);
    on<AddNote>(_onAddNote);
    on<AddHighlight>(_onAddHighlight);
    on<RemoveHighlight>(_onRemoveHighlight);
    on<SearchLibrary>(_onSearchLibrary);
    on<SyncLibrary>(_onSyncLibrary);
    on<LoadReadingStats>(_onLoadReadingStats);
    on<DownloadBook>(_onDownloadBook);
    on<DownloadPodcastEpisode>(_onDownloadPodcastEpisode);
    on<DownloadCompletePodcast>(_onDownloadCompletePodcast);
    on<DeleteDownload>(_onDeleteDownload);
    on<LoadDownloads>(_onLoadDownloads);
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

      print('🎯 LibraryBloc: Loading favorites...');
      final favorites = await _libraryService.getFavorites();
      print('🎯 LibraryBloc: Favorites retrieved: ${favorites.length}');

      print('🎯 LibraryBloc: Calling _libraryService.getRecentlyReadBooks...');
      final recentlyRead = _libraryService.getRecentlyReadBooks(event.userId);
      print('🎯 LibraryBloc: Recently read books retrieved: ${recentlyRead.length}');

      print('🎯 LibraryBloc: Calling _libraryService.getReadingStats...');
      final stats = _libraryService.getReadingStats(event.userId);
      print('🎯 LibraryBloc: Reading stats retrieved: $stats');

      // Load downloads with error handling
      List<DownloadItem> allDownloads = [];
      List<DownloadItem> completedDownloads = [];
      
      try {
        allDownloads = await _downloadService.getAllDownloads().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ LibraryBloc: Timeout loading all downloads');
            return <DownloadItem>[];
          },
        );
      } catch (e) {
        print('❌ LibraryBloc: Error loading all downloads: $e');
        allDownloads = [];
      }
      
      try {
        completedDownloads = await _downloadService.getCompletedDownloads().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ LibraryBloc: Timeout loading completed downloads');
            return <DownloadItem>[];
          },
        );
      } catch (e) {
        print('❌ LibraryBloc: Error loading completed downloads: $e');
        completedDownloads = [];
      }
      
      // Group downloads by item_id to avoid duplicates (a book can have both audio and ebook)
      final bookDownloadsMap = <String, Map<String, dynamic>>{};
      for (final d in completedDownloads.where((d) => d.type == DownloadType.bookAudio || d.type == DownloadType.bookEbook)) {
        if (!bookDownloadsMap.containsKey(d.itemId)) {
          bookDownloadsMap[d.itemId] = {
            'download_id': d.id,
            'item_id': d.itemId,
            'type': 'book',
            'local_path': d.localPath,
            'completed_at': d.completedAt?.toIso8601String(),
          };
        }
      }
      final downloadedBooks = bookDownloadsMap.values.toList();
      
      final downloadedPodcasts = completedDownloads
          .where((d) => d.type == DownloadType.podcastEpisode)
          .map((d) => {
                'download_id': d.id,
                'item_id': d.itemId,
                'type': d.type.toString().split('.').last,
                'local_path': d.localPath,
                'completed_at': d.completedAt?.toIso8601String(),
              })
          .toList();

      final downloads = allDownloads.map((d) => d.toJson()).toList();

      print('🎯 LibraryBloc: Emitting LibraryLoaded state');
      emit(LibraryLoaded(
        library: library,
        favorites: favorites,
        recentlyRead: recentlyRead,
        stats: stats,
        downloads: downloads,
        downloadedBooks: downloadedBooks,
        downloadedPodcasts: downloadedPodcasts,
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
    // Optimistic update: immediately update the UI
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      final currentFavorites = List<Map<String, dynamic>>.from(currentState.favorites);
      
      // Check if item is currently favorited
      final existingIndex = currentFavorites.indexWhere((fav) => 
        fav['item_type'] == event.itemType && fav['item_id'] == event.itemId
      );
      
      // Optimistically toggle the favorite
      if (existingIndex >= 0) {
        // Remove from favorites
        currentFavorites.removeAt(existingIndex);
      } else {
        // Add to favorites
        currentFavorites.add({
          'item_id': event.itemId,
          'item_type': event.itemType,
        });
      }
      
      // Emit updated state immediately
      emit(LibraryLoaded(
        library: currentState.library,
        favorites: currentFavorites,
        recentlyRead: currentState.recentlyRead,
        stats: currentState.stats,
        downloads: currentState.downloads,
        downloadedBooks: currentState.downloadedBooks,
        downloadedPodcasts: currentState.downloadedPodcasts,
      ));
    }
    
    try {
      bool isFavorite;
      if (event.itemType == 'book') {
        isFavorite = await _libraryService.toggleBookFavorite(event.itemId);
      } else {
        isFavorite = await _libraryService.togglePodcastFavorite(event.itemId);
      }

      emit(LibraryOperationSuccess(
        message: isFavorite 
            ? 'Added to favorites' 
            : 'Removed from favorites',
        operation: 'favorite',
      ));

      // Reload favorites to ensure sync with server
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        final favorites = await _libraryService.getFavorites();
        emit(LibraryLoaded(
          library: currentState.library,
          favorites: favorites,
          recentlyRead: currentState.recentlyRead,
          stats: currentState.stats,
          downloads: currentState.downloads,
          downloadedBooks: currentState.downloadedBooks,
          downloadedPodcasts: currentState.downloadedPodcasts,
        ));
      }
    } catch (e) {
      // Revert optimistic update on error
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        final favorites = await _libraryService.getFavorites();
        emit(LibraryLoaded(
          library: currentState.library,
          favorites: favorites,
          recentlyRead: currentState.recentlyRead,
          stats: currentState.stats,
          downloads: currentState.downloads,
          downloadedBooks: currentState.downloadedBooks,
          downloadedPodcasts: currentState.downloadedPodcasts,
        ));
      }
      emit(LibraryError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final favorites = await _libraryService.getFavorites(type: event.type);
      
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        emit(LibraryLoaded(
          library: currentState.library,
          favorites: favorites,
          recentlyRead: currentState.recentlyRead,
          stats: currentState.stats,
        ));
      } else {
        emit(LibraryLoaded(
          library: const [],
          favorites: favorites,
          recentlyRead: const [],
          stats: {},
        ));
      }
    } catch (e) {
      emit(LibraryError('Failed to load favorites: $e'));
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
      // Don't emit loading state for sync to avoid UI flicker
      // Just reload the library data which will update favorites and other data
      
      // Skip the sync API call as it causes rate limiting
      // Instead, just reload the library data
      print('🔄 LibraryBloc: Sync requested, reloading library data instead of calling sync endpoint');
      
      // Reload library data directly (this includes favorites)
      add(LoadLibrary(event.userId));
      
      emit(const LibraryOperationSuccess(
        message: 'Library refreshed successfully',
        operation: 'sync',
      ));
    } catch (e) {
      print('❌ LibraryBloc: Error syncing library: $e');
      // Don't emit error state - just silently fail since we're reloading anyway
      emit(const LibraryOperationSuccess(
        message: 'Library refreshed',
        operation: 'sync',
      ));
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

  Future<void> _onDownloadBook(
    DownloadBook event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      print('📥 LibraryBloc: Starting download for book: ${event.book.id}');
      
      // Download complete book (metadata, ebook content, and audio)
      await _downloadService.downloadCompleteBook(event.book);
      
      print('✅ LibraryBloc: Book download completed');

      // Reload library state with updated downloads
      final currentState = state;
      if (currentState is LibraryLoaded) {
        // Reload downloads and update the state
        final allDownloads = await _downloadService.getAllDownloads();
        final completedDownloads = await _downloadService.getCompletedDownloads();
        
        // Group downloads by item_id to avoid duplicates
        final bookDownloadsMap = <String, Map<String, dynamic>>{};
        for (final d in completedDownloads.where((d) => d.type == DownloadType.bookAudio || d.type == DownloadType.bookEbook)) {
          if (!bookDownloadsMap.containsKey(d.itemId)) {
            bookDownloadsMap[d.itemId] = {
              'download_id': d.id,
              'item_id': d.itemId,
              'type': 'book',
              'local_path': d.localPath,
              'completed_at': d.completedAt?.toIso8601String(),
            };
          }
        }
        final downloadedBooks = bookDownloadsMap.values.toList();
        
        final downloadedPodcasts = completedDownloads
            .where((d) => d.type == DownloadType.podcastEpisode)
            .map((d) => {
                  'download_id': d.id,
                  'item_id': d.itemId,
                  'type': d.type.toString().split('.').last,
                  'local_path': d.localPath,
                  'completed_at': d.completedAt?.toIso8601String(),
                })
            .toList();

        final downloads = allDownloads.map((d) => d.toJson()).toList();

        print('📥 LibraryBloc: Updated downloads - Books: ${downloadedBooks.length}, Podcasts: ${downloadedPodcasts.length}');
        print('📥 LibraryBloc: Downloaded book IDs: ${downloadedBooks.map((d) => d['item_id']).toList()}');
        
        // Update the state with new downloads - this will trigger UI refresh
        emit(currentState.copyWith(
          downloads: downloads,
          downloadedBooks: downloadedBooks,
          downloadedPodcasts: downloadedPodcasts,
        ));
        
        // Note: We don't emit LibraryOperationSuccess here to avoid replacing the LibraryLoaded state
        // The UI should see the updated LibraryLoaded state with the new downloads
      } else {
        // If state is not LibraryLoaded, just emit success
        emit(const LibraryOperationSuccess(
          message: 'Download completed successfully!',
          operation: 'download_book',
        ));
        // Also trigger a full library reload
        add(LoadLibrary('current_user'));
      }
    } catch (e, stackTrace) {
      print('❌ LibraryBloc: Download failed: $e');
      print('❌ Stack trace: $stackTrace');
      emit(LibraryError('Failed to download book: ${e.toString()}'));
    }
  }

  Future<void> _onDownloadPodcastEpisode(
    DownloadPodcastEpisode event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _downloadService.downloadPodcastEpisode(
        event.episodeId,
        event.audioUrl,
        podcastId: event.podcastId,
      );
      
      // Reload downloads
      add(const LoadDownloads());
      
      emit(const LibraryOperationSuccess(
        message: 'Download started successfully',
        operation: 'download_podcast',
      ));
    } catch (e) {
      emit(LibraryError('Failed to download podcast episode: $e'));
    }
  }

  Future<void> _onDownloadCompletePodcast(
    DownloadCompletePodcast event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      // Download complete podcast (metadata + all episodes)
      await _downloadService.downloadCompletePodcast(event.podcast, event.episodes);

      // Reload downloads
      add(const LoadDownloads());
      
      emit(const LibraryOperationSuccess(
        message: 'Podcast download started successfully',
        operation: 'download_podcast_complete',
      ));
    } catch (e) {
      emit(LibraryError('Failed to download podcast: $e'));
    }
  }

  Future<void> _onDeleteDownload(
    DeleteDownload event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      await _downloadService.deleteDownload(event.downloadId);
      
      // Reload downloads
      add(const LoadDownloads());
      
      emit(const LibraryOperationSuccess(
        message: 'Download deleted successfully',
        operation: 'delete_download',
      ));
    } catch (e) {
      emit(LibraryError('Failed to delete download: $e'));
    }
  }

  Future<void> _onLoadDownloads(
    LoadDownloads event,
    Emitter<LibraryState> emit,
  ) async {
    try {
      final allDownloads = await _downloadService.getAllDownloads();
      final completedDownloads = await _downloadService.getCompletedDownloads();
      
      // Group downloads by item_id to avoid duplicates (a book can have both audio and ebook)
      final bookDownloadsMap = <String, Map<String, dynamic>>{};
      for (final d in completedDownloads.where((d) => d.type == DownloadType.bookAudio || d.type == DownloadType.bookEbook)) {
        if (!bookDownloadsMap.containsKey(d.itemId)) {
          bookDownloadsMap[d.itemId] = {
            'download_id': d.id,
            'item_id': d.itemId,
            'type': 'book',
            'local_path': d.localPath,
            'completed_at': d.completedAt?.toIso8601String(),
          };
        }
      }
      final downloadedBooks = bookDownloadsMap.values.toList();
      
      final downloadedPodcasts = completedDownloads
          .where((d) => d.type == DownloadType.podcastEpisode)
          .map((d) => {
                'download_id': d.id,
                'item_id': d.itemId,
                'type': d.type.toString().split('.').last,
                'local_path': d.localPath,
                'completed_at': d.completedAt?.toIso8601String(),
              })
          .toList();

      final downloads = allDownloads.map((d) => d.toJson()).toList();

      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        emit(currentState.copyWith(
          downloads: downloads,
          downloadedBooks: downloadedBooks,
          downloadedPodcasts: downloadedPodcasts,
        ));
      } else {
        emit(LibraryLoaded(
          library: [],
          favorites: [],
          recentlyRead: [],
          stats: {},
          downloads: downloads,
          downloadedBooks: downloadedBooks,
          downloadedPodcasts: downloadedPodcasts,
        ));
      }
    } catch (e) {
      emit(LibraryError('Failed to load downloads: $e'));
    }
  }
}
