import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/features/books/presentation/widgets/shimmer_book_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/features/podcasts/bloc/podcasts_bloc.dart';
import 'package:teekoob/features/podcasts/presentation/widgets/podcast_card.dart';
import 'package:teekoob/core/models/podcast_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> _featuredBooks = [];
  List<Book> _newReleases = [];
  List<Book> _recentBooks = [];
  List<Book> _freeBooks = [];
  List<Book> _randomBooks = [];
  List<Category> _categories = [];
  bool _isLoadingFeatured = false;
  bool _isLoadingNewReleases = false;
  bool _isLoadingRecentBooks = false;
  bool _isLoadingFreeBooks = false;
  bool _isLoadingRandomBooks = false;
  bool _isLoadingCategories = false;
  List<String> _selectedCategoryIds = [];
  
  // Store original unfiltered lists
  List<Book> _originalFeaturedBooks = [];
  List<Book> _originalNewReleases = [];
  List<Book> _originalRecentBooks = [];
  List<Book> _originalFreeBooks = [];
  List<Book> _originalRandomBooks = [];

  // Podcast state variables
  List<Podcast> _featuredPodcasts = [];
  List<Podcast> _newReleasePodcasts = [];
  List<Podcast> _recentPodcasts = [];
  List<Podcast> _freePodcasts = [];
  List<Podcast> _randomPodcasts = [];
  bool _isLoadingFeaturedPodcasts = false;
  bool _isLoadingNewReleasePodcasts = false;
  bool _isLoadingRecentPodcasts = false;
  bool _isLoadingFreePodcasts = false;
  bool _isLoadingRandomPodcasts = false;
  
  // Store original unfiltered podcast lists
  List<Podcast> _originalFeaturedPodcasts = [];
  List<Podcast> _originalNewReleasePodcasts = [];
  List<Podcast> _originalRecentPodcasts = [];
  List<Podcast> _originalFreePodcasts = [];
  List<Podcast> _originalRandomPodcasts = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadLibraryData();
  }

  void _loadInitialData() {
    // Set all loading states to true initially
    setState(() {
      _isLoadingFeatured = true;
      _isLoadingNewReleases = true;
      _isLoadingRecentBooks = true;
      _isLoadingFreeBooks = true;
      _isLoadingRandomBooks = true;
      _isLoadingCategories = true;
      
      // Podcast loading states
      _isLoadingFeaturedPodcasts = true;
      _isLoadingNewReleasePodcasts = true;
      _isLoadingRecentPodcasts = true;
      _isLoadingFreePodcasts = true;
      _isLoadingRandomPodcasts = true;
    });
    
    // Load featured books (for featured section)
    context.read<BooksBloc>().add(const LoadFeaturedBooks(limit: 6));
    
    // Load new releases (for new releases section)
    context.read<BooksBloc>().add(const LoadNewReleases(limit: 10));
    
    // Load recent books (sorted by date - most recent first)
    context.read<BooksBloc>().add(const LoadRecentBooks(limit: 6));
    
    // Load free books
    context.read<BooksBloc>().add(const LoadFreeBooks(limit: 6));
    
    // Load random books for recommendations
    context.read<BooksBloc>().add(const LoadRandomBooks(limit: 5));
    
    // Load categories
    context.read<BooksBloc>().add(const LoadCategories());
    
    // Load podcasts
    context.read<PodcastsBloc>().add(const LoadFeaturedPodcasts(limit: 6));
    context.read<PodcastsBloc>().add(const LoadNewReleasePodcasts(limit: 10));
    context.read<PodcastsBloc>().add(const LoadRecentPodcasts(limit: 6));
    context.read<PodcastsBloc>().add(const LoadFreePodcasts(limit: 6));
    context.read<PodcastsBloc>().add(const LoadRandomPodcasts(limit: 5));
  }

  void _loadLibraryData() {
    // Load library data to show correct status on book cards
    context.read<LibraryBloc>().add(const LoadLibrary('current_user'));
  }


  void _filterBooksByCategory(String? categoryId) {
    print('🏠 HomePage: Filtering by category: $categoryId');
    
    setState(() {
      if (categoryId == null) {
        // Clear all selections
        _selectedCategoryIds.clear();
      } else {
        // Toggle category selection
        if (_selectedCategoryIds.contains(categoryId)) {
          _selectedCategoryIds.remove(categoryId);
        } else {
          _selectedCategoryIds.add(categoryId);
        }
      }
    });
    
    if (_selectedCategoryIds.isEmpty) {
      // Show all books - restore original lists
      print('🏠 HomePage: No categories selected - restoring original lists');
      setState(() {
        _featuredBooks = List.from(_originalFeaturedBooks);
        _newReleases = List.from(_originalNewReleases);
        _recentBooks = List.from(_originalRecentBooks);
        _randomBooks = List.from(_originalRandomBooks);
      });
    } else {
      // Filter all book sections by selected categories
      print('🏠 HomePage: Filtering all sections by categories: $_selectedCategoryIds');
      _filterAllSectionsByCategories(_selectedCategoryIds);
    }
  }

  void _filterAllSectionsByCategories(List<String> categoryIds) {
    // Filter featured books from original list - books that match ANY of the selected categories
    final filteredFeatured = _originalFeaturedBooks.where((book) => 
      book.categories != null && categoryIds.any((categoryId) => book.categories!.contains(categoryId))
    ).toList();
    
    // Filter new releases from original list
    final filteredNewReleases = _originalNewReleases.where((book) => 
      book.categories != null && categoryIds.any((categoryId) => book.categories!.contains(categoryId))
    ).toList();
    
    // Filter recent books from original list
    final filteredRecent = _originalRecentBooks.where((book) => 
      book.categories != null && categoryIds.any((categoryId) => book.categories!.contains(categoryId))
    ).toList();
    
    // Filter random books (recommendations) from original list
    final filteredRandom = _originalRandomBooks.where((book) => 
      book.categories != null && categoryIds.any((categoryId) => book.categories!.contains(categoryId))
    ).toList();
    
    setState(() {
      _featuredBooks = filteredFeatured;
      _newReleases = filteredNewReleases;
      _recentBooks = filteredRecent;
      _randomBooks = filteredRandom;
    });
    
    print('🏠 HomePage: Filtered results - Featured: ${filteredFeatured.length}, New Releases: ${filteredNewReleases.length}, Recent: ${filteredRecent.length}, Random: ${filteredRandom.length}');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Books Bloc Listener
        BlocListener<BooksBloc, BooksState>(
          listener: (context, state) {
            if (state is FeaturedBooksLoaded) {
              setState(() {
                _featuredBooks = state.books;
                _originalFeaturedBooks = List.from(state.books); // Store original
                _isLoadingFeatured = false;
              });
              print('🏠 HomePage: Featured books loaded: ${state.books.length}');
              print('📚 HomePage: Featured book titles: ${state.books.map((b) => b.title).toList()}');
            } else if (state is NewReleasesLoaded) {
              setState(() {
                _newReleases = state.books;
                _originalNewReleases = List.from(state.books); // Store original
                _isLoadingNewReleases = false;
              });
              print('🏠 HomePage: New releases loaded: ${state.books.length}');
              print('📚 HomePage: New release titles: ${state.books.map((b) => b.title).toList()}');
            } else if (state is RecentBooksLoaded) {
              setState(() {
                _recentBooks = state.books;
                _originalRecentBooks = List.from(state.books); // Store original
                _isLoadingRecentBooks = false;
              });
              print('🏠 HomePage: Recent books loaded: ${state.books.length}');
              print('📚 HomePage: Recent book titles: ${state.books.map((b) => b.title).toList()}');
            } else if (state is FreeBooksLoaded) {
              setState(() {
                _freeBooks = state.books;
                _originalFreeBooks = List.from(state.books); // Store original
                _isLoadingFreeBooks = false;
              });
              print('🏠 HomePage: Free books loaded: ${state.books.length}');
              print('📚 HomePage: Free book titles: ${state.books.map((b) => b.title).toList()}');
            } else if (state is RandomBooksLoaded) {
              print('🏠 HomePage: RandomBooksLoaded state received with ${state.books.length} books');
              print('📚 HomePage: Book titles: ${state.books.map((b) => b.title).toList()}');
              setState(() {
                _randomBooks = state.books;
                _originalRandomBooks = List.from(state.books); // Store original
                _isLoadingRandomBooks = false;
              });
              print('✅ HomePage: Updated _randomBooks state with ${_randomBooks.length} books');
              print('📖 HomePage: Final _randomBooks titles: ${_randomBooks.map((b) => b.title).toList()}');
            } else if (state is CategoriesLoaded) {
              setState(() {
                _categories = state.categories;
                _isLoadingCategories = false;
              });
              print('🏠 HomePage: Categories loaded: ${state.categories.length}');
            } else if (state is BooksError) {
              print('🏠 HomePage: Books error: ${state.message}');
            }
          },
        ),
        // Podcasts Bloc Listener
        BlocListener<PodcastsBloc, PodcastsState>(
          listener: (context, state) {
            if (state is FeaturedPodcastsLoaded) {
              setState(() {
                _featuredPodcasts = state.podcasts;
                _originalFeaturedPodcasts = List.from(state.podcasts);
                _isLoadingFeaturedPodcasts = false;
              });
              print('🏠 HomePage: Featured podcasts loaded: ${state.podcasts.length}');
            } else if (state is NewReleasePodcastsLoaded) {
              setState(() {
                _newReleasePodcasts = state.podcasts;
                _originalNewReleasePodcasts = List.from(state.podcasts);
                _isLoadingNewReleasePodcasts = false;
              });
              print('🏠 HomePage: New release podcasts loaded: ${state.podcasts.length}');
            } else if (state is RecentPodcastsLoaded) {
              setState(() {
                _recentPodcasts = state.podcasts;
                _originalRecentPodcasts = List.from(state.podcasts);
                _isLoadingRecentPodcasts = false;
              });
              print('🏠 HomePage: Recent podcasts loaded: ${state.podcasts.length}');
            } else if (state is FreePodcastsLoaded) {
              setState(() {
                _freePodcasts = state.podcasts;
                _originalFreePodcasts = List.from(state.podcasts);
                _isLoadingFreePodcasts = false;
              });
              print('🏠 HomePage: Free podcasts loaded: ${state.podcasts.length}');
            } else if (state is RandomPodcastsLoaded) {
              setState(() {
                _randomPodcasts = state.podcasts;
                _originalRandomPodcasts = List.from(state.podcasts);
                _isLoadingRandomPodcasts = false;
              });
              print('🏠 HomePage: Random podcasts loaded: ${state.podcasts.length}');
            } else if (state is PodcastsError) {
              print('🏠 HomePage: Podcasts error: ${state.message}');
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryFiltersSection(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFeaturedBookSection(),
                      const SizedBox(height: 32),
                      _buildFeaturedPodcastsSection(),
                      const SizedBox(height: 32),
                      _buildFreeBooksSection(),
                      const SizedBox(height: 32),
                      _buildFreePodcastsSection(),
                      const SizedBox(height: 32),
                      _buildRecentBooksSection(),
                      const SizedBox(height: 32),
                      _buildRecentPodcastsSection(),
                      const SizedBox(height: 32),
                      _buildNewReleasesSection(),
                      const SizedBox(height: 32),
                      _buildNewReleasePodcastsSection(),
                      const SizedBox(height: 32),
                      _buildRecommendedBooksSection(),
                      const SizedBox(height: 32),
                      _buildRecommendedPodcastsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Title (centered)
          Expanded(
            child: Text(
              LocalizationService.getHomeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          
          // Notification bell
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCategoryFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.getFilterByCategoryText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingCategories)
            _buildCategoriesLoading()
          else if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All Categories" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildCategoryChip(
                      LocalizationService.getAllCategoriesText,
                      null,
                      0,
                      _selectedCategoryIds.isEmpty,
                    ),
                  ),
                  // Category chips
                  ..._categories.map((category) {
                    final isSelected = _selectedCategoryIds.contains(category.id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCategoryChip(
                        category.name,
                        category.id,
                        category.bookCount,
                        isSelected,
                        category.color,
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            Text(
              LocalizationService.getNoCategoriesAvailableText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId, int count, bool isSelected, [String? color]) {
    final chipColor = color != null 
        ? Color(int.parse(color.replaceAll('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => _filterBooksByCategory(categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (categoryId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesLoading() {
    return Row(
      children: List.generate(4, (index) => 
        Container(
          margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
          height: 40,
          width: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBookSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            LocalizationService.getFeaturedBookText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Featured Book Card
          if (_isLoadingFeatured) ...[
            SizedBox(
              width: double.infinity,
              child: ShimmerBookCard(
                width: double.infinity,
                height: _getResponsiveHorizontalCardHeight(),
              ),
            ),
          ] else if (_featuredBooks.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, libraryState) {
                  final book = _featuredBooks.first;
                  bool isInLibrary = false;
                  bool isFavorite = false;
                  
                  if (libraryState is LibraryLoaded) {
                    isInLibrary = libraryState.library.any((item) => item['bookId'] == book.id);
                    isFavorite = libraryState.library.any((item) => 
                      item['bookId'] == book.id && (item['isFavorite'] == true || item['status'] == 'favorite')
                    );
                  }
                  
                  return BookCard(
                    book: book,
                    onTap: () => _navigateToBookDetail(book),
                    showLibraryActions: false, // Disabled for cleaner design
                    isInLibrary: isInLibrary,
                    isFavorite: isFavorite,
                    userId: 'current_user', // TODO: Get from auth service
                    enableAnimations: true,
                  );
                },
              ),
            ),
          ] else ...[
            _buildEmptyState(LocalizationService.getNoFeaturedBookAvailableText),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeBooksSection() {
    print('Building Free Books Section - _freeBooks: ${_freeBooks.length}, _isLoadingFreeBooks: $_isLoadingFreeBooks');
    
    if (_isLoadingFreeBooks)
      return _buildLoadingHorizontalScroll();
    else if (_freeBooks.isNotEmpty)
      return _buildBooksHorizontalScroll(_freeBooks, 'Free Books');
    else
      return _buildEmptyState('No free books available');
  }

  Widget _buildRecentBooksSection() {
    print('Building Recent Books Section - _recentBooks: ${_recentBooks.length}, _isLoadingRecentBooks: $_isLoadingRecentBooks');
    
    if (_isLoadingRecentBooks)
      return _buildLoadingHorizontalScroll();
    else if (_recentBooks.isNotEmpty)
      return _buildBooksHorizontalScroll(_recentBooks, LocalizationService.getRecentBooksText);
    else
      return _buildEmptyState(LocalizationService.getNoRecentBooksAvailableText);
  }

  Widget _buildNewReleasesSection() {
    print('Building New Releases Section - _newReleases: ${_newReleases.length}, _isLoadingNewReleases: $_isLoadingNewReleases');
    
    if (_isLoadingNewReleases)
      return _buildLoadingHorizontalScroll();
    else if (_newReleases.isNotEmpty)
      return _buildBooksHorizontalScroll(_newReleases, LocalizationService.getNewReleasesText);
    else
      return _buildEmptyState(LocalizationService.getNoNewReleasesAvailableText);
  }

  Widget _buildRecommendedBooksSection() {
    print('🏗️ Building Recommended Books Section');
    print('📊 _randomBooks count: ${_randomBooks.length}');
    print('📚 _randomBooks titles: ${_randomBooks.map((b) => b.title).toList()}');
    print('⏳ _isLoadingRandomBooks: $_isLoadingRandomBooks');
    print('🔍 _randomBooks data: ${_randomBooks.map((b) => {'id': b.id, 'title': b.title, 'coverImageUrl': b.coverImageUrl}).toList()}');
    
    if (_isLoadingRandomBooks)
      return _buildLoadingHorizontalScroll();
    else if (_randomBooks.isNotEmpty)
      return _buildBooksHorizontalScroll(_randomBooks, LocalizationService.getRecommendedBooksText);
    else
      return _buildEmptyState(LocalizationService.getNoRecommendedBooksAvailableText);
  }

  Widget _buildEmptyState(String message) {
    // Determine section title and route based on message
    String sectionTitle = LocalizationService.getRecentBooksText;
    String route = '/all-books/recent/${LocalizationService.getRecentBooksText}';
    
    if (message.contains('new releases') || message.contains('soo saarid')) {
      sectionTitle = LocalizationService.getNewReleasesText;
      route = '/all-books/new-releases/${LocalizationService.getNewReleasesText}';
    } else if (message.contains('recommended') || message.contains('la soo jeediyay')) {
      sectionTitle = LocalizationService.getRecommendedBooksText;
      route = '/all-books/recommended/${LocalizationService.getRecommendedBooksText}';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go(route);
                },
                child: Text(
                  LocalizationService.getViewAllText,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Empty state container
        Container(
          height: _getResponsiveHorizontalCardHeight() + 20, // Use responsive height
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBooksGrid(List<Book> books) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getResponsiveGridColumns(); // Professional responsive columns
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16), // Proper padding to prevent overlap
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _getResponsiveGridAspectRatioFromHeight(), // Use same height as horizontal cards
            crossAxisSpacing: _getResponsiveGridSpacing(), // Responsive spacing
            mainAxisSpacing: _getResponsiveGridSpacing(), // Responsive spacing
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
                
                return BookCard(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                  showLibraryActions: false, // Disabled for cleaner design
                  isInLibrary: isInLibrary,
                  isFavorite: isFavorite,
                  userId: 'current_user', // TODO: Get from auth service
                  enableAnimations: true,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBooksHorizontalScroll(List<Book> books, String sectionTitle) {
    print('🔄 _buildBooksHorizontalScroll: Building horizontal scroll with ${books.length} books');
    print('📖 _buildBooksHorizontalScroll: Book titles: ${books.map((b) => b.title).toList()}');
    
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with view all button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (sectionTitle == LocalizationService.getRecentBooksText) {
                    context.go('/all-books/recent/${LocalizationService.getRecentBooksText}');
                  } else if (sectionTitle == LocalizationService.getNewReleasesText) {
                    context.go('/all-books/new-releases/${LocalizationService.getNewReleasesText}');
                  } else if (sectionTitle == LocalizationService.getRecommendedBooksText) {
                    context.go('/all-books/recommended/${LocalizationService.getRecommendedBooksText}');
                  }
                },
                child: Text(
                  LocalizationService.getViewAllText,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal scrollable books - Dynamic height with overflow protection
        SizedBox(
          height: _getResponsiveHorizontalCardHeight() + 20, // Card height + padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView.builder(
                padding: const EdgeInsets.only(left: 20),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  print('🎨 _buildBooksHorizontalScroll: Building item $index for book: ${book.title}');
                  
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
                      
                      return BookCard(
                        book: book,
                        onTap: () => _navigateToBookDetail(book),
                        showLibraryActions: false, // Disabled for cleaner design
                        isInLibrary: isInLibrary,
                        isFavorite: isFavorite,
                        userId: 'current_user', // TODO: Get from auth service
                        width: _getResponsiveHorizontalCardWidth(), // Responsive width based on screen size
                        // No fixed height - uses responsive height from BookCard component
                        enableAnimations: true,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return Column(
      children: [
        Row(
          children: List.generate(3, (index) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (index) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHorizontalScroll() {
    return SizedBox(
      height: _getResponsiveHorizontalScrollHeight(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: index < 4 ? 16 : 0),
            child: ShimmerBookCard(
              width: _getResponsiveHorizontalCardWidth(),
              height: _getResponsiveHorizontalCardHeight(),
            ),
          );
        },
      ),
    );
  }


  void _navigateToBookDetail(Book book) {
    context.go('/book/${book.id}');
  }

  void _navigateToPodcastDetail(Podcast podcast) {
    context.go('/podcast/${podcast.id}');
  }

  // Podcast Section Builders
  Widget _buildFeaturedPodcastsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            LocalizationService.getFeaturedPodcastsText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Featured Podcast Card
          if (_isLoadingFeaturedPodcasts) ...[
            SizedBox(
              width: double.infinity,
              child: ShimmerPodcastCard(
                width: double.infinity,
                height: _getResponsiveHorizontalCardHeight(),
              ),
            ),
          ] else if (_featuredPodcasts.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: PodcastCard(
                podcast: _featuredPodcasts.first,
                onTap: () => _navigateToPodcastDetail(_featuredPodcasts.first),
                showLibraryActions: false,
                isInLibrary: false,
                isFavorite: false,
                userId: 'current_user',
                enableAnimations: true,
              ),
            ),
          ] else ...[
            _buildEmptyPodcastState(LocalizationService.getNoFeaturedPodcastsAvailableText),
          ],
        ],
      ),
    );
  }

  Widget _buildFreePodcastsSection() {
    print('Building Free Podcasts Section - _freePodcasts: ${_freePodcasts.length}, _isLoadingFreePodcasts: $_isLoadingFreePodcasts');
    
    if (_isLoadingFreePodcasts)
      return _buildLoadingPodcastHorizontalScroll();
    else if (_freePodcasts.isNotEmpty)
      return _buildPodcastsHorizontalScroll(_freePodcasts, LocalizationService.getFreePodcastsText);
    else
      return _buildEmptyPodcastState(LocalizationService.getNoFreePodcastsAvailableText);
  }

  Widget _buildRecentPodcastsSection() {
    print('Building Recent Podcasts Section - _recentPodcasts: ${_recentPodcasts.length}, _isLoadingRecentPodcasts: $_isLoadingRecentPodcasts');
    
    if (_isLoadingRecentPodcasts)
      return _buildLoadingPodcastHorizontalScroll();
    else if (_recentPodcasts.isNotEmpty)
      return _buildPodcastsHorizontalScroll(_recentPodcasts, LocalizationService.getRecentPodcastsText);
    else
      return _buildEmptyPodcastState(LocalizationService.getNoRecentPodcastsAvailableText);
  }

  Widget _buildNewReleasePodcastsSection() {
    print('Building New Release Podcasts Section - _newReleasePodcasts: ${_newReleasePodcasts.length}, _isLoadingNewReleasePodcasts: $_isLoadingNewReleasePodcasts');
    
    if (_isLoadingNewReleasePodcasts)
      return _buildLoadingPodcastHorizontalScroll();
    else if (_newReleasePodcasts.isNotEmpty)
      return _buildPodcastsHorizontalScroll(_newReleasePodcasts, LocalizationService.getNewReleasePodcastsText);
    else
      return _buildEmptyPodcastState(LocalizationService.getNoNewReleasePodcastsAvailableText);
  }

  Widget _buildRecommendedPodcastsSection() {
    print('🏗️ Building Recommended Podcasts Section');
    print('📊 _randomPodcasts count: ${_randomPodcasts.length}');
    print('📚 _randomPodcasts titles: ${_randomPodcasts.map((p) => p.title).toList()}');
    print('⏳ _isLoadingRandomPodcasts: $_isLoadingRandomPodcasts');
    
    if (_isLoadingRandomPodcasts)
      return _buildLoadingPodcastHorizontalScroll();
    else if (_randomPodcasts.isNotEmpty)
      return _buildPodcastsHorizontalScroll(_randomPodcasts, LocalizationService.getRecommendedPodcastsText);
    else
      return _buildEmptyPodcastState(LocalizationService.getNoRecommendedPodcastsAvailableText);
  }

  Widget _buildPodcastsHorizontalScroll(List<Podcast> podcasts, String sectionTitle) {
    print('🔄 _buildPodcastsHorizontalScroll: Building horizontal scroll with ${podcasts.length} podcasts');
    print('📖 _buildPodcastsHorizontalScroll: Podcast titles: ${podcasts.map((p) => p.title).toList()}');
    
    if (podcasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with view all button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (sectionTitle == LocalizationService.getRecentPodcastsText) {
                    context.go('/all-podcasts/recent/${LocalizationService.getRecentPodcastsText}');
                  } else if (sectionTitle == LocalizationService.getNewReleasePodcastsText) {
                    context.go('/all-podcasts/new-releases/${LocalizationService.getNewReleasePodcastsText}');
                  } else if (sectionTitle == LocalizationService.getRecommendedPodcastsText) {
                    context.go('/all-podcasts/recommended/${LocalizationService.getRecommendedPodcastsText}');
                  } else if (sectionTitle == LocalizationService.getFreePodcastsText) {
                    context.go('/all-podcasts/free/${LocalizationService.getFreePodcastsText}');
                  }
                },
                child: Text(
                  LocalizationService.getViewAllText,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal scrollable podcasts
        SizedBox(
          height: _getResponsiveHorizontalCardHeight() + 20,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: podcasts.length,
            itemBuilder: (context, index) {
              final podcast = podcasts[index];
              print('🎨 _buildPodcastsHorizontalScroll: Building item $index for podcast: ${podcast.title}');
              
              return PodcastCard(
                podcast: podcast,
                onTap: () => _navigateToPodcastDetail(podcast),
                showLibraryActions: false,
                isInLibrary: false,
                isFavorite: false,
                userId: 'current_user',
                width: _getResponsiveHorizontalCardWidth(),
                enableAnimations: true,
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingPodcastHorizontalScroll() {
    return SizedBox(
      height: _getResponsiveHorizontalScrollHeight(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: index < 4 ? 16 : 0),
            child: ShimmerPodcastCard(
              width: _getResponsiveHorizontalCardWidth(),
              height: _getResponsiveHorizontalCardHeight(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPodcastState(String message) {
    String sectionTitle = LocalizationService.getRecentPodcastsText;
    String route = '/all-podcasts/recent/${LocalizationService.getRecentPodcastsText}';
    
    if (message.contains('new release') || message.contains('cusub')) {
      sectionTitle = LocalizationService.getNewReleasePodcastsText;
      route = '/all-podcasts/new-releases/${LocalizationService.getNewReleasePodcastsText}';
    } else if (message.contains('recommended') || message.contains('la soo jeediyay')) {
      sectionTitle = LocalizationService.getRecommendedPodcastsText;
      route = '/all-podcasts/recommended/${LocalizationService.getRecommendedPodcastsText}';
    } else if (message.contains('free') || message.contains('bilaashka')) {
      sectionTitle = LocalizationService.getFreePodcastsText;
      route = '/all-podcasts/free/${LocalizationService.getFreePodcastsText}';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go(route);
                },
                child: Text(
                  LocalizationService.getViewAllText,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Empty state container
        Container(
          height: _getResponsiveHorizontalCardHeight() + 20,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.radio,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  // Responsive helper methods for horizontal scroll sections
  double _getResponsiveHorizontalCardWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return screenWidth * 0.42; // Small phones - slightly larger for better visibility
    } else if (screenWidth < 400) {
      return screenWidth * 0.40; // Medium phones
    } else if (screenWidth < 480) {
      return screenWidth * 0.38; // Large phones
    } else if (screenWidth < 600) {
      return screenWidth * 0.36; // Very large phones
    } else if (screenWidth < 768) {
      return screenWidth * 0.34; // Small tablets
    } else if (screenWidth < 1024) {
      return screenWidth * 0.30; // Medium tablets
    } else {
      return screenWidth * 0.26; // Large tablets/desktop
    }
  }

  double _getResponsiveHorizontalCardHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return 180; // Small screens
    } else if (screenHeight < 800) {
      return 200; // Medium screens
    } else {
      return 220; // Large screens
    }
  }

  double _getResponsiveHorizontalScrollHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return screenHeight * 0.28; // Very small screens - accommodate content fitted cards with overflow prevention
    } else if (screenHeight < 700) {
      return screenHeight * 0.26; // Small screens - accommodate content fitted cards with overflow prevention
    } else if (screenHeight < 800) {
      return screenHeight * 0.24; // Medium screens - accommodate content fitted cards with overflow prevention
    } else if (screenHeight < 900) {
      return screenHeight * 0.22; // Large screens - accommodate content fitted cards with overflow prevention
    } else if (screenHeight < 1000) {
      return screenHeight * 0.20; // Very large screens - accommodate content fitted cards with overflow prevention
    } else {
      return screenHeight * 0.18; // Extra large screens - accommodate content fitted cards with overflow prevention
    }
  }

  // Responsive grid helper methods for professional card layout - prevent overflow
  int _getResponsiveGridColumns() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) {
      return 2; // Very small phones - 2 columns
    } else if (screenWidth < 360) {
      return 2; // Small phones - 2 columns
    } else if (screenWidth < 400) {
      return 2; // Medium phones - 2 columns (conservative to prevent overflow)
    } else if (screenWidth < 480) {
      return 2; // Large phones - 2 columns (conservative to prevent overflow)
    } else if (screenWidth < 600) {
      return 2; // Very large phones - 2 columns (reduced from 3 to prevent overflow)
    } else if (screenWidth < 768) {
      return 3; // Small tablets - 3 columns
    } else if (screenWidth < 1024) {
      return 4; // Medium tablets - 4 columns
    } else {
      return 5; // Large tablets/desktop - 5 columns
    }
  }

  double _getResponsiveGridAspectRatio() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 0.75; // More compact aspect ratio for small screens
    } else if (screenWidth < 480) {
      return 0.80; // More compact aspect ratio for medium screens
    } else if (screenWidth < 600) {
      return 0.85; // More compact aspect ratio for large phones
    } else if (screenWidth < 768) {
      return 0.90; // More compact aspect ratio for tablets
    } else {
      return 0.95; // More compact aspect ratio for large screens
    }
  }

  // Calculate aspect ratio based on same height as horizontal cards
  double _getResponsiveGridAspectRatioFromHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final crossAxisCount = _getResponsiveGridColumns();
    final cardHeight = _getResponsiveHorizontalCardHeight();
    
    // Calculate available width per card (accounting for spacing and proper padding)
    final availableWidth = screenWidth - 32 - (_getResponsiveGridSpacing() * (crossAxisCount - 1)); // 32 for proper padding, spacing between cards
    final cardWidth = availableWidth / crossAxisCount;
    
    // Calculate aspect ratio: width / height
    return cardWidth / cardHeight;
  }

  double _getResponsiveGridSpacing() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 8.0; // Proper spacing for small screens
    } else if (screenWidth < 480) {
      return 10.0; // Proper spacing
    } else if (screenWidth < 600) {
      return 12.0; // Proper spacing
    } else if (screenWidth < 768) {
      return 14.0; // Professional spacing for tablets
    } else {
      return 16.0; // Professional spacing for large screens
    }
  }
}
