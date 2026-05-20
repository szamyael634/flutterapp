enum OrderStatus {
  pendingPayment,
  placed,
  sellerConfirmed,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.storeId,
    required this.totalAmount,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String buyerId;
  final String storeId;
  final double totalAmount;
  final double deliveryFee;
  final String paymentMethod;
  final String paymentStatus;
  final OrderStatus status;
  final DateTime createdAt;

  factory OrderRecord.fromMap(Map<String, dynamic> map) {
    return OrderRecord(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String? ?? 'MK-0000',
      buyerId: map['buyer_id'] as String,
      storeId: map['store_id'] as String,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cod',
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      status: _statusFromValue(map['status'] as String? ?? 'placed'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static OrderStatus _statusFromValue(String value) {
    switch (value) {
      case 'pending_payment':
        return OrderStatus.pendingPayment;
      case 'seller_confirmed':
        return OrderStatus.sellerConfirmed;
      case 'ready_for_pickup':
        return OrderStatus.readyForPickup;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      default:
        return OrderStatus.values.byName(value);
    }
  }
}
