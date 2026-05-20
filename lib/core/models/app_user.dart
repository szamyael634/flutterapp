enum AppRole { buyer, seller, rider, admin }

enum ApprovalStatus { pending, approved, rejected, suspended }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.approvalStatus,
    required this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final ApprovalStatus approvalStatus;
  final String? phone;

  bool get canSell =>
      role == AppRole.seller && approvalStatus == ApprovalStatus.approved;

  bool get canDeliver =>
      role == AppRole.rider && approvalStatus == ApprovalStatus.approved;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Mama\'s Kitchen User',
      role: AppRole.values.byName((map['role'] as String? ?? 'buyer')),
      approvalStatus: ApprovalStatus.values.byName(
        (map['approval_status'] as String? ?? 'pending'),
      ),
      phone: map['phone'] as String?,
    );
  }
}
