import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/supabase.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.paymentMethod,
    this.checkoutUrl,
  });

  final String orderId;
  final String paymentMethod;
  final String? checkoutUrl;

  factory CheckoutResult.fromMap(Map<String, dynamic> map) {
    return CheckoutResult(
      orderId: map['order_id'] as String,
      paymentMethod: map['payment_method'] as String,
      checkoutUrl: map['checkout_url'] as String?,
    );
  }
}

class OrdersRepository {
  const OrdersRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<OrderRecord>> fetchOrders(AppUser user) async {
    dynamic query = _supabase.from('orders').select();

    switch (user.role) {
      case AppRole.buyer:
        query = query.eq('buyer_id', user.id);
        break;
      case AppRole.seller:
        final store = await _supabase
            .from('stores')
            .select('id')
            .eq('owner_id', user.id)
            .maybeSingle();
        if (store == null) {
          return [];
        }
        query = query.eq('store_id', store['id']);
        break;
      case AppRole.rider:
        final deliveryRows = await _supabase
            .from('deliveries')
            .select('order_id')
            .eq('rider_id', user.id);
        final orderIds =
            deliveryRows.map((row) => row['order_id'] as String).toList();
        if (orderIds.isEmpty) {
          return [];
        }
        query = query.inFilter('id', orderIds);
        break;
      case AppRole.admin:
        break;
    }

    final rows = await query.order('created_at', ascending: false);
    return rows
        .map<OrderRecord>(
          (row) => OrderRecord.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<CheckoutResult> checkout({
    required String buyerId,
    required List<CartItem> cartItems,
    required String paymentMethod,
    required String deliveryAddress,
    String? notes,
  }) async {
    final payload = {
      'buyer_id': buyerId,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'items': cartItems
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };

    final response = await _supabase.functions.invoke(
      'create-checkout-session',
      body: payload,
    );

    return CheckoutResult.fromMap(Map<String, dynamic>.from(response.data));
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) {
    return _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});

final ordersProvider = FutureProvider<List<OrderRecord>>((ref) async {
  final user = await ref.watch(currentUserProfileProvider.future);
  return ref.watch(ordersRepositoryProvider).fetchOrders(user);
});
