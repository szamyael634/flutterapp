class AdminDisputeRecord {
  const AdminDisputeRecord({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.reporterId,
    required this.reporterEmail,
    required this.status,
    required this.category,
    required this.title,
    required this.description,
    required this.resolutionNotes,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String reporterId;
  final String reporterEmail;
  final String status;
  final String category;
  final String title;
  final String description;
  final String? resolutionNotes;
  final DateTime createdAt;

  factory AdminDisputeRecord.fromMap(Map<String, dynamic> map) {
    return AdminDisputeRecord(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      orderNumber: map['order_number'] as String? ?? 'MK-000000',
      reporterId: map['reporter_id'] as String,
      reporterEmail: map['reporter_email'] as String? ?? '',
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
