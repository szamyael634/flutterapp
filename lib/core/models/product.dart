enum ListingStatus {
  draft,
  active,
  nearExpiry,
  flashSale,
  expired,
  disabled,
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.category,
    required this.originalPrice,
    required this.currentPrice,
    required this.quantity,
    required this.preparedAt,
    required this.expirationAt,
    required this.discountPercent,
    required this.listingStatus,
    required this.imageUrls,
    required this.allergens,
  });

  final String id;
  final String storeId;
  final String name;
  final String description;
  final String category;
  final double originalPrice;
  final double currentPrice;
  final int quantity;
  final DateTime preparedAt;
  final DateTime expirationAt;
  final int discountPercent;
  final ListingStatus listingStatus;
  final List<String> imageUrls;
  final List<String> allergens;

  Duration get timeLeft => expirationAt.difference(DateTime.now());

  bool get isDiscounted => discountPercent > 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final images = (map['product_images'] as List<dynamic>? ?? [])
        .map((entry) => entry is Map<String, dynamic>
            ? (entry['image_url'] as String? ?? '')
            : '')
        .where((url) => url.isNotEmpty)
        .toList();

    final allergens = (map['allergens'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return Product(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      name: map['name'] as String? ?? 'Untitled Product',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Meals',
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0,
      currentPrice: (map['current_price'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int? ?? 0,
      preparedAt: DateTime.parse(map['prepared_at'] as String),
      expirationAt: DateTime.parse(map['expiration_at'] as String),
      discountPercent: map['discount_percent'] as int? ?? 0,
      listingStatus: _statusFromValue(map['listing_status'] as String?),
      imageUrls: images,
      allergens: allergens,
    );
  }

  static ListingStatus _statusFromValue(String? value) {
    switch (value) {
      case 'near_expiry':
        return ListingStatus.nearExpiry;
      case 'flash_sale':
        return ListingStatus.flashSale;
      default:
        return ListingStatus.values.byName(value ?? 'draft');
    }
  }
}
