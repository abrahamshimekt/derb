import 'dart:developer' as developer;

class GuestHouse {
  final String id;
  final String ownerId;
  final double latitude;
  final double longitude;
  final String relativeLocationDescription;
  final int numberOfRooms;
  final String city;
  final String region;
  final String subCity;
  final String? pictureUrl;
  final double? rating;
  final String guestHouseName;
  final String description;

  GuestHouse({
    required this.id,
    required this.ownerId,
    required this.latitude,
    required this.longitude,
    required this.relativeLocationDescription,
    required this.numberOfRooms,
    required this.city,
    required this.region,
    required this.subCity,
    this.pictureUrl,
    this.rating,
    required this.guestHouseName,
    required this.description,
  });

  factory GuestHouse.fromJson(Map<String, dynamic> json) {
    final guestHouse = GuestHouse(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      relativeLocationDescription: json['relative_location_description'] as String,
      numberOfRooms: json['number_of_rooms'] as int,
      city: json['city'] as String,
      region: json['region'] as String,
      subCity: json['sub_city'] as String,
      pictureUrl: json['picture_url'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      guestHouseName: json['guest_house_name'] as String,
      description: json['description'] as String,
    );
    developer.log('Parsed GuestHouse: ${guestHouse.guestHouseName}, pictureUrl: ${guestHouse.pictureUrl}, rating: ${guestHouse.rating}');
    return guestHouse;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'latitude': latitude,
      'longitude': longitude,
      'relative_location_description': relativeLocationDescription,
      'number_of_rooms': numberOfRooms,
      'city': city,
      'region': region,
      'sub_city': subCity,
      'picture_url': pictureUrl,
      'rating': rating,
      'guest_house_name': guestHouseName,
      'description': description,
    };
  }
}