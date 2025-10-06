import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/room.dart';
import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

abstract class IRoomsRepository {
  Future<List<Room>> fetchRooms({required String guestHouseId});
  Future<void> createRoom({
    required String guestHouseId,
    required String roomNumber,
    required double price,
    required String status,
    required List<String> facilities,
    List<String>? roomPictures,
  });
  Future<List<String>> uploadImages({
    required String guestHouseId,
    required List<XFile> images,
  });
  void subscribe({
    required String guestHouseId,
    required void Function(List<Room> rooms) onUpdate,
  });
  void unsubscribe();
}

class SupabaseRoomsRepository implements IRoomsRepository {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  SupabaseRoomsRepository(this._client);

  @override
  Future<List<Room>> fetchRooms({required String guestHouseId}) async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('guest_house_id', guestHouseId);
      developer.log('Fetch rooms response for guestHouseId $guestHouseId: $response');
      return response.map((json) => Room.fromJson(json)).toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching rooms for guestHouseId $guestHouseId: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<String>> uploadImages({
    required String guestHouseId,
    required List<XFile> images,
  }) async {
    try {
      final List<String> imageUrls = [];
      for (var image in images) {
        final file = File(image.path);
        final fileName = '${guestHouseId}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = 'guest_house_rooms/$fileName';
        await _client.storage.from('guest_house_rooms').upload(path, file);
        final url = _client.storage.from('guest_house_rooms').getPublicUrl(path);
        imageUrls.add(url);
      }
      return imageUrls;
    } catch (e, stackTrace) {
      developer.log('Error uploading images: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> createRoom({
    required String guestHouseId,
    required String roomNumber,
    required double price,
    required String status,
    required List<String> facilities,
    List<String>? roomPictures,
  }) async {
    try {
      await _client.from('rooms').insert({
        'guest_house_id': guestHouseId,
        'room_number':roomNumber,
        'price': price,
        'status': status,
        'facilities': facilities,
        'room_pictures': roomPictures,
      });
      final roomCount = await _client
          .from('rooms')
          .select()
          .eq('guest_house_id', guestHouseId)
          .count();
      await _client
          .from('guest_houses')
          .update({'number_of_rooms': roomCount.count})
          .eq('id', guestHouseId);
      developer.log('Updated guest house $guestHouseId with number_of_rooms: ${roomCount.count}');
    } catch (e, stackTrace) {
      developer.log('Error creating room: $e', stackTrace: stackTrace);
      throw mapSupabaseError(e);
    }
  }

  @override
  void subscribe({
    required String guestHouseId,
    required void Function(List<Room> rooms) onUpdate,
  }) {
    // IMPORTANT: filter with .eq instead of putting it in the table string.
    _subscription = _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('guest_house_id', guestHouseId)
        .listen(
      (data) {
        try {
          final rooms = data
              .map((e) => Room.fromJson(e))
              .toList();
          onUpdate(rooms);
        } catch (e) {
          developer.log('Rooms stream parse error: $e');
        }
      },
      onError: (err) {
        developer.log('Rooms stream error: $err');
      },
    );
  }

  @override
  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    developer.log('Unsubscribed from rooms real-time updates');
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
      if (error.message.toLowerCase().contains('network') || error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure('Network error: Please check your connection.');
      }
      return UnknownFailure('Database error: ${error.message}');
    }
    if (error is StorageException) {
      if (error.message.toLowerCase().contains('network') || error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure('Network error during file upload: ${error.message}');
      }
      return UnknownFailure('Storage error: ${error.message}');
    }
    if (error is String) {
      if (error.toLowerCase().contains('network')) {
        return NetworkFailure(error);
      }
      if (error.toLowerCase().contains('auth') || error.toLowerCase().contains('unauthorized')) {
        return AuthFailure(error);
      }
      if (error.toLowerCase().contains('role')) {
        return AuthFailure('Invalid role configuration: $error');
      }
      return UnknownFailure(error);
    }
    return UnknownFailure('An unexpected error occurred: $error');
  }
}

final roomsRepositoryProvider = Provider<IRoomsRepository>(
  (ref) => SupabaseRoomsRepository(AppSupabase.client),
);