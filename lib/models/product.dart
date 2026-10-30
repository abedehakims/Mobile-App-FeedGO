import 'price_type.dart';
import 'package:hive_ce/hive_ce.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category; // Ayam, ikan, sapi, kucing

  @HiveField(3)
  final String unit; // Sak, Sak30 (30Kg), Sak25 (25Kg), Sak(10Kg), Pcs, Kardus (isi 20 pcs)

  @HiveField(4)
  final double hpp; // Harga Pokok Penjualan

  @HiveField(5)
  final double retailPrice; // Harga Eceran

  @HiveField(6)
  final double wholesalePrice; // Harga Grosir

  @HiveField(7)
  final double sackPrice; // Harga par sak

  @HiveField(8)
  final double stock; // jumlah stok

  @HiveField(9)
  final double conversionFactor; // Konversi unit (misal 1 sak = 50kg, atau 1 kardus = 20pcs)

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.hpp,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.sackPrice,
    required this.stock,
    this.conversionFactor = 50.0, // Defaultnya adala 50.0
  });

  // Mendapatkan HPP Konversi
  double getHPPForType(PriceType type) {
    if (type == PriceType.sak) {
      return hpp;
    }
    // Jika eceran / grosir, HPP dibagi ke faktor konversi
    return conversionFactor > 0 ? (hpp / conversionFactor) : hpp;
  }

  // Mendapatkan Harga jual berdasarkan tipe harga
  double getPriceForType(PriceType type) {
    switch (type) {
      case PriceType.eceran:
        return retailPrice;
      case PriceType.grosir:
        return wholesalePrice;
      case PriceType.sak:
        return sackPrice;
    }
  }

  // Menghitung margin keuntungan per tipe harga
  double getMargin(PriceType type) {
    return getPriceForType(type) - getHPPForType(type);
  }

  // protokol CopyWith untuk pembaruan state untuk stok
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? hpp,
    double? retailPrice,
    double? wholesalePrice,
    double? sackPrice,
    double? stock,
    double? conversionFactor,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      hpp: hpp ?? this.hpp,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      sackPrice: sackPrice ?? this.sackPrice,
      stock: stock ?? this.stock,
      conversionFactor: conversionFactor ?? this.conversionFactor,
    );
  }
}
