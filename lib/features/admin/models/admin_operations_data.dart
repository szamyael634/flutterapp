class AdminOperationsData {
  const AdminOperationsData({required this.orders, required this.products});

  final List<AdminMonitoredOrder> orders;
  final List<AdminMonitoredProduct> products;

  factory AdminOperationsData.fromMap(Map<String, dynamic> map) {
    final orderRows = (map['orders'] as List<dynamic>? ?? [])
        .map(
          (item) => AdminMonitoredOrder.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final productRows = (map['products'] as List<dynamic>? ?? [])
        .map(
          (item) => AdminMonitoredProduct.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return AdminOperationsData(orders: orderRows, products: productRows);
  }
}

class AdminMonitoredOrder {
  const AdminMonitoredOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    required this.storeName,
    required this.buyerEmail,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final DateTime createdAt;
  final String storeName;
  final String buyerEmail;

  factory AdminMonitoredOrder.fromMap(Map<String, dynamic> map) {
    return AdminMonitoredOrder(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String? ?? 'MK-000000',
      status: map['status'] as String? ?? 'placed',
      paymentMethod: map['payment_method'] as String? ?? 'cod',
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      storeName: map['store_name'] as String? ?? 'Unknown store',
      buyerEmail: map['buyer_email'] as String? ?? '',
    );
  }
}

class AdminMonitoredProduct {
  const AdminMonitoredProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.listingStatus,
    required this.recommendationStatus,
    required this.currentPrice,
    required this.quantity,
    required this.discountPercent,
    required this.expirationAt,
    required this.storeName,
  });

  final String id;
  final String name;
  final String category;
  final String listingStatus;
  final String recommendationStatus;
  final double currentPrice;
  final int quantity;
  final int discountPercent;
  final DateTime expirationAt;
  final String storeName;

  bool get isNearExpiry =>
      listingStatus == 'near_expiry' || listingStatus == 'flash_sale';

  factory AdminMonitoredProduct.fromMap(Map<String, dynamic> map) {
    return AdminMonitoredProduct(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled product',
      category: map['category'] as String? ?? 'Uncategorized',
      listingStatus: map['listing_status'] as String? ?? 'draft',
      recommendationStatus: map['recommendation_status'] as String? ?? 'none',
      currentPrice: (map['current_price'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int? ?? 0,
      discountPercent: map['discount_percent'] as int? ?? 0,
      expirationAt:
          DateTime.tryParse(map['expiration_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      storeName: map['store_name'] as String? ?? 'Unknown store',
    );
  }
}
