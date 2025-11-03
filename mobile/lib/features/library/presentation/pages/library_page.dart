import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/books/presentation/widgets/book_card.dart';
import 'package:teekoob/features/podcasts/presentation/widgets/podcast_card.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/features/library/bloc/library_bloc.dart';
import 'package:teekoob/features/library/services/library_service.dart';
import 'package:teekoob/features/podcasts/services/podcasts_service.dart';
import 'package:teekoob/core/services/download_service.dart';
// import 'package:teekoob/core/services/storage_service.dart'; // Removed - no local storage

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _userId = 'current_user'; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    
    // Load library data
    _loadLibraryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLibraryData() {
    print('🎯 LibraryPage: Loading library data for user: $_userId');
    try {
      // LoadLibrary already loads favorites, so we don't need a separate LoadFavorites call
      context.read<LibraryBloc>().add(LoadLibrary(_userId));
      print('✅ LibraryPage: LoadLibrary event dispatched successfully');
    } catch (e) {
      print('❌ LibraryPage: Error dispatching LoadLibrary event: $e');
    }
  }

  Widget _buildLibraryContent(LibraryLoaded state) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Library'),
              Tab(text: 'Favorites'),
              Tab(text: 'Offline'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLibraryTab(state),
                _buildFavoritesTab(state),
                _buildOfflineTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(LibraryLoaded state) {
    if (state.library.isEmpty) {
      return _buildPremiumOfflineMessage();
    }
    return _buildBooksGrid(state.library);
  }

  Widget _buildFavoritesTab(LibraryLoaded state) {
    if (state.favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: const Color(0xFF0466c8).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'No favorites yet',
                  somaliText: 'Weli ma jiraan jeceshaha',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0466c8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Tap the heart icon on books or podcasts to add them to favorites',
                  somaliText: 'Guji astaanta wadnaha kutubta ama podkaasta si aad ugu daro jeceshaha',
                ),
                style: TextStyle(
                  color: const Color(0xFF0466c8).withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Separate books and podcasts
    final favoriteBooks = state.favorites
        .where((f) => f['item_type'] == 'book' && f['item'] != null)
        .map((f) => f['item'] as Map<String, dynamic>)
        .toList();
    
    final favoritePodcasts = state.favorites
        .where((f) => f['item_type'] == 'podcast' && f['item'] != null)
        .map((f) => f['item'] as Map<String, dynamic>)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (favoriteBooks.isNotEmpty) ...[
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Favorite Books',
              somaliText: 'Kutubta Jeceshaha',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              int crossAxisCount = 2;
              if (screenWidth > 800) crossAxisCount = 4;
              else if (screenWidth > 600) crossAxisCount = 3;
              final cardWidth = (screenWidth - 24 - (crossAxisCount - 1) * 16) / crossAxisCount;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: favoriteBooks.length,
                itemBuilder: (context, index) {
                  final bookData = favoriteBooks[index];
                  try {
                    final book = Book.fromJson(bookData);
                    return BlocBuilder<LibraryBloc, LibraryState>(
                      builder: (context, libraryState) {
                        bool isFavorite = false;
                        if (libraryState is LibraryLoaded) {
                          isFavorite = libraryState.favorites.any((fav) => 
                            fav['item_type'] == 'book' && fav['item_id'] == book.id
                          );
                        }
                        
                        return BookCard(
                          book: book,
                          onTap: () => context.go('/book/${book.id}'),
                          showLibraryActions: true,
                          isFavorite: isFavorite,
                          userId: _userId,
                          width: cardWidth,
                          enableAnimations: true,
                        );
                      },
                    );
                  } catch (e) {
                    print('❌ Error parsing book: $e');
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (favoritePodcasts.isNotEmpty) ...[
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Favorite Podcasts',
              somaliText: 'Podkaastada Jeceshaha',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              int crossAxisCount = 2;
              if (screenWidth > 800) crossAxisCount = 4;
              else if (screenWidth > 600) crossAxisCount = 3;
              final cardWidth = (screenWidth - 24 - (crossAxisCount - 1) * 16) / crossAxisCount;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: favoritePodcasts.length,
                itemBuilder: (context, index) {
                  final podcastData = favoritePodcasts[index];
                  try {
                    final podcast = Podcast.fromJson(podcastData);
                    return BlocBuilder<LibraryBloc, LibraryState>(
                      builder: (context, libraryState) {
                        bool isFavorite = false;
                        if (libraryState is LibraryLoaded) {
                          isFavorite = libraryState.favorites.any((fav) => 
                            fav['item_type'] == 'podcast' && fav['item_id'] == podcast.id
                          );
                        }
                        
                        return PodcastCard(
                          podcast: podcast,
                          onTap: () => context.go('/podcast/${podcast.id}'),
                          showLibraryActions: true,
                          isFavorite: isFavorite,
                          userId: _userId,
                          width: cardWidth,
                          enableAnimations: true,
                        );
                      },
                    );
                  } catch (e) {
                    print('❌ Error parsing podcast: $e');
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOfflineTab(LibraryLoaded state) {
    final downloadedBooks = state.downloadedBooks;
    final downloadedPodcasts = state.downloadedPodcasts;
    
    print('📥 LibraryPage: Building offline tab - Books: ${downloadedBooks.length}, Podcasts: ${downloadedPodcasts.length}');
    if (downloadedBooks.isNotEmpty) {
      print('📥 LibraryPage: Downloaded book IDs: ${downloadedBooks.map((d) => d['item_id']).toList()}');
    }
    
    if (downloadedBooks.isEmpty && downloadedPodcasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.offline_pin_rounded,
                size: 64,
                color: const Color(0xFF0466c8).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'No offline content',
                  somaliText: 'Weli ma jiraan waxaan ku baahsanahay internet',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0466c8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Download books and podcasts to access them offline',
                  somaliText: 'Soo deji kutubta iyo podkaastada si aad ugu hesho adigoo aan internet lahayn',
                ),
                style: TextStyle(
                  color: const Color(0xFF0466c8).withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (downloadedBooks.isNotEmpty) ...[
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Downloaded Books',
              somaliText: 'Kutubta la soo dejiyey',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Book>>(
            future: _fetchBooksByIds(downloadedBooks.map((d) => d['item_id'] as String).toSet().toList()), // Use Set to remove duplicates
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              // Remove duplicate books (in case of multiple downloads for same book)
              final uniqueBooks = <String, Book>{};
              for (final book in snapshot.data!) {
                if (!uniqueBooks.containsKey(book.id)) {
                  uniqueBooks[book.id] = book;
                }
              }
              final books = uniqueBooks.values.toList();
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (screenWidth > 800) crossAxisCount = 4;
                  else if (screenWidth > 600) crossAxisCount = 3;
                  final cardWidth = (screenWidth - 24 - (crossAxisCount - 1) * 16) / crossAxisCount;
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final downloadInfo = downloadedBooks.firstWhere(
                        (d) => d['item_id'] == book.id,
                        orElse: () => {},
                      );
                      final isDownloaded = downloadInfo.isNotEmpty;
                      
                      return BookCard(
                        book: book,
                        onTap: () => context.go('/book/${book.id}'),
                        showLibraryActions: true,
                        isDownloaded: isDownloaded,
                        userId: _userId,
                        width: cardWidth,
                        enableAnimations: true,
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (downloadedPodcasts.isNotEmpty) ...[
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Downloaded Podcasts',
              somaliText: 'Podkaastada la soo dejiyey',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Podcast>>(
            future: _fetchPodcastsByIds(downloadedPodcasts.map((d) => d['item_id'] as String).toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final podcasts = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (screenWidth > 800) crossAxisCount = 4;
                  else if (screenWidth > 600) crossAxisCount = 3;
                  final cardWidth = (screenWidth - 24 - (crossAxisCount - 1) * 16) / crossAxisCount;
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: podcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = podcasts[index];
                      final downloadInfo = downloadedPodcasts.firstWhere(
                        (d) => d['item_id'] == podcast.id,
                        orElse: () => {},
                      );
                      final isDownloaded = downloadInfo.isNotEmpty;
                      
                      return PodcastCard(
                        podcast: podcast,
                        onTap: () => context.go('/podcast/${podcast.id}'),
                        showLibraryActions: true,
                        isDownloaded: isDownloaded,
                        userId: _userId,
                        width: cardWidth,
                        enableAnimations: true,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Future<List<Book>> _fetchBooksByIds(List<String> bookIds) async {
    try {
      final libraryBloc = context.read<LibraryBloc>();
      return await libraryBloc.fetchBooksByIds(bookIds);
    } catch (e) {
      print('❌ Error fetching books: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDownloadedPodcasts(DownloadService downloadService) async {
    try {
      // Get all podcasts that have metadata stored (downloaded)
      final podcastIds = await downloadService.getPodcastsWithDownloadedEpisodes();
      
      if (podcastIds.isEmpty) {
        return [];
      }
      
      final podcastsService = PodcastsService();
      final List<Map<String, dynamic>> result = [];
      
      // Fetch each podcast by ID
      for (final podcastId in podcastIds) {
        try {
          // First try cached metadata
          final metadata = await downloadService.getPodcastMetadata(podcastId);
          if (metadata != null) {
            final podcastMap = Map<String, dynamic>.from(metadata);
            podcastMap['has_episodes'] = true;
            result.add(podcastMap);
            continue;
          }
          
          // If no metadata, fetch from API
          final podcast = await podcastsService.getPodcastById(podcastId);
          if (podcast != null) {
            final podcastMap = podcast.toJson();
            podcastMap['has_episodes'] = true;
            result.add(podcastMap);
          }
        } catch (e) {
          print('❌ Error fetching podcast $podcastId: $e');
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error fetching downloaded podcasts: $e');
      return [];
    }
  }
  
  Future<List<Podcast>> _fetchPodcastsByIds(List<String> podcastIds) async {
    try {
      // Fetch podcasts by checking metadata first, then API
      final downloadService = DownloadService();
      final List<Podcast> podcasts = [];
      
      for (final podcastId in podcastIds) {
        // First check if podcast metadata is cached
        final metadata = await downloadService.getPodcastMetadata(podcastId);
        if (metadata != null) {
          try {
            podcasts.add(Podcast.fromJson(metadata));
            continue;
          } catch (e) {
            print('❌ Error parsing cached podcast metadata: $e');
          }
        }
        
        // If not cached, try to fetch from API
        try {
          final podcastsService = PodcastsService();
          final podcast = await podcastsService.getPodcastById(podcastId);
          if (podcast != null) {
            podcasts.add(podcast);
          }
        } catch (e) {
          print('❌ Error fetching podcast $podcastId from API: $e');
        }
      }
      
      return podcasts;
    } catch (e) {
      print('❌ Error fetching podcasts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildSearchSection(),
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
                    
                    if (state is LibrarySearchResults) {
                      print('🔍 LibraryPage: Showing search results - ${state.results.length} results');
                      return _buildSearchResults(state);
                    } else if (state is LibraryLoaded) {
                      return _buildLibraryContent(state);
                    } else if (state is LibraryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      // Show premium offline message when not searching
                      return _buildPremiumOfflineMessage();
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
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Icon(
                        Icons.library_books_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      LocalizationService.getLibraryText,
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sync button
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.sync_rounded,
                    size: screenWidth * 0.06,
                    color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  color: const Color(0xFF0466c8).withOpacity(0.5),
                  fontSize: screenWidth * 0.04,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0466c8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: screenWidth * 0.05,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: const Color(0xFF0466c8).withOpacity(0.5),
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
                    color: const Color(0xFF0466c8).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: const Color(0xFF0466c8).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF0466c8),
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
                color: Theme.of(context).colorScheme.primary,
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


  Widget _buildPremiumOfflineMessage() {
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
                        const Color(0xFF0466c8).withOpacity(0.1),
                        const Color(0xFF3A7BD5).withOpacity(0.1),
                        const Color(0xFF5A8BD8).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.15),
                    border: Border.all(
                      color: const Color(0xFF0466c8).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.offline_bolt_rounded,
                    size: screenWidth * 0.15,
                    color: const Color(0xFF0466c8).withOpacity(0.6),
                  ),
                ),
                SizedBox(height: screenWidth * 0.06),
                Text(
                  LocalizationService.getLocalizedText(
                    englishText: 'Premium Offline Access',
                    somaliText: 'Helitaanka Premium Offline',
                  ),
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth * 0.03),
                Text(
                  LocalizationService.getLocalizedText(
                    englishText: 'As a premium user, you can download books for offline reading. Use the search above to find and download your favorite books.',
                    somaliText: 'Sida isticmaale premium ah, waxaad ku soo dejisan kartaa kutubta si aad u akhrin offline. Isticmaal raadista kor ku yaalla si aad u hesho oo u soo dejiso kutubta aad jeceshahay.',
                  ),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF0466c8).withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth * 0.08),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home/books'),
                  icon: Icon(
                    Icons.explore_rounded,
                    size: screenWidth * 0.05,
                  ),
                  label: Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'Browse Books',
                      somaliText: 'Eeg Kutubta',
                    ),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0466c8),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenWidth * 0.04,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF0466c8).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                color: const Color(0xFF0466c8).withOpacity(0.6),
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
                  color: Color(0xFF0466c8),
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
                  color: const Color(0xFF0466c8).withOpacity(0.7),
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
            return _buildSimpleBookCard(item);
          },
        );
      },
    );
  }

  Widget _buildSimpleBookCard(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => context.go('/book/${book['bookId'] ?? book['id']}'),
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
                child: Icon(
                  Icons.book,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
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
                      book['title'] ?? 'Unknown Book',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['authors'] ?? 'Unknown Author',
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
                            (book['format'] ?? 'BOOK').toString().toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (book['rating'] != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.amber),
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


}
