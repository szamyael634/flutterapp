import 'product.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  final String id;
  final Product product;
  final int quantity;

  double get totalPrice => product.currentPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      product: Product.fromMap(
        Map<String, dynamic>.from(map['products'] as Map),
      ),
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}
