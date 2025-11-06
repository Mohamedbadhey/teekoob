import 'package:flutter/material.dart';
import 'package:teekoob/core/models/review_model.dart';
import 'package:teekoob/features/reviews/presentation/widgets/comment_card.dart';
import 'package:teekoob/features/reviews/presentation/widgets/rating_widget.dart';
import 'package:teekoob/features/reviews/services/reviews_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:teekoob/core/config/app_config.dart';

class CommentSection extends StatefulWidget {
  final String itemId;
  final String itemType; // 'book' or 'podcast'
  final String userId;
  final double? currentRating;
  final int? reviewCount;

  const CommentSection({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.userId,
    this.currentRating,
    this.reviewCount,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final ReviewsService _reviewsService = ReviewsService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Review> _reviews = [];
  Review? _userReview;
  bool _isLoading = false;
  bool _isSubmitting = false;
  double _selectedRating = 0.0;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadUserReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _reviewsService.getReviews(
        itemId: widget.itemId,
        itemType: widget.itemType,
        page: _currentPage,
        limit: 20,
      );
      
      setState(() {
        if (_currentPage == 1) {
          _reviews = result['reviews'] as List<Review>;
        } else {
          _reviews.addAll(result['reviews'] as List<Review>);
        }
        _hasMore = _currentPage < result['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserReview() async {
    try {
      final review = await _reviewsService.getUserReview(
        itemId: widget.itemId,
        itemType: widget.itemType,
      );
      
      setState(() {
        _userReview = review;
        // Don't auto-populate form - only populate when user clicks edit
        // Form stays empty for new reviews
      });
    } catch (e) {
    }
  }

  Future<void> _loadUserReviewForEditing(Review review) async {
    // Load the specific review for editing
    setState(() {
      _userReview = review;
      _selectedRating = review.rating;
      _commentController.text = review.comment ?? '';
    });
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent multiple submissions
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Check if user already has a review before submitting
      final existingReview = await _reviewsService.getUserReview(
        itemId: widget.itemId,
        itemType: widget.itemType,
      );

      final isUpdating = existingReview != null;
      
      final review = await _reviewsService.createOrUpdateReview(
        itemId: widget.itemId,
        itemType: widget.itemType,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty 
            ? _commentController.text.trim() 
            : null,
      );

      // Refresh reviews list
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _reviews = []; // Clear existing reviews
      });
      
      // Reload both reviews list and user review
      await Future.wait([
        _loadReviews(),
        _loadUserReview(),
      ]);

      // Always clear form after submission - user must click edit to modify
      setState(() {
        _selectedRating = 0.0;
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdating 
              ? 'Review updated successfully!' 
              : 'Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview() async {
    if (_userReview == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reviewsService.deleteReview(_userReview!.id);
        
        setState(() {
          _userReview = null;
          _selectedRating = 0.0;
          _commentController.clear();
          // Refresh reviews list
          _currentPage = 1;
          _hasMore = true;
          _loadReviews();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and review summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RatingWidget(
                        rating: widget.currentRating ?? 0.0,
                        size: 24,
                        reviewCount: widget.reviewCount ?? 0,
                      ),
                    ],
                  ),
                  if (widget.currentRating != null && widget.currentRating! > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.currentRating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            'out of 5',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Write a review section - only show if no review exists or user is editing
        if (_userReview == null || (_selectedRating > 0 || _commentController.text.isNotEmpty))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userReview == null ? 'Write a Review' : 'Edit Your Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (_userReview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Make your changes and click "Update Review"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating selection
                    Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingWidget(
                      rating: _selectedRating,
                      size: 32,
                      allowInteraction: true,
                      userRating: _selectedRating,
                      onRatingChanged: (rating) {
                        setState(() => _selectedRating = rating);
                      },
                      showRatingText: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Comment text field
                    Text(
                      'Your Comment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts about this ${widget.itemType}...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.background,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Submit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_userReview != null && (_selectedRating > 0 || _commentController.text.isNotEmpty))
                          TextButton(
                            onPressed: _isSubmitting ? null : () {
                              setState(() {
                                _selectedRating = 0.0;
                                _commentController.clear();
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: (_isSubmitting || (_selectedRating == 0.0 && _commentController.text.trim().isEmpty)) 
                              ? null 
                              : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_userReview == null ? 'Submit Review' : 'Update Review'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (_userReview != null && (_selectedRating == 0.0 && _commentController.text.isEmpty))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have already reviewed this ${widget.itemType}. Click "Edit" on your review below to modify it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Reviews list
        Text(
          'Reviews (${_reviews.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_reviews.isEmpty && !_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to review this ${widget.itemType}!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _reviews.length) {
                if (_hasMore) {
                  _currentPage++;
                  _loadReviews();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              
              final review = _reviews[index];
              final isUserReview = review.userId == widget.userId;
              
              return CommentCard(
                review: review,
                showActions: isUserReview,
                onEdit: isUserReview ? () {
                  // Load the user's review and populate form for editing
                  _loadUserReviewForEditing(review);
                  // Scroll to top to show the form
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                onDelete: isUserReview ? () => _deleteReview() : null,
              );
            },
          ),
      ],
    );
  }
}

String _buildFullImageUrl(String relativeUrl) {
  if (relativeUrl.startsWith('http')) {
    return relativeUrl;
  }
  return '${AppConfig.mediaBaseUrl}$relativeUrl';
}

