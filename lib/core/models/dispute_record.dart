class DisputeRecord {
  const DisputeRecord({
    required this.id,
    required this.orderId,
    required this.reporterId,
    required this.status,
    required this.category,
    required this.title,
    required this.description,
    required this.resolutionNotes,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String reporterId;
  final String status;
  final String category;
  final String title;
  final String description;
  final String? resolutionNotes;
  final DateTime createdAt;

  factory DisputeRecord.fromMap(Map<String, dynamic> map) {
    return DisputeRecord(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      reporterId: map['reporter_id'] as String,
      status: map['status'] as String? ?? 'open',
      category: map['category'] as String? ?? 'general',
      title: map['title'] as String? ?? 'Untitled dispute',
      description: map['description'] as String? ?? '',
      resolutionNotes: map['resolution_notes'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
