import 'package:feedgo_app/models/price_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import "../models/transaction_record.dart";
import "cart_provider.dart";
import 'cashier_provider.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class TransactionStorageService {
  static Box<TransactionRecord> get _box =>
      Hive.box<TransactionRecord>('transactions_box');

  static List<TransactionRecord> getTransactions() {
    return _box.values.toList();
  }

  static Future<void> addTransaction(TransactionRecord tx) async {
    await _box.put(tx.id, tx);
  }

  static Future<void> clearAllTransactions() async {
    await _box.clear();
  }
}

class TransactionNotifier extends StateNotifier<List<TransactionRecord>> {
  TransactionNotifier(this.ref)
    : super(TransactionStorageService.getTransactions());

  final Ref ref;

  // Menyelesaikan transaksi
  bool processTransaction() {
    final cartItems = ref.read(cartProvider);
    final subtotal = ref.read(cartSubtotalProvider);
    final profit = ref.read(cartEstimatedProfitProvider);
    final amountPaid = ref.read(amountPaidProvider);
    final change = ref.read(changeAmountProvider);

    if (cartItems.isEmpty || amountPaid < subtotal) {
      return false; // Transaksi gagal jika keranjang kosong;
    }

    // Validasi stok
    final stockError = ref.read(cartStockValidationProvider);
    if (stockError != null) {
      return false;
    }

    final now = DateTime.now();

    // Buat record transaksi baru
    final newRecord = TransactionRecord(
      id: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: now,
      items: List.from(cartItems),
      subtotal: subtotal,
      totalProfit: profit,
      amountPaid: amountPaid,
      change: change,
    );

    // Simpan transaksi ke list
    state = [newRecord, ...state];
    TransactionStorageService.addTransaction(newRecord);

    // Kurangi stok produk
    final products = List.of(ref.read(rawProductsProvider));
    for (var item in cartItems) {
      final index = products.indexWhere((p) => p.id == item.product.id);
      if (index == -1) continue;
      final currentProd = products[index];
      final isProductSak = currentProd.unit.toLowerCase().trim() == 'sak';
      final conversionRatio = currentProd.conversionFactor > 0
          ? currentProd.conversionFactor
          : 50.0;

      // Menyelesaikan pengurangan stok sesuai rasio unit
      double deduction = 0.0;
      if (isProductSak) {
        if (item.priceType == PriceType.sak) {
          deduction = item.quantity;
        } else {
          deduction = item.quantity / conversionRatio;
        }
      } else {
        if (item.priceType == PriceType.sak) {
          deduction = item.quantity * conversionRatio;
        } else {
          deduction = item.quantity;
        }
      }

      final newStock = (currentProd.stock - deduction).clamp(
        0.0,
        double.infinity,
      );
      products[index] = currentProd.copyWith(stock: newStock);
    }
    ref.read(rawProductsProvider.notifier).updateProducts(products);

    // Reset keranjang
    ref.read(cartProvider.notifier).clearCart();
    ref.read(amountPaidProvider.notifier).state = 0.0;

    return true; // Transaksi sukses
  }

  // Menghapus seluruh riwayat transaksi
  void resetAllTransactions() {
    state = [];
    TransactionStorageService.clearAllTransactions();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionRecord>>((ref) {
      return TransactionNotifier(ref);
    });
