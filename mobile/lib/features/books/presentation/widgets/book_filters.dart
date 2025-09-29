import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/models/category_model.dart';
import 'package:teekoob/features/books/bloc/books_bloc.dart';

class BookFilters extends StatefulWidget {
  final List<String> selectedCategories;
  final String selectedYear;
  final String sortBy;
  final String sortOrder;
  final Function(List<String>, String, String, String) onApply;
  final VoidCallback onClear;

  const BookFilters({
    super.key,
    required this.selectedCategories,
    required this.selectedYear,
    required this.sortBy,
    required this.sortOrder,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<BookFilters> createState() => _BookFiltersState();
}

class _BookFiltersState extends State<BookFilters> {
  late List<String> _selectedCategories;
  late String _selectedYear;
  late String _sortBy;
  late String _sortOrder;
  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
    _selectedYear = widget.selectedYear;
    _sortBy = widget.sortBy;
    _sortOrder = widget.sortOrder;
    
    // Load categories when the widget initializes
    context.read<BooksBloc>().add(const LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BooksBloc, BooksState>(
      listener: (context, state) {
        if (state is CategoriesLoaded) {
          setState(() {
            _categories = state.categories;
            _isLoadingCategories = false;
          });
        } else if (state is BooksLoading) {
          setState(() {
            _isLoadingCategories = true;
          });
        }
      },
      child: Container(
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
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
                    // Category Filter
                    _buildFilterSection(
                      title: LocalizationService.getLocalizedText(
                        englishText: 'Category',
                        somaliText: 'Qaybta',
                      ),
                      child: _buildCategoryFilter(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Year Filter
                    _buildFilterSection(
                      title: LocalizationService.getLocalizedText(
                        englishText: 'Year Published',
                        somaliText: 'Sanadka La Daabacay',
                      ),
                      child: _buildYearFilter(),
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
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        LocalizationService.getClearText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
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
                          _selectedCategories,
                          _selectedYear,
                          _sortBy,
                          _sortOrder,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        LocalizationService.getApplyText,
                        style: TextStyle(
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildCategoryFilter() {
    if (_isLoadingCategories) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            LocalizationService.getLocalizedText(
              englishText: 'No categories available',
              somaliText: 'Qaybaha lama helin',
            ),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "All Categories" chip
            _buildCategoryChip(
              LocalizationService.getLocalizedText(
                englishText: 'All Categories',
                somaliText: 'Dhammaan Qaybaha',
              ),
              'all_categories',
              constraints.maxWidth * 0.45,
            ),
            // Dynamic category chips
            ..._categories.map((category) {
              return _buildCategoryChip(
                category.name,
                category.id,
                constraints.maxWidth * 0.45,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, String categoryId, double maxWidth) {
    final isSelected = categoryId == 'all_categories'
        ? _selectedCategories.isEmpty  // "All Categories" is selected only when no categories are selected
        : _selectedCategories.contains(categoryId);  // Regular categories are selected when they're in the list
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (categoryId == 'all_categories') {
            // Clear all selections
            _selectedCategories.clear();
          } else {
            // Toggle category selection
            if (_selectedCategories.contains(categoryId)) {
              _selectedCategories.remove(categoryId);
            } else {
              _selectedCategories.add(categoryId);
            }
          }
        });
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
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
  }


  Widget _buildYearFilter() {
    final currentYear = DateTime.now().year;
    final years = [
      LocalizationService.getLocalizedText(
        englishText: 'All Years',
        somaliText: 'Dhammaan Sanadaha',
      ),
      ...List.generate(10, (index) => (currentYear - index).toString()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: years.map((year) {
            final isSelected = _selectedYear == year || 
                (_selectedYear.isEmpty && year.contains('All'));
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedYear = isSelected ? '' : year;
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.3,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0466c8) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0466c8) : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF0466c8).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
                value: 'date',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Date',
                  somaliText: 'Taariikhda',
                )),
              ),
              DropdownMenuItem(
                value: 'rating',
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Rating',
                  somaliText: 'Qiimaynta',
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
