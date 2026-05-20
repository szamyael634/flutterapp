import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../orders/data/orders_repository.dart';
import '../data/cart_repository.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'cod';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: AsyncValueView(
        value: cart,
        data: (items) {
          final subtotal = items.fold<double>(
            0,
            (sum, item) => sum + item.totalPrice,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.product.name),
                    subtitle: Text(AppFormatters.currency(item.totalPrice)),
                    leading: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        await ref.read(cartRepositoryProvider).updateQuantity(
                              cartItemId: item.id,
                              quantity: item.quantity - 1,
                            );
                        ref.invalidate(cartProvider);
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        await ref.read(cartRepositoryProvider).updateQuantity(
                              cartItemId: item.id,
                              quantity: item.quantity + 1,
                            );
                        ref.invalidate(cartProvider);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: const [
                  DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery')),
                  DropdownMenuItem(value: 'paymongo', child: Text('PayMongo')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Subtotal: ${AppFormatters.currency(subtotal)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final errorColor = Theme.of(context).colorScheme.error;
                        final userId = ref.read(currentUserIdProvider);
                        if (userId == null) {
                          return;
                        }
                        try {
                          final result = await ref
                              .read(ordersRepositoryProvider)
                              .checkout(
                                buyerId: userId,
                                cartItems: items,
                                paymentMethod: _paymentMethod,
                                deliveryAddress: _addressController.text.trim(),
                              );
                          ref.invalidate(cartProvider);
                          ref.invalidate(ordersProvider);
                          if (!mounted) {
                            return;
                          }
                          scaffoldMessenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                            result.checkoutUrl == null
                                ? 'Order ${result.orderId} created'
                                : 'Order ${result.orderId} created. Continue payment in your browser.',
                                ),
                              ),
                            );
                        } catch (error) {
                          if (!mounted) {
                            return;
                          }
                          scaffoldMessenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(error.toString()),
                                backgroundColor: errorColor,
                              ),
                            );
                        }
                      },
                child: const Text('Checkout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
