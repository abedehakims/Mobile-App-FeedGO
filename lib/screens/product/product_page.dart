import 'package:feedgo_app/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../providers/cashier_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/add_product_dialog.dart';

String formatProductStock(double stock, String unit) {
  final lowerUnit = unit.toLowerCase().trim();

  // Deteksi apakah ini termasuk variasi Sak atau Kardus
  bool isSakOrKardus =
      lowerUnit.contains('sak') ||
      lowerUnit.contains('kardus') ||
      lowerUnit.contains('pcs');

  // Selalu tampilkan 2 digit desimal untuk unit Sak & Kardus agar terlihat presisi,
  // atau gunakan desimal jika tidak bulat
  final stockStr = stock.toStringAsFixed(2);

  // Jika bukan satuan khusus (misal Kg murni), boleh gunakan format dinamis (bulat jika .00)
  final dynamicStockStr = stock % 1 == 0
      ? stock.toInt().toString()
      : stock.toStringAsFixed(2);

  if (isSakOrKardus) {
    // Memastikan format selalu mencetak desimal 2 angka (misal: 1.00 Sak (25Kg) atau 2.00 Kardus (isi 20 Pcs))
    return '$stockStr $unit';
  }

  return '$dynamicStockStr $unit';
}

// Provider search state for product page
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Filter products
final filteredRawProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(rawProductsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return products;

  return products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query);
  }).toList();
});

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  void _confirmDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    String productId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Produk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$productName" dari daftar produk?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final products = List.of(ref.read(rawProductsProvider));
                products.removeWhere((p) => p.id == productId);
                ref.read(rawProductsProvider.notifier).updateProducts(products);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$productName" berhasil dihapus'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Fungsi untuk menangani aksi tambah/kurang stok dari UI
  void _handleStockAdjustment(
    BuildContext context,
    WidgetRef ref,
    Product product,
    double defaultDelta,
  ) {
    final isSak = product.unit.toLowerCase().trim() == 'sak';

    if (isSak) {
      // Jika satuan Sak, buka Dialog Input Nominal & Step Desimal
      _showStockAdjustmentDialog(context, ref, product);
    } else {
      // Jika satuan biasa (misal Kg), langsung sesuaikan dengan delta default (1.0 / -1.0)
      _adjustStockDirectly(ref, product, defaultDelta);
    }
  }

  void _adjustStockDirectly(WidgetRef ref, Product product, double delta) {
    final products = List.of(ref.read(rawProductsProvider));
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final currentStock = products[index].stock;
      final newStock = (currentStock + delta).clamp(0.0, double.infinity);
      products[index] = products[index].copyWith(stock: newStock);
      ref.read(rawProductsProvider.notifier).updateProducts(products);
    }
  }

  /// DIALOG PENYESUAIAN STOK KHUSUS SAK (Bisa Input Langsung + Preset 1.0, 0.1, 0.01)
  void _showStockAdjustmentDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final controller = TextEditingController(
      text: product.stock % 1 == 0
          ? product.stock.toInt().toString()
          : product.stock.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ubah Stok (${product.name})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan jumlah stok baru atau gunakan preset:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),

              // TextField untuk ketik angka manual
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Jumlah Stok (${product.unit})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: product.unit,
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Quick Adjuster:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // Tombol-tombol Preset Tambah/Kurang (+1.0, +0.1, +0.01, dst)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickStepChip(controller, 1.0, isAdd: true),
                  _buildQuickStepChip(controller, 0.1, isAdd: true),
                  _buildQuickStepChip(controller, 0.01, isAdd: true),
                  _buildQuickStepChip(controller, 1.0, isAdd: false),
                  _buildQuickStepChip(controller, 0.1, isAdd: false),
                  _buildQuickStepChip(controller, 0.01, isAdd: false),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final inputVal =
                    double.tryParse(controller.text.replaceAll(',', '.')) ??
                    product.stock;
                final products = List.of(ref.read(rawProductsProvider));
                final index = products.indexWhere((p) => p.id == product.id);

                if (index != -1) {
                  products[index] = products[index].copyWith(
                    stock: inputVal.clamp(0.0, double.infinity),
                  );
                  ref
                      .read(rawProductsProvider.notifier)
                      .updateProducts(products);
                }

                Navigator.pop(ctx);
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper Chip untuk Tombol Cepat (+ / -) di dalam Dialog
  Widget _buildQuickStepChip(
    TextEditingController controller,
    double step, {
    required bool isAdd,
  }) {
    final label = '${isAdd ? '+' : '-'}${step == 1.0 ? '1' : step.toString()}';
    final color = isAdd ? AppTheme.successGreen : AppTheme.dangerRed;

    return ActionChip(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () {
        final currentVal =
            double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
        final newVal = isAdd ? (currentVal + step) : (currentVal - step);
        final clampedVal = newVal.clamp(0.0, double.infinity);

        controller.text = clampedVal % 1 == 0
            ? clampedVal.toInt().toString()
            : clampedVal.toStringAsFixed(2);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredRawProductsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Produk',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tekan lama pada produk untuk menghapus',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddProductDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Tambah Produk',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primarySky,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search Bar di Product Page
                TextField(
                  onChanged: (val) {
                    ref.read(productSearchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    filled: true,
                    fillColor: AppTheme.bgCanvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Produk (Support Long Press Hapus & Responsive Tablet Layout)
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteProduct(
                          context,
                          ref,
                          product.id,
                          product.name,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Badge Kategori Terpisah Rapi dari Nama Produk
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primarySky,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            product.category.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryLight,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textMain,
                                          ),
                                        ),
                                        Text(
                                          'Satuan: ${product.unit}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tombol tambah & kurangi stok produk
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Stok: ${formatProductStock(product.stock, product.unit)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _handleStockAdjustment(
                                                    context,
                                                    ref,
                                                    product,
                                                    -1.0,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.dangerRed
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.remove_circle_outlined,
                                                  size: 14,
                                                  color: AppTheme.dangerRed,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () =>
                                                  _handleStockAdjustment(
                                                    context,
                                                    ref,
                                                    product,
                                                    1.0,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.add_circle_outlined,
                                                  size: 14,
                                                  color: AppTheme.primarySky,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPriceInfo(
                                      'HPP',
                                      currencyFormatter.format(product.hpp),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildPriceInfo(
                                      'Eceran',
                                      currencyFormatter.format(
                                        product.retailPrice,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildPriceInfo(
                                      'Grosir',
                                      currencyFormatter.format(
                                        product.wholesalePrice,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildPriceInfo(
                                      'Sak',
                                      currencyFormatter.format(
                                        product.sackPrice,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
