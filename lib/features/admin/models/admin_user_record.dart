class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.approvalStatus,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String approvalStatus;
  final DateTime createdAt;

  bool get needsApproval =>
      (role == 'seller' || role == 'rider') && approvalStatus == 'pending';

  factory AdminUserRecord.fromMap(Map<String, dynamic> map) {
    return AdminUserRecord(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Mama\'s Kitchen User',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'buyer',
      approvalStatus: map['approval_status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
