import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/services/download_service.dart';

class LibraryService {
  final NetworkService _networkService;

  LibraryService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Add book to library
  Future<void> addBookToLibrary(String userId, String bookId, {
    String? status,
    double? progress,
    DateTime? lastReadAt,
  }) async {
    try {
      final libraryItem = {
        'userId': userId,
        'bookId': bookId,
        'status': status ?? 'reading',
        'progress': progress ?? 0.0,
        'addedAt': DateTime.now().toIso8601String(),
        'lastReadAt': lastReadAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'isFavorite': false,
        'notes': <String>[],
        'highlights': <Map<String, dynamic>>[],
        'bookmarks': <Map<String, dynamic>>[],
      };

      // Note: No local storage - library item not saved locally

      // Sync with server if online (optional for demo)
      try {
        await _networkService.post('/library/add', data: libraryItem);
      } catch (e) {
        // Continue offline if sync fails (this is expected for demo without auth)
      }
    } catch (e) {
      throw Exception('Failed to add book to library: $e');
    }
  }

  // Remove book from library
  Future<void> removeBookFromLibrary(String userId, String bookId) async {
    try {
      // Note: No local storage - library item not deleted locally

      // Sync with server if online
      try {
        await _networkService.delete('/library/remove', data: {'userId': userId, 'bookId': bookId});
      } catch (e) {
        // Continue offline if sync fails
      }
    } catch (e) {
      throw Exception('Failed to remove book from library: $e');
    }
  }

  // Update reading progress
  Future<void> updateReadingProgress(String userId, String bookId, double progress) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null) {
        item['progress'] = progress;
        item['lastReadAt'] = DateTime.now().toIso8601String();
        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.put('/library/progress', data: {
            'userId': userId,
            'bookId': bookId,
            'progress': progress,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to update reading progress: $e');
    }
  }

  // Update book status
  Future<void> updateBookStatus(String userId, String bookId, String status) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null) {
        item['status'] = status;
        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.put('/library/status', data: {
            'userId': userId,
            'bookId': bookId,
            'status': status,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to update book status: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String userId, String bookId) async {
    try {
      
      // Note: No local storage - cannot get library item
      var item = null;
      
      if (item != null) {
        // Book is already in library, toggle favorite status
        final currentFavoriteStatus = item['isFavorite'] ?? false;
        final newFavoriteStatus = !currentFavoriteStatus;
        
        
        if (newFavoriteStatus) {
          // Adding to favorites - update the item
          item['isFavorite'] = true;
          // Note: No local storage - library item not saved locally
        } else {
          // Removing from favorites - check if it's a favorite-only item
          if (item['status'] == 'favorite') {
            // This is a favorite-only item, remove it completely
            // Note: No local storage - library item not deleted locally
          } else {
            // Book is in library for other reasons (reading, completed, etc.), just remove favorite status
            item['isFavorite'] = false;
            // Note: No local storage - library item not saved locally
          }
        }
      } else {
        // Book is not in library, create new library item as favorite
        
        item = {
          'userId': userId,
          'bookId': bookId,
          'status': 'favorite', // Special status for favorite-only items
          'progress': 0.0,
          'addedAt': DateTime.now().toIso8601String(),
          'lastReadAt': DateTime.now().toIso8601String(),
          'isFavorite': true,
          'notes': <String>[],
          'highlights': <Map<String, dynamic>>[],
          'bookmarks': <Map<String, dynamic>>[],
        };
        // Note: No local storage - library item not saved locally
      }

      // Sync with server if online (optional for demo)
      try {
        final isFavorite = item != null ? (item['isFavorite'] ?? false) : false;
        await _networkService.put('/library/favorite', data: {
          'userId': userId,
          'bookId': bookId,
          'isFavorite': isFavorite,
        });
      } catch (e) {
        // Continue offline if sync fails (this is expected for demo without auth)
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Add bookmark
  Future<void> addBookmark(String userId, String bookId, {
    required String title,
    required String description,
    required int page,
    String? note,
  }) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null) {
        final bookmark = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'description': description,
          'page': page,
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
        };

        if (item['bookmarks'] == null) {
          item['bookmarks'] = <Map<String, dynamic>>[];
        }
        item['bookmarks'].add(bookmark);

        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.post('/library/bookmarks', data: {
            'userId': userId,
            'bookId': bookId,
            'bookmark': bookmark,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String userId, String bookId, String bookmarkId) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null && item['bookmarks'] != null) {
        item['bookmarks'].removeWhere((bookmark) => bookmark['id'] == bookmarkId);
        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.delete('/library/bookmarks/$bookmarkId');
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  // Add note
  Future<void> addNote(String userId, String bookId, {
    required String content,
    int? page,
    String? chapter,
  }) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null) {
        final note = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'page': page,
          'chapter': chapter,
          'createdAt': DateTime.now().toIso8601String(),
        };

        if (item['notes'] == null) {
          item['notes'] = <String>[];
        }
        item['notes'].add(note['content']);

        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.post('/library/notes', data: {
            'userId': userId,
            'bookId': bookId,
            'note': note,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // Add highlight
  Future<void> addHighlight(String userId, String bookId, {
    required String text,
    required int startPage,
    required int endPage,
    String? color,
    String? note,
  }) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null) {
        final highlight = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': text,
          'startPage': startPage,
          'endPage': endPage,
          'color': color ?? '#FFD700',
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
        };

        if (item['highlights'] == null) {
          item['highlights'] = <Map<String, dynamic>>[];
        }
        item['highlights'].add(highlight);

        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.post('/library/highlights', data: {
            'userId': userId,
            'bookId': bookId,
            'highlight': highlight,
          });
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to add highlight: $e');
    }
  }

  // Remove highlight
  Future<void> removeHighlight(String userId, String bookId, String highlightId) async {
    try {
      // Note: No local storage - cannot get library item
      final item = null;
      if (item != null && item['highlights'] != null) {
        item['highlights'].removeWhere((highlight) => highlight['id'] == highlightId);
        // Note: No local storage - library item not saved locally

        // Sync with server if online
        try {
          await _networkService.delete('/library/highlights/$highlightId');
        } catch (e) {
          // Continue offline if sync fails
        }
      }
    } catch (e) {
      throw Exception('Failed to remove highlight: $e');
    }
  }

  // Get user's library
  List<Map<String, dynamic>> getUserLibrary(String userId) {
    try {
      // Note: No local storage - return empty library
      final library = <Map<String, dynamic>>[];
      return library;
    } catch (e) {
      return [];
    }
  }

  // Toggle favorite for book
  Future<bool> toggleBookFavorite(String bookId) async {
    try {
      final response = await _networkService.put('/library/favorites/books/$bookId');
      final isFavorite = response.data['isFavorite'] as bool;
      return isFavorite;
    } catch (e) {
      rethrow;
    }
  }

  // Toggle favorite for podcast
  Future<bool> togglePodcastFavorite(String podcastId) async {
    try {
      final response = await _networkService.put('/library/favorites/podcasts/$podcastId');
      final isFavorite = response.data['isFavorite'] as bool;
      return isFavorite;
    } catch (e) {
      rethrow;
    }
  }

  // Check if book is favorited
  Future<bool> isBookFavorite(String bookId) async {
    try {
      final response = await _networkService.get('/library/favorites/book/$bookId');
      return response.data['isFavorite'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if podcast is favorited
  Future<bool> isPodcastFavorite(String podcastId) async {
    try {
      final response = await _networkService.get('/library/favorites/podcast/$podcastId');
      return response.data['isFavorite'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get all favorites
  Future<List<Map<String, dynamic>>> getFavorites({String? type}) async {
    try {
      final queryParams = type != null ? {'type': type} : null;
      final response = await _networkService.get('/library/favorites', queryParameters: queryParams);
      final favorites = (response.data['favorites'] as List?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ?? [];
      return favorites;
    } catch (e) {
      return [];
    }
  }

  // Get favorite books
  Future<List<Map<String, dynamic>>> getFavoriteBooks() async {
    return getFavorites(type: 'book');
  }

  // Get favorite podcasts
  Future<List<Map<String, dynamic>>> getFavoritePodcasts() async {
    return getFavorites(type: 'podcast');
  }

  // Get recently read books
  List<Map<String, dynamic>> getRecentlyReadBooks(String userId, {int limit = 10}) {
    try {
      // Note: No local storage - return empty library
      final library = <Map<String, dynamic>>[];
      library.sort((a, b) {
        final aDate = DateTime.tryParse(a['lastReadAt'] ?? '') ?? DateTime(1900);
        final bDate = DateTime.tryParse(b['lastReadAt'] ?? '') ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
      final recentlyRead = library.take(limit).toList();
      return recentlyRead;
    } catch (e) {
      return [];
    }
  }

  // Get books by status
  List<Map<String, dynamic>> getBooksByStatus(String userId, String status) {
    try {
      // Note: No local storage - return empty library
      final library = <Map<String, dynamic>>[];
      return library.where((item) => item['status'] == status).toList();
    } catch (e) {
      return [];
    }
  }

  // Search library items
  List<Map<String, dynamic>> searchLibraryItems(String userId, String query) {
    final queryLower = query.toLowerCase();
    final items = getUserLibrary(userId);
    
    return items.where((item) {
      // Note: No local storage - cannot get book
      final book = null;
      if (book == null) return false;
      
      return book.title.toLowerCase().contains(queryLower) ||
        (book.titleSomali?.toLowerCase().contains(queryLower) ?? false) ||
        (book.authors?.toLowerCase().contains(queryLower) ?? false) ||
        (book.authorsSomali?.toLowerCase().contains(queryLower) ?? false) ||
        (book.categoryNames?.any((category) => category.toLowerCase().contains(queryLower)) ?? false);
    }).toList();
  }

  // Sync library with server
  // NOTE: This endpoint causes rate limiting issues. We skip the actual sync call
  // and just reload the library data instead.
  Future<void> syncLibrary(String userId) async {
    try {
      // Skip the sync API call to avoid rate limiting
      // The LoadLibrary event already loads all necessary data including favorites
      
      // Get local library (empty since we have no local storage)
      final localLibrary = <Map<String, dynamic>>[];
      
      // Don't call the sync endpoint - just return
      // The LoadLibrary will fetch fresh data from the server
      return;
      
      // OLD CODE - commented out to prevent rate limiting
      // final response = await _networkService.get('/library/sync/$userId');
      // if (response.statusCode == 200) {
      //   final serverLibrary = response.data['library'] as List;
      //   // ... merge logic
      // }
    } catch (e) {
      // Silently fail - don't throw to avoid breaking the UI
      // Don't throw - just return
    }
  }

  // Get reading statistics
  Map<String, dynamic> getReadingStats(String userId) {
    try {
      // Note: No local storage - return empty library
      final library = <Map<String, dynamic>>[];
      
      int totalBooks = library.length;
      int completedBooks = library.where((item) => item['status'] == 'completed').length;
      int readingBooks = library.where((item) => item['status'] == 'reading').length;
      int favoriteBooks = library.where((item) => 
        item['isFavorite'] == true || item['status'] == 'favorite'
      ).length;
      
      double totalProgress = library.fold(0.0, (sum, item) => sum + (item['progress'] ?? 0.0));
      double averageProgress = totalBooks > 0 ? totalProgress / totalBooks : 0.0;
      
      final stats = {
        'totalBooks': totalBooks,
        'completedBooks': completedBooks,
        'readingBooks': readingBooks,
        'favoriteBooks': favoriteBooks,
        'averageProgress': averageProgress,
        'totalProgress': totalProgress,
      };
      
      return stats;
    } catch (e) {
      return {
        'totalBooks': 0,
        'completedBooks': 0,
        'readingBooks': 0,
        'favoriteBooks': 0,
        'averageProgress': 0.0,
        'totalProgress': 0.0,
      };
    }
  }

  // Fetch book by ID from database
  Future<Book?> fetchBookById(String bookId) async {
    try {
      
      // Try to get from local storage first
      // Note: No local storage - cannot get book
      final localBook = null;
      if (localBook != null) {
        return localBook;
      }
      
      // If not in local storage, fetch from database
      final response = await _networkService.get('/books/$bookId');
      
      if (response.statusCode == 200 && response.data != null) {
        final bookData = response.data;
        final book = Book.fromJson(bookData);
        
        // Save to local storage for future use
        // Note: No local storage - book not saved locally
        
        return book;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Fetch multiple books by IDs from database
  Future<List<Book>> fetchBooksByIds(List<String> bookIds) async {
    try {
      
      final List<Book> books = [];
      final List<String> missingIds = [];
      
      // Import DownloadService to check for local metadata
      final downloadService = DownloadService();
      
      // First, try to get from local metadata (downloaded books)
      for (final bookId in bookIds) {
        try {
          final metadata = await downloadService.getBookMetadata(bookId);
          if (metadata != null) {
            try {
              final book = Book.fromJson(metadata);
              books.add(book);
              continue;
            } catch (e) {
              // Fall through to fetch from API
            }
          }
        } catch (e) {
          // Fall through to fetch from API
        }
        
        // If not found locally, mark for API fetch
        missingIds.add(bookId);
      }
      
      
      // Fetch missing books from database
      if (missingIds.isNotEmpty) {
        try {
          final response = await _networkService.post('/books/batch', data: {
            'bookIds': missingIds,
          });
          
          if (response.statusCode == 200 && response.data != null) {
            final List<dynamic> booksData = response.data['books'] ?? [];
            
            for (final bookData in booksData) {
              final book = Book.fromJson(bookData);
              books.add(book);
              
              // Save to local storage
              // Note: No local storage - book not saved locally
            }
            
          }
        } catch (e) {
        }
      }
      
      return books;
    } catch (e) {
      return [];
    }
  }
}
