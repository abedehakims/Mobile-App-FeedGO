import 'cart_item.dart';
import 'package:hive_ce/hive_ce.dart';

part 'transaction_record.g.dart';

@HiveType(typeId: 1)
class TransactionRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final List<CartItem> items;

  @HiveField(3)
  final double subtotal;

  @HiveField(4)
  final double totalProfit;

  @HiveField(5)
  final double amountPaid;

  @HiveField(6)
  final double change;

  TransactionRecord({
    required this.id,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.totalProfit,
    required this.amountPaid,
    required this.change,
  });
}
