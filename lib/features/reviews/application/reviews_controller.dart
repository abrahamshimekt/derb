import 'dart:async';
import 'package:derb/features/reviews/data/model/review.dart';
import 'package:derb/features/reviews/data/reviews_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:derb/core/failures.dart';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/legacy.dart';
import '../../rooms/application/rooms_controller.dart';

abstract class ReviewsStatus {
  const ReviewsStatus();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Review> reviews, double averageRating) loaded,
    required T Function(String message, bool isNetworkError, bool isAuthError) error,
  });
}

class ReviewsInitial extends ReviewsStatus {
  const ReviewsInitial();

  @override
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Review> reviews, double averageRating) loaded,
    required T Function(String message, bool isNetworkError, bool isAuthError) error,
  }) {
    return initial();
  }
}

class ReviewsLoading extends ReviewsStatus {
  const ReviewsLoading();

  @override
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Review> reviews, double averageRating) loaded,
    required T Function(String message, bool isNetworkError, bool isAuthError) error,
  }) {
    return loading();
  }
}

class ReviewsLoaded extends ReviewsStatus {
  final List<Review> reviews;
  final double averageRating;

  const ReviewsLoaded(this.reviews, this.averageRating);

  @override
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Review> reviews, double averageRating) loaded,
    required T Function(String message, bool isNetworkError, bool isAuthError) error,
  }) {
    return loaded(reviews, averageRating);
  }
}

class ReviewsError extends ReviewsStatus {
  final String message;
  final bool isNetworkError;
  final bool isAuthError;

  const ReviewsError(
    this.message, {
    this.isNetworkError = false,
    this.isAuthError = false,
  });

  @override
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Review> reviews, double averageRating) loaded,
    required T Function(String message, bool isNetworkError, bool isAuthError) error,
  }) {
    return error(message, isNetworkError, isAuthError);
  }
}

class ReviewsController extends StateNotifier<ReviewsStatus> {
  final IReviewsRepository _repository;
  final Ref _ref;
  StreamSubscription<List<Review>>? _subscription;

  // simple memo to avoid repeated checks during a session
  final Map<String, bool> _canReviewCache = {};

  ReviewsController(this._repository, this._ref) : super(const ReviewsInitial());

  double _avg(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    double s = 0;
    for (final r in reviews) {
      s += r.rating;
    }
    return s / reviews.length;
  }

  String _cacheKey(String roomId, String userId) => '$roomId::$userId';

  Future<bool> canAddReview({required String roomId, required String userId}) async {
    final key = _cacheKey(roomId, userId);
    if (_canReviewCache.containsKey(key)) return _canReviewCache[key]!;
    try {
      final hasReviewed = await _repository.hasUserReviewed(roomId: roomId, userId: userId);
      final can = !hasReviewed;
      _canReviewCache[key] = can;
      return can;
    } catch (e, stackTrace) {
      developer.log('Error checking if user can review roomId $roomId: $e',
          stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> fetchReviews({required String roomId}) async {
    state = const ReviewsLoading();
    try {
      final reviews = await _repository.fetchReviews(roomId: roomId);
      state = ReviewsLoaded(reviews, _avg(reviews));
      developer.log(
          'Reviews loaded for roomId $roomId: ${reviews.length} reviews, avg: ${_avg(reviews)}');
    } catch (e, stackTrace) {
      developer.log('Error fetching reviews for roomId $roomId: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = ReviewsError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = ReviewsError(e.message, isAuthError: true);
      } else {
        state = ReviewsError(e.toString());
      }
    }
  }

  Future<void> addReview({
    required String roomId,
    required String userId,
    required String comment,
    required double rating,
  }) async {
    // Store current state for optimistic update
    final currentState = state;
    
    try {
      if (!await canAddReview(roomId: roomId, userId: userId)) {
        state = const ReviewsError('You have already reviewed this room.');
        developer.log('User $userId attempted to review room $roomId again');
        return;
      }
      
      state = const ReviewsLoading();
      
      // Create optimistic review
      final optimisticReview = Review(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        userId: userId,
        comment: comment,
        rating: rating,
        createdAt: DateTime.now(),
        userName: 'You', // Will be replaced with actual name from server
      );
      
      // Optimistic update - add review to current list
      if (currentState is ReviewsLoaded) {
        final optimisticReviews = [optimisticReview, ...currentState.reviews];
        final optimisticAverage = _avg(optimisticReviews);
        state = ReviewsLoaded(optimisticReviews, optimisticAverage);
        
        // Optimistically update room rating
        _ref.read(roomsControllerProvider.notifier).updateRoomRatingOptimistically(roomId, optimisticAverage);
      }
      
      await _repository.addReview(
        roomId: roomId,
        userId: userId,
        comment: comment,
        rating: rating,
      );
      
      // user just reviewed; prevent immediate duplicate
      _canReviewCache[_cacheKey(roomId, userId)] = false;
      await fetchReviews(roomId: roomId);
      developer.log('Review added and refreshed for roomId $roomId');
    } catch (e, stackTrace) {
      developer.log('Error adding review for roomId $roomId: $e', stackTrace: stackTrace);
      // Revert optimistic updates on error
      if (currentState is ReviewsLoaded) {
        state = currentState;
      }
      if (e is NetworkFailure) {
        state = ReviewsError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = ReviewsError(e.message, isAuthError: true);
      } else {
        state = ReviewsError(e.toString());
      }
    }
  }

  void subscribe({required String roomId}) {
    _subscription?.cancel();
    _repository.subscribe(
      roomId: roomId,
      onUpdate: (reviews) {
        state = ReviewsLoaded(reviews, _avg(reviews));
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.unsubscribe();
    super.dispose();
    developer.log('ReviewsController disposed');
  }
}

final reviewsControllerProvider =
    StateNotifierProvider.family<ReviewsController, ReviewsStatus, String>(
  (ref, roomId) => ReviewsController(ref.read(reviewsRepositoryProvider), ref),
);
