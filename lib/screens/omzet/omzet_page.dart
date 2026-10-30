import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';

class OmzetPage extends ConsumerWidget {
  const OmzetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // ==========================================================
    // === SATU SUMBER DATA TRANSAKSI ===
    // ==========================================================

    final history = ref.watch(transactionProvider);

    // ==========================================================
    // TOTAL

    final totalOmzet = history.fold<double>(
      0,
      (sum, transaction) => sum + transaction.subtotal,
    );

    final totalLaba = history.fold<double>(
      0,
      (sum, transaction) => sum + transaction.totalProfit,
    );

    final totalHpp = totalOmzet - totalLaba;

    final totalTransaksi = history.length;

    final avgPerTransaction = totalTransaksi > 0
        ? totalOmzet / totalTransaksi
        : 0.0;

    // ==========================================================
    // Keuntungan per tipe harga

    double profitRetail = 0;
    double profitWholesale = 0;
    double profitSack = 0;

    for (final transaction in history) {
      for (final item in transaction.items) {
        final itemProfit = item.estimatedProfit;

        switch (item.priceType) {
          case .eceran:
            profitRetail += itemProfit;
            break;

          case .grosir:
            profitWholesale += itemProfit;
            break;

          case .sak:
            profitSack += itemProfit;
            break;
        }
      }
    }

    // ==========================================================
    // Data Grafik harian

    final dailyData = _buildDailyData(history);

    final maxDailyValue = dailyData.fold<double>(0, (max, item) {
      final value = item.omzet > item.laba ? item.omzet : item.laba;

      return value > max ? value : max;
    });

    final chartMaxY = maxDailyValue > 0 ? maxDailyValue * 1.2 : 200000;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Omzet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ringkasan penjualan & laba',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  // TOMBOL RESET DATA (Hanya aktif/tampak saat ada riwayat)
                  IconButton(
                    tooltip: 'Reset Data Transaksi',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.dangerRed,
                    ),
                    onPressed: history.isEmpty
                        ? null // Nonaktifkan jika data sudah kosong
                        : () => _showResetConfirmationDialog(context, ref),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ============================================
                  // Gridview metric card
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
                      _buildMetricCard(
                        'Total Omzet',
                        currencyFormatter.format(totalOmzet),
                        AppTheme.primaryDark,
                        Colors.white,
                        Icons.account_balance_wallet_outlined,
                      ),
                      _buildMetricCard(
                        'Total Laba',
                        currencyFormatter.format(totalLaba),
                        Colors.white,
                        AppTheme.textMain,
                        Icons.trending_up,
                      ),
                      _buildMetricCard(
                        'Transaksi',
                        '$totalTransaksi',
                        Colors.white,
                        AppTheme.textMain,
                        Icons.receipt_long_outlined,
                      ),
                      _buildMetricCard(
                        'Rata-rata/Transaksi',
                        currencyFormatter.format(avgPerTransaction),
                        Colors.white,
                        AppTheme.textMain,
                        Icons.pie_chart_outline,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===========================================
                  // Grafik bar harian
                  _buildCardWrapper(
                    title: 'Omzet & Laba per Hari',
                    child: SizedBox(
                      height: 250,
                      child: dailyData.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada transaksi',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            )
                          : ClipRect(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: chartMaxY.toDouble(),
                                  minY: 0,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 60,
                                        getTitlesWidget: (value, meta) {
                                          if (value == 0) {
                                            return const Text(
                                              'Rp 0',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: AppTheme.textMuted,
                                              ),
                                            );
                                          }

                                          return Text(
                                            'Rp ${(value / 1000).round()}k',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: AppTheme.textMuted,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();

                                          if (index < 0 ||
                                              index >= dailyData.length) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              DateFormat(
                                                'dd/MM',
                                              ).format(dailyData[index].date),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  barGroups: List.generate(dailyData.length, (
                                    index,
                                  ) {
                                    final data = dailyData[index];

                                    return BarChartGroupData(
                                      x: index,
                                      barsSpace: 4,
                                      barRods: [
                                        BarChartRodData(
                                          toY: data.omzet < 0 ? 0 : data.omzet,
                                          width: 14,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: AppTheme.primaryDark,
                                        ),
                                        BarChartRodData(
                                          toY: data.laba < 0 ? 0 : data.laba,
                                          width: 14,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: AppTheme.successGreen,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ============================================
                  // Profit per tipe harga
                  _buildCardWrapper(
                    title: 'Laba per Tipe Harga',
                    child: Column(
                      children: [
                        _buildHorizontalBarItem(
                          'Eceran',
                          profitRetail,
                          AppTheme.accentCyan,
                        ),
                        const SizedBox(height: 12),
                        _buildHorizontalBarItem(
                          'Grosir',
                          profitWholesale,
                          AppTheme.successGreen,
                        ),
                        const SizedBox(height: 12),
                        _buildHorizontalBarItem(
                          'Sak',
                          profitSack,
                          const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ============================================
                  // INFO HPP
                  _buildCardWrapper(
                    title: 'Ringkasan HPP',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total HPP',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        Text(
                          currencyFormatter.format(totalHpp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Data Harian

  List<_DailyData> _buildDailyData(List<dynamic> history) {
    final Map<String, _DailyData> grouped = {};

    for (final transaction in history) {
      final date = transaction.timestamp;

      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(key)) {
        grouped[key] = _DailyData(
          date: DateTime(date.year, date.month, date.day),
          omzet: 0,
          laba: 0,
        );
      }

      grouped[key] = _DailyData(
        date: grouped[key]!.date,
        omzet: grouped[key]!.omzet + transaction.subtotal,
        laba: grouped[key]!.laba + transaction.totalProfit,
      );
    }

    final result = grouped.values.toList();

    result.sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  // ============================================================
  // Data card metris

  Widget _buildMetricCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: textColor.withValues()),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Grid card wrapper

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // Bar Chart keuntungan horizontal

  Widget _buildHorizontalBarItem(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value > 0 ? (value / 100000).clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // WARNING RESET DATA Transaksi
  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed),
            SizedBox(width: 8),
            Text('Reset Semua Data?'),
          ],
        ),
        content: const Text(
          'Tindakan ini akan menghapus seluruh riwayat transaksi dan mengembalikan total omzet serta laba ke Rp 0. Data yang dihapus tidak dapat dikembalikan.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
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
              backgroundColor: AppTheme.dangerRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Panggil fungsi reset dari provider
              ref.read(transactionProvider.notifier).resetAllTransactions();
              Navigator.pop(ctx);

              // Tampilkan notifikasi berhasil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat omzet & transaksi berhasil di-reset!'),
                  backgroundColor: AppTheme.dangerRed,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Ya, Reset',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Data Model harian

class _DailyData {
  final DateTime date;
  final double omzet;
  final double laba;

  _DailyData({required this.date, required this.omzet, required this.laba});
}
