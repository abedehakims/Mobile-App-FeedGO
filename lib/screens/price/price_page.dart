import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/cashier_provider.dart';
import '../../theme/app_theme.dart';

// Provider pencarian khusus untuk Price Page
final priceSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPriceProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(rawProductsProvider);
  final query = ref.watch(priceSearchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return products;

  return products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query);
  }).toList();
});

class PricePage extends ConsumerWidget {
  const PricePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(rawProductsProvider);
    final filteredProducts = ref.watch(filteredPriceProductsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Kalkulasi Rata-rata HPP, Eceran, Grosir, Sak
    double avgHpp = 0;
    double avgRetail = 0;
    double avgWholesale = 0;
    double avgSack = 0;

    if (products.isNotEmpty) {
      avgHpp =
          products.map((p) => p.hpp).reduce((a, b) => a + b) / products.length;
      avgRetail =
          products.map((p) => p.retailPrice).reduce((a, b) => a + b) /
          products.length;
      avgWholesale =
          products.map((p) => p.wholesalePrice).reduce((a, b) => a + b) /
          products.length;
      avgSack =
          products.map((p) => p.sackPrice).reduce((a, b) => a + b) /
          products.length;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HPP & Harga Jual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Atur harga modal dan harga jual eceran, grosir, & sak',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  // Kolom pencarian
                  TextField(
                    onChanged: (val) {
                      ref.read(priceSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari produk untuk ubah harga...',
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: AppTheme.bgCanvas,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // GRID BUBBLE RATA-RATA HARGA (2x2 Card)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 4
                        : 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildSummaryCard(
                        'Rata-rata HPP',
                        currencyFormatter.format(avgHpp),
                        Colors.white,
                        AppTheme.textMain,
                      ),
                      _buildSummaryCard(
                        'Rata-rata Eceran',
                        currencyFormatter.format(avgRetail),
                        AppTheme.primaryDark,
                        Colors.white,
                      ),
                      _buildSummaryCard(
                        'Rata-rata Grosir',
                        currencyFormatter.format(avgWholesale),
                        AppTheme.primaryDark,
                        Colors.white,
                      ),
                      _buildSummaryCard(
                        'Rata-rata Sak',
                        currencyFormatter.format(avgSack),
                        AppTheme.primaryDark,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. DAFTAR EDIT PRODUK & MARGIN
                  filteredProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductPriceEditCard(
                              product: product,
                              onSave: (updatedProduct) {
                                final allProducts = List<Product>.from(
                                  products,
                                );
                                final originalIndex = allProducts.indexWhere(
                                  (p) => p.id == updatedProduct.id,
                                );
                                if (originalIndex != -1) {
                                  allProducts[index] = updatedProduct;
                                  ref
                                      .read(rawProductsProvider.notifier)
                                      .updateProducts(allProducts);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Harga "${updatedProduct.name}" berhasil disimpan!',
                                      ),
                                      backgroundColor: AppTheme.successGreen,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: textColor == Colors.white
                  ? Colors.white70
                  : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful Widget untuk Form Edit Setiap Produk
class ProductPriceEditCard extends StatefulWidget {
  final Product product;
  final Function(Product) onSave;

  const ProductPriceEditCard({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductPriceEditCard> createState() => _ProductPriceEditCardState();
}

class _ProductPriceEditCardState extends State<ProductPriceEditCard> {
  late TextEditingController _hppController;
  late TextEditingController _retailController;
  late TextEditingController _wholesaleController;
  late TextEditingController _sackController;

  @override
  void initState() {
    super.initState();
    _hppController = TextEditingController(
      text: widget.product.hpp.toInt().toString(),
    );
    _retailController = TextEditingController(
      text: widget.product.retailPrice.toInt().toString(),
    );
    _wholesaleController = TextEditingController(
      text: widget.product.wholesalePrice.toInt().toString(),
    );
    _sackController = TextEditingController(
      text: widget.product.sackPrice.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _hppController.dispose();
    _retailController.dispose();
    _wholesaleController.dispose();
    _sackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final double hpp = double.tryParse(_hppController.text) ?? 0;
    final double retail = double.tryParse(_retailController.text) ?? 0;
    final double wholesale = double.tryParse(_wholesaleController.text) ?? 0;
    final double sack = double.tryParse(_sackController.text) ?? 0;

    // Kalkulasi Margin per Sak Equivalent
    final double marginRetail =
        (retail * widget.product.conversionFactor) - hpp;
    final double marginWholesale =
        (wholesale * widget.product.conversionFactor) - hpp;
    final double marginSack = sack - hpp;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Stock Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${widget.product.category} • stok ${widget.product.stock.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  final updated = widget.product.copyWith(
                    hpp: hpp,
                    retailPrice: retail,
                    wholesalePrice: wholesale,
                    sackPrice: sack,
                  );
                  widget.onSave(updated);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primarySky,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input Row 1: HPP & Eceran
          Row(
            children: [
              Expanded(child: _buildInputField('HPP', _hppController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Eceran', _retailController)),
            ],
          ),
          const SizedBox(height: 12),

          // Input Row 2: Grosir & Sak
          Row(
            children: [
              Expanded(child: _buildInputField('Grosir', _wholesaleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Sak', _sackController)),
            ],
          ),
          const SizedBox(height: 16),

          // Live Margin Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMarginText(
                'Margin Eceran',
                marginRetail,
                currencyFormatter,
              ),
              _buildMarginText(
                'Margin Grosir',
                marginWholesale,
                currencyFormatter,
              ),
              _buildMarginText('Margin Sak', marginSack, currencyFormatter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}), // Trigger recalculate margin
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgCanvas,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarginText(String label, double margin, NumberFormat formatter) {
    final bool isPositive = margin >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          formatter.format(margin),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
          ),
        ),
      ],
    );
  }
}
