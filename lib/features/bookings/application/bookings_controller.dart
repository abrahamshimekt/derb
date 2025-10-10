import 'package:derb/features/bookings/data/bookings_repository.dart';
import 'package:derb/features/bookings/data/models/booking.dart';
import 'package:derb/features/rooms/data/models/room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/failures.dart';
import 'dart:developer' as developer;
import '../../rooms/application/rooms_controller.dart';

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
  final IBookingsRepository _repo;
  final Ref _ref;

  BookingsController(this._repo, this._ref) : super(const BookingsInitial());

  BookingsError _mapErrorToBookingsError(dynamic error) {
    if (error is NetworkFailure) {
      return const BookingsError(
        message: 'Network error. Please check your connection.',
        isNetworkError: true,
      );
    } else if (error is AuthFailure) {
      return const BookingsError(
        message: 'Authentication error. Please sign in again.',
        isAuthError: true,
      );
    } else {
      return BookingsError(message: 'An error occurred: $error');
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
    required String phoneNumber
  }) async {
    // Store current state before setting loading
    final currentState = state;
    state = const BookingsLoading();
    
    // Optimistically update room status to 'booked' immediately
    _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(bedroomId, 'booked');
    
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
        phoneNumber: phoneNumber
      );
      
      // Update state immutably - append to existing bookings
      if (currentState is BookingsLoaded) {
        state = BookingsLoaded(
          bedrooms: currentState.bedrooms.where((b) => b.id != bedroomId).toList(),
          userBookings: [...currentState.userBookings, booking],
        );
      } else {
        state = BookingsLoaded(bedrooms: [], userBookings: [booking]);
      }
    } catch (e, stackTrace) {
      developer.log('Create booking error: $e', stackTrace: stackTrace);
      // Revert optimistic room status update on error
      _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(bedroomId, 'available');
      state = _mapErrorToBookingsError(e);
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
      state = _mapErrorToBookingsError(e);
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
      state = _mapErrorToBookingsError(e);
    }
  }

  Future<void> approveBooking(String bookingId) async {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    
    // Optimistic update - immediately update UI
    final optimisticBooking = currentState.userBookings
        .firstWhere((b) => b.id == bookingId)
        .copyWith(status: 'approved');
    
    final optimisticBookings = currentState.userBookings
        .map((b) => b.id == bookingId ? optimisticBooking : b)
        .toList();
    
    state = BookingsLoaded(
      bedrooms: currentState.bedrooms,
      userBookings: optimisticBookings,
    );
    
    try {
      final updatedBooking = await _repo.approveBooking(bookingId);
      // Update with actual server response - preserve the current state structure
      final finalBookings = optimisticBookings
          .map((b) => b.id == bookingId ? updatedBooking : b)
          .toList();
      
      state = BookingsLoaded(
        bedrooms: currentState.bedrooms,
        userBookings: finalBookings,
      );
    } catch (e, stackTrace) {
      developer.log('Approve booking error: $e', stackTrace: stackTrace);
      // Revert optimistic update on error
      state = currentState;
      state = _mapErrorToBookingsError(e);
    }
  }

  Future<void> checkInBooking(String bookingId) async {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    
    // Optimistic update - immediately update UI
    final optimisticBooking = currentState.userBookings
        .firstWhere((b) => b.id == bookingId)
        .copyWith(status: 'checked_in');
    
    final optimisticBookings = currentState.userBookings
        .map((b) => b.id == bookingId ? optimisticBooking : b)
        .toList();
    
    state = BookingsLoaded(
      bedrooms: currentState.bedrooms,
      userBookings: optimisticBookings,
    );
    
    try {
      final updatedBooking = await _repo.checkInBooking(bookingId);
      // Update with actual server response - preserve the current state structure
      final finalBookings = optimisticBookings
          .map((b) => b.id == bookingId ? updatedBooking : b)
          .toList();
      
      state = BookingsLoaded(
        bedrooms: currentState.bedrooms,
        userBookings: finalBookings,
      );
    } catch (e, stackTrace) {
      developer.log('Check-in booking error: $e', stackTrace: stackTrace);
      // Revert optimistic update on error
      state = currentState;
      state = _mapErrorToBookingsError(e);
    }
  }

  Future<void> checkOutBooking(String bookingId) async {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    
    // Find the booking to get the bedroom ID for optimistic room status update
    final booking = currentState.userBookings.firstWhere((b) => b.id == bookingId);
    
    // Optimistic update - immediately remove booking from UI and update room status
    final updatedBookings = currentState.userBookings
        .where((b) => b.id != bookingId)
        .toList();
    
    state = BookingsLoaded(
      bedrooms: currentState.bedrooms,
      userBookings: updatedBookings,
    );
    
    // Optimistically update room status to 'available'
    _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(booking.bedroomId, 'available');
    
    try {
      await _repo.checkOutBooking(bookingId);
      // Booking is already removed from UI, no need to update state again
      // The server operation confirms the check-out was successful
    } catch (e, stackTrace) {
      developer.log('Check-out booking error: $e', stackTrace: stackTrace);
      // Revert optimistic updates on error - restore the booking and room status
      _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(booking.bedroomId, 'booked');
      state = currentState;
      state = _mapErrorToBookingsError(e);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    
    // Find the booking to get the bedroom ID for optimistic room status update
    final booking = currentState.userBookings.firstWhere((b) => b.id == bookingId);
    
    // Optimistic update - immediately update UI
    final optimisticBooking = booking.copyWith(status: 'cancelled');
    
    final optimisticBookings = currentState.userBookings
        .map((b) => b.id == bookingId ? optimisticBooking : b)
        .toList();
    
    state = BookingsLoaded(
      bedrooms: currentState.bedrooms,
      userBookings: optimisticBookings,
    );
    
    // Optimistically update room status to 'available'
    _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(booking.bedroomId, 'available');
    
    try {
      final updatedBooking = await _repo.cancelBooking(bookingId);
      // Update with actual server response - preserve the current state structure
      final finalBookings = optimisticBookings
          .map((b) => b.id == bookingId ? updatedBooking : b)
          .toList();
      
      state = BookingsLoaded(
        bedrooms: currentState.bedrooms,
        userBookings: finalBookings,
      );
    } catch (e, stackTrace) {
      developer.log('Cancel booking error: $e', stackTrace: stackTrace);
      // Revert optimistic updates on error - restore booking and room status
      _ref.read(roomsControllerProvider.notifier).updateRoomStatusOptimistically(booking.bedroomId, 'booked');
      state = currentState;
      state = _mapErrorToBookingsError(e);
    }
  }
}

final bookingsControllerProvider =
    StateNotifierProvider<BookingsController, BookingsStatus>((ref) {
      return BookingsController(ref.watch(bookingsRepositoryProvider), ref);
    });