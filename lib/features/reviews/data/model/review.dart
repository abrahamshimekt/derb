
class Review {
  final String id;
  final String roomId;
  final String userId;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final String? userName;

  Review({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      comment: json['comment'],
      rating: (json['rating'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
    );
  }
}

