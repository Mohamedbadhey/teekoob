import 'dart:async';
import 'package:flutter/material.dart';
import 'package:teekoob/core/services/localization_service.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String? hintText;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    this.hintText,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(query);
    });
  }

  void _onSubmitted(String query) {
    _debounceTimer?.cancel();
    widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: _onSearchChanged,
        onSubmitted: _onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText ?? LocalizationService.getLocalizedText(
            englishText: 'Search books, authors, genres...',
            somaliText: 'Raadi kutub, qoraayaal, noocyada...',
          ),
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0466c8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search,
              color: const Color(0xFF0466c8),
              size: 20,
            ),
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear();
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }
}
