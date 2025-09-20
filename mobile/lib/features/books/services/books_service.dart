
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/services/storage_service.dart';

class BooksService {
  final NetworkService _networkService;
  final StorageService _storageService;

  BooksService({
    required StorageService storageService,
  }) : _storageService = storageService,
       _networkService = NetworkService(storageService: storageService) {
    _networkService.initialize();
  }

  // Get all books with pagination
  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
    String? language,
    String? format,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('BooksService: Getting books with params: page=$page, limit=$limit, search=$search, genre=$genre, language=$language, format=$format, sortBy=$sortBy, sortOrder=$sortOrder');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (genre != null && genre.isNotEmpty) queryParams['genre'] = genre;
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (format != null && format.isNotEmpty) queryParams['format'] = format;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      print('BooksService: Making request to /books with queryParams: $queryParams');
      final response = await _networkService.get('/books', queryParameters: queryParams);
      print('BooksService: Response received - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final booksData = response.data['books'] as List;
        final books = booksData.map((json) => Book.fromJson(json)).toList();
        
        // DO NOT cache books locally - always fetch fresh
        print('🚫 BooksService: Not caching books - always fetch fresh');
        
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
      print('💥 BooksService: Error fetching books from API: $e');
      throw Exception('Failed to fetch books: $e');
    }
  }

  // Get book by ID - ALWAYS fetch from API (no caching)
  Future<Book?> getBookById(String bookId, {bool forceRefresh = false}) async {
    try {
      print('🔍 BooksService: Getting book by ID from API: $bookId');
      print('🚫 BooksService: Caching disabled - always fetching fresh data');
      
      // Always fetch from API - no caching
      return await _fetchBookFromAPI(bookId);
    } catch (e) {
      print('💥 BooksService: Error getting book by ID: $e');
      return null;
    }
  }

  // Helper method to fetch book from API (no caching)
  Future<Book?> _fetchBookFromAPI(String bookId) async {
    try {
      final response = await _networkService.get('/books/$bookId');
      
      print('📡 BooksService: Server response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final bookData = response.data as Map<String, dynamic>;
        print('📚 BooksService: API book data keys: ${bookData.keys.toList()}');
        print('📝 BooksService: API ebookContent: ${bookData['ebookContent']?.toString().substring(0, 100)}...');
        print('📅 BooksService: API book updated at: ${bookData['updatedAt']}');
        
        final book = Book.fromJson(bookData);
        print('📖 BooksService: API book ebook content length: ${book.ebookContent?.length ?? 0}');
        
        // DO NOT save to local storage - always fetch fresh
        print('🚫 BooksService: Not saving to cache - always fetch fresh');
        
        return book;
      } else {
        print('❌ BooksService: Server returned status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 BooksService: Error fetching book from API: $e');
      return null;
    }
  }

  // Check if a book should be refreshed from the server
  bool _shouldRefreshBook(Book book) {
    // Always refresh if ebook content is missing
    if (book.ebookContent == null || book.ebookContent!.isEmpty) {
      print('🔄 BooksService: Book missing ebook content, needs refresh');
      return true;
    }
    
    // For now, only refresh if ebook content is missing
    // We can add time-based refresh later if needed
    print('✅ BooksService: Book has ebook content, no refresh needed');
    return false;
  }

  // Clear cache for a specific book (useful when admin updates a book)
  Future<void> clearBookCache(String bookId) async {
    try {
      print('🗑️ BooksService: Clearing cache for book: $bookId');
      await _storageService.deleteBook(bookId);
      print('✅ BooksService: Cache cleared for book: $bookId');
    } catch (e) {
      print('💥 BooksService: Error clearing cache for book $bookId: $e');
    }
  }

  // Clear all book cache
  Future<void> clearAllBookCache() async {
    try {
      print('🗑️ BooksService: Clearing all book cache');
      await _storageService.clearBooks();
      print('✅ BooksService: All book cache cleared');
    } catch (e) {
      print('💥 BooksService: Error clearing all book cache: $e');
    }
  }

  // Initialize service - clear all cache on startup
  Future<void> initialize() async {
    try {
      print('🚀 BooksService: Initializing - clearing all cache');
      await clearAllBookCache();
      print('✅ BooksService: Initialization complete - cache cleared');
    } catch (e) {
      print('💥 BooksService: Error during initialization: $e');
    }
  }

  // Simple method to get book with fallback (for debugging)
  Future<Book?> getBookByIdSimple(String bookId) async {
    try {
      print('🔍 BooksService: Simple get book by ID: $bookId');
      
      // Try local storage first
      Book? book = _storageService.getBook(bookId);
      if (book != null) {
        print('✅ BooksService: Found book in local storage (simple)');
        return book;
      }
      
      // Try API
      print('🔄 BooksService: Not in local storage, trying API (simple)');
      return await _fetchBookFromAPI(bookId);
    } catch (e) {
      print('💥 BooksService: Error in simple get book: $e');
      return null;
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
        
        // Cache search results
        await _storageService.saveBooks(books);
        
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
    final allBooks = _storageService.getBooks();
    
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
        print('🚫 getFeaturedBooks: Not caching books - always fetch fresh');
        
        return books;
      } else {
        print('❌ getFeaturedBooks: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getFeaturedBooks: Error occurred: $e');
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
        print('🚫 getNewReleases: Not caching books - always fetch fresh');
        
        return books;
      } else {
        print('❌ getNewReleases: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getNewReleases: Error occurred: $e');
      return [];
    }
  }

  // Get random books for recommendations
  Future<List<Book>> getRandomBooks({int limit = 10}) async {
    try {
      print('🔍 getRandomBooks: Fetching $limit random books from API...');
      final response = await _networkService.get('/books/random/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        print('✅ getRandomBooks: API response status: ${response.statusCode}');
        print('📊 getRandomBooks: Response data keys: ${response.data.keys.toList()}');
        print('📊 getRandomBooks: Full response data: ${response.data}');
        
        final booksData = response.data['randomBooks'] as List;
        print('📚 getRandomBooks: Found ${booksData.length} books in response');
        print('📖 getRandomBooks: Book titles: ${booksData.map((b) => b['title']).toList()}');
        print('🖼️ getRandomBooks: Book cover URLs: ${booksData.map((b) => b['coverImageUrl']).toList()}');
        print('🔍 getRandomBooks: Full book data: ${booksData.map((b) => {'id': b['id'], 'title': b['title'], 'coverImageUrl': b['coverImageUrl']})}');
        
        final books = booksData.map((json) {
          print('🔧 getRandomBooks: Processing book: ${json['title']}');
          return Book.fromJson(json);
        }).toList();
        
        print('✅ getRandomBooks: Successfully parsed ${books.length} books');
        print('📚 getRandomBooks: Final book titles: ${books.map((b) => b.title).toList()}');
        
        // DO NOT cache random books - always fetch fresh
        print('🚫 getRandomBooks: Not caching books - always fetch fresh');
        
        return books;
      } else {
        print('❌ getRandomBooks: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getRandomBooks: Error occurred: $e');
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
        
        // Cache popular books
        await _storageService.saveBooks(books);
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      final allBooks = _storageService.getBooks();
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
        
        // Cache recommended books
        await _storageService.saveBooks(books);
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      final allBooks = _storageService.getBooks();
      // Return featured and new release books as recommendations
      return allBooks.where((book) => book.isFeatured || book.isNewRelease).take(limit).toList();
    }
  }

  // Get books by genre (now category)
  List<Book> getBooksByGenre(String genre) {
    final allBooks = _storageService.getBooks();
    return allBooks.where((book) => 
      (book.categoryNames?.any((category) => category.toLowerCase() == genre.toLowerCase()) ?? false)
    ).toList();
  }

  // Get books by author
  List<Book> getBooksByAuthor(String author) {
    final allBooks = _storageService.getBooks();
    return allBooks.where((book) => 
      (book.authors?.toLowerCase().contains(author.toLowerCase()) ?? false) ||
      (book.authorsSomali?.toLowerCase().contains(author.toLowerCase()) ?? false)
    ).toList();
  }

  // Get books by language
  Future<List<Book>> filterBooksByLanguage(String language) async {
    try {
      print('📚 BooksService: Filtering books by language: $language');
      final response = await _networkService.get('/books/language/$language');
      print('📚 BooksService: Language filter response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('📚 BooksService: Language filter response data: $data');
        if (data['success'] == true) {
          final booksData = data['books'] as List;
          final books = booksData.map((json) => Book.fromJson(json)).toList();
          print('📚 BooksService: Found ${books.length} books for language $language');
          
          // Cache filtered books locally
          await _storageService.saveBooks(books);
          
          return books;
        } else {
          print('📚 BooksService: API returned success=false for language filtering');
          return [];
        }
      } else {
        print('📚 BooksService: API returned error status ${response.statusCode} for language filtering');
        return [];
      }
    } catch (e) {
      print('📚 BooksService: Error filtering by language: $e');
      // Fallback to local filtering if network fails
      final allBooks = _storageService.getBooks();
      final filteredBooks = allBooks.where((book) => 
        book.language.toLowerCase() == language.toLowerCase()
      ).toList();
      print('📚 BooksService: Fallback local filtering found ${filteredBooks.length} books');
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
          
          // Cache categories locally
          await _storageService.saveCategories(categories);
          
          return categories;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      return _storageService.getCategories();
    }
  }

  // Get books by category
  Future<List<Book>> getBooksByCategory(String categoryId, {int limit = 20}) async {
    try {
      print('🏷️ BooksService: Filtering books by category: $categoryId');
      final response = await _networkService.get('/categories/$categoryId/books', queryParameters: {'limit': limit});
      print('🏷️ BooksService: Category filter response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('🏷️ BooksService: Category filter response data: $data');
        if (data['success'] == true) {
          final booksData = data['books'] as List;
          final books = booksData.map((json) => Book.fromJson(json)).toList();
          print('🏷️ BooksService: Found ${books.length} books for category $categoryId');
          return books;
        } else {
          print('🏷️ BooksService: API returned success=false for category filtering');
          return [];
        }
      } else {
        print('🏷️ BooksService: API returned error status ${response.statusCode} for category filtering');
        return [];
      }
    } catch (e) {
      print('🏷️ BooksService: Error filtering by category: $e');
      // Try to get from local storage if network fails
      final localBooks = _storageService.getBooks();
      final filteredBooks = localBooks.where((book) => 
        book.categories != null && 
        book.categories!.contains(categoryId)
      ).take(limit).toList();
      print('🏷️ BooksService: Fallback local filtering found ${filteredBooks.length} books');
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
      final localBooks = _storageService.getBooks();
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
        
        // Cache related books
        await _storageService.saveBooks(books);
        
        return books;
      } else {
        return [];
      }
    } catch (e) {
      // Try to get from local storage if network fails
      final allBooks = _storageService.getBooks();
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
    final allBooks = _storageService.getBooks();
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
      final allBooks = _storageService.getBooks();
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
      final allBooks = _storageService.getBooks();
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
      await _storageService.saveDownload(bookId, {
        'downloadedAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get download status
  Map<String, dynamic>? getDownloadStatus(String bookId) {
    return _storageService.getDownload(bookId);
  }

  // Clear local cache
  Future<void> clearCache() async {
    await _storageService.clearCache();
  }
}
