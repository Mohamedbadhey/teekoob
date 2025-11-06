import 'package:teekoob/core/models/podcast_model.dart';
import 'package:teekoob/core/services/network_service.dart';

class PodcastsService {
  final NetworkService _networkService;

  PodcastsService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Get all podcasts with pagination
  Future<Map<String, dynamic>> getPodcasts({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? categories,
    String? language,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categories != null && categories.isNotEmpty) queryParams['categories'] = categories.join(',');
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      final response = await _networkService.get('/podcasts', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final podcastsData = response.data['podcasts'] as List;
        final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
        
        return {
          'podcasts': podcasts,
          'total': response.data['total'],
          'page': response.data['page'],
          'limit': response.data['limit'],
          'totalPages': response.data['totalPages'],
        };
      } else {
        throw Exception('Failed to fetch podcasts');
      }
    } catch (e) {
      throw Exception('Failed to fetch podcasts: $e');
    }
  }

  // Get podcast by ID
  Future<Podcast?> getPodcastById(String podcastId) async {
    try {
      
      final response = await _networkService.get('/podcasts/$podcastId');
      
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['success'] == true && responseData['podcast'] != null) {
          final podcastData = responseData['podcast'] as Map<String, dynamic>;
          final podcast = Podcast.fromJson(podcastData);
          
          return podcast;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get featured podcasts
  Future<List<Podcast>> getFeaturedPodcasts({int limit = 10}) async {
    try {
      final response = await _networkService.get('/podcasts/featured/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        final podcastsData = response.data['featuredPodcasts'] as List;
        final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get new release podcasts
  Future<List<Podcast>> getNewReleasePodcasts({int limit = 10}) async {
    try {
      final response = await _networkService.get('/podcasts/new-releases/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        final podcastsData = response.data['newReleasePodcasts'] as List;
        final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get recent podcasts (sorted by creation date)
  Future<List<Podcast>> getRecentPodcasts({int limit = 10}) async {
    try {
      final response = await _networkService.get('/podcasts/recent/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final podcastsData = response.data['recentPodcasts'] as List;
        
        final podcasts = podcastsData.map((json) {
          return Podcast.fromJson(json);
        }).toList();
        
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get free podcasts
  Future<List<Podcast>> getFreePodcasts({int limit = 10}) async {
    try {
      final response = await _networkService.get('/podcasts/free/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final podcastsData = response.data['freePodcasts'] as List;
        
        final podcasts = podcastsData.map((json) {
          return Podcast.fromJson(json);
        }).toList();
        
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get random podcasts for recommendations
  Future<List<Podcast>> getRandomPodcasts({int limit = 10}) async {
    try {
      final response = await _networkService.get('/podcasts/random/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        
        final podcastsData = response.data['randomPodcasts'] as List;
        
        final podcasts = podcastsData.map((json) {
          return Podcast.fromJson(json);
        }).toList();
        
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get podcasts by category
  Future<List<Podcast>> getPodcastsByCategory(String categoryId, {int limit = 20}) async {
    try {
      final response = await _networkService.get('/categories/$categoryId/podcasts', queryParameters: {'limit': limit});
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final podcastsData = data['podcasts'] as List;
          final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
          return podcasts;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get podcast episodes
  Future<List<PodcastEpisode>> getPodcastEpisodes(String podcastId, {
    int page = 1,
    int limit = 20,
    String? search,
    int? season,
  }) async {
    try {
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (season != null) queryParams['season'] = season;

      final response = await _networkService.get('/podcasts/$podcastId/episodes', queryParameters: queryParams);
      
      
      if (response.statusCode == 200) {
        final episodesData = response.data['episodes'] as List;
        
        if (episodesData.isNotEmpty) {
        }
        
        final episodes = episodesData.map((json) {
          return PodcastEpisode.fromJson(json);
        }).toList();
        
        return episodes;
      } else {
        return [];
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
      }
      return [];
    }
  }

  // Get episode by ID
  Future<PodcastEpisode?> getEpisodeById(String podcastId, String episodeId) async {
    try {
      
      final response = await _networkService.get('/podcasts/$podcastId/episodes/$episodeId');
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['episode'] != null) {
          final episodeData = responseData['episode'] as Map<String, dynamic>;
          final episode = PodcastEpisode.fromJson(episodeData);
          
          return episode;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Search podcasts
  Future<List<Podcast>> searchPodcasts(String query, {
    String? language,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
        'limit': limit,
      };

      if (language != null && language.isNotEmpty) queryParams['language'] = language;

      final response = await _networkService.get('/podcasts', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final podcastsData = response.data['podcasts'] as List;
        final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
        
        return podcasts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get available languages for podcasts
  Future<List<String>> getPodcastLanguages() async {
    try {
      final response = await _networkService.get('/podcasts/languages/list');

      if (response.statusCode == 200) {
        final languagesData = response.data['languages'] as List;
        return languagesData.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    // No local caching implemented yet
  }
}
