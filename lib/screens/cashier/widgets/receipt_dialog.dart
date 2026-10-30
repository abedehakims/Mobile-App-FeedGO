import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/cart_item.dart';
import '../../../theme/app_theme.dart';

class ReceiptDialog extends StatelessWidget {
  final List<CartItem> items;
  final double subtotal;
  final double paidAmount;
  final double balance;

  const ReceiptDialog({
    super.key,
    required this.items,
    required this.subtotal,
    required this.paidAmount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Struk
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.successGreen,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'FeedGO!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const Text(
              'Struk Pembayaran Toko Pakan',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            Text(
              dateFormatted,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Colors.black26),

            // Daftar Item Belanja
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    final itemTotal =
                        item.customNominal ?? (item.unitPrice * item.quantity);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(itemTotal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(thickness: 1, color: Colors.black26),

            // Total, Dibayar & Kembalian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tunai', style: TextStyle(fontSize: 12)),
                Text(
                  currencyFormatter.format(paidAmount),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembali', style: TextStyle(fontSize: 12)),
                Text(
                  currencyFormatter.format(balance),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primarySky,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tutup Struk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
