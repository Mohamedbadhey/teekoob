import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/features/podcasts/services/podcasts_service.dart';

// Events
abstract class PodcastsEvent extends Equatable {
  const PodcastsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeaturedPodcasts extends PodcastsEvent {
  final int limit;
  
  const LoadFeaturedPodcasts({this.limit = 6});
  
  @override
  List<Object?> get props => [limit];
}

class LoadNewReleasePodcasts extends PodcastsEvent {
  final int limit;
  
  const LoadNewReleasePodcasts({this.limit = 10});
  
  @override
  List<Object?> get props => [limit];
}

class LoadRecentPodcasts extends PodcastsEvent {
  final int limit;
  
  const LoadRecentPodcasts({this.limit = 6});
  
  @override
  List<Object?> get props => [limit];
}

class LoadFreePodcasts extends PodcastsEvent {
  final int limit;
  
  const LoadFreePodcasts({this.limit = 6});
  
  @override
  List<Object?> get props => [limit];
}

class LoadRandomPodcasts extends PodcastsEvent {
  final int limit;
  
  const LoadRandomPodcasts({this.limit = 5});
  
  @override
  List<Object?> get props => [limit];
}

class LoadPodcastById extends PodcastsEvent {
  final String podcastId;
  
  const LoadPodcastById(this.podcastId);
  
  @override
  List<Object?> get props => [podcastId];
}

class LoadPodcastEpisodes extends PodcastsEvent {
  final String podcastId;
  final int page;
  final int limit;
  final String? search;
  final int? season;
  
  const LoadPodcastEpisodes({
    required this.podcastId,
    this.page = 1,
    this.limit = 20,
    this.search,
    this.season,
  });
  
  @override
  List<Object?> get props => [podcastId, page, limit, search, season];
}

class LoadEpisodeById extends PodcastsEvent {
  final String podcastId;
  final String episodeId;
  
  const LoadEpisodeById({
    required this.podcastId,
    required this.episodeId,
  });
  
  @override
  List<Object?> get props => [podcastId, episodeId];
}

class LoadPodcastEpisodeById extends PodcastsEvent {
  final String podcastId;
  final String episodeId;
  
  const LoadPodcastEpisodeById(this.podcastId, this.episodeId);
  
  @override
  List<Object?> get props => [podcastId, episodeId];
}

class SearchPodcasts extends PodcastsEvent {
  final String query;
  final String? language;
  final int limit;
  
  const SearchPodcasts({
    required this.query,
    this.language,
    this.limit = 50,
  });
  
  @override
  List<Object?> get props => [query, language, limit];
}

class LoadPodcastsByCategory extends PodcastsEvent {
  final String categoryId;
  final int limit;
  
  const LoadPodcastsByCategory({
    required this.categoryId,
    this.limit = 20,
  });
  
  @override
  List<Object?> get props => [categoryId, limit];
}

// States
abstract class PodcastsState extends Equatable {
  const PodcastsState();

  @override
  List<Object?> get props => [];
}

class PodcastsInitial extends PodcastsState {}

class PodcastsLoading extends PodcastsState {}

class PodcastsError extends PodcastsState {
  final String message;
  
  const PodcastsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Featured Podcasts States
class FeaturedPodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  
  const FeaturedPodcastsLoaded(this.podcasts);
  
  @override
  List<Object?> get props => [podcasts];
}

// New Release Podcasts States
class NewReleasePodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  
  const NewReleasePodcastsLoaded(this.podcasts);
  
  @override
  List<Object?> get props => [podcasts];
}

// Recent Podcasts States
class RecentPodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  
  const RecentPodcastsLoaded(this.podcasts);
  
  @override
  List<Object?> get props => [podcasts];
}

// Free Podcasts States
class FreePodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  
  const FreePodcastsLoaded(this.podcasts);
  
  @override
  List<Object?> get props => [podcasts];
}

// Random Podcasts States
class RandomPodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  
  const RandomPodcastsLoaded(this.podcasts);
  
  @override
  List<Object?> get props => [podcasts];
}

// Single Podcast States
class PodcastLoaded extends PodcastsState {
  final Podcast podcast;
  
  const PodcastLoaded(this.podcast);
  
  @override
  List<Object?> get props => [podcast];
}

// Podcast Episodes States
class PodcastEpisodesLoaded extends PodcastsState {
  final List<PodcastEpisode> episodes;
  final String podcastId;
  
  const PodcastEpisodesLoaded({
    required this.episodes,
    required this.podcastId,
  });
  
  @override
  List<Object?> get props => [episodes, podcastId];
}

// Single Episode States
class EpisodeLoaded extends PodcastsState {
  final PodcastEpisode episode;
  
  const EpisodeLoaded(this.episode);
  
  @override
  List<Object?> get props => [episode];
}

class PodcastEpisodeLoaded extends PodcastsState {
  final PodcastEpisode episode;
  
  const PodcastEpisodeLoaded(this.episode);
  
  @override
  List<Object?> get props => [episode];
}

// Search Results States
class PodcastsSearchLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  final String query;
  
  const PodcastsSearchLoaded({
    required this.podcasts,
    required this.query,
  });
  
  @override
  List<Object?> get props => [podcasts, query];
}

// Category Podcasts States
class CategoryPodcastsLoaded extends PodcastsState {
  final List<Podcast> podcasts;
  final String categoryId;
  
  const CategoryPodcastsLoaded({
    required this.podcasts,
    required this.categoryId,
  });
  
  @override
  List<Object?> get props => [podcasts, categoryId];
}

// Bloc
class PodcastsBloc extends Bloc<PodcastsEvent, PodcastsState> {
  final PodcastsService _podcastsService;

  PodcastsBloc({PodcastsService? podcastsService}) 
      : _podcastsService = podcastsService ?? PodcastsService(),
        super(PodcastsInitial()) {
    
    // Featured podcasts
    on<LoadFeaturedPodcasts>(_onLoadFeaturedPodcasts);
    
    // New release podcasts
    on<LoadNewReleasePodcasts>(_onLoadNewReleasePodcasts);
    
    // Recent podcasts
    on<LoadRecentPodcasts>(_onLoadRecentPodcasts);
    
    // Free podcasts
    on<LoadFreePodcasts>(_onLoadFreePodcasts);
    
    // Random podcasts
    on<LoadRandomPodcasts>(_onLoadRandomPodcasts);
    
    // Single podcast
    on<LoadPodcastById>(_onLoadPodcastById);
    
    // Podcast episodes
    on<LoadPodcastEpisodes>(_onLoadPodcastEpisodes);
    
    // Single episode
    on<LoadEpisodeById>(_onLoadEpisodeById);
    
    // Single podcast episode
    on<LoadPodcastEpisodeById>(_onLoadPodcastEpisodeById);
    
    // Search podcasts
    on<SearchPodcasts>(_onSearchPodcasts);
    
    // Podcasts by category
    on<LoadPodcastsByCategory>(_onLoadPodcastsByCategory);
  }

  Future<void> _onLoadFeaturedPodcasts(
    LoadFeaturedPodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getFeaturedPodcasts(limit: event.limit);
      emit(FeaturedPodcastsLoaded(podcasts));
    } catch (e) {
      emit(PodcastsError('Failed to load featured podcasts: $e'));
    }
  }

  Future<void> _onLoadNewReleasePodcasts(
    LoadNewReleasePodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getNewReleasePodcasts(limit: event.limit);
      emit(NewReleasePodcastsLoaded(podcasts));
    } catch (e) {
      emit(PodcastsError('Failed to load new release podcasts: $e'));
    }
  }

  Future<void> _onLoadRecentPodcasts(
    LoadRecentPodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getRecentPodcasts(limit: event.limit);
      emit(RecentPodcastsLoaded(podcasts));
    } catch (e) {
      emit(PodcastsError('Failed to load recent podcasts: $e'));
    }
  }

  Future<void> _onLoadFreePodcasts(
    LoadFreePodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getFreePodcasts(limit: event.limit);
      emit(FreePodcastsLoaded(podcasts));
    } catch (e) {
      emit(PodcastsError('Failed to load free podcasts: $e'));
    }
  }

  Future<void> _onLoadRandomPodcasts(
    LoadRandomPodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getRandomPodcasts(limit: event.limit);
      emit(RandomPodcastsLoaded(podcasts));
    } catch (e) {
      emit(PodcastsError('Failed to load random podcasts: $e'));
    }
  }

  Future<void> _onLoadPodcastById(
    LoadPodcastById event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcast = await _podcastsService.getPodcastById(event.podcastId);
      if (podcast != null) {
        emit(PodcastLoaded(podcast));
      } else {
        emit(const PodcastsError('Podcast not found'));
      }
    } catch (e) {
      emit(PodcastsError('Failed to load podcast: $e'));
    }
  }

  Future<void> _onLoadPodcastEpisodes(
    LoadPodcastEpisodes event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      
      emit(PodcastsLoading());
      
      final episodes = await _podcastsService.getPodcastEpisodes(
        event.podcastId,
        page: event.page,
        limit: event.limit,
        search: event.search,
        season: event.season,
      );
      
      
      emit(PodcastEpisodesLoaded(
        episodes: episodes,
        podcastId: event.podcastId,
      ));
      
    } catch (e) {
      emit(PodcastsError('Failed to load podcast episodes: $e'));
    }
  }

  Future<void> _onLoadEpisodeById(
    LoadEpisodeById event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final episode = await _podcastsService.getEpisodeById(event.podcastId, event.episodeId);
      if (episode != null) {
        emit(EpisodeLoaded(episode));
      } else {
        emit(const PodcastsError('Episode not found'));
      }
    } catch (e) {
      emit(PodcastsError('Failed to load episode: $e'));
    }
  }

  Future<void> _onLoadPodcastEpisodeById(
    LoadPodcastEpisodeById event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final episode = await _podcastsService.getEpisodeById(event.podcastId, event.episodeId);
      if (episode != null) {
        emit(PodcastEpisodeLoaded(episode));
      } else {
        emit(const PodcastsError('Episode not found'));
      }
    } catch (e) {
      emit(PodcastsError('Failed to load episode: $e'));
    }
  }

  Future<void> _onSearchPodcasts(
    SearchPodcasts event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.searchPodcasts(
        event.query,
        language: event.language,
        limit: event.limit,
      );
      emit(PodcastsSearchLoaded(
        podcasts: podcasts,
        query: event.query,
      ));
    } catch (e) {
      emit(PodcastsError('Failed to search podcasts: $e'));
    }
  }

  Future<void> _onLoadPodcastsByCategory(
    LoadPodcastsByCategory event,
    Emitter<PodcastsState> emit,
  ) async {
    try {
      emit(PodcastsLoading());
      final podcasts = await _podcastsService.getPodcastsByCategory(
        event.categoryId,
        limit: event.limit,
      );
      emit(CategoryPodcastsLoaded(
        podcasts: podcasts,
        categoryId: event.categoryId,
      ));
    } catch (e) {
      emit(PodcastsError('Failed to load podcasts by category: $e'));
    }
  }
}
