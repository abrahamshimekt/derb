import 'package:derb/features/bookings/data/bookings_repository.dart';
import 'package:derb/features/bookings/data/models/booking.dart';
import 'package:derb/features/rooms/data/models/room.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/failures.dart';
import 'dart:developer' as developer;

sealed class BookingsStatus {
  const BookingsStatus();
}

class BookingsInitial extends BookingsStatus {
  const BookingsInitial();
}

class BookingsLoading extends BookingsStatus {
  const BookingsLoading();
}

class BookingsLoaded extends BookingsStatus {
  final List<Room> bedrooms;
  final List<Booking> userBookings;
  const BookingsLoaded({required this.bedrooms, required this.userBookings});
}

class BookingsError extends BookingsStatus {
  final String message;
  final bool isNetworkError;
  final bool isAuthError;
  const BookingsError({
    required this.message,
    this.isNetworkError = false,
    this.isAuthError = false,
  });
}

class BookingsController extends StateNotifier<BookingsStatus> {
  BookingsController(this._repo) : super(const BookingsInitial());

  final IBookingsRepository _repo;

  Future<void> fetchAvailableBedrooms(String guestHouseId) async {
    state = const BookingsLoading();
    try {
      final bedrooms = await _repo.fetchAvailableBedrooms(guestHouseId);
      state = BookingsLoaded(bedrooms: bedrooms, userBookings: []);
    } catch (e, stackTrace) {
      developer.log('Fetch bedrooms error: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = const BookingsError(
          message: 'Network error. Please check your connection.',
          isNetworkError: true,
        );
      } else if (e is AuthFailure) {
        state = const BookingsError(
          message: 'Authentication error. Please sign in again.',
          isAuthError: true,
        );
      } else {
        state = BookingsError(message: 'Failed to load bedrooms: $e');
      }
    }
  }

  Future<void> createBooking({
    required String bedroomId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    String? transactionId,
    required XFile idImage,
    required XFile receiptImage,
  }) async {
    state = const BookingsLoading();
    try {
      final booking = await _repo.createBooking(
        bedroomId: bedroomId,
        tenantId: tenantId,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        transactionId: transactionId,
        idImage: idImage,
        receiptImage: receiptImage,
      );
      if (state is BookingsLoaded) {
        final current = state as BookingsLoaded;
        state = BookingsLoaded(
          bedrooms: current.bedrooms.where((b) => b.id != bedroomId).toList(),
          userBookings: [...current.userBookings, booking],
        );
      } else {
        state = BookingsLoaded(bedrooms: [], userBookings: [booking]);
      }
    } catch (e, stackTrace) {
      developer.log('Create booking error: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = const BookingsError(
          message: 'Network error. Please check your connection.',
          isNetworkError: true,
        );
      } else if (e is AuthFailure) {
        state = const BookingsError(
          message: 'Authentication error. Please sign in again.',
          isAuthError: true,
        );
      } else {
        state = BookingsError(message: 'Failed to create booking: $e');
      }
      rethrow;
    }
  }

  Future<void> fetchUserBookings(String tenantId) async {
    state = const BookingsLoading();
    try {
      final bookings = await _repo.fetchUserBookings(tenantId);
      state = BookingsLoaded(bedrooms: [], userBookings: bookings);
    } catch (e, stackTrace) {
      developer.log('Fetch user bookings error: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = const BookingsError(
          message: 'Network error. Please check your connection.',
          isNetworkError: true,
        );
      } else if (e is AuthFailure) {
        state = const BookingsError(
          message: 'Authentication error. Please sign in again.',
          isAuthError: true,
        );
      } else {
        state = BookingsError(message: 'Failed to load bookings: $e');
      }
    }
  }

  Future<void> fetchGuestHouseBookings(String ownerId) async {
    state = const BookingsLoading();
    try {
      final bookings = await _repo.fetchGuestHouseBookings(ownerId);
      state = BookingsLoaded(bedrooms: [], userBookings: bookings);
    } catch (e, stackTrace) {
      developer.log(
        'Fetch guest house bookings error: $e',
        stackTrace: stackTrace,
      );
      if (e is NetworkFailure) {
        state = const BookingsError(
          message: 'Network error. Please check your connection.',
          isNetworkError: true,
        );
      } else if (e is AuthFailure) {
        state = const BookingsError(
          message: 'Authentication error. Please sign in again.',
          isAuthError: true,
        );
      } else {
        state = BookingsError(message: 'Failed to load bookings: $e');
      }
    }
  }
}

final bookingsControllerProvider =
    StateNotifierProvider<BookingsController, BookingsStatus>((ref) {
      return BookingsController(ref.watch(bookingsRepositoryProvider));
    });
