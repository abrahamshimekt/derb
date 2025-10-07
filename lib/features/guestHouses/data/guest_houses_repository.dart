import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/failures.dart';
import '../../../core/supabase_client.dart';
import 'models/guest_house.dart';

abstract class IGuestHousesRepository {
  Future<List<GuestHouse>> fetchGuestHouses({
    int? pageNumber,
    int? pageSize,
    String? userId,
    required String role,
  });

  Future<GuestHouse> createGuestHouse({
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
  });

  void subscribeToGuestHouses(
    void Function(List<GuestHouse> guestHouses) onUpdate, {
    String? userId,
    required String role,
  });

  void unsubscribe();
}

class SupabaseGuestHousesRepository implements IGuestHousesRepository {
  final _client = AppSupabase.client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<GuestHouse>> fetchGuestHouses({
    int? pageNumber,
    int? pageSize,
    String? userId,
    required String role,
  }) async {
    try {
      if (role == 'guest_house_owner' && userId == null) {
        return [];
      }

      var query = _client
          .from('guest_houses')
          .select(
            'id, owner_id, latitude, longitude, relative_location_description, number_of_rooms, city, region, sub_city, picture_url, guest_house_name, description, rating',
          );

      if (role == 'guest_house_owner' && userId != null) {
        query = query.eq('owner_id', userId);
      }

      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformQuery =
          query;

      if (pageNumber != null && pageSize != null) {
        final from = (pageNumber - 1) * pageSize;
        final to = from + pageSize - 1;
        transformQuery = query.range(from, to);
      } else if (pageSize != null) {
        transformQuery = query.range(0, pageSize - 1);
      }

      final response = await transformQuery;
      final guestHouses = (response as List<dynamic>)
          .map((json) => GuestHouse.fromJson(json as Map<String, dynamic>))
          .toList();

      return guestHouses;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<GuestHouse> createGuestHouse({
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
      String? pictureUrl;
      if (imageFile != null) {
        final fileName =
            '${const Uuid().v4()}.${imageFile.path.split('.').last}';
        await _client.storage.from('guest_houses').upload(fileName, imageFile);
        pictureUrl = _client.storage
            .from('guest_houses')
            .getPublicUrl(fileName);
        developer.log('Uploaded image to: $pictureUrl');
      }

      final response = await _client
          .from('guest_houses')
          .insert({
            'id': const Uuid().v4(),
            'owner_id': ownerId,
            'latitude': latitude,
            'longitude': longitude,
            'relative_location_description': relativeLocationDescription,
            'number_of_rooms': numberOfRooms,
            'city': city,
            'region': region,
            'sub_city': subCity,
            'picture_url': pictureUrl,
            'guest_house_name': guestHouseName,
            'description': description,
          })
          .select()
          .single();

      developer.log('Created guest house: ${response['guest_house_name']}');
      return GuestHouse.fromJson(response);
    } catch (e) {
      developer.log('Error creating guest house: $e');
      throw mapSupabaseError(e);
    }
  }

  @override
  void subscribeToGuestHouses(
    void Function(List<GuestHouse> guestHouses) onUpdate, {
    String? userId,
    required String role,
  }) {
    try {
      Stream<List<Map<String, dynamic>>> stream;

      if (role == 'guest_house_owner') {
        if (userId == null) {
          developer.log(
            'Warning: userId is null for guest_house_owner role, emitting empty list',
          );
          onUpdate([]);
          return;
        }
        stream = _client
            .from('guest_houses')
            .stream(primaryKey: ['id'])
            .eq('owner_id', userId);
      } else {
        stream = _client.from('guest_houses').stream(primaryKey: ['id']);
      }

      _subscription = stream.listen(
        (data) {
          try {
            final guestHouses =
                data.map((json) => GuestHouse.fromJson(json)).toList()..sort(
                  (a, b) => a.guestHouseName.compareTo(b.guestHouseName),
                );

            developer.log(
              'Real-time update: ${guestHouses.length} guest houses'
              '${role == "guest_house_owner" ? " (owner $userId)" : ""}',
            );
            onUpdate(guestHouses);
          } catch (e) {
            developer.log('Real-time parse error: $e');
          }
        },
        onError: (error) {
          developer.log('Real-time subscription error: $error');
        },
      );
    } catch (e) {
      developer.log('Error setting up real-time subscription: $e');
      throw mapSupabaseError(e);
    }
  }

  @override
  void unsubscribe() {
    _subscription?.cancel();
    developer.log('Unsubscribed from guest houses real-time updates');
    _subscription = null;
  }

  Failure mapSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      if (error.code == '42501' ||
          error.message.contains('permission denied')) {
        return AuthFailure('Permission denied: Please sign in again.');
      } else if (error.code == '42601' ||
          error.message.contains('syntax error')) {
        return UnknownFailure('Database query syntax error: ${error.message}');
      } else if (error.message.toLowerCase().contains('network') ||
          error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure('Network error: Please check your connection.');
      }
      return UnknownFailure('Database error: ${error.message}');
    } else if (error is StorageException) {
      if (error.message.toLowerCase().contains('network') ||
          error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure(
          'Network error during file upload: ${error.message}',
        );
      }
      return UnknownFailure('Storage error: ${error.message}');
    } else if (error is String) {
      if (error.toLowerCase().contains('network')) {
        return NetworkFailure(error);
      } else if (error.toLowerCase().contains('auth') ||
          error.toLowerCase().contains('unauthorized')) {
        return AuthFailure(error);
      } else if (error.toLowerCase().contains('role')) {
        return AuthFailure('Invalid role configuration: $error');
      }
      return UnknownFailure(error);
    }
    return UnknownFailure('An unexpected error occurred: $error');
  }
}

final guestHousesRepositoryProvider = Provider<IGuestHousesRepository>(
  (ref) => SupabaseGuestHousesRepository(),
);
