class AdminDashboardData {
  const AdminDashboardData({required this.metrics, required this.recentOrders});

  final AdminDashboardMetrics metrics;
  final List<AdminRecentOrder> recentOrders;

  factory AdminDashboardData.fromMap(Map<String, dynamic> map) {
    final recentOrders = (map['recent_orders'] as List<dynamic>? ?? [])
        .map((row) => AdminRecentOrder.fromMap(Map<String, dynamic>.from(row)))
        .toList();

    return AdminDashboardData(
      metrics: AdminDashboardMetrics.fromMap(
        Map<String, dynamic>.from(map['metrics'] as Map? ?? const {}),
      ),
      recentOrders: recentOrders,
    );
  }
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalUsers,
    required this.activeSellers,
    required this.completedDeliveries,
    required this.totalStores,
    required this.totalSales,
    required this.pendingApprovals,
    required this.reducedCommissionOrders,
    required this.estimatedFoodSaved,
    required this.reducedCommissionValue,
    required this.pendingVerifications,
  });

  final int totalUsers;
  final int activeSellers;
  final int completedDeliveries;
  final int totalStores;
  final double totalSales;
  final int pendingApprovals;
  final int reducedCommissionOrders;
  final int estimatedFoodSaved;
  final double reducedCommissionValue;
  final int pendingVerifications;

  factory AdminDashboardMetrics.fromMap(Map<String, dynamic> map) {
    return AdminDashboardMetrics(
      totalUsers: map['total_users'] as int? ?? 0,
      activeSellers: map['active_sellers'] as int? ?? 0,
      completedDeliveries: map['completed_deliveries'] as int? ?? 0,
      totalStores: map['total_stores'] as int? ?? 0,
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0,
      pendingApprovals: map['pending_approvals'] as int? ?? 0,
      reducedCommissionOrders: map['reduced_commission_orders'] as int? ?? 0,
      estimatedFoodSaved: map['estimated_food_saved'] as int? ?? 0,
      reducedCommissionValue:
          (map['reduced_commission_value'] as num?)?.toDouble() ?? 0,
      pendingVerifications: map['pending_verifications'] as int? ?? 0,
    );
  }
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;

  factory AdminRecentOrder.fromMap(Map<String, dynamic> map) {
    return AdminRecentOrder(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String? ?? 'MK-000000',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cod',
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      status: map['status'] as String? ?? 'placed',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
