import 'package:teekoob/core/models/review_model.dart';
import 'package:teekoob/core/services/network_service.dart';

class ReviewsService {
  final NetworkService _networkService;

  ReviewsService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Get reviews for a book or podcast
  Future<Map<String, dynamic>> getReviews({
    required String itemId,
    required String itemType, // 'book' or 'podcast'
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _networkService.get(
        '/reviews/$itemType/$itemId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final reviewsData = response.data['reviews'] as List;
        final reviews = reviewsData.map((json) => Review.fromJson(json)).toList();

        return {
          'reviews': reviews,
          'total': response.data['total'],
          'page': response.data['page'],
          'limit': response.data['limit'],
          'totalPages': response.data['totalPages'],
          'averageRating': response.data['averageRating'] ?? 0.0,
        };
      } else {
        throw Exception('Failed to fetch reviews');
      }
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  // Get user's review for a specific item
  Future<Review?> getUserReview({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final response = await _networkService.get('/reviews/user/$itemType/$itemId');

      if (response.statusCode == 200) {
        final reviewData = response.data['review'];
        if (reviewData != null) {
          return Review.fromJson(reviewData);
        }
        return null;
      } else {
        throw Exception('Failed to fetch user review');
      }
    } catch (e) {
      return null;
    }
  }

  // Create or update a review
  Future<Review> createOrUpdateReview({
    required String itemId,
    required String itemType,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _networkService.post(
        '/reviews',
        data: {
          'itemId': itemId,
          'itemType': itemType,
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Review.fromJson(response.data['review']);
      } else {
        throw Exception('Failed to create/update review');
      }
    } catch (e) {
      throw Exception('Failed to create/update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _networkService.delete('/reviews/$reviewId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete review');
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}

