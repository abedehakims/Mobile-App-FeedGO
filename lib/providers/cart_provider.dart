import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/cart_item.dart';
import '../models/price_type.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // ============================================================
  // Tambah produk untuk item

  void addProduct(Product product, PriceType priceType) {
    final existingIndex = state.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.priceType == priceType &&
          item.customNominal == null,
    );

    final unitPrice = _getUnitPrice(product, priceType);

    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];

      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1.0,
      );

      final updatedList = List<CartItem>.from(state);
      updatedList[existingIndex] = updatedItem;

      state = updatedList;
      return;
    }

    state = [
      ...state,
      CartItem(
        product: product,
        priceType: priceType,
        quantity: 1.0,
        unitPrice: unitPrice,
      ),
    ];
  }

  // ============================================================
  // Ambil harga produk berdasarkan tipe harga

  double _getUnitPrice(Product product, PriceType priceType) {
    switch (priceType) {
      case PriceType.eceran:
        return product.retailPrice;

      case PriceType.grosir:
        return product.wholesalePrice;

      case PriceType.sak:
        return product.sackPrice;
    }
  }

  // ============================================================
  // Update quantity produk ketika di add

  void updateQuantity(int index, double newQuantity) {
    if (index < 0 || index >= state.length) return;

    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final updatedList = List<CartItem>.from(state);

    updatedList[index] = updatedList[index].copyWith(
      quantity: newQuantity,
      clearCustomNominal: true,
    );

    state = updatedList;
  }

  // ============================================================
  // Update custom nominal saat checkout

  void updateCustomNominal(int index, double nominal) {
    if (index < 0 || index >= state.length) return;
    if (nominal <= 0) return;

    final item = state[index];

    if (item.unitPrice <= 0) return;
    final newQuantity = nominal / item.unitPrice;

    final updatedList = List<CartItem>.from(state);

    updatedList[index] = item.copyWith(
      quantity: newQuantity,
      customNominal: nominal,
    );

    state = updatedList;
  }

  // ============================================================
  // Tambah custom nominal dengan taraf +Rp500

  void increaseCustomNominal(int index, {double amount = 500}) {
    if (index < 0 || index >= state.length) return;

    final item = state[index];

    final currentNominal =
        item.customNominal ?? (item.unitPrice * item.quantity);

    updateCustomNominal(index, currentNominal + amount);
  }

  // ============================================================
  // Kurang custom nominal dengan taraf -Rp500
  void decreaseCustomNominal(int index, {double amount = 500}) {
    if (index < 0 || index >= state.length) return;

    final item = state[index];

    final currentNominal =
        item.customNominal ?? (item.unitPrice * item.quantity);

    final newNominal = currentNominal - amount;

    // Jika nominal baru lebih kecil atau sama dengan 0, atur ke 0 atau kembalikan nominal default
    if (newNominal <= 0) return;

    updateCustomNominal(index, newNominal);
  }

  // ============================================================
  // Reset custom nominal harga

  void resetCustomNominal(int index) {
    if (index < 0 || index >= state.length) return;

    final item = state[index];

    final updatedList = List<CartItem>.from(state);

    updatedList[index] = item.copyWith(clearCustomNominal: true);

    state = updatedList;
  }

  // ============================================================
  // Hapus item dari cart produk

  void removeItem(int index) {
    if (index < 0 || index >= state.length) return;

    final updatedList = List<CartItem>.from(state)..removeAt(index);

    state = updatedList;
  }

  // ============================================================
  // Hapus produk

  void clearCart() {
    state = [];
  }
}

// ============================================================
// Cart provider

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// ============================================================
// Subtotal

final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);

  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

// ============================================================
// Estimasi keuntungan

final cartEstimatedProfitProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);

  return cart.fold(0.0, (sum, item) => sum + item.estimatedProfit);
});

// ============================================================
// Nominal yang dibayar

final amountPaidProvider = StateProvider<double>((ref) => 0.0);

// ============================================================
// Kembalian

final changeAmountProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final paid = ref.watch(amountPaidProvider);

  return paid >= subtotal ? paid - subtotal : 0.0;
});

// ============================================================
// Validasi stok

final cartStockValidationProvider = Provider<String?>((ref) {
  final cart = ref.watch(cartProvider);

  for (final item in cart) {
    final product = item.product;
    final isProductSak = product.unit.toLowerCase().trim() == 'sak';
    final conversionRatio = product.conversionFactor > 0
        ? product.conversionFactor
        : 50.0;

    double requiredBaseStock = 0.0;

    if (isProductSak) {
      // Satuan Utama Produk: SAK
      if (item.priceType == PriceType.sak) {
        requiredBaseStock = item.quantity; // Sak ke Sak
      } else {
        requiredBaseStock = item.quantity / conversionRatio; // Kg ke Sak
      }
    } else {
      // Satuan Utama Produk: KG
      if (item.priceType == PriceType.sak) {
        requiredBaseStock = item.quantity * conversionRatio; // Sak ke Kg
      } else {
        requiredBaseStock = item.quantity; // Kg ke Kg
      }
    }

    if (requiredBaseStock > product.stock) {
      final stockStr = product.stock % 1 == 0
          ? product.stock.toInt().toString()
          : product.stock.toStringAsFixed(2);

      return 'Stok "${product.name}" tidak cukup! (Sisa $stockStr ${product.unit})';
    }
  }

  return null;
});
