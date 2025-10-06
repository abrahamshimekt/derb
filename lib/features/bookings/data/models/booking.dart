// bookings_repository.dart (Booking model only — keep the rest of the file as you have it)

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

  // Related fields (from join: rooms -> guest_houses)
  final String? roomNumber;
  final List<String>? roomPictures;
  final String? guestHouseName;
  final String? city;
  final String? subCity;

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
    this.roomNumber,
    this.roomPictures,
    this.guestHouseName,
    this.city,
    this.subCity,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse nested relations if present
    final rooms = json['rooms'] as Map<String, dynamic>?;
    final gh = rooms?['guest_houses'] as Map<String, dynamic>?;

    // room_pictures may come as List or comma-separated String — normalize to List<String>
    List<String>? pics;
    final rawPics = rooms?['room_pictures'];
    if (rawPics is List) {
      pics = rawPics.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      if (pics.isEmpty) pics = null;
    } else if (rawPics is String) {
      pics = rawPics
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (pics.isEmpty) pics = null;
    }

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

      // related
      roomNumber: rooms?['room_number']?.toString(),
      roomPictures: pics,
      guestHouseName: gh?["guest_house_name"]?.toString(),
      city: gh?['city']?.toString(),
      subCity: gh?['sub_city']?.toString(),
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

      // expose related fields if needed for UI (optional)
      'rooms': {
        if (roomNumber != null) 'room_number': roomNumber,
        if (roomPictures != null) 'room_pictures': roomPictures,
        'guest_houses': {
          if(guestHouseName !=null) "guest_house_name":guestHouseName,
          if (city != null) 'city': city,
          if (subCity != null) 'sub_city': subCity,

        },
      },
    };
  }

  String? get primaryImage =>
      (roomPictures != null && roomPictures!.isNotEmpty) ? roomPictures!.first : null;
}
