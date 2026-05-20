class ProductRecommendation {
  const ProductRecommendation({
    required this.id,
    required this.productId,
    required this.status,
    required this.suggestedDiscountPercent,
    required this.message,
    required this.applyReducedCommission,
  });

  final String id;
  final String productId;
  final String status;
  final int suggestedDiscountPercent;
  final String message;
  final bool applyReducedCommission;

  factory ProductRecommendation.fromMap(Map<String, dynamic> map) {
    return ProductRecommendation(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      status: map['status'] as String? ?? 'none',
      suggestedDiscountPercent: map['suggested_discount_percent'] as int? ?? 0,
      message: map['message'] as String? ?? '',
      applyReducedCommission:
          map['apply_reduced_commission'] as bool? ?? false,
    );
  }
}
