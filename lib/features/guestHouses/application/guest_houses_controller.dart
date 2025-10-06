import 'package:derb/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/guest_houses_repository.dart';
import '../data/models/guest_house.dart';
import '../../../core/failures.dart';
import 'dart:io';
import 'dart:developer' as developer;

abstract class GuestHousesStatus {
  const GuestHousesStatus();
}

class GuestHousesInitial extends GuestHousesStatus {
  const GuestHousesInitial();
}

class GuestHousesLoading extends GuestHousesStatus {
  const GuestHousesLoading();
}

class GuestHousesLoaded extends GuestHousesStatus {
  final List<GuestHouse> guestHouses;

  const GuestHousesLoaded(this.guestHouses);
}

class GuestHousesError extends GuestHousesStatus {
  final String message;
  final bool isNetworkError;
  final bool isAuthError;

  const GuestHousesError(
    this.message, {
    this.isNetworkError = false,
    this.isAuthError = false,
  });
}

class GuestHousesController extends StateNotifier<GuestHousesStatus> {
  final IGuestHousesRepository _repository;
  final Ref _ref;

  GuestHousesController(this._repository, this._ref)
      : super(const GuestHousesInitial()) {
    // Listen to auth status changes
    _ref.listen(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        final userId = next.session.user.id;
        final role = next.session.user.userMetadata != null &&
                next.session.user.userMetadata!.containsKey('role')
            ? next.session.user.userMetadata!['role'].toString()
            : 'tenant';
        // Re-fetch data and update subscription on login
        fetchGuestHouses(userId: userId, role: role);
        _updateSubscription(userId: userId, role: role);
      }
    });

    // Initial fetch based on current auth status
    final authStatus = _ref.read(authControllerProvider);
    final userId = authStatus is AuthAuthenticated
        ? authStatus.session.user.id
        : null;
    final role = authStatus is AuthAuthenticated
        ? (authStatus.session.user.userMetadata != null &&
                  authStatus.session.user.userMetadata!.containsKey('role')
              ? authStatus.session.user.userMetadata!['role'].toString()
              : 'tenant')
        : 'tenant';
    fetchGuestHouses(userId: userId, role: role);
    _subscribe(userId: userId, role: role);
  }

  Future<void> fetchGuestHouses({
    int? pageNumber,
    int? pageSize,
    required String? userId,
    required String role,
  }) async {
    state = const GuestHousesLoading();
    try {
      final guestHouses = await _repository.fetchGuestHouses(
        pageNumber: pageNumber,
        pageSize: pageSize,
        userId: userId,
        role: role,
      );
      state = GuestHousesLoaded(guestHouses);
    } catch (e, stackTrace) {
      developer.log('Error fetching guest houses: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = GuestHousesError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = GuestHousesError(e.message, isAuthError: true);
      } else {
        state = GuestHousesError(e.toString());
      }
    }
  }

  Future<void> createGuestHouse({
    required String ownerId,
    required double latitude,
    required double longitude,
    required String relativeLocationDescription,
    required int numberOfRooms,
    required String city,
    required String region,
    required String subCity,
    File? imageFile,
    required String guestHouseName,
    required String description,
  }) async {
    try {
      await _repository.createGuestHouse(
        ownerId: ownerId,
        latitude: latitude,
        longitude: longitude,
        relativeLocationDescription: relativeLocationDescription,
        numberOfRooms: numberOfRooms,
        city: city,
        region: region,
        subCity: subCity,
        imageFile: imageFile,
        guestHouseName: guestHouseName,
        description: description,
      );
      // No need to call fetchGuestHouses; real-time subscription updates state
    } catch (e, stackTrace) {
      developer.log('Error creating guest house: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = GuestHousesError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = GuestHousesError(e.message, isAuthError: true);
      } else {
        state = GuestHousesError(e.toString());
      }
    }
  }

  void _subscribe({required String? userId, required String role}) {
    try {
      _repository.subscribeToGuestHouses(
        (guestHouses, {dynamic error}) {
          if (error != null) {
            developer.log('Subscription error: $error');
            state = GuestHousesError(error.toString());
            return;
          }
          state = GuestHousesLoaded(guestHouses);
        },
        userId: userId,
        role: role,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting up subscription: $e',
        stackTrace: stackTrace,
      );
      state = GuestHousesError(e.toString());
    }
  }

  void _updateSubscription({required String? userId, required String role}) {
    // Unsubscribe from previous subscription
    _repository.unsubscribe();
    // Start a new subscription with updated userId and role
    _subscribe(userId: userId, role: role);
  }

  @override
  void dispose() {
    _repository.unsubscribe();
    super.dispose();
  }
}

final guestHousesControllerProvider =
    StateNotifierProvider<GuestHousesController, GuestHousesStatus>(
      (ref) =>
          GuestHousesController(ref.read(guestHousesRepositoryProvider), ref),
    );