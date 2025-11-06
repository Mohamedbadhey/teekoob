import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';

class Podcast {
  final String id;
  final String title;
  final String? titleSomali;
  final String? description;
  final String? descriptionSomali;
  final String? host;
  final String? hostSomali;
  final String language;
  final String? coverImageUrl;
  final String? rssFeedUrl;
  final String? websiteUrl;
  final int? totalEpisodes;
  final double? rating;
  final int? reviewCount;
  final bool isFeatured;
  final bool isNewRelease;
  final bool isPremium;
  final bool isFree;
  final List<String>? categories; // category IDs
  final List<String>? categoryNames; // category names for display
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Podcast({
    required this.id,
    required this.title,
    this.titleSomali,
    this.description,
    this.descriptionSomali,
    this.host,
    this.hostSomali,
    required this.language,
    this.coverImageUrl,
    this.rssFeedUrl,
    this.websiteUrl,
    this.totalEpisodes,
    this.rating,
    this.reviewCount,
    required this.isFeatured,
    required this.isNewRelease,
    required this.isPremium,
    required this.isFree,
    this.categories,
    this.categoryNames,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get displayTitle => titleSomali?.isNotEmpty == true ? titleSomali! : title;
  String get displayDescription => descriptionSomali?.isNotEmpty == true ? descriptionSomali! : (description ?? '');
  String get displayHost => hostSomali?.isNotEmpty == true ? hostSomali! : (host ?? '');
  String get displayCategories => categoryNames?.isNotEmpty == true ? categoryNames!.join(', ') : '';

  // Factory constructor from JSON
  factory Podcast.fromJson(Map<String, dynamic> json) {
    
    try {
      final podcast = Podcast(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        titleSomali: json['title_somali'],
        description: json['description'],
        descriptionSomali: json['description_somali'],
        host: json['host']?.toString(),
        hostSomali: json['host_somali']?.toString(),
        language: json['language'] ?? '',
        coverImageUrl: json['cover_image_url'] ?? json['coverImageUrl'],
        rssFeedUrl: json['rss_feed_url'] ?? json['rssFeedUrl'],
        websiteUrl: json['website_url'] ?? json['websiteUrl'],
        totalEpisodes: json['total_episodes'] != null 
            ? (json['total_episodes'] is String 
                ? int.tryParse(json['total_episodes']) ?? 0
                : (json['total_episodes'] is num 
                    ? json['total_episodes'].toInt() 
                    : 0))
            : 0,
        rating: json['rating'] != null 
            ? (json['rating'] is String 
                ? double.tryParse(json['rating']) ?? 0.0
                : (json['rating'] is num 
                    ? json['rating'].toDouble() 
                    : 0.0))
            : 0.0,
        reviewCount: json['review_count'] != null 
            ? (json['review_count'] is String 
                ? int.tryParse(json['review_count']) ?? 0
                : (json['review_count'] is num 
                    ? json['review_count'].toInt() 
                    : 0))
            : 0,
        isFeatured: json['is_featured'] == true || json['is_featured'] == 1 || json['isFeatured'] == true || json['isFeatured'] == 1,
        isNewRelease: json['is_new_release'] == true || json['is_new_release'] == 1 || json['isNewRelease'] == true || json['isNewRelease'] == 1,
        isPremium: json['is_premium'] == true || json['is_premium'] == 1 || json['isPremium'] == true || json['isPremium'] == 1,
        isFree: json['is_free'] == true || json['is_free'] == 1 || json['isFree'] == true || json['isFree'] == 1,
        categories: json['categories'] != null 
            ? (json['categories'] is String 
                ? List<String>.from(jsonDecode(json['categories']))
                : List<String>.from(json['categories']))
            : null,
        categoryNames: json['categoryNames'] != null 
            ? (json['categoryNames'] is String 
                ? List<String>.from(jsonDecode(json['categoryNames']))
                : List<String>.from(json['categoryNames']))
            : null,
        metadata: json['metadata'] != null 
            ? (json['metadata'] is String 
                ? jsonDecode(json['metadata'])
                : json['metadata'])
            : null,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'])
            : (json['createdAt'] != null 
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'])
            : (json['updatedAt'] != null 
                ? DateTime.parse(json['updatedAt'])
                : DateTime.now()),
      );
      
      return podcast;
    } catch (e) {
      rethrow;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_somali': titleSomali,
      'description': description,
      'description_somali': descriptionSomali,
      'host': host,
      'host_somali': hostSomali,
      'language': language,
      'cover_image_url': coverImageUrl,
      'rss_feed_url': rssFeedUrl,
      'website_url': websiteUrl,
      'total_episodes': totalEpisodes,
      'rating': rating,
      'review_count': reviewCount,
      'is_featured': isFeatured,
      'is_new_release': isNewRelease,
      'is_premium': isPremium,
      'is_free': isFree,
      'categories': categories,
      'categoryNames': categoryNames,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Podcast copyWith({
    String? id,
    String? title,
    String? titleSomali,
    String? description,
    String? descriptionSomali,
    String? host,
    String? hostSomali,
    String? language,
    String? coverImageUrl,
    String? rssFeedUrl,
    String? websiteUrl,
    int? totalEpisodes,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isNewRelease,
    bool? isPremium,
    bool? isFree,
    List<String>? categories,
    List<String>? categoryNames,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      titleSomali: titleSomali ?? this.titleSomali,
      description: description ?? this.description,
      descriptionSomali: descriptionSomali ?? this.descriptionSomali,
      host: host ?? this.host,
      hostSomali: hostSomali ?? this.hostSomali,
      language: language ?? this.language,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      rssFeedUrl: rssFeedUrl ?? this.rssFeedUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isNewRelease: isNewRelease ?? this.isNewRelease,
      isPremium: isPremium ?? this.isPremium,
      isFree: isFree ?? this.isFree,
      categories: categories ?? this.categories,
      categoryNames: categoryNames ?? this.categoryNames,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Podcast &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Podcast{id: $id, title: $title, categories: $categoryNames}';
  }
}

class PodcastEpisode {
  final String id;
  final String podcastId;
  final String title;
  final String? titleSomali;
  final String? description;
  final String? descriptionSomali;
  final int episodeNumber;
  final int seasonNumber;
  final int? duration; // in minutes
  final String? audioUrl;
  final String? transcriptUrl;
  final String? transcriptContent;
  final Map<String, dynamic>? showNotes;
  final List<Map<String, dynamic>>? chapters;
  final double? rating;
  final int playCount;
  final int downloadCount;
  final bool isFeatured;
  final bool isPremium;
  final bool isFree;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PodcastEpisode({
    required this.id,
    required this.podcastId,
    required this.title,
    this.titleSomali,
    this.description,
    this.descriptionSomali,
    required this.episodeNumber,
    required this.seasonNumber,
    this.duration,
    this.audioUrl,
    this.transcriptUrl,
    this.transcriptContent,
    this.showNotes,
    this.chapters,
    this.rating,
    required this.playCount,
    required this.downloadCount,
    required this.isFeatured,
    required this.isPremium,
    required this.isFree,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get displayTitle => titleSomali?.isNotEmpty == true ? titleSomali! : title;
  String get displayDescription => descriptionSomali?.isNotEmpty == true ? descriptionSomali! : (description ?? '');
  String get formattedDuration {
    if (duration == null) return 'N/A';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Factory constructor from JSON
  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    try {
      return PodcastEpisode(
        id: json['id'] ?? '',
        podcastId: json['podcast_id'] ?? json['podcastId'] ?? '',
        title: json['title'] ?? '',
        titleSomali: json['title_somali'] ?? json['titleSomali'],
        description: json['description'],
        descriptionSomali: json['description_somali'] ?? json['descriptionSomali'],
        episodeNumber: _parseInt(json['episode_number'] ?? json['episodeNumber'], defaultValue: 1),
        seasonNumber: _parseInt(json['season_number'] ?? json['seasonNumber'], defaultValue: 1),
        duration: json['duration'] != null 
            ? (json['duration'] is String 
                ? int.tryParse(json['duration']) ?? 0
                : (json['duration'] is num 
                    ? json['duration'].toInt() 
                    : 0))
            : null,
        audioUrl: json['audio_url'] ?? json['audioUrl'],
        transcriptUrl: json['transcript_url'] ?? json['transcriptUrl'],
        transcriptContent: json['transcript_content'] ?? json['transcriptContent'],
        showNotes: _parseShowNotes(json['show_notes'] ?? json['showNotes']),
        chapters: json['chapters'] != null 
            ? (json['chapters'] is String 
                ? List<Map<String, dynamic>>.from(jsonDecode(json['chapters']))
                : List<Map<String, dynamic>>.from(json['chapters']))
            : null,
        rating: json['rating'] != null 
            ? (json['rating'] is String 
                ? double.tryParse(json['rating']) ?? 0.0
                : (json['rating'] is num 
                    ? json['rating'].toDouble() 
                    : 0.0))
            : 0.0,
        playCount: _parseInt(json['play_count'] ?? json['playCount'], defaultValue: 0),
        downloadCount: _parseInt(json['download_count'] ?? json['downloadCount'], defaultValue: 0),
        isFeatured: _parseBoolean(json['is_featured'] ?? json['isFeatured']),
        isPremium: _parseBoolean(json['is_premium'] ?? json['isPremium']),
        isFree: _parseBoolean(json['is_free'] ?? json['isFree']),
        publishedAt: _parseDateTime(json['published_at'] ?? json['publishedAt']),
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to parse boolean values from various types
  static bool _parseBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // Helper method to parse integer values from various types
  static int _parseInt(dynamic value, {required int defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  // Helper method to parse DateTime values
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method to parse show notes from various types
  static Map<String, dynamic>? _parseShowNotes(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcast_id': podcastId,
      'title': title,
      'title_somali': titleSomali,
      'description': description,
      'description_somali': descriptionSomali,
      'episode_number': episodeNumber,
      'season_number': seasonNumber,
      'duration': duration,
      'audio_url': audioUrl,
      'transcript_url': transcriptUrl,
      'transcript_content': transcriptContent,
      'show_notes': showNotes,
      'chapters': chapters,
      'rating': rating,
      'play_count': playCount,
      'download_count': downloadCount,
      'is_featured': isFeatured,
      'is_premium': isPremium,
      'is_free': isFree,
      'published_at': publishedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodcastEpisode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PodcastEpisode{id: $id, title: $title, episodeNumber: $episodeNumber}';
  }
}
