import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/features/books/presentation/widgets/shimmer_book_card.dart';
import 'package:teekoob/features/books/presentation/widgets/search_bar.dart' as custom_search;
import 'package:teekoob/features/books/presentation/widgets/book_filters.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/features/podcasts/services/podcasts_service.dart';
import 'package:teekoob/features/podcasts/presentation/widgets/podcast_card.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/features/books/services/books_service.dart';

enum ContentType { all, books, podcast }

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final TextEditingController _searchController = TextEditingController();
  final BooksService _booksService = BooksService();
  final PodcastsService _podcastsService = PodcastsService();
  List<String> _selectedCategories = [];
  String _selectedYear = '';
  String _sortBy = 'title';
  String _sortOrder = 'asc';
  bool _hasLoadedInitialData = false;
  bool _isInitialBuild = true;
  String _currentSearchQuery = '';
  List<dynamic> _allContent = [];
  ContentType _selectedContentType = ContentType.all;
  bool _isLoadingContent = false;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    // Load books immediately when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedInitialData) {
    _loadInitialData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load if we haven't loaded initial data yet
    if (!_hasLoadedInitialData) {
    _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (_hasLoadedInitialData) {
      return; // Prevent duplicate loading
    }
    
    _hasLoadedInitialData = true;
    
    // Load metadata (genres, languages) and library
    context.read<BooksBloc>().add(const LoadGenres());
    context.read<BooksBloc>().add(const LoadLanguages());
    context.read<LibraryBloc>().add(const LoadLibrary('current_user'));
    
    // Load initial books and podcasts on page load
    _loadCombinedContent();
  }

  void _searchBooks(String query) {
    if (query.trim().isNotEmpty) {
      final q = query.trim();
      setState(() {
        _currentSearchQuery = q;
      });
      _loadCombinedContent();
    } else {
      setState(() {
        _currentSearchQuery = '';
      });
      _loadCombinedContent();
    }
  }

  void _loadBooksWithFilters() {
    if (_isInitialBuild) {
      _isInitialBuild = false;
      return; // Don't load on initial build
    }
    
    
    _loadCombinedContent();
  }

  void _applyFilters() {
    _isInitialBuild = false; // Allow loading when filters are applied
    _loadBooksWithFilters();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedYear = '';
      _sortBy = 'title';
      _sortOrder = 'asc';
    });
    _isInitialBuild = false; // Allow loading when filters are cleared
    _loadBooksWithFilters();
  }

 Future<void> _loadCombinedContent() async {
  setState(() { _isLoadingContent = true; _contentError = null; });
  try {
    final booksFut = _booksService.getBooks(
      search: _currentSearchQuery,
      categories: _selectedCategories,
      year: _selectedYear.isNotEmpty ? _selectedYear : null,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    ).then((res) {
      return res['books'] as List;
    });
    
    final podcastsFut = _podcastsService.getPodcasts(
      search: _currentSearchQuery,
      categories: _selectedCategories,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    ).then((res) {
      return res['podcasts'] as List;
    });
    
    final books = await booksFut;
    final podcasts = await podcastsFut;
    
    final allContent = [...books, ...podcasts];
    
    setState(() {
      _allContent = allContent;
    });
  } catch (e, stackTrace) {
    setState(() => _contentError = e.toString());
  } finally {
    setState(() => _isLoadingContent = false);
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildSearchSection(),
            Expanded(child: _buildContentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, // 5% of screen width
            vertical: screenWidth * 0.05, // 5% of screen width
          ),
      child: Row(
        children: [
          // Title with icon
          Expanded(
            child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% of screen width
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: screenWidth * 0.06, // 6% of screen width
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // 3% of screen width
                        Text(
                  LocalizationService.getExploreBooksText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.055, // 5.5% of screen width
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                        ),
                      ],
                    ),
          ),
          
          // Filter button with badge
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(screenWidth * 0.04), // 4% of screen width
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Stack(
                      children: [
                        Icon(
                    Icons.tune_rounded,
                    size: screenWidth * 0.06, // 6% of screen width
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: screenWidth * 0.02, // 2% of screen width
                        height: screenWidth * 0.02, // 2% of screen width
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
        ],
      ),
              onPressed: () => _showFiltersDialog(),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty || 
           _selectedYear.isNotEmpty;
  }

  Widget _buildSearchSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Container(
          margin: EdgeInsets.fromLTRB(
            screenWidth * 0.05, 
            0, 
            screenWidth * 0.05, 
            screenWidth * 0.04,
          ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: custom_search.SearchBar(
              controller: _searchController,
              onSearch: _searchBooks,
              onClear: () {
                _searchController.clear();
                _loadCombinedContent();
              },
            ),
          ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _contentTypeButton('All', ContentType.all),
                  SizedBox(width: 12),
                  _contentTypeButton('Books', ContentType.books),
                  SizedBox(width: 12),
                  _contentTypeButton('Podcast', ContentType.podcast),
                ],
              ),
        ],
      ),
        );
      },
    );
  }

  Widget _contentTypeButton(String label, ContentType type) {
    final bool selected = _selectedContentType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedContentType = type);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200,
        foregroundColor: selected
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: selected ? 2 : 0,
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }


  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05, // 5% of screen width
            0, 
            screenWidth * 0.05, // 5% of screen width
            screenHeight * 0.02, // 2% of screen height
          ),
          itemCount: 8, // Show 8 shimmer cards
          itemBuilder: (context, index) {
            // Alternate soft backgrounds for better distinction
            final Color itemBg = index % 2 == 0
              ? const Color(0xFFF8FAFF)
              : const Color(0xFFFAFAFF);

            return ShimmerBookCard(
              compact: true,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(BooksError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.error_outline,
              size: 60,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LocalizationService.getSomethingWentWrongText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            state.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: Text(LocalizationService.getTryAgainText),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beautiful empty state illustration
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0466c8).withOpacity(0.1),
                    const Color(0xFF1E3A8A).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 70,
                color: const Color(0xFF1E3A8A).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              LocalizationService.getStartYourJourneyText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationService.getDiscoverBooksDescriptionText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _loadCombinedContent();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(LocalizationService.getRefreshText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showFiltersDialog(),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(LocalizationService.getFilterText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchResultsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beautiful search results header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.1),
                const Color(0xFF0466c8).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
            LocalizationService.getLocalizedText(
                        englishText: 'Search Results',
                        somaliText: 'Natiijooyinka Raadinta',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${state.query}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8),
                  borderRadius: BorderRadius.circular(20),
                ),
          child: Text(
                  '${state.books.length} found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBooksList(state.books),
        ),
      ],
    );
  }

  Widget _buildBooksGrid(BooksLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Removed "Book Collection" header per request
        Expanded(
          child: _buildBooksList(state.books),
        ),
        if (state.totalPages > 1 && !state.hasReachedMax)
          Container(
            margin: const EdgeInsets.all(20),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<BooksBloc>().add(LoadBooks(
                    page: state.page + 1,
                    limit: state.limit,
                    search: _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
                    categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
                    year: _selectedYear.isEmpty ? null : _selectedYear,
                    sortBy: _sortBy,
                    sortOrder: _sortOrder,
                  ));
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(LocalizationService.getLoadMoreText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBooksList(List<dynamic> books) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              // Beautiful no results illustration
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.background,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(70),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 70,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 32),
            Text(
              LocalizationService.getNoBooksFoundText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
              const SizedBox(height: 12),
            Text(
              LocalizationService.getTryAdjustingSearchText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _loadBooksWithFilters();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(LocalizationService.getClearSearchText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showFiltersDialog(),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(LocalizationService.getAdjustFiltersText),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
              ),
            ),
          ],
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05, // 5% of screen width
            0, 
            screenWidth * 0.05, // 5% of screen width
            screenHeight * 0.02, // 2% of screen height
      ),
      itemCount: books.length,
          itemBuilder: (context, index) {
        final book = books[index];
            return BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, libraryState) {
                bool isInLibrary = false;
                bool isFavorite = false;
                
                if (libraryState is LibraryLoaded) {
                  isInLibrary = libraryState.library.any((item) => item['bookId'] == book.id);
                  // Check favorites from favorites list
                  isFavorite = libraryState.favorites.any((fav) => 
                    fav['item_type'] == 'book' && fav['item_id'] == book.id
                  );
                }
                
                // Alternate soft backgrounds for better distinction
                final Color itemBg = index % 2 == 0
                  ? const Color(0xFFF8FAFF)
                  : const Color(0xFFFAFAFF);

                return BookCard(
          book: book,
                  onTap: () => _navigateToBookDetail(book),
                  showLibraryActions: true,
                  isInLibrary: isInLibrary,
                  isFavorite: isFavorite,
                  userId: 'current_user', // TODO: Get from auth service
                  compact: true,
                  backgroundColor: itemBg,
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToBookDetail(Book book) {
    context.go('/book/${book.id}');
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BookFilters(
        selectedCategories: _selectedCategories,
        selectedYear: _selectedYear,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        onApply: (categories, year, sortBy, sortOrder) {
          setState(() {
            _selectedCategories = categories;
            _selectedYear = year;
            _sortBy = sortBy;
            _sortOrder = sortOrder;
          });
          _applyFilters();
          Navigator.of(context).pop();
        },
        onClear: () {
          _clearFilters();
          Navigator.of(context).pop();
        },
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (_isLoadingContent) {
      return Center(child: CircularProgressIndicator());
    }
    if (_contentError != null) {
      final isRateLimit = _contentError!.contains('429') || 
                          _contentError!.contains('Too many requests') ||
                          _contentError!.contains('rate limit');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isRateLimit 
                    ? 'Too many requests. Please wait a moment and try again.'
                    : 'Error loading content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _contentError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_allContent.isEmpty) {
      // Show helpful message prompting user to search
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Search for books or podcasts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the search bar above to find content, or apply filters to browse',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // Separate by type
   final books = _allContent.where((e) => e is Book).cast<Book>().toList();
final podcasts = _allContent.where((e) => e is Podcast).cast<Podcast>().toList();
    List<dynamic> feedCards;
    switch (_selectedContentType) {
      case ContentType.books:
        feedCards = books;
        break;
      case ContentType.podcast:
        feedCards = podcasts;
        break;
      default:
        feedCards = [...books, ...podcasts];
        break;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 2;
        if (screenWidth > 800) crossAxisCount = 4;
        else if (screenWidth > 600) crossAxisCount = 3;
        final cardWidth = (screenWidth - 24 - (crossAxisCount-1)*16) / crossAxisCount;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82, // More compact - wider cards, less tall
          ),
          itemCount: feedCards.length,
          itemBuilder: (context, index) {
            final item = feedCards[index];
            if (item is Book) {
              return BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, libraryState) {
                  bool isFavorite = false;
                  if (libraryState is LibraryLoaded) {
                    isFavorite = libraryState.favorites.any((fav) => 
                      fav['item_type'] == 'book' && fav['item_id'] == item.id
                    );
                  }
                  
                  return BookCard(
                    book: item,
                    onTap: () => _navigateToBookDetail(item),
                    compact: false,
                    width: cardWidth,
                    userId: 'current_user',
                    showLibraryActions: true,
                    isFavorite: isFavorite,
                  );
                },
              );
            } else if (item is Podcast) {
              return BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, libraryState) {
                  bool isFavorite = false;
                  if (libraryState is LibraryLoaded) {
                    isFavorite = libraryState.favorites.any((fav) => 
                      fav['item_type'] == 'podcast' && fav['item_id'] == item.id
                    );
                  }
                  
                  return PodcastCard(
                    podcast: item,
                    onTap: () => _navigateToPodcastDetail(item),
                    width: cardWidth,
                    userId: 'current_user',
                    showLibraryActions: true,
                    isFavorite: isFavorite,
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Icon(
            title == 'Books' ? Icons.menu_book_rounded : Icons.podcasts_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.primary,
              shadows: [Shadow(color: Colors.black12, blurRadius: 6)],
            ),
          )
        ],
      ),
    );
  }

  void _navigateToPodcastDetail(Podcast podcast) {
    context.go('/podcast/${podcast.id}');
  }
}
