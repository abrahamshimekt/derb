import 'dart:async' show StreamSubscription;
import 'package:derb/features/reviews/data/model/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:derb/core/failures.dart';
import 'dart:developer' as developer;

abstract class IReviewsRepository {
  Future<List<Review>> fetchReviews({required String roomId});
  Future<void> addReview({
    required String roomId,
    required String userId,
    required String comment,
    required double rating,
  });
  Future<double> getAverageRating({required String roomId});
  Future<bool> hasUserReviewed({required String roomId, required String userId});
  void subscribe({
    required String roomId,
    required void Function(List<Review> reviews) onUpdate,
  });
  void unsubscribe();
}

class SupabaseReviewsRepository implements IReviewsRepository {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  SupabaseReviewsRepository(this._client);

  @override
  Future<List<Review>> fetchReviews({required String roomId}) async {
    try {
      // Lean select; includes nested user name if you have a FK to public.users
      final rows = await _client
          .from('reviews')
          .select('''
            id,
            room_id,
            user_id,
            comment,
            rating,
            created_at,
            users (
              full_name
            )
          ''')
          .eq('room_id', roomId)
          .order('created_at', ascending: false);

      developer.log('Fetch reviews response for roomId $roomId: ${rows.length} rows');

      return (rows as List)
          .map((json) {
            final user = (json['users'] as Map?) ?? const {};
            return Review.fromJson({
              ...json,
              'user_name': user['full_name'],
            });
          })
          .toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching reviews for roomId $roomId: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> addReview({
    required String roomId,
    required String userId,
    required String comment,
    required double rating,
  }) async {
    try {
      await _client.from('reviews').insert({
        'room_id': roomId,
        'user_id': userId,
        'comment': comment,
        'rating': rating,
      });
      developer.log('Review added for roomId $roomId');
    } catch (e, stackTrace) {
      developer.log('Error adding review for roomId $roomId: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  // Kept for compatibility. Controller computes average locally from fetched/streamed data.
  @override
  Future<double> getAverageRating({required String roomId}) async {
    try {
      final rows = await _client
          .from('reviews')
          .select('rating')
          .eq('room_id', roomId);

      if (rows.isEmpty) return 0.0;
      final ratings = (rows as List).map((e) => (e['rating'] as num).toDouble()).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      developer.log('Average rating for roomId $roomId: $average');
      return average;
    } catch (e, stackTrace) {
      developer.log('Error fetching average rating for roomId $roomId: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<bool> hasUserReviewed({required String roomId, required String userId}) async {
    try {
      final rows = await _client
          .from('reviews')
          .select('id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .limit(1);

      final hasReviewed = rows.isNotEmpty;
      developer.log('User $userId hasReviewed room $roomId: $hasReviewed');
      return hasReviewed;
    } catch (e, stackTrace) {
      developer.log('Error checking if user reviewed roomId $roomId: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  void subscribe({
    required String roomId,
    required void Function(List<Review> reviews) onUpdate,
  }) {
    _subscription?.cancel();
    _subscription = _client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .listen(
          (data) {
            try {
              // Streams typically do not include joined tables. userName may be null; UI already handles it.
              final reviews = data.map((e) => Review.fromJson(e)).toList();
              onUpdate(reviews);
              developer.log('Reviews stream update for roomId $roomId: ${reviews.length} reviews');
            } catch (e) {
              developer.log('Reviews stream parse error: $e');
            }
          },
          onError: (err) {
            developer.log('Reviews stream error for roomId $roomId: $err');
          },
        );
  }

  @override
  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    developer.log('Unsubscribed from reviews real-time updates');
  }

  Failure mapSupabaseError(dynamic error) {
    developer.log('Mapping error: $error');
    if (error is PostgrestException) {
      if (error.code == '42501' || error.message.contains('permission denied')) {
        return AuthFailure('Permission denied: Please sign in again.');
      }
      if (error.code == '42601' || error.message.contains('syntax error')) {
        return UnknownFailure('Database query syntax error: ${error.message}');
      }
      if (error.message.toLowerCase().contains('network') ||
          error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure('Network error: Please check your connection.');
      }
      return UnknownFailure('Database error: ${error.message}');
    }
    if (error is String) {
      final lower = error.toLowerCase();
      if (lower.contains('network')) {
        return NetworkFailure(error);
      }
      if (lower.contains('auth') || lower.contains('unauthorized')) {
        return AuthFailure(error);
      }
      return UnknownFailure(error);
    }
    return UnknownFailure('An unexpected error occurred: $error');
  }
}

final reviewsRepositoryProvider = Provider<IReviewsRepository>(
  (ref) => SupabaseReviewsRepository(Supabase.instance.client),
);
