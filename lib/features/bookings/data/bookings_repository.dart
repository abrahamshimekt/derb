import 'dart:io';
import 'package:derb/core/failures.dart';
import 'package:derb/core/supabase_client.dart';
import 'package:derb/features/rooms/data/models/room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class Booking {
  final String id;
  final String bedroomId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final bool hasPaid;
  final String? idUrl;
  final String? paymentReceiptUrl;
  final String? transactionId;

  Booking({
    required this.id,
    required this.bedroomId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.hasPaid,
    this.idUrl,
    this.paymentReceiptUrl,
    this.transactionId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      bedroomId: json['bedroom_id'] as String,
      tenantId: json['tenant_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      hasPaid: json['has_paid'] as bool,
      idUrl: json['id_url'] as String?,
      paymentReceiptUrl: json['payment_reciept_url'] as String?,
      transactionId: json['transaction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedroom_id': bedroomId,
      'tenant_id': tenantId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'has_paid': hasPaid,
      'id_url': idUrl,
      'payment_reciept_url': paymentReceiptUrl,
      'transaction_id': transactionId,
      'bedrooms': {
        'room_number': (this as dynamic).roomNumber ?? 'Unknown',
        'room_pictures': (this as dynamic).roomPictures ?? '',
        'guest_houses': {
          'city': (this as dynamic).city ?? 'Unknown',
          'sub_city': (this as dynamic).subCity ?? 'Unknown',
        },
      },
    };
  }
}

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
  });
  Future<List<Booking>> fetchUserBookings(String tenantId);
  Future<List<Booking>> fetchGuestHouseBookings(String ownerId);
}

class SupabaseBookingsRepository implements IBookingsRepository {
  final _client = AppSupabase.client;

  @override
  Future<List<Room>> fetchAvailableBedrooms(String guestHouseId) async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('guest_house_id', guestHouseId)
          .eq('is_available', true);
      return (response as List<dynamic>)
          .map((json) => Room.fromJson(json))
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
  }) async {
    try {
      // Check if bedroom is available
      await _client
          .from('rooms')
          .select()
          .eq('id', bedroomId)
          .eq('is_available', true)
          .single();

      // Check for overlapping bookings
      final overlappingBookings = await _client
          .from('bookings')
          .select()
          .eq('bedroom_id', bedroomId)
          .lte('start_date', endDate.toIso8601String())
          .gte('end_date', startDate.toIso8601String())
          .neq('status', 'check_in');
      if ((overlappingBookings as List<dynamic>).isNotEmpty) {
        throw UnknownFailure('Bedroom is already booked for the selected dates');
      }

      // Upload images
      final List<String> imageUrls = [];
      for (var image in [idImage, receiptImage]) {
        final file = File(image.path);
        final fileName =
            '${bedroomId}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = 'booking_images/$fileName';
        await _client.storage.from('booking_images').upload(path, file);
        final url = _client.storage.from('booking_images').getPublicUrl(path);
        imageUrls.add(url);
      }

      // Create booking
      final response = await _client.from('bookings').insert({
        'bedroom_id': bedroomId,
        'tenant_id': tenantId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'total_price': totalPrice,
        'status': 'pending',
        'has_paid': false,
        'id_url': imageUrls[0],
        'payment_reciept_url': imageUrls[1],
        'transaction_id': transactionId,
      }).select('*, rooms!inner(room_number, room_pictures, guest_houses!inner(city, sub_city))').single();

      // Update bedroom availability
      await _client
          .from('rooms')
          .update({'is_available': false})
          .eq('id', bedroomId);

      return Booking.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Booking>> fetchUserBookings(String tenantId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, bedrooms!inner(room_number, room_pictures, guest_houses!inner(city, sub_city))')
          .eq('tenant_id', tenantId);
      if (response.isEmpty) {
        developer.log('No bookings found for tenantId: $tenantId');
        return [];
      }
      return (response as List<dynamic>)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error fetching user bookings: $e');
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Booking>> fetchGuestHouseBookings(String ownerId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, bedrooms!inner(room_number, room_pictures, guest_houses!inner(city, sub_city, owner_id))')
          .eq('bedrooms.guest_houses.owner_id', ownerId)
          .neq('status', 'checked_out');
      if (response.isEmpty) {
        developer.log('No active bookings found for ownerId: $ownerId');
        return [];
      }
      return (response as List<dynamic>)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error fetching guest house bookings: $e');
      throw mapSupabaseError(e);
    }
  }

  Failure mapSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      developer.log('PostgrestException: code=${error.code}, message=${error.message}, details=${error.details}');
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
      if (error.message.contains('column') || error.message.contains('relation')) {
        return UnknownFailure('Database schema error: ${error.message}');
      }
      return UnknownFailure('Database error: ${error.message}');
    }
    if (error is StorageException) {
      developer.log('StorageException: message=${error.message}');
      if (error.message.toLowerCase().contains('network') ||
          error.message.toLowerCase().contains('timeout')) {
        return NetworkFailure('Network error during file upload: ${error.message}');
      }
      return UnknownFailure('Storage error: ${error.message}');
    }
    developer.log('Unexpected error: $error');
    return UnknownFailure('An unexpected error occurred: $error');
  }
}

final bookingsRepositoryProvider = Provider<IBookingsRepository>((ref) {
  return SupabaseBookingsRepository();
});