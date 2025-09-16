import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/services/storage_service.dart';
import 'package:teekoob/core/services/network_service.dart';

class ReaderService {
  final StorageService _storageService;
  final NetworkService _networkService;

  ReaderService({
    required StorageService storageService,
  }) : _storageService = storageService,
       _networkService = NetworkService(storageService: storageService) {
    _networkService.initialize();
  }

  // Get book content
  Future<String> getBookContent(Book book) async {
    try {
      // Try to get from local storage first
      final localContent = _storageService.getBook(book.id)?.description;
      if (localContent != null && localContent.isNotEmpty) {
        return localContent;
      }

      // Try to get from network
      if (book.ebookUrl != null) {
        final response = await _networkService.get(book.ebookUrl!);
        if (response.statusCode == 200) {
          final content = response.data.toString();
          // Save content locally for future use
          // Note: We'll need to implement a way to store book content
          return content;
        }
      }

      // Return description as fallback
      return book.description ?? 'Content not available';
    } catch (e) {
      return book.description ?? 'Content not available';
    }
  }

  // Create placeholder book for testing - REMOVED: No more hardcoded books
  Book _createPlaceholderBook() {
    throw Exception('No placeholder books - use real database data');
  }

  // Load reading position
  Future<double> loadReadingPosition(String userId, String bookId) async {
    try {
      final libraryItem = _storageService.getLibraryItem(userId, bookId);
      return libraryItem?['progress'] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Load reading preferences
  Future<Map<String, dynamic>> loadReadingPreferences(String userId) async {
    try {
      final settings = _storageService.getSettings(userId);
      return {
        'fontSize': settings['fontSize'] ?? 16.0,
        'fontFamily': settings['fontFamily'] ?? 'Roboto',
        'lineHeight': settings['lineHeight'] ?? 1.5,
        'theme': settings['readingTheme'] ?? 'light',
        'backgroundColor': settings['backgroundColor'] ?? '#FFFFFF',
        'textColor': settings['textColor'] ?? '#000000',
        'margin': settings['margin'] ?? 16.0,
        'justifyText': settings['justifyText'] ?? true,
      };
    } catch (e) {
      // Return default preferences
      return {
        'fontSize': 16.0,
        'fontFamily': 'Roboto',
        'lineHeight': 1.5,
        'theme': 'light',
        'backgroundColor': '#FFFFFF',
        'textColor': '#000000',
        'margin': 16.0,
        'justifyText': true,
      };
    }
  }

  // Load bookmarks
  Future<List<Map<String, dynamic>>> loadBookmarks(String userId, String bookId) async {
    try {
      final libraryItem = _storageService.getLibraryItem(userId, bookId);
      return libraryItem?['bookmarks'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // Load notes
  Future<List<String>> loadNotes(String userId, String bookId) async {
    try {
      final libraryItem = _storageService.getLibraryItem(userId, bookId);
      return libraryItem?['notes'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // Load highlights
  Future<List<Map<String, dynamic>>> loadHighlights(String userId, String bookId) async {
    try {
      final libraryItem = _storageService.getLibraryItem(userId, bookId);
      return libraryItem?['highlights'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // Update reading progress
  Future<void> updateReadingProgress(String userId, String bookId, double progress) async {
    try {
      final item = _storageService.getLibraryItem(userId, bookId);
      if (item != null) {
        item['progress'] = progress;
        item['lastReadAt'] = DateTime.now().toIso8601String();
        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.put('/library/progress', data: {
            'userId': userId,
            'bookId': bookId,
            'progress': progress,
          });
        } catch (e) {
          // Continue offline if sync fails
          print('Progress sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update reading progress: $e');
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
      final item = _storageService.getLibraryItem(userId, bookId);
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

        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.post('/library/bookmarks', data: {
            'userId': userId,
            'bookId': bookId,
            'bookmark': bookmark,
          });
        } catch (e) {
          // Continue offline if sync fails
          print('Bookmark sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String userId, String bookId, String bookmarkId) async {
    try {
      final item = _storageService.getLibraryItem(userId, bookId);
      if (item != null && item['bookmarks'] != null) {
        item['bookmarks'].removeWhere((bookmark) => bookmark['id'] == bookmarkId);
        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.delete('/library/bookmarks/$bookmarkId');
        } catch (e) {
          // Continue offline if sync fails
          print('Bookmark sync failed: $e');
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
      final item = _storageService.getLibraryItem(userId, bookId);
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

        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.post('/library/notes', data: {
            'userId': userId,
            'bookId': bookId,
            'note': note,
          });
        } catch (e) {
          // Continue offline if sync fails
          print('Note sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // Update note
  Future<void> updateNote(String userId, String bookId, int noteIndex, String newContent) async {
    try {
      final item = _storageService.getLibraryItem(userId, bookId);
      if (item != null && item['notes'] != null && noteIndex < item['notes'].length) {
        item['notes'][noteIndex] = newContent;
        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.put('/library/notes', data: {
            'userId': userId,
            'bookId': bookId,
            'noteIndex': noteIndex,
            'content': newContent,
          });
        } catch (e) {
          // Continue offline if sync fails
          print('Note sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Remove note
  Future<void> removeNote(String userId, String bookId, int noteIndex) async {
    try {
      final item = _storageService.getLibraryItem(userId, bookId);
      if (item != null && item['notes'] != null && noteIndex < item['notes'].length) {
        item['notes'].removeAt(noteIndex);
        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.delete('/library/notes/$noteIndex');
        } catch (e) {
          // Continue offline if sync fails
          print('Note sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to remove note: $e');
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
      final item = _storageService.getLibraryItem(userId, bookId);
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

        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.post('/library/highlights', data: {
            'userId': userId,
            'bookId': bookId,
            'highlight': highlight,
          });
        } catch (e) {
          // Continue offline if sync fails
          print('Highlight sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to add highlight: $e');
    }
  }

  // Remove highlight
  Future<void> removeHighlight(String userId, String bookId, String highlightId) async {
    try {
      final item = _storageService.getLibraryItem(userId, bookId);
      if (item != null && item['highlights'] != null) {
        item['highlights'].removeWhere((highlight) => highlight['id'] == highlightId);
        await _storageService.saveLibraryItem(userId, bookId, item);

        // Sync with server if online
        try {
          await _networkService.delete('/library/highlights/$highlightId');
        } catch (e) {
          // Continue offline if sync fails
          print('Highlight sync failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to remove highlight: $e');
    }
  }

  // Update reading preferences
  Future<void> updateReadingPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final currentSettings = _storageService.getSettings(userId);
      currentSettings.addAll(preferences);
      await _storageService.saveSettings(userId, currentSettings);

      // Sync with server if online
      try {
        await _networkService.put('/user/preferences', data: {
          'userId': userId,
          'preferences': preferences,
        });
      } catch (e) {
        // Continue offline if sync fails
        print('Preferences sync failed: $e');
      }
    } catch (e) {
      throw Exception('Failed to update reading preferences: $e');
    }
  }

  // Save reading position
  Future<void> saveReadingPosition(String userId, String bookId, double position) async {
    try {
      await updateReadingProgress(userId, bookId, position);
    } catch (e) {
      throw Exception('Failed to save reading position: $e');
    }
  }

  // Get book statistics
  Future<Map<String, dynamic>> getBookStatistics(String userId, String bookId) async {
    try {
      final libraryItem = _storageService.getLibraryItem(userId, bookId);
      if (libraryItem != null) {
        final bookmarks = libraryItem['bookmarks'] ?? [];
        final notes = libraryItem['notes'] ?? [];
        final highlights = libraryItem['highlights'] ?? [];
        final progress = libraryItem['progress'] ?? 0.0;
        final lastReadAt = libraryItem['lastReadAt'];

        return {
          'progress': progress,
          'lastReadAt': lastReadAt,
          'bookmarksCount': bookmarks.length,
          'notesCount': notes.length,
          'highlightsCount': highlights.length,
          'readingTime': _calculateReadingTime(libraryItem),
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Calculate reading time (estimated)
  Duration _calculateReadingTime(Map<String, dynamic> libraryItem) {
    try {
      final addedAt = DateTime.tryParse(libraryItem['addedAt'] ?? '');
      final lastReadAt = DateTime.tryParse(libraryItem['lastReadAt'] ?? '');
      
      if (addedAt != null && lastReadAt != null) {
        return lastReadAt.difference(addedAt);
      }
      return Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  // Search within book content
  Future<List<Map<String, dynamic>>> searchInBook(String userId, String bookId, String query) async {
    try {
      // Get the actual book from storage instead of placeholder
      final book = _storageService.getBook(bookId);
      if (book == null) {
        throw Exception('Book not found: $bookId');
      }
      
      final content = await getBookContent(book);
      
      if (content == null) return [];

      final results = <Map<String, dynamic>>[];
      final queryLower = query.toLowerCase();
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.toLowerCase().contains(queryLower)) {
          results.add({
            'lineNumber': i + 1,
            'text': line,
            'context': _getContext(lines, i),
          });
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // Get context around a line
  String _getContext(List<String> lines, int lineIndex) {
    final start = (lineIndex - 2).clamp(0, lines.length - 1);
    final end = (lineIndex + 2).clamp(0, lines.length - 1);
    
    final contextLines = <String>[];
    for (int i = start; i <= end; i++) {
      if (i == lineIndex) {
        contextLines.add('>>> ${lines[i]} <<<');
      } else {
        contextLines.add(lines[i]);
      }
    }
    
    return contextLines.join('\n');
  }

  // Export book data (bookmarks, notes, highlights)
  Future<Map<String, dynamic>> exportBookData(String userId, String bookId) async {
    try {
      final bookmarks = await loadBookmarks(userId, bookId);
      final notes = await loadNotes(userId, bookId);
      final highlights = await loadHighlights(userId, bookId);
      final statistics = await getBookStatistics(userId, bookId);

      return {
        'bookId': bookId,
        'exportedAt': DateTime.now().toIso8601String(),
        'bookmarks': bookmarks,
        'notes': notes,
        'highlights': highlights,
        'statistics': statistics,
      };
    } catch (e) {
      throw Exception('Failed to export book data: $e');
    }
  }

  // Import book data
  Future<void> importBookData(String userId, String bookId, Map<String, dynamic> data) async {
    try {
      // Import bookmarks
      if (data['bookmarks'] != null) {
        for (final bookmark in data['bookmarks']) {
          await addBookmark(
            userId,
            bookId,
            title: bookmark['title'] ?? '',
            description: bookmark['description'] ?? '',
            page: bookmark['page'] ?? 0,
            note: bookmark['note'],
          );
        }
      }

      // Import notes
      if (data['notes'] != null) {
        for (final note in data['notes']) {
          await addNote(
            userId,
            bookId,
            content: note,
          );
        }
      }

      // Import highlights
      if (data['highlights'] != null) {
        for (final highlight in data['highlights']) {
          await addHighlight(
            userId,
            bookId,
            text: highlight['text'] ?? '',
            startPage: highlight['startPage'] ?? 0,
            endPage: highlight['endPage'] ?? 0,
            color: highlight['color'],
            note: highlight['note'],
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to import book data: $e');
    }
  }
}
