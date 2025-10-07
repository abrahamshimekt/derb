import 'dart:io';
import 'dart:developer' as developer;

import 'package:derb/core/failures.dart';
import 'package:derb/core/supabase_client.dart';
import 'package:derb/features/bookings/data/models/booking.dart';
import 'package:derb/features/rooms/data/models/room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


abstract class IBookingsRepository {
  Future<List<Room>> fetchAvailableBedrooms(String guestHouseId);
  Future<Booking> createBooking({
    required String bedroomId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    String? transactionId,
    required XFile idImage,
    required XFile receiptImage,
    required String phoneNumber
  });
  Future<List<Booking>> fetchUserBookings(String tenantId);
  Future<List<Booking>> fetchGuestHouseBookings(String ownerId);
}

class SupabaseBookingsRepository implements IBookingsRepository {
  final _client = AppSupabase.client;

  @override
  Future<List<Room>> fetchAvailableBedrooms(String guestHouseId) async {
    try {
      final resp = await _client
          .from('rooms')
          .select()
          .eq('guest_house_id', guestHouseId)
          // using status column per your latest schema
          .eq('status', 'available');

      return (resp as List)
          .map<Room>((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Booking> createBooking({
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
    try {
      // 1) Validate room exists & is available
      final room = await _client
          .from('rooms')
          .select('id,status')
          .eq('id', bedroomId)
          .eq('status', 'available')
          .maybeSingle();

      if (room == null) {
        throw UnknownFailure('Room is not available or does not exist');
      }

      // 2) Check for overlap using DATE strings
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      developer.log('Checking overlaps $startStr → $endStr', name: 'bookings.create');
      final overlaps = await _client
          .from('bookings')
          .select('id,start_date,end_date,status')
          .eq('bedroom_id', bedroomId)
          .lte('start_date', endStr)
          .gte('end_date', startStr)
          // only block if booking is still active
          .not('status', 'in', ['cancelled', 'checked_out']);

      if ((overlaps as List).isNotEmpty) {
        throw UnknownFailure('Bedroom is already booked for the selected dates');
      }


      final urls = <String>[];
      for (final image in [idImage, receiptImage]) {
        final f = File(image.path);
        if (!f.existsSync()) {
          throw UnknownFailure('Image file not found: ${image.path}');
        }
        final fileName =
            '${bedroomId}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = '$tenantId/$fileName';

        await _client.storage.from('booking_images').upload(path, f);
        final publicUrl =
            _client.storage.from('booking_images').getPublicUrl(path);
        urls.add(publicUrl);
      }

      final inserted = await _client
          .from('bookings')
          .insert({
            'bedroom_id': bedroomId,
            'tenant_id': tenantId,
            'start_date': startStr,
            'end_date': endStr,
            'total_price': totalPrice,
            'status': 'pending',
            'has_paid': false,
            'id_url': urls[0],
            'payment_reciept_url': urls[1],
            'transaction_id': transactionId,
            'phone_number':phoneNumber
          })
          .select() 
          .single();

      return Booking.fromJson(inserted);
    } catch (e) {
      developer.log('Create booking error: $e',
          name: 'bookings.create', stackTrace: StackTrace.current);
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Booking>> fetchUserBookings(String tenantId) async {
    try {
      final resp = await _client
          .from('bookings')
          .select(r'''
            *,
            rooms!bookings_bedroom_id_fkey(
              room_number,
              room_pictures,
              guest_houses!inner(guest_house_name,city, sub_city)
            )
          ''')
          .eq('tenant_id', tenantId);

      if (resp.isEmpty) {
        developer.log('No bookings for tenant $tenantId', name: 'bookings.list');
        return [];
      }
      return (resp as List)
          .map<Booking>((j) => Booking.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Fetch user bookings error: $e', name: 'bookings.list');
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Booking>> fetchGuestHouseBookings(String ownerId) async {
    try {
      final resp = await _client
          .from('bookings')
          .select(r'''
            *,
            rooms!bookings_bedroom_id_fkey(
              room_number,
              room_pictures,
              guest_houses!inner(guest_house_name,city, sub_city, owner_id)
            )
          ''')
          .eq('rooms.guest_houses.owner_id', ownerId)
          // active-ish states; adjust if you add more
          .not('status', 'in', ['checked_out', 'cancelled']);

      if (resp.isEmpty) {
        developer.log('No GH bookings for $ownerId', name: 'bookings.list');
        return [];
      }
      return (resp as List)
          .map<Booking>((j) => Booking.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Fetch GH bookings error: $e', name: 'bookings.list');
      throw mapSupabaseError(e);
    }
  }

  Failure mapSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      developer.log(
        'PostgrestException: code=${error.code}, message=${error.message}, details=${error.details}',
        name: 'bookings.error',
      );
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
      if (error.message.contains('relationship') ||
          error.message.contains('join')) {
        return UnknownFailure('Relation error: ${error.message}');
      }
      if (error.message.contains('column') ||
          error.message.contains('relation')) {
        return UnknownFailure('Database schema error: ${error.message}');
      }
      return UnknownFailure('Database error: ${error.message}');
    }
    if (error is StorageException) {
      developer.log('StorageException: ${error.message}', name: 'bookings.error');
      if (error.message.toLowerCase().contains('network') ||
          error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure(
            'Network error during file upload: ${error.message}');
      }
      return UnknownFailure('Storage error: ${error.message}');
    }
    developer.log('Unexpected error: $error', name: 'bookings.error');
    return UnknownFailure('An unexpected error occurred: $error');
  }
}

final bookingsRepositoryProvider = Provider<IBookingsRepository>((ref) {
  return SupabaseBookingsRepository();
});
