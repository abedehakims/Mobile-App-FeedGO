import 'package:feedgo_app/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_theme.dart';
import 'receipt_dialog.dart';

class CartBottomSheet extends ConsumerStatefulWidget {
  const CartBottomSheet({super.key});

  @override
  ConsumerState<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends ConsumerState<CartBottomSheet> {
  final TextEditingController _paidController = TextEditingController();

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  String _formatQuantity(double quantity) {
    if (quantity % 1 == 0) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final profit = ref.watch(cartEstimatedProfitProvider);
    final stockErrorMsg = ref.watch(cartStockValidationProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              spreadRadius: 2,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator Drag Line
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // UI keranjang kosong
              if (cartItems.isEmpty) ...[
                const SizedBox(height: 24),
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keranjang Kosong!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih produk di menu kasir untuk ditambahkan',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali ke Kasir'),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Header Keranjang
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_basket_outlined,
                      color: AppTheme.primarySky,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keranjang (${cartItems.length} item)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textMain,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        _paidController.clear();
                      },
                      child: const Text(
                        'Kosongkan',
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(),

              // Daftar Item Keranjang
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.30,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cartItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final unitPrice = item.unitPrice;

                    final currentNominal =
                        item.customNominal ?? (item.unitPrice * item.quantity);

                    return SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${currencyFormatter.format(unitPrice)}/${item.activeUnitLabel} • ${item.priceType.label}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity counter Plus - Minus
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            index,
                                            item.quantity - 1,
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    color: AppTheme.primarySky,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      _formatQuantity(item.quantity),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            index,
                                            item.quantity + 1,
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                    ),
                                    color: AppTheme.primarySky,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Custom nominal harga per item oleh kasir
                          Row(
                            children: [
                              const Text(
                                'Nominal: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    currencyFormatter.format(currentNominal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '- Kurang Rp500',
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                ),
                                color: AppTheme.primarySky,
                                onPressed: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .decreaseCustomNominal(
                                        index,
                                        amount: 500,
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: '+ Tambah Rp500',
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 22,
                                ),
                                color: AppTheme.primarySky,
                                onPressed: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .increaseCustomNominal(
                                        index,
                                        amount: 500,
                                      );
                                },
                              ),

                              // Input nominal manual
                              SizedBox(
                                width: 100,
                                height: 32,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgCanvas,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currencyFormatter.format(item.subtotal),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Informasi hasil konversi
                          Text(
                            '${currencyFormatter.format(item.unitPrice)} × ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} ${item.activeUnitLabel} = Rp ${currencyFormatter.format(item.subtotal)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),

              // Ringkasan Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  Text(
                    currencyFormatter.format(subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Input Uang Dibayar
              _PaymentSection(
                controller: _paidController,
                subtotal: subtotal,
                stockErrorMsg: stockErrorMsg,
                cartItems: cartItems,
                profit: profit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sub-Widget untuk _PaymentSection supaya tidak merender ulang
class _PaymentSection extends ConsumerWidget {
  final TextEditingController controller;
  final double subtotal;
  final String? stockErrorMsg;
  final List<CartItem> cartItems;
  final double profit;

  const _PaymentSection({
    required this.controller,
    required this.subtotal,
    required this.stockErrorMsg,
    required this.cartItems,
    required this.profit,
  });

  double _parseNominal(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ??
        0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Uang yang Dibayar',
            prefixText: 'Rp ',
            filled: true,
            fillColor: AppTheme.bgCanvas,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            final paid = _parseNominal(val);
            // Tetap update provider, tapi sekarang aman karena tidak memicu rebuild TextField ini
            ref.read(amountPaidProvider.notifier).state = paid;
          },
        ),
        const SizedBox(height: 4),

        // Indicator uang kembalian (Sudah terisolasi, aman!)
        _KembalianText(subtotal: subtotal),

        if (stockErrorMsg != null) ...[
          const SizedBox(height: 2),
          Text(
            stockErrorMsg!,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.dangerRed,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Tombol Bayar disembunyikan di dalam Consumer terpisah agar tidak ikutan rebuild
        SizedBox(
          width: double.infinity,
          child: Consumer(
            builder: (context, buttonRef, child) {
              return ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();

                  // 🔥 Ambil paidAmount tepat saat tombol ditekan menggunakan buttonRef.read
                  final paidAmount = buttonRef.read(amountPaidProvider);
                  final balance = paidAmount - subtotal;

                  final currentCartItems = List<CartItem>.from(cartItems);
                  final currentSubtotal = subtotal;
                  final currentPaid = paidAmount;
                  final currentBalance = balance;

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  try {
                    final success = buttonRef
                        .read(transactionProvider.notifier)
                        .processTransaction();
                    if (success) {
                      controller.clear();
                      // Reset state pembayaran setelah sukses transaksi
                      buttonRef.read(amountPaidProvider.notifier).state = 0.0;

                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Transaksi berhasil dicatat!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => ReceiptDialog(
                          items: currentCartItems,
                          subtotal: currentSubtotal,
                          paidAmount: currentPaid,
                          balance: currentBalance,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Transaksi gagal!. Pastikan uang pembayaran dan stok mencukupi.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.dangerRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                  } catch (e, st) {
                    debugPrint('❗ processTransaction error ❗: $e\n$st');
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Bayar & Cetak Struk'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget Terpisah Khusus Teks Kembalian (Tetap seperti kode Anda, ini sudah bagus dan terisolasi)
class _KembalianText extends ConsumerWidget {
  final double subtotal;
  const _KembalianText({required this.subtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidAmount = ref.watch(amountPaidProvider);
    if (paidAmount <= 0) return const SizedBox.shrink();
    final balance = paidAmount - subtotal;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Text(
      balance >= 0
          ? 'Kembalian: ${currencyFormatter.format(balance)}'
          : 'Kurang: ${currencyFormatter.format(balance.abs())}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: balance >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
      ),
    );
  }
}
