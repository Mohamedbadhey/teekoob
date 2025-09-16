import 'package:flutter/material.dart';
import 'package:teekoob/core/services/localization_service.dart';

class BookFilters extends StatefulWidget {
  final String selectedGenre;
  final String selectedLanguage;
  final String selectedFormat;
  final String sortBy;
  final String sortOrder;
  final Function(String, String, String, String, String) onApply;
  final VoidCallback onClear;

  const BookFilters({
    super.key,
    required this.selectedGenre,
    required this.selectedLanguage,
    required this.selectedFormat,
    required this.sortBy,
    required this.sortOrder,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<BookFilters> createState() => _BookFiltersState();
}

class _BookFiltersState extends State<BookFilters> {
  late String _selectedGenre;
  late String _selectedLanguage;
  late String _selectedFormat;
  late String _sortBy;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.selectedGenre;
    _selectedLanguage = widget.selectedLanguage;
    _selectedFormat = widget.selectedFormat;
    _sortBy = widget.sortBy;
    _sortOrder = widget.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Fixed at top
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Filters & Sort',
                      somaliText: 'Shaandhaynta & Habka',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Genre Filter
                  _buildFilterSection(
                    title: LocalizationService.getLocalizedText(
                      englishText: 'Genre',
                      somaliText: 'Nooca',
                    ),
                    child: _buildGenreFilter(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Language Filter
                  _buildFilterSection(
                    title: LocalizationService.getLocalizedText(
                      englishText: 'Language',
                      somaliText: 'Luuqadda',
                    ),
                    child: _buildLanguageFilter(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Format Filter
                  _buildFilterSection(
                    title: LocalizationService.getLocalizedText(
                      englishText: 'Format',
                      somaliText: 'Qaabka',
                    ),
                    child: _buildFormatFilter(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sort Options
                  _buildFilterSection(
                    title: LocalizationService.getLocalizedText(
                      englishText: 'Sort By',
                      somaliText: 'Habka',
                    ),
                    child: _buildSortOptions(),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Action Buttons - Fixed at bottom
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      LocalizationService.getClearText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _selectedGenre,
                        _selectedLanguage,
                        _selectedFormat,
                        _sortBy,
                        _sortOrder,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF56C23),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      LocalizationService.getApplyText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildGenreFilter() {
    final genres = [
      LocalizationService.getLocalizedText(
        englishText: 'All Genres',
        somaliText: 'Dhammaan Noocyada',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Fiction',
        somaliText: 'Sheeko',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Non-Fiction',
        somaliText: 'Sheeko Aan Sheeko Aheyn',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Science Fiction',
        somaliText: 'Sheeko Saynis',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Mystery',
        somaliText: 'Sirta',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Romance',
        somaliText: 'Jacaylka',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Biography',
        somaliText: 'Taariikh Nololeed',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'History',
        somaliText: 'Taariikh',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Self-Help',
        somaliText: 'Iska Caawinta',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Children',
        somaliText: 'Carruurta',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((genre) {
            final isSelected = _selectedGenre == genre || 
                (_selectedGenre.isEmpty && genre.contains('All'));
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGenre = isSelected ? '' : genre;
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF56C23) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF56C23) : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFF56C23).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLanguageFilter() {
    final languages = [
      LocalizationService.getLocalizedText(
        englishText: 'All Languages',
        somaliText: 'Dhammaan Luuqadaha',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'English',
        somaliText: 'Ingiriisi',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Somali',
        somaliText: 'Soomaali',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Arabic',
        somaliText: 'Carabi',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'French',
        somaliText: 'Faransiis',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((language) {
            final isSelected = _selectedLanguage == language || 
                (_selectedLanguage.isEmpty && language.contains('All'));
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLanguage = isSelected ? '' : language;
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF56C23) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF56C23) : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFF56C23).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  language,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFormatFilter() {
    final formats = [
      LocalizationService.getLocalizedText(
        englishText: 'All Formats',
        somaliText: 'Dhammaan Qaabka',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Ebook',
        somaliText: 'Kitaabka',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'Audiobook',
        somaliText: 'Kutubta Codka',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'PDF',
        somaliText: 'PDF',
      ),
      LocalizationService.getLocalizedText(
        englishText: 'EPUB',
        somaliText: 'EPUB',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: formats.map((format) {
            final isSelected = _selectedFormat == format || 
                (_selectedFormat.isEmpty && format.contains('All'));
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFormat = isSelected ? '' : format;
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF56C23) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF56C23) : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFFF56C23).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  format,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: [
        // Sort Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              labelStyle: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 16,
            ),
            items: [
              DropdownMenuItem(
                value: 'title',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Title',
                  somaliText: 'Cinwaanka',
                )),
              ),
              DropdownMenuItem(
                value: 'author',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Author',
                  somaliText: 'Qoraaga',
                )),
              ),
              DropdownMenuItem(
                value: 'rating',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Rating',
                  somaliText: 'Qiimaynta',
                )),
              ),
              DropdownMenuItem(
                value: 'date',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Date',
                  somaliText: 'Taariikhda',
                )),
              ),
              DropdownMenuItem(
                value: 'popularity',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Popularity',
                  somaliText: 'Caansheynta',
                )),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sort Order
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _sortOrder,
            decoration: const InputDecoration(
              labelText: 'Order',
              labelStyle: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 16,
            ),
            items: [
              DropdownMenuItem(
                value: 'asc',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Ascending (A-Z)',
                  somaliText: 'Kor u kaca (A-Z)',
                )),
              ),
              DropdownMenuItem(
                value: 'desc',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Descending (Z-A)',
                  somaliText: 'Hoos u dhic (Z-A)',
                )),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
              });
            },
          ),
        ),
      ],
    );
  }
}
