import 'price_type.dart';
import 'product.dart';
import 'package:hive_ce/hive_ce.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 2)
class CartItem extends HiveObject {
  @HiveField(0)
  final Product product;
  @HiveField(1)
  final double quantity;
  @HiveField(2)
  final PriceType priceType;

  /// Harga dasar per satuan.
  @HiveField(3)
  final double unitPrice;

  /// Nominal custom yang ditentukan kasir untuk seluruh item.
  /// unitPrice * quantity
  @HiveField(4)
  final double? customNominal;

  CartItem({
    required this.product,
    required this.quantity,
    required this.priceType,
    required this.unitPrice,
    this.customNominal,
  });

  /// Total harga item.
  double get subtotal => customNominal ?? (quantity * unitPrice);

  // HPP tetap dihitung berdasarkan jumlah barang yang benar-benar keluar.
  double get estimatedProfit {
    double totalHpp = 0.0;
    final isProductSak = product.unit.toLowerCase().trim() == 'sak';
    final conversionRatio = product.conversionFactor > 0
        ? product.conversionFactor
        : 50.0;

    if (isProductSak) {
      if (priceType == PriceType.sak) {
        totalHpp = product.hpp * quantity;
      } else {
        totalHpp = (product.hpp / conversionRatio) * quantity;
      }
    } else {
      if (priceType == PriceType.sak) {
        totalHpp = (product.hpp * conversionRatio) * quantity;
      } else {
        totalHpp = product.hpp * quantity;
      }
    }
    return subtotal - totalHpp;
  }

  // Mendapatkan label satuan kontekstual (Kg / Sak)
  String get activeUnitLabel {
    if (priceType == PriceType.sak) {
      return 'Sak';
    } else {
      return 'Kg';
    }
  }

  CartItem copyWith({
    Product? product,
    double? quantity,
    PriceType? priceType,
    double? unitPrice,
    double? customNominal,
    bool clearCustomNominal = false,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceType: priceType ?? this.priceType,
      unitPrice: unitPrice ?? this.unitPrice,
      customNominal: clearCustomNominal
          ? null
          : customNominal ?? this.customNominal,
    );
  }
}
