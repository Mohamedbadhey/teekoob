import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/features/books/presentation/widgets/search_bar.dart' as custom_search;
import 'package:teekoob/features/books/presentation/widgets/book_filters.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCategories = [];
  String _selectedYear = '';
  String _sortBy = 'title';
  String _sortOrder = 'asc';
  bool _hasLoadedInitialData = false;
  bool _isInitialBuild = true;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    print('🏗️ BooksPage: initState called');
    // Load books immediately when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🏗️ BooksPage: PostFrameCallback called');
      if (!_hasLoadedInitialData) {
    _loadInitialData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 BooksPage: didChangeDependencies called');
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
      print('🚫 BooksPage: Skipping initial data load - already loaded');
      return; // Prevent duplicate loading
    }
    
    print('🚀 BooksPage: Loading initial data - dispatching events');
    _hasLoadedInitialData = true;
    
    print('📚 BooksPage: Dispatching LoadBooks event');
    context.read<BooksBloc>().add(const LoadBooks());
    print('🏷️ BooksPage: Dispatching LoadGenres event');
    context.read<BooksBloc>().add(const LoadGenres());
    print('🌍 BooksPage: Dispatching LoadLanguages event');
    context.read<BooksBloc>().add(const LoadLanguages());
    print('📖 BooksPage: Dispatching LoadLibrary event');
    context.read<LibraryBloc>().add(const LoadLibrary('current_user'));
  }

  void _searchBooks(String query) {
    print('🔍 BooksPage: Search called with query: "$query"');
    if (query.trim().isNotEmpty) {
      final q = query.trim();
      print('🔍 BooksPage: Dispatching LoadBooks with search and filters for: "$q"');
      setState(() {
        _currentSearchQuery = q;
      });
      context.read<BooksBloc>().add(LoadBooks(
        search: q,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        year: _selectedYear.isEmpty ? null : _selectedYear,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      ));
    } else {
      print('🔍 BooksPage: Empty query, loading books with filters');
      setState(() {
        _currentSearchQuery = '';
      });
      _loadBooksWithFilters();
    }
  }

  void _loadBooksWithFilters() {
    if (_isInitialBuild) {
      print('🚫 BooksPage: Skipping filter load - initial build');
      _isInitialBuild = false;
      return; // Don't load on initial build
    }
    
    print('🔧 BooksPage: Loading books with filters');
    print('🔧 BooksPage: Filters - categories: $_selectedCategories, year: $_selectedYear');
    print('🔧 BooksPage: Filters - sortBy: $_sortBy, sortOrder: $_sortOrder');
    
    context.read<BooksBloc>().add(LoadBooks(
      search: _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      year: _selectedYear.isEmpty ? null : _selectedYear,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    ));
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<BooksBloc, BooksState>(
      listenWhen: (previous, current) {
        // Only listen to states that are relevant to the books list
        return current is BooksLoading || 
               current is BooksLoaded || 
               current is BooksError || 
               current is SearchResultsLoaded;
      },
      listener: (context, state) {
        print('🎧 BooksPage BlocListener: State changed to ${state.runtimeType}');
        
        if (state is BooksLoading) {
          print('⏳ BooksPage Listener: Books are loading...');
        } else if (state is BooksLoaded) {
          print('✅ BooksPage Listener: Books loaded successfully - ${state.books.length} books');
        } else if (state is BooksError) {
          print('❌ BooksPage Listener: Books error - ${state.message}');
        } else if (state is SearchResultsLoaded) {
          print('🔍 BooksPage Listener: Search results loaded - ${state.books.length} books');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              _buildSearchSection(),
          Expanded(
            child: BlocBuilder<BooksBloc, BooksState>(
                  buildWhen: (previous, current) {
                    // Only rebuild for states that are relevant to the books list
                    return current is BooksLoading || 
                           current is BooksLoaded || 
                           current is BooksError || 
                           current is SearchResultsLoaded ||
                           current is BooksInitial;
                  },
              builder: (context, state) {
                    print('🔍 BooksPage BlocBuilder: Current state = ${state.runtimeType}');
                    
                if (state is BooksLoading) {
                      print('📱 BooksPage: Showing loading state');
                      return _buildLoadingState();
                } else if (state is BooksError) {
                      print('❌ BooksPage: Showing error state - ${state.message}');
                      return _buildErrorState(state);
                    } else if (state is SearchResultsLoaded) {
                      print('🔍 BooksPage: Showing search results - ${state.books.length} books');
                      // Show the same compact list without a separate search header
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildBooksList(state.books),
                          ),
                        ],
                      );
                    } else if (state is BooksLoaded) {
                      print('📚 BooksPage: Showing books grid - ${state.books.length} books');
                      return _buildBooksGrid(state);
                    } else {
                      print('⏳ BooksPage: Initial/Unknown state, showing loading state');
                      return _buildLoadingState();
                    }
                  },
                ),
              ),
            ],
          ),
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
                const Color(0xFF0466c8),
                const Color(0xFFE55A1A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0466c8).withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% of screen width
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.06, // 6% of screen width
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // 3% of screen width
                        Text(
                  'Explore Books',
                  style: TextStyle(
                    fontSize: screenWidth * 0.055, // 5.5% of screen width
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                        ),
                      ],
                    ),
          ),
          
          // Filter button with badge
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.04), // 4% of screen width
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                    color: const Color(0xFF0466c8),
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: screenWidth * 0.02, // 2% of screen width
                        height: screenWidth * 0.02, // 2% of screen width
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
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
            screenWidth * 0.05, // 5% of screen width
            0, 
            screenWidth * 0.05, // 5% of screen width
            screenWidth * 0.04, // 4% of screen width
          ),
      child: Column(
        children: [
          // Search bar with enhanced styling
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
                _loadBooksWithFilters();
              },
            ),
          ),
          
          // Search suggestions removed per request
        ],
      ),
        );
      },
    );
  }



  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0466c8).withOpacity(0.1),
                  const Color(0xFF1E3A8A).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0466c8)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discovering amazing books...',
            style: TextStyle(
              color: const Color(0xFF1E3A8A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          // Removed extra loading subtitle per request
        ],
      ),
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
              color: Colors.grey[100],
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
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            state.message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Colors.white,
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
              'Start Your Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Discover thousands of amazing books waiting for you. Use the search bar or filters to find your next favorite read.',
              style: TextStyle(
                color: Colors.grey[600],
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
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
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
                  label: const Text('Filter'),
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
                  color: const Color(0xFF1E3A8A),
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
                        color: Colors.grey[600],
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
                  style: const TextStyle(
                    color: Colors.white,
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
                  foregroundColor: Colors.white,
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
                      Colors.grey[100]!,
                      Colors.grey[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(70),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 70,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
            Text(
              LocalizationService.getLocalizedText(
                  englishText: 'No Books Found',
                  somaliText: 'Kutubta Lama Helin',
                ),
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
              LocalizationService.getLocalizedText(
                  englishText: 'Try adjusting your search terms or filters to find what you\'re looking for.',
                  somaliText: 'Isku day inaad beddesho raadinta ama shaandhaynta si aad u heshid waxa aad raadineysid.',
                ),
                style: TextStyle(
                  color: Colors.grey[600],
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
                    label: const Text('Clear Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
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
                    label: const Text('Adjust Filters'),
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
                  isFavorite = libraryState.library.any((item) => 
                    item['bookId'] == book.id && (item['isFavorite'] == true || item['status'] == 'favorite')
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
}
