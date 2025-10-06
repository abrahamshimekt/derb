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
    };
  }
}