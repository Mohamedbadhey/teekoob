import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';
import 'package:teekoob/features/books/services/books_service.dart';
// import 'package:teekoob/core/services/storage_service.dart'; // Removed - no local storage
import 'package:teekoob/core/config/app_router.dart';
import 'package:teekoob/features/books/presentation/pages/book_read_page.dart';
import 'package:teekoob/features/player/presentation/pages/audio_player_page.dart';
import 'package:teekoob/features/player/services/audio_state_manager.dart';
import 'package:teekoob/core/presentation/widgets/book_reminder_widget.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  Book? book;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  void _loadBookDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('🔍 BookDetailPage: Loading book details for ID: ${widget.bookId}');

      // Fetch book details from the backend
      final booksService = BooksService();
      
      final fetchedBook = await booksService.getBookById(widget.bookId);
      
      print('📚 BookDetailPage: Fetched book: ${fetchedBook != null}');
      if (fetchedBook != null) {
        print('📖 BookDetailPage: Book title: ${fetchedBook.title}');
        print('📝 BookDetailPage: Ebook content length: ${fetchedBook.ebookContent?.length ?? 0}');
        if (fetchedBook.ebookContent?.isNotEmpty == true) {
          final content = fetchedBook.ebookContent!;
          print('📝 BookDetailPage: Ebook content preview: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
        } else {
          print('📝 BookDetailPage: Ebook content is empty');
        }
        
        setState(() {
          book = fetchedBook;
          isLoading = false;
        });
      } else {
        print('❌ BookDetailPage: Book not found in API');
        setState(() {
          error = 'Book not found';
          isLoading = false;
        });
      }
    } catch (e) {
      print('💥 BookDetailPage: Error loading book: $e');
      setState(() {
        error = 'Failed to load book: $e';
        isLoading = false;
      });
    }
  }

  String _buildFullImageUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    return '${AppConfig.mediaBaseUrl}$relativeUrl';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            await AppRouter.handleAndroidBackButton(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (error != null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            await AppRouter.handleAndroidBackButton(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadBookDetails,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (book == null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            await AppRouter.handleAndroidBackButton(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(
            child: Text('Book not found'),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await AppRouter.handleAndroidBackButton(context);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover Image
                    _buildBookCoverImage(),
                    
                    const SizedBox(height: 24),
                    
                    // Title and Author
                    _buildTitleSection(),
                    
                    // Reading Time & Rating
                    _buildTimeAndRating(),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    // Rating Section
                    _buildRatingSection(),
                    
                    // Book Reminder Widget
                    BookReminderWidget(book: book!),
                    
                    const SizedBox(height: 24),
                    
                    // Text Blocks
                    _buildTextBlocks(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF0466c8), // Blue - same as home page top bar
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => AppRouter.handleBackNavigation(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Text(
                (book?.titleSomali?.isNotEmpty ?? false) ? book!.titleSomali! : book?.title ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text on orange background
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement share functionality
              },
              icon: const Icon(Icons.share, color: Colors.white), // White on orange
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCoverImage() {
    return Center(
      child: Container(
        width: 200,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: book?.coverImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: _buildFullImageUrl(book!.coverImageUrl!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => _buildPlaceholderImage(),
                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                )
              : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.book,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          (book?.titleSomali?.isNotEmpty ?? false) ? book!.titleSomali! : book?.title ?? '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          book?.authors ?? 'Unknown Author',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reading Time
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${book?.duration ?? 12} min',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 32),
        
        // Rating
        Row(
          children: [
            Icon(Icons.star, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${book?.rating?.toStringAsFixed(1) ?? '0.0'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (book != null) {
                  context.push('/home/books/${book!.id}/read', extra: book);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0466c8), // Blue - same as home page
                foregroundColor: Colors.white, // White text on orange background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Read',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Consumer<GlobalAudioPlayerService>(
              builder: (context, audioService, child) {
                final bool isCurrentBook = audioService.currentItem?.id == book?.id;
                final bool isPlaying = audioService.isPlaying && isCurrentBook;
                
                return OutlinedButton.icon(
                  onPressed: () {
                    if (book != null) {
                      if (isCurrentBook && isPlaying) {
                        audioService.pause();
                      } else {
                        audioService.playBook(book!);
                        context.push('/home/player/${book!.id}', extra: book);
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A), // Dark blue text
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 2), // Dark blue border
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(
                    (isCurrentBook && isPlaying) ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF1E3A8A),
                  ),
                  label: Text(
                    (isCurrentBook && isPlaying) ? 'Pause' : 'Listen',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left Side - Add Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) => 
                    Icon(
                      Icons.star_border,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Vertical Divider
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[300],
          ),
          
          // Right Side - Language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book?.language == 'somali' ? 'Somali' : 'English',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Section
        if (book?.description != null && book!.description!.isNotEmpty)
          _buildTextBlock(
            title: 'Description',
            content: book!.description!,
          ),
        
        if (book?.description != null && book!.description!.isNotEmpty)
          const SizedBox(height: 24),
        
        // Somali Description Section
        if (book?.descriptionSomali != null && book!.descriptionSomali!.isNotEmpty)
          _buildTextBlock(
            title: 'Faahfaahin',
            content: book!.descriptionSomali!,
          ),
        
        if (book?.descriptionSomali != null && book!.descriptionSomali!.isNotEmpty)
          const SizedBox(height: 24),
        
        // Author Section
        if (book?.authors != null && book!.authors!.isNotEmpty)
          _buildTextBlock(
            title: 'Author',
            content: 'Written by ${book!.authors!}',
          ),
        
        // Genre/Category Section
        if (book?.categoryNames != null && book!.categoryNames!.isNotEmpty)
          _buildTextBlock(
            title: 'Category',
            content: book!.categoryNames!.join(', '),
          ),
      ],
    );
  }

  Widget _buildTextBlock({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2FF), // Light blue
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }


}
