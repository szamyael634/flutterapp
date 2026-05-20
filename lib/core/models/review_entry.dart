class ReviewEntry {
  const ReviewEntry({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.targetType,
    required this.targetId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String authorId;
  final String targetType;
  final String targetId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory ReviewEntry.fromMap(Map<String, dynamic> map) {
    return ReviewEntry(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      authorId: map['author_id'] as String,
      targetType: map['target_type'] as String? ?? 'product',
      targetId: map['target_id'] as String,
      rating: map['rating'] as int? ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
