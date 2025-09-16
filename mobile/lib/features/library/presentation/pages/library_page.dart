import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/features/library/services/library_service.dart';
import 'package:teekoob/core/services/storage_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _userId = 'current_user'; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    // Load library data
    _loadLibraryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadLibraryData() {
    print('🎯 LibraryPage: Loading library data for user: $_userId');
    try {
      context.read<LibraryBloc>().add(LoadLibrary(_userId));
      print('✅ LibraryPage: LoadLibrary event dispatched successfully');
    } catch (e) {
      print('❌ LibraryPage: Error dispatching LoadLibrary event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildSearchSection(),
            _buildStatsSection(),
            _buildTabBar(),
            Expanded(
              child: BlocListener<LibraryBloc, LibraryState>(
                listener: (context, state) {
                  print('🎧 LibraryPage BlocListener: State changed to ${state.runtimeType}');
                  
                  if (state is LibraryLoading) {
                    print('⏳ LibraryPage Listener: Library is loading...');
                  } else if (state is LibraryLoaded) {
                    print('✅ LibraryPage Listener: Library loaded successfully - ${state.library.length} books');
                  } else if (state is LibraryError) {
                    print('❌ LibraryPage Listener: Library error - ${state.message}');
                  } else if (state is LibrarySearchResults) {
                    print('🔍 LibraryPage Listener: Search results loaded - ${state.results.length} results');
                  }
                },
                child: BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, state) {
                    print('🔍 LibraryPage BlocBuilder: Current state = ${state.runtimeType}');
                    
                    if (state is LibraryLoading) {
                      print('📱 LibraryPage: Showing loading state');
                      return _buildLoadingState();
                    } else if (state is LibraryError) {
                      print('❌ LibraryPage: Showing error state - ${state.message}');
                      return _buildErrorState(state);
                    } else if (state is LibrarySearchResults) {
                      print('🔍 LibraryPage: Showing search results - ${state.results.length} results');
                      return _buildSearchResults(state);
                    } else if (state is LibraryLoaded) {
                      print('📚 LibraryPage: Showing library content - ${state.library.length} books');
                      return _buildTabContent(state);
                    } else {
                      print('⏳ LibraryPage: Initial/Unknown state, showing loading state');
                      return _buildLoadingState();
                    }
                  },
                ),
              ),
            ),
          ],
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
                const Color(0xFFF56C23), // Orange
                const Color(0xFFFF8A65), // Light orange
                const Color(0xFFFFAB91), // Lighter orange
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF56C23).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.05,
          ),
          child: Row(
            children: [
              // Title with icon
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Icon(
                        Icons.library_books_rounded,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      LocalizationService.getLibraryText,
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sync button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.sync_rounded,
                    size: screenWidth * 0.06,
                    color: const Color(0xFFF56C23),
                  ),
            onPressed: () {
                    context.read<LibraryBloc>().add(SyncLibrary(_userId));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Container(
          margin: EdgeInsets.fromLTRB(
            screenWidth * 0.05,
            screenWidth * 0.04,
            screenWidth * 0.05,
            screenWidth * 0.02,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF56C23).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: LocalizationService.getLocalizedText(
                  englishText: 'Search your library...',
                  somaliText: 'Raadi maktabaddaada...',
                ),
                hintStyle: TextStyle(
                  color: const Color(0xFFF56C23).withOpacity(0.5),
                  fontSize: screenWidth * 0.04,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF56C23).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFFF56C23),
                    size: screenWidth * 0.05,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: const Color(0xFFF56C23).withOpacity(0.5),
                        ),
            onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: const Color(0xFFF56C23).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: const Color(0xFFF56C23).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFF56C23),
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.04,
                ),
              ),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: const Color(0xFFF56C23),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
                if (value.isNotEmpty) {
                  context.read<LibraryBloc>().add(SearchLibrary(_userId, value));
                } else {
                  _loadLibraryData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state is! LibraryLoaded) return const SizedBox.shrink();
        
        final stats = state.stats;
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Books',
                      'Dhammaan Kutubta',
                      stats['totalBooks']?.toString() ?? '0',
                      Icons.library_books_rounded,
                      const Color(0xFFF56C23),
                      screenWidth,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: _buildStatCard(
                      'Reading',
                      'Akhrinta',
                      stats['readingBooks']?.toString() ?? '0',
                      Icons.menu_book_rounded,
                      const Color(0xFF3B82F6),
                      screenWidth,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: _buildStatCard(
                      'Favorites',
                      'Ku Xiisatay',
                      stats['favoriteBooks']?.toString() ?? '0',
                      Icons.favorite_rounded,
                      const Color(0xFFF56C23),
                      screenWidth,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String titleEn, String titleSo, String value, IconData icon, Color color, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: screenWidth * 0.05,
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            LocalizationService.getLocalizedText(
              englishText: titleEn,
              somaliText: titleSo,
            ),
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.03,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF56C23).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
          controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFFF56C23),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFF56C23),
            labelStyle: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
          tabs: [
            Tab(
              icon: Icon(
                  _currentTabIndex == 0 ? Icons.library_books_rounded : Icons.library_books_outlined,
                  size: screenWidth * 0.05,
              ),
              text: LocalizationService.getLocalizedText(
                  englishText: 'All',
                  somaliText: 'Dhammaan',
              ),
            ),
            Tab(
              icon: Icon(
                  _currentTabIndex == 1 ? Icons.headphones_rounded : Icons.headphones_outlined,
                  size: screenWidth * 0.05,
              ),
              text: LocalizationService.getLocalizedText(
                  englishText: 'Audio',
                  somaliText: 'Codka',
              ),
            ),
            Tab(
              icon: Icon(
                  _currentTabIndex == 2 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: screenWidth * 0.05,
              ),
              text: LocalizationService.getLocalizedText(
                englishText: 'Favorites',
                somaliText: 'Ku Xiisatay',
              ),
            ),
            Tab(
              icon: Icon(
                  _currentTabIndex == 3 ? Icons.download_rounded : Icons.download_outlined,
                  size: screenWidth * 0.05,
              ),
              text: LocalizationService.getLocalizedText(
                englishText: 'Downloads',
                somaliText: 'Soo Dejinta',
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildTabContent(LibraryLoaded state) {
    return TabBarView(
        controller: _tabController,
      children: [
        _buildAllBooksTab(state),
        _buildAudiobooksTab(state),
        _buildFavoritesTab(state),
        _buildDownloadsTab(state),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFF56C23)),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Loading your library...',
              somaliText: 'Waxaan soo gelinaynaa maktabaddaada...',
            ),
            style: const TextStyle(
              color: Color(0xFFF56C23),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LibraryError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Error loading library',
                somaliText: 'Qalad ayaa ka dhacay maktabadda',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF56C23),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLibraryData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(LocalizationService.getLocalizedText(
                englishText: 'Retry',
                somaliText: 'Dib u day',
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF56C23),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(LibrarySearchResults state) {
    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: const Color(0xFFF56C23).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'No results found',
                  somaliText: 'Natiijooyin lama helin',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF56C23),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Try searching with different keywords',
                  somaliText: 'Iska day inaad raadiso ereyada kale',
                ),
                style: TextStyle(
                  color: const Color(0xFFF56C23).withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildBooksGrid(state.results);
  }

  Widget _buildAllBooksTab(LibraryLoaded state) {
    if (state.library.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_books_rounded,
        title: LocalizationService.getLocalizedText(
          englishText: 'Your library is empty',
          somaliText: 'Maktabaddaada waa madhan',
        ),
        subtitle: LocalizationService.getLocalizedText(
          englishText: 'Start adding books to your library',
          somaliText: 'Bilaabo inaad ku dartid kutubta maktabaddaada',
        ),
        actionText: LocalizationService.getLocalizedText(
          englishText: 'Browse Books',
          somaliText: 'Eeg Kutubta',
        ),
        onAction: () => context.go('/home/books'),
      );
    }

    return _buildBooksGrid(state.library);
  }

  Widget _buildAudiobooksTab(LibraryLoaded state) {
    final audiobooks = state.library.where((item) {
      // Filter for audiobooks - you might need to adjust this based on your data structure
      return item['format'] == 'audio' || item['isAudiobook'] == true;
    }).toList();
    
    if (audiobooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.headphones_rounded,
        title: LocalizationService.getLocalizedText(
          englishText: 'No audiobooks yet',
          somaliText: 'Kutubta codka ma jiraan',
        ),
        subtitle: LocalizationService.getLocalizedText(
          englishText: 'Add audiobooks to start listening',
          somaliText: 'Ku dar kutubta codka si aad u bilowdo inaad dhegayso',
        ),
        actionText: LocalizationService.getLocalizedText(
          englishText: 'Find Audiobooks',
          somaliText: 'Raadi Kutubta Codka',
        ),
        onAction: () => context.go('/home/books'),
      );
    }

    return _buildBooksGrid(audiobooks);
  }

  Widget _buildFavoritesTab(LibraryLoaded state) {
    if (state.favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_rounded,
        title: LocalizationService.getLocalizedText(
          englishText: 'No favorites yet',
          somaliText: 'Ku xiisatay ma jiraan',
        ),
        subtitle: LocalizationService.getLocalizedText(
          englishText: 'Mark books as favorite to see them here',
          somaliText: 'Ku calaamadee kutubta si aad u aragto halkan',
        ),
        actionText: LocalizationService.getLocalizedText(
          englishText: 'Browse Books',
          somaliText: 'Eeg Kutubta',
        ),
        onAction: () => context.go('/home/books'),
      );
    }

    return _buildBooksGrid(state.favorites);
  }

  Widget _buildDownloadsTab(LibraryLoaded state) {
    final downloads = state.library.where((item) {
      // Filter for downloaded books - you might need to adjust this based on your data structure
      return item['isDownloaded'] == true || item['status'] == 'downloaded';
    }).toList();
    
    if (downloads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_rounded,
        title: LocalizationService.getLocalizedText(
          englishText: 'No downloads yet',
          somaliText: 'Soo dejinta ma jiraan',
        ),
        subtitle: LocalizationService.getLocalizedText(
          englishText: 'Download books to read offline',
          somaliText: 'Soo deji kutubta si aad u akhrin offline',
        ),
        actionText: LocalizationService.getLocalizedText(
          englishText: 'Browse Books',
          somaliText: 'Eeg Kutubta',
        ),
        onAction: () => context.go('/home/books'),
      );
    }

    return _buildBooksGrid(downloads);
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
    return Center(
      child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF56C23).withOpacity(0.1),
                        const Color(0xFFFF8A65).withOpacity(0.1),
                        const Color(0xFFFFAB91).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.15),
                    border: Border.all(
                      color: const Color(0xFFF56C23).withOpacity(0.2),
                      width: 2,
                    ),
              ),
              child: Icon(
                icon,
                    size: screenWidth * 0.15,
                    color: const Color(0xFFF56C23).withOpacity(0.6),
              ),
            ),
                SizedBox(height: screenWidth * 0.06),
            Text(
              title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                    color: const Color(0xFFF56C23),
              ),
              textAlign: TextAlign.center,
            ),
                SizedBox(height: screenWidth * 0.03),
            Text(
              subtitle,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFFF56C23).withOpacity(0.7),
                    height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
                SizedBox(height: screenWidth * 0.08),
            ElevatedButton.icon(
              onPressed: onAction,
                  icon: Icon(
                    Icons.explore_rounded,
                    size: screenWidth * 0.05,
                  ),
                  label: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56C23),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenWidth * 0.04,
                    ),
                shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                ),
                    elevation: 4,
                    shadowColor: const Color(0xFFF56C23).withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildBooksGrid(List<Map<String, dynamic>> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Responsive grid configuration
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;
        
        if (screenWidth < 360) {
          // Small phones
          crossAxisCount = 2;
          childAspectRatio = 0.65;
          crossAxisSpacing = 12;
          mainAxisSpacing = 12;
        } else if (screenWidth < 400) {
          // Medium phones
          crossAxisCount = 2;
          childAspectRatio = 0.68;
          crossAxisSpacing = 14;
          mainAxisSpacing = 14;
        } else if (screenWidth < 480) {
          // Large phones
          crossAxisCount = 2;
          childAspectRatio = 0.70;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (screenWidth < 600) {
          // Very large phones
          crossAxisCount = 2;
          childAspectRatio = 0.72;
          crossAxisSpacing = 18;
          mainAxisSpacing = 18;
        } else {
          // Tablets and larger
          crossAxisCount = 3;
          childAspectRatio = 0.75;
          crossAxisSpacing = 20;
          mainAxisSpacing = 20;
        }
        
    return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05, // 5% of screen width
            0, 
            screenWidth * 0.05, // 5% of screen width
            screenHeight * 0.02, // 2% of screen height
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final item = books[index];
            return _buildLibraryBookCard(item);
          },
        );
      },
    );
  }

  Widget _buildLibraryBookCard(Map<String, dynamic> libraryItem) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Get book data from storage service first
        final bookId = libraryItem['bookId'];
        final localBook = StorageService().getBook(bookId);
        
        if (localBook != null) {
          // Book found in local storage, use it
          return BookCard(
            book: localBook,
            onTap: () => context.go('/book/${localBook.id}'),
            showLibraryActions: true,
            isInLibrary: true,
            isFavorite: libraryItem['isFavorite'] ?? false,
            userId: _userId,
          );
        } else {
          // Book not in local storage, fetch from database
          return FutureBuilder<Book?>(
            future: context.read<LibraryBloc>().fetchBookById(bookId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingCard();
              } else if (snapshot.hasData && snapshot.data != null) {
                final book = snapshot.data!;
                return BookCard(
                  book: book,
                  onTap: () => context.go('/book/${book.id}'),
                  showLibraryActions: true,
                  isInLibrary: true,
                  isFavorite: libraryItem['isFavorite'] ?? false,
                  userId: _userId,
                );
              } else {
                // Book not found, show fallback card
                return _buildMapBookCard(libraryItem);
              }
            },
          );
        }
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF56C23).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF56C23)),
        ),
      ),
    );
  }

  Widget _buildMapBookCard(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => context.go('/home/books/${book['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: _buildMapPlaceholderCover(book),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (LocalizationService.currentLanguage == 'so' && (book['titleSomali'] ?? '').toString().isNotEmpty)
                          ? (book['titleSomali'] ?? '').toString()
                          : (book['title'] ?? '').toString(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if ((book['authors'] is List && (book['authors'] as List).isNotEmpty) ||
                        (book['authorsSomali'] is List && (book['authorsSomali'] as List).isNotEmpty))
                      Text(
                        (LocalizationService.currentLanguage == 'so' && book['authorsSomali'] is List && (book['authorsSomali'] as List).isNotEmpty)
                            ? (book['authorsSomali'] as List).first.toString()
                            : (book['authors'] is List && (book['authors'] as List).isNotEmpty
                                ? (book['authors'] as List).first.toString()
                                : ''),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (book['format'] ?? '').toString().toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (book['rating'] != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                double.tryParse(book['rating'].toString())?.toStringAsFixed(1) ?? '0.0',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholderCover(Map<String, dynamic> book) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            (LocalizationService.currentLanguage == 'so' && (book['titleSomali'] ?? '').toString().isNotEmpty)
                ? (book['titleSomali'] ?? '').toString()
                : (book['title'] ?? '').toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
