import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/features/books/presentation/widgets/shimmer_book_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/core/config/app_router.dart';

class AllBooksPage extends StatefulWidget {
  final String category;
  final String title;

  const AllBooksPage({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage> {
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      _isLoading = true;
    });

    // Dispatch appropriate event based on category
    switch (widget.category) {
      case 'new-releases':
        context.read<BooksBloc>().add(const LoadNewReleases(limit: 50));
        break;
      case 'recommended':
        context.read<BooksBloc>().add(const LoadRandomBooks(limit: 50));
        break;
      case 'recent':
        context.read<BooksBloc>().add(const LoadRecentBooks(limit: 50));
        break;
      case 'featured':
        context.read<BooksBloc>().add(const LoadFeaturedBooks(limit: 50));
        break;
      case 'free':
        context.read<BooksBloc>().add(const LoadFreeBooks(limit: 50));
        break;
      default:
        context.read<BooksBloc>().add(const LoadBooks(limit: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0466c8),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => AppRouter.handleBackNavigation(context),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove default back button
      ),
      body: BlocListener<BooksBloc, BooksState>(
        listener: (context, state) {
          if (state is NewReleasesLoaded && widget.category == 'new-releases') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          } else if (state is RandomBooksLoaded && widget.category == 'recommended') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          } else if (state is RecentBooksLoaded && widget.category == 'recent') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          } else if (state is FeaturedBooksLoaded && widget.category == 'featured') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          } else if (state is FreeBooksLoaded && widget.category == 'free') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          } else if (state is BooksLoaded && widget.category == 'all') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          }
        },
        child: _isLoading
            ? _buildShimmerLoading()
            : _books.isEmpty
                ? _buildEmptyState()
                : _buildBooksGrid(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 shimmer cards
      itemBuilder: (context, index) {
        return ShimmerBookCard();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No books available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getResponsiveGridColumns(); // Professional responsive columns
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _getResponsiveGridAspectRatioFromHeight(), // Use same height as horizontal cards
            crossAxisSpacing: _getResponsiveGridSpacing(), // Responsive spacing
            mainAxisSpacing: _getResponsiveGridSpacing(), // Responsive spacing
          ),
          itemCount: _books.length,
          itemBuilder: (context, index) {
            final book = _books[index];
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
                  userId: 'current_user',
                  width: _getResponsiveGridCardWidth(), // Responsive width for grid layout
                  enableAnimations: true,
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
    
    // Use a more appropriate aspect ratio for grid layout
    // Grid cards should be more square-like for better visual balance
    return 0.75; // Fixed aspect ratio for consistent grid layout
  }

  // Get responsive horizontal card height (same as HomePage)
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

  // Get responsive card width for grid layout (same as horizontal cards)
  double _getResponsiveGridCardWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getResponsiveGridColumns();
    
    // Calculate available width per card (accounting for spacing and proper padding)
    final availableWidth = screenWidth - 32 - (_getResponsiveGridSpacing() * (crossAxisCount - 1)); // 32 for proper padding, spacing between cards
    return availableWidth / crossAxisCount;
  }
}
