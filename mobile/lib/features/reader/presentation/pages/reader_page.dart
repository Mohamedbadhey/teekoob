import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/reader/bloc/reader_bloc.dart';
import 'package:teekoob/features/reader/services/reader_service.dart';
// import 'package:teekoob/core/services/storage_service.dart'; // Removed - no local storage
import 'package:teekoob/features/books/services/books_service.dart';

class ReaderPage extends StatefulWidget {
  final String bookId;

  const ReaderPage({
    super.key,
    required this.bookId,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  String _selectedFont = 'Roboto';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black87;
  bool _isFullScreen = false;
  int _currentPage = 1;
  int _totalPages = 100;
  Book? _book;
  String? _bookContent;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() async {
    try {
      // Note: No local storage - cannot get book from storage
      final book = null;
      print('🔍 ReaderPage: Loading book with ID: ${widget.bookId}');
      print('📖 ReaderPage: Book found in storage: ${book != null}');
      if (book != null) {
        print('📚 ReaderPage: Book title: ${book.title}');
        setState(() {
          _book = book;
          _bookContent = book.ebookContent;
        });
      } else {
        print('❌ ReaderPage: Book not found in local storage');
        // Try to get all books to see what's available
        // Note: No local storage - cannot get books from storage
        final allBooks = <Book>[];
        print('📚 ReaderPage: Total books in storage: ${allBooks.length}');
        print('📖 ReaderPage: Available book IDs: ${allBooks.map((b) => b.id).toList()}');
        
        // Try to fetch the book from API as fallback
        print('🔄 ReaderPage: Attempting to fetch book from API...');
        try {
          final booksService = BooksService();
          final fetchedBook = await booksService.getBookById(widget.bookId);
          if (fetchedBook != null) {
            print('✅ ReaderPage: Successfully fetched book from API');
            setState(() {
              _book = fetchedBook;
              _bookContent = fetchedBook.ebookContent;
            });
          } else {
            print('❌ ReaderPage: Book not found in API either');
          }
        } catch (e) {
          print('💥 ReaderPage: Error fetching book from API: $e');
        }
      }
    } catch (e) {
      print('💥 ReaderPage: Error loading book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isFullScreen
          ? _buildFullScreenReader()
          : _buildReaderWithControls(),
    );
  }

  Widget _buildReaderWithControls() {
    return Column(
      children: [
        // App Bar
        _buildAppBar(),
        
        // Reader Content
        Expanded(
          child: _buildReaderContent(),
        ),
      ],
    );
  }

  Widget _buildFullScreenReader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFullScreen = false;
        });
      },
      child: _buildReaderContent(),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      foregroundColor: _textColor,
      elevation: 0,
      title: Text(
        _book?.title ?? LocalizationService.getLocalizedText(
          englishText: 'Reader',
          somaliText: 'Akhrinta',
        ),
        style: TextStyle(color: _textColor),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.fullscreen, color: _textColor),
          onPressed: () {
            setState(() {
              _isFullScreen = true;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.settings, color: _textColor),
          onPressed: () {
            _showReaderSettings();
          },
        ),
        IconButton(
          icon: Icon(Icons.bookmark_border, color: _textColor),
          onPressed: () {
            // TODO: Add bookmark functionality
          },
        ),
      ],
    );
  }

  Widget _buildReaderContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: _buildBookContent(),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Chapter 1: The Beginning',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${_currentPage}/${_totalPages}',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBookContent() {
    if (_bookContent == null || _bookContent!.isEmpty) {
      return Center(
        child: Text(
          'There is no data',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: _fontSize,
          ),
        ),
      );
    }

    return Text(
      _bookContent!,
      style: TextStyle(
        color: _textColor,
        fontSize: _fontSize,
        height: _lineHeight,
        fontFamily: _selectedFont,
      ),
    );
  }

  Widget _buildPageFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $_currentPage',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          'Teekoob',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(
            color: _textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Page
          IconButton(
            icon: Icon(Icons.chevron_left, color: _textColor),
            onPressed: _currentPage > 1 ? _previousPage : null,
          ),
          
          const Spacer(),
          
          // Page Info
          Text(
            '$_currentPage / $_totalPages',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(),
          
          // Next Page
          IconButton(
            icon: Icon(Icons.chevron_right, color: _textColor),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _backgroundColor,
      builder: (context) => _buildSettingsPanel(),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Reader Settings',
              somaliText: 'Dejinta Akhrinta',
            ),
            style: TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Font Size
          _buildSettingItem(
            title: LocalizationService.getLocalizedText(
              englishText: 'Font Size',
              somaliText: 'Xajka Qoraalka',
            ),
            child: Slider(
              value: _fontSize,
              min: 12.0,
              max: 32.0,
              divisions: 20,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
          ),
          
          // Line Height
          _buildSettingItem(
            title: LocalizationService.getLocalizedText(
              englishText: 'Line Height',
              somaliText: 'Dhererka Safka',
            ),
            child: Slider(
              value: _lineHeight,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              label: _lineHeight.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _lineHeight = value;
                });
              },
            ),
          ),
          
          // Font Family
          _buildSettingItem(
            title: LocalizationService.getLocalizedText(
              englishText: 'Font Family',
              somaliText: 'Qoyska Qoraalka',
            ),
            child: DropdownButton<String>(
              value: _selectedFont,
              isExpanded: true,
              underline: Container(),
              items: [
                'Roboto',
                'Arial',
                'Times New Roman',
                'Georgia',
                'Verdana',
              ].map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFont = value!;
                });
              },
            ),
          ),
          
          // Theme
          _buildSettingItem(
            title: LocalizationService.getLocalizedText(
              englishText: 'Theme',
              somaliText: 'Mawduuca',
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  name: LocalizationService.getLocalizedText(
                    englishText: 'Light',
                    somaliText: 'Iftiin',
                  ),
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  isSelected: _backgroundColor == Colors.white,
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  name: LocalizationService.getLocalizedText(
                    englishText: 'Sepia',
                    somaliText: 'Sepia',
                  ),
                  backgroundColor: const Color(0xFFF4ECD8),
                  textColor: const Color(0xFF5C4B37),
                  isSelected: _backgroundColor == const Color(0xFFF4ECD8),
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  name: LocalizationService.getLocalizedText(
                    englishText: 'Dark',
                    somaliText: 'Madow',
                  ),
                  backgroundColor: const Color(0xFF1A1A1A),
                  textColor: Colors.white,
                  isSelected: _backgroundColor == const Color(0xFF1A1A1A),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Close',
                somaliText: 'Xir',
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String name,
    required Color backgroundColor,
    required Color textColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _backgroundColor = backgroundColor;
          _textColor = textColor;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

}
