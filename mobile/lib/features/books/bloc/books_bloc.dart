import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';

// Events
abstract class BooksEvent extends Equatable {
  const BooksEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooks extends BooksEvent {
  final int page;
  final int limit;
  final String? search;
  final String? genre;
  final List<String>? categories;
  final String? language;
  final String? format;
  final String? year;
  final bool? isFeatured;
  final bool? isNewRelease;
  final String? sortBy;
  final String? sortOrder;

  const LoadBooks({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.genre,
    this.categories,
    this.language,
    this.format,
    this.year,
    this.isFeatured,
    this.isNewRelease,
    this.sortBy,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [
    page, limit, search, genre, categories, language, format, year,
    isFeatured, isNewRelease, sortBy, sortOrder
  ];
}

class LoadBookById extends BooksEvent {
  final String bookId;

  const LoadBookById(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class LoadFeaturedBooks extends BooksEvent {
  final int limit;

  const LoadFeaturedBooks({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadNewReleases extends BooksEvent {
  final int limit;

  const LoadNewReleases({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadRandomBooks extends BooksEvent {
  final int limit;

  const LoadRandomBooks({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadRecentBooks extends BooksEvent {
  final int limit;

  const LoadRecentBooks({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class SearchBooks extends BooksEvent {
  final String query;
  final int limit;

  const SearchBooks(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class LoadBooksByGenre extends BooksEvent {
  final String genre;
  final int limit;

  const LoadBooksByGenre(this.genre, {this.limit = 20});

  @override
  List<Object?> get props => [genre, limit];
}

class LoadBooksByAuthor extends BooksEvent {
  final String author;
  final int limit;

  const LoadBooksByAuthor(this.author, {this.limit = 20});

  @override
  List<Object?> get props => [author, limit];
}

class FilterBooksByCategory extends BooksEvent {
  final String? category;

  const FilterBooksByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterBooksByLanguage extends BooksEvent {
  final String language;

  const FilterBooksByLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

class LoadCategories extends BooksEvent {
  const LoadCategories();
}

class LoadAudiobooks extends BooksEvent {
  final int limit;

  const LoadAudiobooks({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class LoadEbooks extends BooksEvent {
  final int limit;

  const LoadEbooks({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class LoadGenres extends BooksEvent {
  const LoadGenres();
}

class LoadLanguages extends BooksEvent {
  const LoadLanguages();
}

class LoadBookRecommendations extends BooksEvent {
  final String bookId;
  final int limit;

  const LoadBookRecommendations(this.bookId, {this.limit = 5});

  @override
  List<Object?> get props => [bookId, limit];
}

class RateBook extends BooksEvent {
  final String bookId;
  final double rating;

  const RateBook(this.bookId, this.rating);

  @override
  List<Object?> get props => [bookId, rating];
}

class AddBookReview extends BooksEvent {
  final String bookId;
  final String review;
  final double rating;

  const AddBookReview(this.bookId, this.review, this.rating);

  @override
  List<Object?> get props => [bookId, review, rating];
}

class LoadBookReviews extends BooksEvent {
  final String bookId;
  final int page;
  final int limit;

  const LoadBookReviews(this.bookId, {this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [bookId, page, limit];
}

class DownloadBookSample extends BooksEvent {
  final String bookId;

  const DownloadBookSample(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class CheckBookAvailability extends BooksEvent {
  final String bookId;

  const CheckBookAvailability(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class ClearBooks extends BooksEvent {
  const ClearBooks();
}

// States
abstract class BooksState extends Equatable {
  const BooksState();

  @override
  List<Object?> get props => [];
}

class BooksInitial extends BooksState {
  const BooksInitial();
}

class BooksLoading extends BooksState {
  const BooksLoading();
}

class BooksLoaded extends BooksState {
  final List<Book> books;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasReachedMax;

  const BooksLoaded({
    required this.books,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.hasReachedMax = false,
  });

  BooksLoaded copyWith({
    List<Book>? books,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    bool? hasReachedMax,
  }) {
    return BooksLoaded(
      books: books ?? this.books,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [books, total, page, limit, totalPages, hasReachedMax];
}

class BookLoaded extends BooksState {
  final Book book;

  const BookLoaded(this.book);

  @override
  List<Object?> get props => [book];
}

class FeaturedBooksLoaded extends BooksState {
  final List<Book> books;

  const FeaturedBooksLoaded(this.books);

  @override
  List<Object?> get props => [books];
}

class NewReleasesLoaded extends BooksState {
  final List<Book> books;
  final int total;

  const NewReleasesLoaded({
    required this.books,
    required this.total,
  });

  @override
  List<Object?> get props => [books, total];
}

class RandomBooksLoaded extends BooksState {
  final List<Book> books;
  final int total;

  const RandomBooksLoaded({
    required this.books,
    required this.total,
  });

  @override
  List<Object?> get props => [books, total];
}

class RecentBooksLoaded extends BooksState {
  final List<Book> books;
  final int total;

  const RecentBooksLoaded({
    required this.books,
    required this.total,
  });

  @override
  List<Object?> get props => [books, total];
}

class SearchResultsLoaded extends BooksState {
  final List<Book> books;
  final String query;

  const SearchResultsLoaded(this.books, this.query);

  @override
  List<Object?> get props => [books, query];
}

class GenresLoaded extends BooksState {
  final List<String> genres;

  const GenresLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}

class CategoriesLoaded extends BooksState {
  final List<Category> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class LanguagesLoaded extends BooksState {
  final List<String> languages;

  const LanguagesLoaded(this.languages);

  @override
  List<Object?> get props => [languages];
}

class RecommendationsLoaded extends BooksState {
  final List<Book> books;

  const RecommendationsLoaded(this.books);

  @override
  List<Object?> get props => [books];
}

class ReviewsLoaded extends BooksState {
  final List<Map<String, dynamic>> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class BookRated extends BooksState {
  final String bookId;
  final double rating;

  const BookRated(this.bookId, this.rating);

  @override
  List<Object?> get props => [bookId, rating];
}

class ReviewAdded extends BooksState {
  final String bookId;
  final String review;
  final double rating;

  const ReviewAdded(this.bookId, this.review, this.rating);

  @override
  List<Object?> get props => [bookId, review, rating];
}

class SampleDownloaded extends BooksState {
  final String bookId;
  final String message;

  const SampleDownloaded(this.bookId, this.message);

  @override
  List<Object?> get props => [bookId, message];
}

class BookAvailabilityChecked extends BooksState {
  final String bookId;
  final bool isAvailable;

  const BookAvailabilityChecked(this.bookId, this.isAvailable);

  @override
  List<Object?> get props => [bookId, isAvailable];
}

class BooksError extends BooksState {
  final String message;

  const BooksError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BooksService _booksService;

  BooksBloc({required BooksService booksService})
      : _booksService = booksService,
        super(const BooksInitial()) {
    
    on<LoadBooks>(_onLoadBooks);
    on<LoadBookById>(_onLoadBookById);
    on<LoadFeaturedBooks>(_onLoadFeaturedBooks);
    on<LoadNewReleases>(_onLoadNewReleases);
    on<LoadRecentBooks>(_onLoadRecentBooks);
    on<LoadRandomBooks>(_onLoadRandomBooks);
    on<SearchBooks>(_onSearchBooks);
    on<LoadBooksByGenre>(_onLoadBooksByGenre);
    on<LoadBooksByAuthor>(_onLoadBooksByAuthor);
    on<FilterBooksByCategory>(_onFilterBooksByCategory);
    on<FilterBooksByLanguage>(_onFilterBooksByLanguage);
    on<LoadCategories>(_onLoadCategories);
    on<LoadAudiobooks>(_onLoadAudiobooks);
    on<LoadEbooks>(_onLoadEbooks);
    on<LoadGenres>(_onLoadGenres);
    on<LoadLanguages>(_onLoadLanguages);
    on<LoadBookRecommendations>(_onLoadBookRecommendations);
    on<RateBook>(_onRateBook);
    on<AddBookReview>(_onAddBookReview);
    on<LoadBookReviews>(_onLoadBookReviews);
    on<DownloadBookSample>(_onDownloadBookSample);
    on<CheckBookAvailability>(_onCheckBookAvailability);
    on<ClearBooks>(_onClearBooks);
  }

  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      print('🎯 BooksBloc: _onLoadBooks called with event: $event');
      print('🎯 BooksBloc: Emitting BooksLoading state');
      emit(const BooksLoading());
      
      print('🎯 BooksBloc: Calling _booksService.getBooks...');
      final result = await _booksService.getBooks(
        page: event.page,
        limit: event.limit,
        search: event.search,
        genre: event.genre,
        categories: event.categories,
        language: event.language,
        format: event.format,
        year: event.year,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );
      
      print('🎯 BooksBloc: Received result from service: $result');

      final books = result['books'] as List<Book>;
      final total = result['total'] as int;
      final page = result['page'] as int;
      final limit = result['limit'] as int;
      final totalPages = result['totalPages'] as int;

      print('🎯 BooksBloc: Parsed data - books: ${books.length}, total: $total, page: $page');
      print('🎯 BooksBloc: Emitting BooksLoaded state with ${books.length} books');
      
      emit(BooksLoaded(
        books: books,
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
        hasReachedMax: page >= totalPages,
      ));
      
      print('🎯 BooksBloc: BooksLoaded state emitted successfully');
    } catch (e) {
      print('❌ BooksBloc: Error loading books: $e');
      print('❌ BooksBloc: Emitting BooksError state');
      emit(BooksError('Failed to load books: $e'));
    }
  }

  Future<void> _onLoadBookById(
    LoadBookById event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final book = await _booksService.getBookById(event.bookId);
      
      if (book != null) {
        emit(BookLoaded(book));
      } else {
        emit(const BooksError('Book not found'));
      }
    } catch (e) {
      emit(BooksError('Failed to load book: $e'));
    }
  }

  Future<void> _onLoadFeaturedBooks(
    LoadFeaturedBooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.getFeaturedBooks(limit: event.limit);
      
      emit(FeaturedBooksLoaded(books));
    } catch (e) {
      emit(BooksError('Failed to load featured books: $e'));
    }
  }

  Future<void> _onLoadNewReleases(
    LoadNewReleases event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.getNewReleases(limit: event.limit);

      emit(NewReleasesLoaded(books: books, total: books.length));
    } catch (e) {
      emit(BooksError('Failed to load new releases: $e'));
    }
  }

  Future<void> _onLoadRecentBooks(
    LoadRecentBooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      print('🎯 _onLoadRecentBooks: Starting to load ${event.limit} recent books...');
      emit(const BooksLoading());
      
      final books = await _booksService.getRecentBooks(limit: event.limit);
      print('📚 _onLoadRecentBooks: Service returned ${books.length} books');
      print('📖 _onLoadRecentBooks: Book titles: ${books.map((b) => b.title).toList()}');

      emit(RecentBooksLoaded(books: books, total: books.length));
      print('✅ _onLoadRecentBooks: Emitted RecentBooksLoaded state with ${books.length} books');
    } catch (e) {
      print('💥 _onLoadRecentBooks: Error occurred: $e');
      emit(BooksError('Failed to load recent books: $e'));
    }
  }

  Future<void> _onLoadRandomBooks(
    LoadRandomBooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      print('🎯 _onLoadRandomBooks: Starting to load ${event.limit} random books...');
      emit(const BooksLoading());
      
      final books = await _booksService.getRandomBooks(limit: event.limit);
      print('📚 _onLoadRandomBooks: Service returned ${books.length} books');
      print('📖 _onLoadRandomBooks: Book titles: ${books.map((b) => b.title).toList()}');

      emit(RandomBooksLoaded(books: books, total: books.length));
      print('✅ _onLoadRandomBooks: Emitted RandomBooksLoaded state with ${books.length} books');
    } catch (e) {
      print('💥 _onLoadRandomBooks: Error occurred: $e');
      emit(BooksError('Failed to load random books: $e'));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      print('🔍 BooksBloc: _onSearchBooks called with query: "${event.query}"');
      print('🔍 BooksBloc: Emitting BooksLoading state for search');
      emit(const BooksLoading());
      
      print('🔍 BooksBloc: Calling _booksService.searchBooks...');
      final books = await _booksService.searchBooks(event.query, limit: event.limit);
      
      print('🔍 BooksBloc: Search completed, found ${books.length} books');
      print('🔍 BooksBloc: Emitting SearchResultsLoaded state');
      emit(SearchResultsLoaded(books, event.query));
    } catch (e) {
      print('❌ BooksBloc: Search error: $e');
      emit(BooksError('Failed to search books: $e'));
    }
  }

  Future<void> _onLoadBooksByGenre(
    LoadBooksByGenre event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.getBooksByGenre(event.genre);
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: event.limit,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to load books by genre: $e'));
    }
  }

  Future<void> _onLoadBooksByAuthor(
    LoadBooksByAuthor event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.getBooksByAuthor(event.author);
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: event.limit,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to load books by author: $e'));
    }
  }

  Future<void> _onFilterBooksByCategory(
    FilterBooksByCategory event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.filterBooksByCategory(event.category);
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: books.length,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to filter books by category: $e'));
    }
  }

  Future<void> _onFilterBooksByLanguage(
    FilterBooksByLanguage event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final books = await _booksService.filterBooksByLanguage(event.language);
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: books.length,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to filter books by language: $e'));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final categories = await _booksService.getCategories();
      
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(BooksError('Failed to load categories: $e'));
    }
  }

  Future<void> _onLoadAudiobooks(
    LoadAudiobooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      // Get audiobooks by filtering books with audio format
      final allBooks = await _booksService.getBooks(limit: 100);
      final books = allBooks['books'].where((book) => book.format == 'audiobook').take(event.limit).toList();
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: event.limit,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to load audiobooks: $e'));
    }
  }

  Future<void> _onLoadEbooks(
    LoadEbooks event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      // Get ebooks by filtering books with ebook format
      final allBooks = await _booksService.getBooks(limit: 100);
      final books = allBooks['books'].where((book) => book.format == 'ebook').take(event.limit).toList();
      
      emit(BooksLoaded(
        books: books,
        total: books.length,
        page: 1,
        limit: event.limit,
        totalPages: 1,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(BooksError('Failed to load ebooks: $e'));
    }
  }

  Future<void> _onLoadGenres(
    LoadGenres event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final genres = await _booksService.getGenres();
      
      emit(GenresLoaded(genres));
    } catch (e) {
      emit(BooksError('Failed to load genres: $e'));
    }
  }

  Future<void> _onLoadLanguages(
    LoadLanguages event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      final languages = await _booksService.getLanguages();
      
      emit(LanguagesLoaded(languages));
    } catch (e) {
      emit(BooksError('Failed to load languages: $e'));
    }
  }

  Future<void> _onLoadBookRecommendations(
    LoadBookRecommendations event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      // First get the book by ID
      final book = await _booksService.getBookById(event.bookId);
      if (book == null) {
        emit(BooksError('Book not found'));
        return;
      }
      
      // Then get related books
      final books = await _booksService.getRelatedBooks(book);
      
      emit(RecommendationsLoaded(books));
    } catch (e) {
      emit(BooksError('Failed to load book recommendations: $e'));
    }
  }

  Future<void> _onRateBook(
    RateBook event,
    Emitter<BooksState> emit,
  ) async {
    try {
      // TODO: Implement book rating functionality
      // await _booksService.rateBook(event.bookId, event.rating);
      
      emit(BookRated(event.bookId, event.rating));
    } catch (e) {
      emit(BooksError('Failed to rate book: $e'));
    }
  }

  Future<void> _onAddBookReview(
    AddBookReview event,
    Emitter<BooksState> emit,
  ) async {
    try {
      // TODO: Implement book review functionality
      // await _booksService.addBookReview(event.bookId, event.review, event.rating);
      
      emit(ReviewAdded(event.bookId, event.review, event.rating));
    } catch (e) {
      emit(BooksError('Failed to add book review: $e'));
    }
  }

  Future<void> _onLoadBookReviews(
    LoadBookReviews event,
    Emitter<BooksState> emit,
  ) async {
    try {
      emit(const BooksLoading());
      
      // TODO: Implement book reviews functionality
      // final reviews = await _booksService.getBookReviews(
      //   event.bookId,
      //   page: event.page,
      //   limit: event.limit,
      // );
      
      emit(ReviewsLoaded([])); // Empty reviews for now
    } catch (e) {
      emit(BooksError('Failed to load book reviews: $e'));
    }
  }

  Future<void> _onDownloadBookSample(
    DownloadBookSample event,
    Emitter<BooksState> emit,
  ) async {
    try {
      // TODO: Implement book sample download functionality
      // final message = await _booksService.downloadBookSample(event.bookId);
      
      emit(SampleDownloaded(event.bookId, 'Sample download functionality coming soon!'));
    } catch (e) {
      emit(BooksError('Failed to download book sample: $e'));
    }
  }

  Future<void> _onCheckBookAvailability(
    CheckBookAvailability event,
    Emitter<BooksState> emit,
  ) async {
    try {
      // TODO: Implement book availability check functionality
      // final isAvailable = await _booksService.isBookAvailable(event.bookId);
      
      emit(BookAvailabilityChecked(event.bookId, true)); // Assume available for now
    } catch (e) {
      emit(BooksError('Failed to check book availability: $e'));
    }
  }

  Future<void> _onClearBooks(
    ClearBooks event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksInitial());
  }

  // Helper methods
  bool get isLoading => state is BooksLoading;
  bool get hasBooks => state is BooksLoaded && (state as BooksLoaded).books.isNotEmpty;
  List<Book> get currentBooks {
    if (state is BooksLoaded) {
      return (state as BooksLoaded).books;
    }
    return [];
  }

  Book? get currentBook {
    if (state is BookLoaded) {
      return (state as BookLoaded).book;
    }
    return null;
  }
}
