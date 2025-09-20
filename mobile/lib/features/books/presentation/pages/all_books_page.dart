import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';

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
      default:
        context.read<BooksBloc>().add(const LoadBooks(limit: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF56C23),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/home'),
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
          } else if (state is BooksLoaded && widget.category == 'all') {
            setState(() {
              _books = state.books;
              _isLoading = false;
            });
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _books.isEmpty
                ? _buildEmptyState()
                : _buildBooksGrid(),
      ),
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
              showLibraryActions: true,
              isInLibrary: isInLibrary,
              isFavorite: isFavorite,
              userId: 'current_user',
            );
          },
        );
      },
    );
  }

  void _navigateToBookDetail(Book book) {
    context.go('/book/${book.id}');
  }
}
