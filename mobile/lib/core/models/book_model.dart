import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert'; // Added for jsonDecode

class Book {
  final String id;
  final String title;
  final String? titleSomali;
  final String? description;

  final String? descriptionSomali;
  final String? authors;
  final String? authorsSomali;
  final List<String>? categories; // New: category IDs
  final List<String>? categoryNames; // New: category names for display
  final String language;
  final String format;
  final String? coverImageUrl;
  final String? audioUrl;

  final String? ebookUrl;

  final String? sampleUrl;

  final String? ebookContent; // New: actual ebook text content

  final int? duration;

  final int? pageCount;

  final double? rating;

  final int? reviewCount;

  final bool isFeatured;

  final bool isNewRelease;

  final bool isPremium;

  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.titleSomali,
    this.description,
    this.descriptionSomali,
    this.authors,
    this.authorsSomali,
    this.categories,
    this.categoryNames,
    required this.language,
    required this.format,
    this.coverImageUrl,
    this.audioUrl,
    this.ebookUrl,
    this.sampleUrl,
    this.ebookContent,
    this.duration,
    this.pageCount,
    this.rating,
    this.reviewCount,
    required this.isFeatured,
    required this.isNewRelease,
    required this.isPremium,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get displayTitle => titleSomali?.isNotEmpty == true ? titleSomali! : title;
  String get displayDescription => descriptionSomali?.isNotEmpty == true ? descriptionSomali! : (description ?? '');
  String get displayAuthors => authors ?? '';
  String get displayCategories => categoryNames?.isNotEmpty == true ? categoryNames!.join(', ') : '';

  // Factory constructor from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    print('🔧 Book.fromJson: Parsing book with ID: ${json['id']}');
    print('🔧 Book.fromJson: Raw JSON data: $json');
    print('🖼️ Book.fromJson: coverImageUrl from JSON: ${json['coverImageUrl']}');
    print('🖼️ Book.fromJson: coverImageUrl type: ${json['coverImageUrl']?.runtimeType}');
    
    try {
      final book = Book(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        titleSomali: json['titleSomali'],
        description: json['description'],
        descriptionSomali: json['descriptionSomali'],
        authors: json['authors']?.toString(),
        authorsSomali: json['authorsSomali']?.toString(),
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
        language: json['language'] ?? '',
        format: json['format'] ?? '',
        coverImageUrl: json['cover_image_url'] ?? json['coverImageUrl'],
        audioUrl: json['audio_url'] ?? json['audioUrl'],
        ebookUrl: json['ebook_url'] ?? json['ebookUrl'],
        sampleUrl: json['sample_url'] ?? json['sampleUrl'],
        ebookContent: json['ebookContent'],
        duration: json['duration'] != null 
            ? (json['duration'] is String 
                ? int.tryParse(json['duration']) ?? 0
                : (json['duration'] is num 
                    ? json['duration'].toInt() 
                    : 0))
            : 0,
        pageCount: json['pageCount'] != null 
            ? (json['pageCount'] is String 
                ? int.tryParse(json['pageCount']) ?? 0
                : (json['pageCount'] is num 
                    ? json['pageCount'].toInt() 
                    : 0))
            : 0,
        rating: json['rating'] != null 
            ? (json['rating'] is String 
                ? double.tryParse(json['rating']) ?? 0.0
                : (json['rating'] is num 
                    ? json['rating'].toDouble() 
                    : 0.0))
            : 0.0,
        reviewCount: json['reviewCount'] != null 
            ? (json['reviewCount'] is String 
                ? int.tryParse(json['reviewCount']) ?? 0
                : (json['reviewCount'] is num 
                    ? json['reviewCount'].toInt() 
                    : 0))
            : 0,
        isFeatured: json['isFeatured'] == true || json['isFeatured'] == 1,
        isNewRelease: json['isNewRelease'] == true || json['isNewRelease'] == 1,
        isPremium: json['isPremium'] == true || json['isPremium'] == 1,
        metadata: json['metadata'] != null 
            ? (json['metadata'] is String 
                ? jsonDecode(json['metadata'])
                : json['metadata'])
            : null,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
      
      print('✅ Book.fromJson: Successfully parsed book: ${book.title}');
      return book;
    } catch (e) {
      print('💥 Book.fromJson: Error parsing book: $e');
      print('💥 Book.fromJson: Problematic JSON: $json');
      rethrow;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleSomali': titleSomali,
      'description': description,
      'descriptionSomali': descriptionSomali,
      'authors': authors,
      'authorsSomali': authorsSomali,
      'categories': categories,
      'categoryNames': categoryNames,
      'language': language,
      'format': format,
      'coverImageUrl': coverImageUrl,
      'audioUrl': audioUrl,
      'ebookUrl': ebookUrl,
      'sampleUrl': sampleUrl,
      'ebookContent': ebookContent,
      'duration': duration,
      'pageCount': pageCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'isNewRelease': isNewRelease,
      'isPremium': isPremium,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Book copyWith({
    String? id,
    String? title,
    String? titleSomali,
    String? description,
    String? descriptionSomali,
    String? authors,
    String? authorsSomali,
    List<String>? categories,
    List<String>? categoryNames,
    String? language,
    String? format,
    String? coverImageUrl,
    String? audioUrl,
    String? ebookUrl,
    String? sampleUrl,
    String? ebookContent,
    int? duration,
    int? pageCount,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isNewRelease,
    bool? isPremium,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      titleSomali: titleSomali ?? this.titleSomali,
      description: description ?? this.description,
      descriptionSomali: descriptionSomali ?? this.descriptionSomali,
      authors: authors ?? this.authors,
      authorsSomali: authorsSomali ?? this.authorsSomali,
      categories: categories ?? this.categories,
      categoryNames: categoryNames ?? this.categoryNames,
      language: language ?? this.language,
      format: format ?? this.format,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      ebookUrl: ebookUrl ?? this.ebookUrl,
      sampleUrl: sampleUrl ?? this.sampleUrl,
      ebookContent: ebookContent ?? this.ebookContent,
      duration: duration ?? this.duration,
      pageCount: pageCount ?? this.pageCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isNewRelease: isNewRelease ?? this.isNewRelease,
      isPremium: isPremium ?? this.isPremium,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Book{id: $id, title: $title, categories: $categoryNames}';
  }
}
