class Room {
  final String id;
  final String guestHouseId;
  final List<String>? roomPictures;
  final String roomNumber;
  final double price;
  final double rating;
  final String status;
  final List<String>? facilities;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.guestHouseId,
    this.roomPictures,
    required this.roomNumber,
    required this.price,
    required this.rating,
    required this.status,
    this.facilities,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      guestHouseId: json['guest_house_id'],
      roomPictures: json['room_pictures'] != null
          ? List<String>.from(json['room_pictures'])
          : null,

      roomNumber: json['room_number'] as String,
      price: (json['price'] as num).toDouble(),
      rating:(json['rating'] as num).toDouble(),
      status: json['status'],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Room copyWith({
    String? id,
    String? guestHouseId,
    List<String>? roomPictures,
    String? roomNumber,
    double? price,
    double? rating,
    String? status,
    List<String>? facilities,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      guestHouseId: guestHouseId ?? this.guestHouseId,
      roomPictures: roomPictures ?? this.roomPictures,
      roomNumber: roomNumber ?? this.roomNumber,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      facilities: facilities ?? this.facilities,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
