import 'price_type.dart';
import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final PriceType priceType;
  final double unitPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.priceType,
    required this.unitPrice,
  });
}

class Transaction {
  final String id;
  final List<CartItem> items;
  final double totalPrice;
  final double totalHpp;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.totalHpp,
    required this.createdAt,
  });
}
