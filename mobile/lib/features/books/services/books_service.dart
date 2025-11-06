
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/core/services/network_service.dart';

class BooksService {
  final NetworkService _networkService;

  BooksService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Get all books with pagination
  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    List<String>? categories,
    String? language,
    String? format,
    String? year,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (genre != null && genre.isNotEmpty) queryParams['genre'] = genre;
      if (categories != null && categories.isNotEmpty) queryParams['categories'] = categories.join(',');
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (format != null && format.isNotEmpty) queryParams['format'] = format;
      if (year != null && year.isNotEmpty) queryParams['year'] = year;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      final response = await _networkService.get('/books', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache books locally - always fetch fresh
        
        return {
          'books': books,
          'total': response.data['total'],
          'page': response.data['page'],
          'limit': response.data['limit'],
          'totalPages': response.data['totalPages'],
        };
      } else {
        throw Exception('Failed to fetch books');
      }
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  // Get book by ID - ALWAYS fetch from API (no caching)
  Future<Book?> getBookById(String bookId, {bool forceRefresh = false}) async {
    try {
      
      // Always fetch from API - no caching
      return await _fetchBookFromAPI(bookId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to fetch book from API (no caching)
  Future<Book?> _fetchBookFromAPI(String bookId) async {
    try {
      final response = await _networkService.get('/books/$bookId');
      
      
      if (response.statusCode == 200) {
        final bookData = response.data as Map<String, dynamic>;
        final ebookContent = bookData['ebookContent']?.toString() ?? '';
        if (ebookContent.isNotEmpty) {
        } else {
        }
        
        final book = Book.fromJson(bookData);
        
        // DO NOT save to local storage - always fetch fresh
        
        return book;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Check if a book should be refreshed from the server
  bool _shouldRefreshBook(Book book) {
    // Always refresh if ebook content is missing
    if (book.ebookContent == null || book.ebookContent!.isEmpty) {
      return true;
    }
    
    // For now, only refresh if ebook content is missing
    // We can add time-based refresh later if needed
    return false;
  }

  // Clear cache for a specific book (useful when admin updates a book)
  Future<void> clearBookCache(String bookId) async {
    try {
      // Note: No local storage - book not deleted locally
    } catch (e) {
    }
  }

  // Clear all book cache
  Future<void> clearAllBookCache() async {
    try {
      // Note: No local storage - books not cleared locally
    } catch (e) {
    }
  }

  // Initialize service - clear all cache on startup
  Future<void> initialize() async {
    try {
      await clearAllBookCache();
    } catch (e) {
    }
  }


  // Search books
  Future<List<Book>> searchBooks(String query, {
    String? genre,
    String? language,
    String? format,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
        'limit': limit,
      };

      if (genre != null && genre.isNotEmpty) queryParams['genre'] = genre;
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (format != null && format.isNotEmpty) queryParams['format'] = format;

      final response = await _networkService.get('/books', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache search results - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Fallback to local search
      return searchBooksLocally(query);
    }
  }

  // Local search in books
  List<Book> searchBooksLocally(String query) {
    final queryLower = query.toLowerCase();
    // Note: No local storage - return empty list
    final allBooks = <Book>[];
    
    return allBooks.where((book) =>
      book.title.toLowerCase().contains(queryLower) ||
      (book.titleSomali?.toLowerCase().contains(queryLower) ?? false) ||
      (book.description?.toLowerCase().contains(queryLower) ?? false) ||
      (book.descriptionSomali?.toLowerCase().contains(queryLower) ?? false) ||
      (book.authors?.toLowerCase().contains(queryLower) ?? false) ||
      (book.authorsSomali?.toLowerCase().contains(queryLower) ?? false) ||
      (book.categoryNames?.any((category) => category.toLowerCase().contains(queryLower)) ?? false)
    ).toList();
  }

  // Get featured books
  Future<List<Book>> getFeaturedBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/featured/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        final booksData = response.data['featuredBooks'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache featured books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get new releases
  Future<List<Book>> getNewReleases({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/new-releases/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        final booksData = response.data['newReleases'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache new releases - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get recent books (sorted by creation date)
  Future<List<Book>> getRecentBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/recent/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final booksData = response.data['recentBooks'] as List;
        
        final books = booksData.map((json) {
          return Book.fromJson(json);
        }).toList();
        
        
        // DO NOT cache recent books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get free books
  Future<List<Book>> getFreeBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/free/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final booksData = response.data['freeBooks'] as List;
        
        final books = booksData.map((json) {
          return Book.fromJson(json);
        }).toList();
        
        
        // DO NOT cache free books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get random books for recommendations
  Future<List<Book>> getRandomBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/random/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final booksData = response.data['randomBooks'] as List;
        
        final books = booksData.map((json) {
          return Book.fromJson(json);
        }).toList();
        
        
        // DO NOT cache random books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get popular books
  Future<List<Book>> getPopularBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/popular', queryParameters: {'limit': limit});
      
      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache popular books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      // Sort by rating and review count for popularity
      allBooks.sort((a, b) {
        final aScore = (a.rating ?? 0) * (a.reviewCount ?? 0);
        final bScore = (b.rating ?? 0) * (b.reviewCount ?? 0);
        return bScore.compareTo(aScore);
      });
      return allBooks.take(limit).toList();
    }
  }

  // Get recommended books
  Future<List<Book>> getRecommendedBooks({int limit = 10}) async {
    try {
      final response = await _networkService.get('/books/recommended', queryParameters: {'limit': limit});
      
      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache recommended books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      // Return featured and new release books as recommendations
      return allBooks.where((book) => book.isFeatured || book.isNewRelease).take(limit).toList();
    }
  }

  // Get books by genre (now category)
  List<Book> getBooksByGenre(String genre) {
    // Note: No local storage - return empty list
    final allBooks = <Book>[];
    return allBooks.where((book) => 
      (book.categoryNames?.any((category) => category.toLowerCase() == genre.toLowerCase()) ?? false)
    ).toList();
  }

  // Get books by author
  List<Book> getBooksByAuthor(String author) {
    // Note: No local storage - return empty list
    final allBooks = <Book>[];
    return allBooks.where((book) => 
      (book.authors?.toLowerCase().contains(author.toLowerCase()) ?? false) ||
      (book.authorsSomali?.toLowerCase().contains(author.toLowerCase()) ?? false)
    ).toList();
  }

  // Get books by language
  Future<List<Book>> filterBooksByLanguage(String language) async {
    try {
      final response = await _networkService.get('/books/language/$language');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final booksData = data['books'] as List;
          final books = booksData.map((json) => Book.fromJson(json)).toList();
          
          // DO NOT cache filtered books - always fetch fresh
          
          return books;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      // Fallback to local filtering if network fails
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      final filteredBooks = allBooks.where((book) => 
        book.language.toLowerCase() == language.toLowerCase()
      ).toList();
      return filteredBooks;
    }
  }

  // Get all unique categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _networkService.get('/categories');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final categoriesData = data['categories'] as List;
          final categories = categoriesData.map((json) => Category.fromJson(json)).toList();
          
          // DO NOT cache categories - always fetch fresh
          
          return categories;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
      return <Category>[];
    }
  }

  // Get books by category
  Future<List<Book>> getBooksByCategory(String categoryId, {int limit = 20}) async {
    try {
      final response = await _networkService.get('/categories/$categoryId/books', queryParameters: {'limit': limit});
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final booksData = data['books'] as List;
          final books = booksData.map((json) => Book.fromJson(json)).toList();
          return books;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
      final localBooks = <Book>[];
      final filteredBooks = localBooks.where((book) => 
        book.categories != null && 
        book.categories!.contains(categoryId)
      ).take(limit).toList();
      return filteredBooks;
    }
  }

  // Filter books by category
  Future<List<Book>> filterBooksByCategory(String? categoryId) async {
    try {
      if (categoryId == null) {
        // If no category selected, return all books
        final allBooks = await getBooks(limit: 50);
        return allBooks['books'] as List<Book>;
      }

      // Get books by specific category
      return await getBooksByCategory(categoryId, limit: 50);
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
      final localBooks = <Book>[];
      if (categoryId == null) {
        return localBooks;
      }
      return localBooks.where((book) => 
        book.categories != null && 
        book.categories!.contains(categoryId)
      ).toList();
    }
  }

  // Get related books based on current book
  Future<List<Book>> getRelatedBooks(Book currentBook, {int limit = 5}) async {
    try {
      final response = await _networkService.get('/books/${currentBook.id}/related', queryParameters: {'limit': limit});
      
      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache related books - always fetch fresh
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      return allBooks.where((book) => 
        book.id != currentBook.id &&
        (book.categoryNames?.any((category) => 
          currentBook.categoryNames?.contains(category) ?? false
        ) ?? false)
      ).take(limit).toList();
    }
  }

  // Get all unique genres/categories
  List<String> getGenres() {
    // Note: No local storage - return empty list
    final allBooks = <Book>[];
    final genres = <String>{};
    
    for (final book in allBooks) {
      if (book.categoryNames != null && book.categoryNames!.isNotEmpty) {
        genres.addAll(book.categoryNames!);
      }
    }
    
    return genres.toList()..sort();
  }

  // Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final response = await _networkService.get('/books/languages/list');

      if (response.statusCode == 200) {
        final languagesData = response.data['languages'] as List;
        return languagesData.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      // Fallback to local languages
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      final languages = <String>{};
      for (final book in allBooks) {
        languages.add(book.language);
      }
      return languages.toList()..sort();
    }
  }

  // Get available formats
  Future<List<String>> getFormats() async {
    try {
      // TODO: Backend doesn't have formats endpoint yet
      // For now, return common formats
      return ['ebook', 'audiobook', 'both'];
    } catch (e) {
      // Fallback to local formats
      // Note: No local storage - return empty list
    final allBooks = <Book>[];
      final formats = <String>{};
      for (final book in allBooks) {
        formats.add(book.format);
      }
      return formats.toList()..sort();
    }
  }

  // Download book
  Future<bool> downloadBook(String bookId) async {
    try {
      // TODO: Backend doesn't have direct book download endpoint yet
      // For now, just mark as downloaded in user library
      // final response = await _networkService.put('/library/$bookId/download', data: {
      //   'downloadPath': '/downloads/$bookId'
      // });

      // Save download info locally for now
      // Note: No local storage - download not saved locally
      // await _storageService.saveDownload(bookId, {
      //   'downloadedAt': DateTime.now().toIso8601String(),
      //   'status': 'completed',
      // });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get download status
  Map<String, dynamic>? getDownloadStatus(String bookId) {
    // Note: No local storage - return null
    return null;
  }

  // Clear local cache
  Future<void> clearCache() async {
    // Note: No local storage - cache not cleared locally
  }
}
