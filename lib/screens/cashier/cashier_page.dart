import 'package:feedgo_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/price_type.dart';
import '../../providers/cart_provider.dart';
import '../../providers/cashier_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/product_card.dart';

class CashierPage extends ConsumerStatefulWidget {
  const CashierPage({super.key});

  @override
  ConsumerState<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends ConsumerState<CashierPage> {
  // Map untuk menyimpan GlobalKey unik per produk agar tidak terebuild ulang
  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _getOrCreateKey(String id) {
    if (!_cardKeys.containsKey(id)) {
      _cardKeys[id] = GlobalKey();
    }
    return _cardKeys[id]!;
  }

  // Fungsi membuat animasi produk melayang ke ikon keranjang di AppBar
  void _runAddToCartAnimation(GlobalKey widgetKey) {
    final RenderObject? widgetRenderObject = widgetKey.currentContext
        ?.findRenderObject();
    final RenderObject? cartRenderObject = cartIconKey.currentContext
        ?.findRenderObject();

    if (widgetRenderObject == null || cartRenderObject == null) return;

    final RenderBox widgetRenderBox = widgetRenderObject as RenderBox;
    final RenderBox cartRenderBox = cartRenderObject as RenderBox;

    final startOffset = widgetRenderBox.localToGlobal(Offset.zero);
    final endOffset = cartRenderBox.localToGlobal(Offset.zero);

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 550),
    );

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final progress = curvedAnimation.value;
            // Kurva parabola
            final currentX =
                startOffset.dx + (endOffset.dx - startOffset.dx) * progress;
            final currentY =
                startOffset.dy +
                (endOffset.dy - startOffset.dy) * progress -
                (120 * (1 - (2 * progress - 1) * (2 * progress - 1)));

            final scale = 1.0 - (0.6 * progress);
            final opacity = 1.0 - (0.3 * progress);

            return Positioned(
              left: currentX,
              top: currentY,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
    animationController.forward().then((_) {
      overlayEntry.remove();
      animationController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    final selectedPriceType = ref.watch(selectedPriceTypeProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kasir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pilih produk dan jenis harga',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),

                // Search bar
                TextField(
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
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
                const SizedBox(height: 12),

                // Selector Tipe harga
                Row(
                  children: PriceType.values.map((type) {
                    final isSelected = selectedPriceType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedPriceTypeProvider.notifier).state =
                              type;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: isSelected
                                ? AppTheme.accentCyan
                                : const Color.fromARGB(255, 201, 201, 201),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primarySky
                                  : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Grid Daftar Produk
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 4
                          : 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final cardKey = _getOrCreateKey(product.id.toString());
                      return ProductCard(
                        key: cardKey,
                        product: product,
                        selectedPriceType: selectedPriceType,
                        onTap: () {
                          // Tambah ke keranjang
                          ref
                              .read(cartProvider.notifier)
                              .addProduct(product, selectedPriceType);

                          // Jalankan animasi ikon keranjang
                          _runAddToCartAnimation(cardKey);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
