import 'package:feedgo_app/screens/product/product_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/price_type.dart';
import '../../../models/product.dart';
import '../../../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final PriceType selectedPriceType;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.selectedPriceType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final displayPrice = product.getPriceForType(selectedPriceType);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row atas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? AppTheme.primaryLight
                              : AppTheme.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Stok ${formatProductStock(product.stock, product.unit)}',
                          style: TextStyle(
                            fontSize: 8.6,
                            fontWeight: FontWeight.w600,
                            color: product.stock > 0
                                ? AppTheme.primarySky
                                : AppTheme.dangerRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),

            // Row tengah
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.add_circle_outline, color: AppTheme.primarySky),
            ),

            // Row bawah
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormatter.format(displayPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedPriceType == PriceType.sak ? 'Per Sak' : 'Per Kg',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
