import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> _featuredBooks = [];
  List<Book> _newReleases = [];
  List<Book> _recentBooks = [];
  List<Book> _randomBooks = [];
  List<Book> _filteredBooks = [];
  List<Category> _categories = [];
  bool _isLoadingFeatured = false;
  bool _isLoadingNewReleases = false;
  bool _isLoadingRecentBooks = false;
  bool _isLoadingRandomBooks = false;
  bool _isLoadingCategories = false;
  String? _selectedLanguage;
  String? _selectedCategoryId;

  // Language options
  final List<Map<String, dynamic>> _languages = [
    {'name': 'All Books', 'code': null, 'color': '#1E3A8A'},
    {'name': 'English', 'code': 'en', 'color': '#0466c8'},
    {'name': 'Somali', 'code': 'so', 'color': '#10B981'},
    {'name': 'Arabic', 'code': 'ar', 'color': '#8B5CF6'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadLibraryData();
  }

  void _loadInitialData() {
    // Load featured books (for featured section)
    context.read<BooksBloc>().add(const LoadFeaturedBooks(limit: 6));
    
    // Load new releases (for new releases section)
    context.read<BooksBloc>().add(const LoadNewReleases(limit: 10));
    
    // Load recent books (sorted by date - most recent first)
    context.read<BooksBloc>().add(const LoadRecentBooks(limit: 6));
    
    // Load random books for recommendations
    context.read<BooksBloc>().add(const LoadRandomBooks(limit: 5));
    
    // Load categories
    context.read<BooksBloc>().add(const LoadCategories());
  }

  void _loadLibraryData() {
    // Load library data to show correct status on book cards
    context.read<LibraryBloc>().add(const LoadLibrary('current_user'));
  }

  void _filterBooksByLanguage(String? languageCode) {
    print('🏠 HomePage: Filtering by language: $languageCode');
    setState(() {
      _selectedLanguage = languageCode;
      _selectedCategoryId = null; // Reset category when language changes
    });
    
    if (languageCode == null) {
      // Show all books
      print('🏠 HomePage: Clearing language filter');
      setState(() {
        _filteredBooks = [];
      });
    } else {
      // Filter books by language
      print('🏠 HomePage: Dispatching FilterBooksByLanguage event for: $languageCode');
      context.read<BooksBloc>().add(FilterBooksByLanguage(languageCode));
    }
  }

  void _filterBooksByCategory(String? categoryId) {
    print('🏠 HomePage: Filtering by category: $categoryId');
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedLanguage = null; // Reset language when category changes
    });
    
    if (categoryId == null) {
      // Show all books
      print('🏠 HomePage: Clearing category filter');
      setState(() {
        _filteredBooks = [];
      });
    } else {
      // Filter books by category
      print('🏠 HomePage: Dispatching FilterBooksByCategory event for: $categoryId');
      context.read<BooksBloc>().add(FilterBooksByCategory(categoryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BooksBloc, BooksState>(
      listener: (context, state) {
        if (state is FeaturedBooksLoaded) {
          setState(() {
            _featuredBooks = state.books;
            _isLoadingFeatured = false;
          });
          print('🏠 HomePage: Featured books loaded: ${state.books.length}');
          print('📚 HomePage: Featured book titles: ${state.books.map((b) => b.title).toList()}');
        } else if (state is NewReleasesLoaded) {
          setState(() {
            _newReleases = state.books;
            _isLoadingNewReleases = false;
          });
          print('🏠 HomePage: New releases loaded: ${state.books.length}');
          print('📚 HomePage: New release titles: ${state.books.map((b) => b.title).toList()}');
        } else if (state is RecentBooksLoaded) {
          setState(() {
            _recentBooks = state.books;
            _isLoadingRecentBooks = false;
          });
          print('🏠 HomePage: Recent books loaded: ${state.books.length}');
          print('📚 HomePage: Recent book titles: ${state.books.map((b) => b.title).toList()}');
        } else if (state is RandomBooksLoaded) {
          print('🏠 HomePage: RandomBooksLoaded state received with ${state.books.length} books');
          print('📚 HomePage: Book titles: ${state.books.map((b) => b.title).toList()}');
          setState(() {
            _randomBooks = state.books;
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
        } else if (state is BooksLoaded && (_selectedLanguage != null || _selectedCategoryId != null)) {
          setState(() {
            _filteredBooks = state.books;
          });
          print('🏠 HomePage: Filtered books loaded: ${state.books.length}');
        } else if (state is BooksError) {
          print('🏠 HomePage: Books error: ${state.message}');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildLanguageFiltersSection(),
              _buildCategoryFiltersSection(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFeaturedBookSection(),
                      const SizedBox(height: 32),
                      _buildRecentBooksSection(),
                      const SizedBox(height: 32),
                      _buildNewReleasesSection(),
                      const SizedBox(height: 32),
                      
                      // Filtered Books Section (shown when filters are applied)
                      if (_selectedLanguage != null || _selectedCategoryId != null) ...[
                        _buildFilteredBooksSection(),
                        const SizedBox(height: 32),
                      ],
                      
                      _buildRecommendedBooksSection(),
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
      color: const Color(0xFF0466c8), // Blue
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Title (centered)
          Expanded(
            child: Text(
              'Home',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Notification bell
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 20,
              color: const Color(0xFF0466c8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languages.map((language) {
                final isSelected = _selectedLanguage == language['code'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildLanguageChip(
                    language['name'],
                    language['code'],
                    language['color'],
                    isSelected,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String name, String? languageCode, String color, bool isSelected) {
    final chipColor = Color(int.parse(color.replaceAll('#', '0xFF')));
    
    return GestureDetector(
      onTap: () => _filterBooksByLanguage(languageCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: chipColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
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
                      'All Categories',
                      null,
                      0,
                      _selectedCategoryId == null,
                    ),
                  ),
                  // Category chips
                  ..._categories.map((category) {
                    final isSelected = _selectedCategoryId == category.id;
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
            const Text(
              'No categories available',
              style: TextStyle(
                color: Colors.grey,
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
        : const Color(0xFF1E3A8A);
    
    return GestureDetector(
      onTap: () => _filterBooksByCategory(categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (categoryId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey.shade600,
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
            color: Colors.grey.shade300,
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
          const Text(
            'Featured Book',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Featured Book Card
          if (_featuredBooks.isNotEmpty) ...[
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
            _buildEmptyState('No featured book available'),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentBooksSection() {
    print('Building Recent Books Section - _recentBooks: ${_recentBooks.length}, _isLoadingRecentBooks: $_isLoadingRecentBooks');
    
    if (_isLoadingRecentBooks)
      return _buildLoadingHorizontalScroll();
    else if (_recentBooks.isNotEmpty)
      return _buildBooksHorizontalScroll(_recentBooks, 'Recent Books');
    else
      return _buildEmptyState('No recent books available');
  }

  Widget _buildNewReleasesSection() {
    print('Building New Releases Section - _newReleases: ${_newReleases.length}, _isLoadingNewReleases: $_isLoadingNewReleases');
    
    if (_isLoadingNewReleases)
      return _buildLoadingHorizontalScroll();
    else if (_newReleases.isNotEmpty)
      return _buildBooksHorizontalScroll(_newReleases, 'New Releases');
    else
      return _buildEmptyState('No new releases available');
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
      return _buildBooksHorizontalScroll(_randomBooks, 'Recommended Books');
    else
      return _buildEmptyState('No recommended books available');
  }

  Widget _buildEmptyState(String message) {
    // Determine section title and route based on message
    String sectionTitle = 'Recent Books';
    String route = '/all-books/recent/Recent Books';
    
    if (message.contains('new releases')) {
      sectionTitle = 'New Releases';
      route = '/all-books/new-releases/New Releases';
    } else if (message.contains('recommended')) {
      sectionTitle = 'Recommended Books';
      route = '/all-books/recommended/Recommended Books';
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go(route);
                },
                child: Text(
                  'View All',
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
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (sectionTitle == 'Recent Books') {
                    context.go('/all-books/recent/Recent Books');
                  } else if (sectionTitle == 'New Releases') {
                    context.go('/all-books/new-releases/New Releases');
                  } else if (sectionTitle == 'Recommended Books') {
                    context.go('/all-books/recommended/Recommended Books');
                  }
                },
                child: Text(
                  'View All',
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
                  color: Colors.grey.shade300,
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
                  color: Colors.grey.shade300,
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
      height: _getResponsiveHorizontalScrollHeight(), // Responsive height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: index < 4 ? 16 : 0),
            width: _getResponsiveHorizontalCardWidth() * 0.8, // Responsive width (80% of card width)
            height: _getResponsiveHorizontalCardHeight(), // Responsive height
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilteredBooksSection() {
    String filterTitle = '';
    String filterColor = '#1E3A8A';
    
    if (_selectedLanguage != null) {
      final selectedLanguage = _languages.firstWhere(
        (lang) => lang['code'] == _selectedLanguage,
        orElse: () => {'name': 'Unknown', 'code': null, 'color': '#1E3A8A'},
      );
      filterTitle = '${selectedLanguage['name']} Books';
      filterColor = selectedLanguage['color'];
    } else if (_selectedCategoryId != null) {
      final selectedCategory = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => Category(
          id: '',
          name: 'Unknown',
          nameSomali: '',
          color: '#1E3A8A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      filterTitle = '${selectedCategory.name} Books';
      filterColor = selectedCategory.color;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(int.parse(filterColor.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                filterTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_filteredBooks.isEmpty)
            _buildEmptyState('No $filterTitle available')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
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
            ),
        ],
      ),
    );
  }

  void _navigateToBookDetail(Book book) {
    context.go('/book/${book.id}');
  }

  // Responsive helper methods for horizontal scroll sections
  double _getResponsiveHorizontalCardWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return screenWidth * 0.40; // Small phones - more conservative
    } else if (screenWidth < 400) {
      return screenWidth * 0.38; // Medium phones - more conservative
    } else if (screenWidth < 480) {
      return screenWidth * 0.36; // Large phones - more conservative
    } else if (screenWidth < 600) {
      return screenWidth * 0.34; // Very large phones - more conservative
    } else if (screenWidth < 768) {
      return screenWidth * 0.32; // Small tablets - more conservative
    } else {
      return screenWidth * 0.28; // Large tablets - more conservative
    }
  }

  double _getResponsiveHorizontalCardHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return screenHeight * 0.26; // Very small screens - content fitted with overflow prevention
    } else if (screenHeight < 700) {
      return screenHeight * 0.24; // Small screens - content fitted with overflow prevention
    } else if (screenHeight < 800) {
      return screenHeight * 0.22; // Medium screens - content fitted with overflow prevention
    } else if (screenHeight < 900) {
      return screenHeight * 0.20; // Large screens - content fitted with overflow prevention
    } else if (screenHeight < 1000) {
      return screenHeight * 0.18; // Very large screens - content fitted with overflow prevention
    } else {
      return screenHeight * 0.16; // Extra large screens - content fitted with overflow prevention
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
