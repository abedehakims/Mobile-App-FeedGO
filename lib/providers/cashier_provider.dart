import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/price_type.dart';
import '../models/product.dart';

// State untuk tipe harga yang sedang dipilih
final selectedPriceTypeProvider = StateProvider<PriceType>(
  (ref) => PriceType.eceran,
);

// State untuk kata kunci pencarian produk
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk simpan daftar produk dari Hive
class ProductStorageService {
  static Box<Product> get _box => Hive.box<Product>('products_box');

  // Ambil semua produk, jika kosong kembalikan dummy awal
  static List<Product> getProducts() {
    if (_box.isEmpty) {
      // Data Default awal untuk Toko Pakan jika database masih baru kosong
      final initialProducts = [
        Product(
          id: '1',
          name: 'DUMMY Pakan Ayam BR-1',
          category: 'Ayam',
          unit: 'Kg',
          hpp: 8500,
          retailPrice: 10000,
          wholesalePrice: 9500,
          sackPrice: 450000,
          stock: 50,
        ),
        Product(
          id: '2',
          name: 'DUMMY Konsentrat Sapi Super',
          category: 'Sapi',
          unit: 'Kg',
          hpp: 12000,
          retailPrice: 15000,
          wholesalePrice: 14000,
          sackPrice: 650000,
          stock: 30,
        ),
      ];

      for (var p in initialProducts) {
        _box.put(p.id, p);
      }
      return initialProducts;
    }

    return _box.values.toList();
  }

  static Future<void> saveProducts(List<Product> products) async {
    await _box.clear();
    for (var p in products) {
      await _box.put(p.id, p);
    }
  }
}

// Notifier untuk state produk
class RawProductsNotifier extends StateNotifier<List<Product>> {
  RawProductsNotifier() : super(ProductStorageService.getProducts());

  // tambah method state supaya bisa memperbarui seluruh list produk
  void updateProducts(List<Product> products) {
    state = products;
    ProductStorageService.saveProducts(products); // Sekaligus simpan ke Hive
  }

  // Menyimpan perubahan
  void addProduct(Product product) {
    state = [...state, product];
    ProductStorageService.saveProducts(state);
  }

  void updateProduct(String id, double newStock) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(stock: newStock) else p,
    ];
    ProductStorageService.saveProducts(state);
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
    ProductStorageService.saveProducts(state);
  }
}

// State untuk produk
final rawProductsProvider =
    StateNotifierProvider<RawProductsNotifier, List<Product>>((ref) {
      return RawProductsNotifier();
    });

// Provider produk yang sudah difilter berdasarkan pencarian
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(rawProductsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return products;

  return products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query);
  }).toList();
});
