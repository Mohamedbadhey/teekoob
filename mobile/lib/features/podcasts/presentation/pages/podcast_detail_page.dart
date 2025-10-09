import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/podcasts/bloc/podcasts_bloc.dart';
import 'package:teekoob/features/podcasts/presentation/widgets/podcast_episode_card.dart';

class PodcastDetailPage extends StatefulWidget {
  final String podcastId;

  const PodcastDetailPage({
    super.key,
    required this.podcastId,
  });

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage>
    with TickerProviderStateMixin {
  Podcast? _podcast;
  List<PodcastEpisode> _episodes = [];
  bool _isLoadingPodcast = true;
  bool _isLoadingEpisodes = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadPodcastData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPodcastData() {
    print('🎧 PodcastDetailPage: Loading podcast data for ID: ${widget.podcastId}');
    
    // Load podcast details
    print('🎧 PodcastDetailPage: Dispatching LoadPodcastById event');
    context.read<PodcastsBloc>().add(LoadPodcastById(widget.podcastId));
    
    // Load podcast episodes
    print('🎧 PodcastDetailPage: Dispatching LoadPodcastEpisodes event');
    context.read<PodcastsBloc>().add(LoadPodcastEpisodes(podcastId: widget.podcastId));
    
    print('✅ PodcastDetailPage: Both events dispatched successfully');
  }

  void _navigateToEpisode(PodcastEpisode episode) {
    context.go('/podcast/${widget.podcastId}/episode/${episode.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<PodcastsBloc, PodcastsState>(
            listener: (context, state) {
              if (state is PodcastLoaded) {
                setState(() {
                  _podcast = state.podcast;
                  _isLoadingPodcast = false;
                });
                _animationController.forward();
              } else if (state is PodcastsError) {
                setState(() {
                  _isLoadingPodcast = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          ),
          BlocListener<PodcastsBloc, PodcastsState>(
            listener: (context, state) {
              print('🎧 PodcastDetailPage: Received state: ${state.runtimeType}');
              
              if (state is PodcastEpisodesLoaded) {
                print('🎧 PodcastDetailPage: Episodes loaded - count: ${state.episodes.length}');
                print('🎧 PodcastDetailPage: Episodes data: ${state.episodes.map((e) => '${e.id}: ${e.title}').toList()}');
                
                setState(() {
                  _episodes = state.episodes;
                  _isLoadingEpisodes = false;
                });
                
                print('✅ PodcastDetailPage: Episodes state updated successfully');
              } else if (state is PodcastsError) {
                print('💥 PodcastDetailPage: Error state received: ${state.message}');
                
                setState(() {
                  _isLoadingEpisodes = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else if (state is PodcastsLoading) {
                print('🎧 PodcastDetailPage: Loading state received');
              }
            },
          ),
        ],
        child: CustomScrollView(
          slivers: [
            // App Bar with Podcast Cover
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPodcastHeader(),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // TODO: Implement share functionality
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // TODO: Implement more options
                  },
                ),
              ],
            ),
            
            // Podcast Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingPodcast)
                      _buildLoadingContent()
                    else if (_podcast != null)
                      _buildPodcastContent()
                    else
                      _buildErrorContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastHeader() {
    if (_isLoadingPodcast) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_podcast == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.error.withOpacity(0.3),
              Theme.of(context).colorScheme.error.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.getNoPodcastFoundText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final coverImageUrl = _podcast!.coverImageUrl != null && _podcast!.coverImageUrl!.isNotEmpty
        ? '${AppConfig.mediaBaseUrl}/${_podcast!.coverImageUrl}'
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Image
          if (coverImageUrl != null)
            Positioned.fill(
              child: Image.network(
                coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.radio,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _podcast!.displayTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _podcast!.host ?? 'Unknown Host',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.headphones,
                        size: 20,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_podcast!.totalEpisodes} ${LocalizationService.getEpisodesText}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _podcast!.rating?.toStringAsFixed(1) ?? '0.0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildShimmerBox(height: 20, width: double.infinity),
          const SizedBox(height: 16),
          _buildShimmerBox(height: 16, width: double.infinity),
          const SizedBox(height: 8),
          _buildShimmerBox(height: 16, width: 200),
          const SizedBox(height: 24),
          _buildShimmerBox(height: 200, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPodcastContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            LocalizationService.getDescriptionText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _podcast!.description ?? 'No description available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Episodes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocalizationService.getEpisodesText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_episodes.length} ${LocalizationService.getEpisodesText.toLowerCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Episodes List
          if (_isLoadingEpisodes)
            _buildEpisodesLoading()
          else if (_episodes.isEmpty)
            _buildNoEpisodesState()
          else
            _buildEpisodesList(),
        ],
      ),
    );
  }

  Widget _buildEpisodesLoading() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildShimmerBox(height: 80, width: double.infinity),
      )),
    );
  }

  Widget _buildNoEpisodesState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.headphones_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.getNoEpisodesAvailableText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService.getCheckBackLaterText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Column(
      children: _episodes.map((episode) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PodcastEpisodeCard(
          episode: episode,
          onTap: () => _navigateToEpisode(episode),
        ),
      )).toList(),
    );
  }

  Widget _buildErrorContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.getErrorOccurredText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.getTryAgainLaterText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPodcastData,
              child: Text(LocalizationService.getRetryText),
            ),
          ],
        ),
      ),
    );
  }
}
