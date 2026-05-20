class SellerVerificationReview {
  const SellerVerificationReview({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.sellerRole,
    required this.documentType,
    required this.filePath,
    required this.claimedFullName,
    required this.claimedCredentialNumber,
    required this.extractedFullName,
    required this.extractedCredentialNumber,
    required this.screeningStatus,
    required this.screeningScore,
    required this.screeningNotes,
    required this.verificationStatus,
    required this.reviewNotes,
    required this.createdAt,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String sellerRole;
  final String documentType;
  final String filePath;
  final String claimedFullName;
  final String claimedCredentialNumber;
  final String extractedFullName;
  final String extractedCredentialNumber;
  final String screeningStatus;
  final double? screeningScore;
  final String screeningNotes;
  final String verificationStatus;
  final String reviewNotes;
  final DateTime createdAt;

  bool get hasMatchSignals =>
      claimedFullName.isNotEmpty &&
      extractedFullName.isNotEmpty &&
      claimedFullName.trim().toLowerCase() ==
          extractedFullName.trim().toLowerCase();

  factory SellerVerificationReview.fromMap(Map<String, dynamic> map) {
    return SellerVerificationReview(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      sellerName: map['seller_name'] as String? ?? 'Unknown seller',
      sellerEmail: map['seller_email'] as String? ?? '',
      sellerRole: map['seller_role'] as String? ?? '',
      documentType: map['document_type'] as String? ?? 'document',
      filePath: map['file_path'] as String? ?? '',
      claimedFullName: map['claimed_full_name'] as String? ?? '',
      claimedCredentialNumber:
          map['claimed_credential_number'] as String? ?? '',
      extractedFullName: map['extracted_full_name'] as String? ?? '',
      extractedCredentialNumber:
          map['extracted_credential_number'] as String? ?? '',
      screeningStatus: map['screening_status'] as String? ?? 'pending',
      screeningScore: (map['screening_score'] as num?)?.toDouble(),
      screeningNotes: map['screening_notes'] as String? ?? '',
      verificationStatus: map['verification_status'] as String? ?? 'pending',
      reviewNotes: map['review_notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
