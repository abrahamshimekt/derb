import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../data/rooms_repository.dart';
import '../data/models/room.dart';
import '../../../core/failures.dart';
import 'dart:developer' as developer;

abstract class RoomsStatus {
  const RoomsStatus();
}

class RoomsInitial extends RoomsStatus {
  const RoomsInitial();
}

class RoomsLoading extends RoomsStatus {
  const RoomsLoading();
}

class RoomsLoaded extends RoomsStatus {
  final List<Room> rooms;

  const RoomsLoaded(this.rooms);
}

class RoomsError extends RoomsStatus {
  final String message;
  final bool isNetworkError;
  final bool isAuthError;

  const RoomsError(
    this.message, {
    this.isNetworkError = false,
    this.isAuthError = false,
  });
}

class RoomsController extends StateNotifier<RoomsStatus> {
  final IRoomsRepository _repository;

  RoomsController(this._repository) : super(const RoomsInitial());

  Future<List<String>> uploadImages({
    required String guestHouseId,
    required List<XFile> images,
  }) async {
    try {
      return await _repository.uploadImages(
        guestHouseId: guestHouseId,
        images: images,
      );
    } catch (e, stackTrace) {
      developer.log('Error uploading images: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = RoomsError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = RoomsError(e.message, isAuthError: true);
      } else {
        state = RoomsError(e.toString());
      }
      rethrow;
    }
  }

  Future<void> createRoom({
    required String guestHouseId,
    required String roomNumber,
    required double price,
    required String status,
    required List<String> facilities,
    List<String>? roomPictures,
  }) async {
    try {
      await _repository.createRoom(
        guestHouseId: guestHouseId,
        roomNumber: roomNumber,
        price: price,
        status: status,
        facilities: facilities,
        roomPictures: roomPictures,
      );
    } catch (e, stackTrace) {
      developer.log('Error creating room: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = RoomsError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = RoomsError(e.message, isAuthError: true);
      } else {
        state = RoomsError(e.toString());
      }
    }
  }

  Future<void> fetchRooms({required String guestHouseId}) async {
    state = const RoomsLoading();
    try {
      final rooms = await _repository.fetchRooms(guestHouseId: guestHouseId);
      state = RoomsLoaded(rooms);
    } catch (e, stackTrace) {
      developer.log('Error fetching rooms: $e', stackTrace: stackTrace);
      if (e is NetworkFailure) {
        state = RoomsError(e.message, isNetworkError: true);
      } else if (e is AuthFailure) {
        state = RoomsError(e.message, isAuthError: true);
      } else {
        state = RoomsError(e.toString());
      }
    }
  }

  void subscribe({required String guestHouseId}) {
    _repository.subscribe(
      guestHouseId: guestHouseId,
      onUpdate: (rooms) => state = RoomsLoaded(rooms),
    );
  }

  void updateRoomStatusOptimistically(String roomId, String newStatus) {
    final currentState = state;
    if (currentState is RoomsLoaded) {
      final updatedRooms = currentState.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(status: newStatus);
        }
        return room;
      }).toList();
      state = RoomsLoaded(updatedRooms);
    }
  }

  void updateRoomRatingOptimistically(String roomId, double newRating) {
    final currentState = state;
    if (currentState is RoomsLoaded) {
      final updatedRooms = currentState.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(rating: newRating);
        }
        return room;
      }).toList();
      state = RoomsLoaded(updatedRooms);
    }
  }

  @override
  void dispose() {
    _repository.unsubscribe();
    super.dispose();
  }
}

final roomsControllerProvider =
    StateNotifierProvider<RoomsController, RoomsStatus>(
      (ref) => RoomsController(ref.read(roomsRepositoryProvider)),
    );
