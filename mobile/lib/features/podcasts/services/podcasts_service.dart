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
      print('PodcastsService: Getting podcasts with params: page=$page, limit=$limit, search=$search, categories=$categories, language=$language, sortBy=$sortBy, sortOrder=$sortOrder');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categories != null && categories.isNotEmpty) queryParams['categories'] = categories.join(',');
      if (language != null && language.isNotEmpty) queryParams['language'] = language;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      print('PodcastsService: Making request to /podcasts with queryParams: $queryParams');
      final response = await _networkService.get('/podcasts', queryParameters: queryParams);
      print('PodcastsService: Response received - Status: ${response.statusCode}');

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
      print('💥 PodcastsService: Error fetching podcasts from API: $e');
      throw Exception('Failed to fetch podcasts: $e');
    }
  }

  // Get podcast by ID
  Future<Podcast?> getPodcastById(String podcastId) async {
    try {
      print('🔍 PodcastsService: Getting podcast by ID from API: $podcastId');
      
      final response = await _networkService.get('/podcasts/$podcastId');
      
      print('📡 PodcastsService: Server response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('📚 PodcastsService: API response data keys: ${responseData.keys.toList()}');
        
        if (responseData['success'] == true && responseData['podcast'] != null) {
          final podcastData = responseData['podcast'] as Map<String, dynamic>;
          final podcast = Podcast.fromJson(podcastData);
          print('📖 PodcastsService: Successfully parsed podcast: ${podcast.title}');
          
          return podcast;
        } else {
          print('❌ PodcastsService: Invalid response format');
          return null;
        }
      } else {
        print('❌ PodcastsService: Server returned status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 PodcastsService: Error getting podcast by ID: $e');
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
        
        print('✅ getFeaturedPodcasts: Successfully fetched ${podcasts.length} featured podcasts');
        return podcasts;
      } else {
        print('❌ getFeaturedPodcasts: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getFeaturedPodcasts: Error occurred: $e');
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
        
        print('✅ getNewReleasePodcasts: Successfully fetched ${podcasts.length} new release podcasts');
        return podcasts;
      } else {
        print('❌ getNewReleasePodcasts: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getNewReleasePodcasts: Error occurred: $e');
      return [];
    }
  }

  // Get recent podcasts (sorted by creation date)
  Future<List<Podcast>> getRecentPodcasts({int limit = 10}) async {
    try {
      print('🔍 getRecentPodcasts: Fetching $limit recent podcasts from API...');
      final response = await _networkService.get('/podcasts/recent/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        print('✅ getRecentPodcasts: API response status: ${response.statusCode}');
        print('📊 getRecentPodcasts: Response data keys: ${response.data.keys.toList()}');
        
        final podcastsData = response.data['recentPodcasts'] as List;
        print('📚 getRecentPodcasts: Found ${podcastsData.length} podcasts in response');
        print('📖 getRecentPodcasts: Podcast titles: ${podcastsData.map((p) => p['title']).toList()}');
        
        final podcasts = podcastsData.map((json) {
          print('🔧 getRecentPodcasts: Processing podcast: ${json['title']}');
          return Podcast.fromJson(json);
        }).toList();
        
        print('✅ getRecentPodcasts: Successfully parsed ${podcasts.length} podcasts');
        print('📚 getRecentPodcasts: Final podcast titles: ${podcasts.map((p) => p.title).toList()}');
        
        return podcasts;
      } else {
        print('❌ getRecentPodcasts: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getRecentPodcasts: Error occurred: $e');
      return [];
    }
  }

  // Get free podcasts
  Future<List<Podcast>> getFreePodcasts({int limit = 10}) async {
    try {
      print('🔍 getFreePodcasts: Fetching $limit free podcasts from API...');
      final response = await _networkService.get('/podcasts/free/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        print('✅ getFreePodcasts: API response status: ${response.statusCode}');
        print('📊 getFreePodcasts: Response data keys: ${response.data.keys.toList()}');
        
        final podcastsData = response.data['freePodcasts'] as List;
        print('📚 getFreePodcasts: Found ${podcastsData.length} podcasts in response');
        print('📖 getFreePodcasts: Podcast titles: ${podcastsData.map((p) => p['title']).toList()}');
        
        final podcasts = podcastsData.map((json) {
          print('🔧 getFreePodcasts: Processing podcast: ${json['title']}');
          return Podcast.fromJson(json);
        }).toList();
        
        print('✅ getFreePodcasts: Successfully parsed ${podcasts.length} podcasts');
        print('📚 getFreePodcasts: Final podcast titles: ${podcasts.map((p) => p.title).toList()}');
        
        return podcasts;
      } else {
        print('❌ getFreePodcasts: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getFreePodcasts: Error occurred: $e');
      return [];
    }
  }

  // Get random podcasts for recommendations
  Future<List<Podcast>> getRandomPodcasts({int limit = 10}) async {
    try {
      print('🔍 getRandomPodcasts: Fetching $limit random podcasts from API...');
      final response = await _networkService.get('/podcasts/random/list', queryParameters: {'limit': limit});

      if (response.statusCode == 200) {
        print('✅ getRandomPodcasts: API response status: ${response.statusCode}');
        print('📊 getRandomPodcasts: Response data keys: ${response.data.keys.toList()}');
        
        final podcastsData = response.data['randomPodcasts'] as List;
        print('📚 getRandomPodcasts: Found ${podcastsData.length} podcasts in response');
        print('📖 getRandomPodcasts: Podcast titles: ${podcastsData.map((p) => p['title']).toList()}');
        
        final podcasts = podcastsData.map((json) {
          print('🔧 getRandomPodcasts: Processing podcast: ${json['title']}');
          return Podcast.fromJson(json);
        }).toList();
        
        print('✅ getRandomPodcasts: Successfully parsed ${podcasts.length} podcasts');
        print('📚 getRandomPodcasts: Final podcast titles: ${podcasts.map((p) => p.title).toList()}');
        
        return podcasts;
      } else {
        print('❌ getRandomPodcasts: API returned status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 getRandomPodcasts: Error occurred: $e');
      return [];
    }
  }

  // Get podcasts by category
  Future<List<Podcast>> getPodcastsByCategory(String categoryId, {int limit = 20}) async {
    try {
      print('🏷️ PodcastsService: Filtering podcasts by category: $categoryId');
      final response = await _networkService.get('/categories/$categoryId/podcasts', queryParameters: {'limit': limit});
      print('🏷️ PodcastsService: Category filter response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('🏷️ PodcastsService: Category filter response data: $data');
        if (data['success'] == true) {
          final podcastsData = data['podcasts'] as List;
          final podcasts = podcastsData.map((json) => Podcast.fromJson(json)).toList();
          print('🏷️ PodcastsService: Found ${podcasts.length} podcasts for category $categoryId');
          return podcasts;
        } else {
          print('🏷️ PodcastsService: API returned success=false for category filtering');
          return [];
        }
      } else {
        print('🏷️ PodcastsService: API returned error status ${response.statusCode} for category filtering');
        return [];
      }
    } catch (e) {
      print('🏷️ PodcastsService: Error filtering by category: $e');
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
      print('🎧 PodcastsService: Getting episodes for podcast: $podcastId');
      print('🎧 PodcastsService: Query params - page: $page, limit: $limit, search: $search, season: $season');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (season != null) queryParams['season'] = season;

      print('🎧 PodcastsService: Making API call to /podcasts/$podcastId/episodes');
      final response = await _networkService.get('/podcasts/$podcastId/episodes', queryParameters: queryParams);
      
      print('🎧 PodcastsService: API response status: ${response.statusCode}');
      print('🎧 PodcastsService: API response data keys: ${response.data.keys.toList()}');
      
      if (response.statusCode == 200) {
        final episodesData = response.data['episodes'] as List;
        print('🎧 PodcastsService: Raw episodes data count: ${episodesData.length}');
        
        if (episodesData.isNotEmpty) {
          print('🎧 PodcastsService: First episode data: ${episodesData.first}');
        }
        
        final episodes = episodesData.map((json) {
          print('🎧 PodcastsService: Parsing episode: ${json['id']} - ${json['title']}');
          return PodcastEpisode.fromJson(json);
        }).toList();
        
        print('✅ getPodcastEpisodes: Successfully fetched ${episodes.length} episodes');
        return episodes;
      } else {
        print('❌ getPodcastEpisodes: API returned status ${response.statusCode}');
        print('❌ getPodcastEpisodes: Response data: ${response.data}');
        return [];
      }
    } catch (e) {
      print('💥 getPodcastEpisodes: Error occurred: $e');
      print('💥 getPodcastEpisodes: Error type: ${e.runtimeType}');
      if (e.toString().contains('DioException')) {
        print('💥 getPodcastEpisodes: DioException details: $e');
      }
      return [];
    }
  }

  // Get episode by ID
  Future<PodcastEpisode?> getEpisodeById(String podcastId, String episodeId) async {
    try {
      print('🔍 PodcastsService: Getting episode by ID: $episodeId from podcast: $podcastId');
      
      final response = await _networkService.get('/podcasts/$podcastId/episodes/$episodeId');
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['episode'] != null) {
          final episodeData = responseData['episode'] as Map<String, dynamic>;
          final episode = PodcastEpisode.fromJson(episodeData);
          
          print('✅ getEpisodeById: Successfully fetched episode: ${episode.title}');
          return episode;
        } else {
          print('❌ getEpisodeById: Invalid response format');
          return null;
        }
      } else {
        print('❌ getEpisodeById: API returned status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 getEpisodeById: Error occurred: $e');
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
      print('💥 searchPodcasts: Error occurred: $e');
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
      print('💥 getPodcastLanguages: Error occurred: $e');
      return [];
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    // No local caching implemented yet
    print('🗑️ PodcastsService: Cache cleared');
  }
}
