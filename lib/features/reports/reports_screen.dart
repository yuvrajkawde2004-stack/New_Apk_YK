import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../dashboard/dashboard_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'Monthly';
  final _periods = ['Daily', 'Weekly', 'Monthly', 'All Time'];

  Future<Map<String, dynamic>> _fetchReportData() async {
    final db = DatabaseHelper.instance;
    final todaySales = await db.getTodaySales();
    final monthlySales = await db.getMonthlySales();
    final totalBills = await db.getTotalBills();
    final weeklySalesData = await db.getWeeklySalesData();
    final customers = await db.getCustomers(limit: 1000);
    final suppliers = await db.getSuppliers();
    final purchases = await db.getAllPurchases();

    final customerDues = customers.fold<double>(0.0, (sum, c) => sum + ((c['outstanding_balance'] as num?)?.toDouble() ?? 0.0));
    final supplierDues = suppliers.fold<double>(0.0, (sum, s) => sum + ((s['outstanding_due'] as num?)?.toDouble() ?? 0.0));
    final totalPurchasesCost = purchases.fold<double>(0.0, (sum, p) => sum + ((p['total_amount'] as num?)?.toDouble() ?? 0.0));

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final monthStr = DateTime.now().toIso8601String().substring(0, 7);
    final weekAgoStr = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);

    double selectedSales = monthlySales;
    double selectedPurchasesCost = 0.0;
    
    if (_period == 'Daily') {
      selectedSales = todaySales;
      selectedPurchasesCost = purchases.where((p) => (p['purchase_date'] ?? '').startsWith(todayStr))
          .fold<double>(0.0, (sum, p) => sum + ((p['total_amount'] as num?)?.toDouble() ?? 0.0));
    } else if (_period == 'Monthly') {
      selectedSales = monthlySales;
      selectedPurchasesCost = purchases.where((p) => (p['purchase_date'] ?? '').startsWith(monthStr))
          .fold<double>(0.0, (sum, p) => sum + ((p['total_amount'] as num?)?.toDouble() ?? 0.0));
    } else if (_period == 'Weekly') {
      selectedSales = weeklySalesData.fold<double>(0.0, (sum, item) => sum + ((item['sales'] as num?)?.toDouble() ?? 0.0));
      selectedPurchasesCost = purchases.where((p) {
        final dStr = (p['purchase_date'] as String?) ?? '';
        return dStr.isNotEmpty && dStr.substring(0, 10).compareTo(weekAgoStr) >= 0;
      }).fold<double>(0.0, (sum, p) => sum + ((p['total_amount'] as num?)?.toDouble() ?? 0.0));
    } else if (_period == 'All Time') {
      final allBills = await db.getBills(limit: 10000);
      selectedSales = allBills.fold<double>(0.0, (sum, b) => sum + ((b['grand_total'] as num?)?.toDouble() ?? 0.0));
      selectedPurchasesCost = totalPurchasesCost;
    }

    final double estProfit = await db.getProfitForPeriod(_period);

    return {
      'sales': selectedSales,
      'todaySales': todaySales,
      'monthlySales': monthlySales,
      'totalBills': totalBills,
      'customerDues': customerDues,
      'supplierDues': supplierDues,
      'totalPurchasesCost': selectedPurchasesCost,
      'weeklySalesData': weeklySalesData,
      'estProfit': estProfit,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Sales & Business Intelligence',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: AppColors.royalBlue,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _periods.map((p) {
                    final sel = _period == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _period = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: sel
                                ? const LinearGradient(colors: [AppColors.royalBlue, Color(0xFF2563EB)])
                                : null,
                            color: sel ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: sel
                                ? [BoxShadow(color: AppColors.royalBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                                : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Text(
                            p,
                            style: GoogleFonts.outfit(
                              color: sel ? Colors.white : AppColors.textSecondaryLight,
                              fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              FutureBuilder<Map<String, dynamic>>(
                future: _fetchReportData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.royalBlue)));
                  }

                  final data = snapshot.data ?? {};
                  final sales = (data['sales'] as num?)?.toDouble() ?? 0.0;
                  final totalBills = data['totalBills'] ?? 0;
                  final customerDues = (data['customerDues'] as num?)?.toDouble() ?? 0.0;
                  final supplierDues = (data['supplierDues'] as num?)?.toDouble() ?? 0.0;
                  final purchasesCost = (data['totalPurchasesCost'] as num?)?.toDouble() ?? 0.0;
                  final estProfit = (data['estProfit'] as num?)?.toDouble() ?? 0.0;
                  final weeklyData = (data['weeklySalesData'] as List<Map<String, dynamic>>?) ?? [];

                  // Find max sales for weekly chart scaling
                  final maxWeeklySales = weeklyData.fold<double>(1.0, (maxVal, item) {
                    final s = (item['sales'] as num?)?.toDouble() ?? 0.0;
                    return s > maxVal ? s : maxVal;
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 1. HERO SALES CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Revenue ($_period)', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                  ),
                                  child: Text('LIVE DATA', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AnimatedRollingCurrency(
                              value: sales,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.receipt_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                                const SizedBox(width: 6),
                                AnimatedRollingNumber(
                                  value: totalBills,
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                                ),
                                Text(' Total Invoices Created', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: -0.05).fadeIn(),

                      const SizedBox(height: 18),

                      // 📊 2. FINANCIAL METRICS GRID
                      Row(
                        children: [
                          Expanded(
                            child: _miniMetricCard('Customer Dues', customerDues, 'Customer Dues', Icons.people_outline_rounded, Colors.red.shade600, const Color(0xFFFEF2F2)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _miniMetricCard('Supplier Dues', supplierDues, 'Supplier Dues', Icons.local_shipping_outlined, Colors.orange.shade700, const Color(0xFFFFF7ED)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _miniMetricCard('Stock Purchases', purchasesCost, 'Total Purchases', Icons.shopping_bag_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showProductProfitBreakdownSheet(context),
                              child: _miniMetricCard('Net Gross Profit', estProfit > 0 ? estProfit : 0.0, 'Net Gross Profit', Icons.trending_up_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 📈 3. WEEKLY SALES GRAPH CHART
                      Text('7-DAY REVENUE PERFORMANCE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 0.8)),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Weekly Revenue Trend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Last 7 Days', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 150,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: weeklyData.map((item) {
                                  final daySales = (item['sales'] as num?)?.toDouble() ?? 0.0;
                                  final pct = (daySales / maxWeeklySales).clamp(0.08, 1.0);
                                  final dayName = item['day'] ?? '';

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(daySales > 0 ? '₹${(daySales / 1000).toStringAsFixed(1)}k' : '₹0', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                      const SizedBox(height: 6),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 600),
                                        width: 24,
                                        height: 100 * pct,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: daySales > 0 ? [AppColors.royalBlue, const Color(0xFF3B82F6)] : [Colors.grey.shade300, Colors.grey.shade200],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(dayName, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAverageProfitModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, double>>(
        future: DatabaseHelper.instance.getAverageProfitStats(),
        builder: (ctx, snapshot) {
          final stats = snapshot.data ?? {};
          final totalProfit = stats['total_profit'] ?? 0.0;
          final avgItemProfit = stats['avg_profit_per_item'] ?? 0.0;
          final avgBillProfit = stats['avg_profit_per_bill'] ?? 0.0;
          final fmt = NumberFormat('#,##,##0.00');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Average Profit Analysis', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Average profit calculated across all sales to date:', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF86EFAC))),
                  child: Column(
                    children: [
                      Text('Avg Profit / Item', style: GoogleFonts.outfit(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('₹${fmt.format(avgItemProfit)}', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Text('Total Profit', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text('₹${fmt.format(totalProfit)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Text('Avg Profit / Bill', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text('₹${fmt.format(avgBillProfit)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductProfitBreakdownSheet(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Product Net Profit Ledger', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text('Cumulative profit earned across all transactions per product:', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),

            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getProductProfitBreakdown(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.royalBlue));
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No product sales recorded yet', style: GoogleFonts.outfit(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final item = list[i];
                      final name = item['product_name'] ?? 'Product';
                      final qtySold = (item['total_qty_sold'] as num?)?.toInt() ?? 0;
                      final profit = (item['total_product_profit'] as num?)?.toDouble() ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('$qtySold Units Sold', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${fmt.format(profit)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: profit >= 0 ? const Color(0xFF059669) : Colors.red)),
                                Text('Profit', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetricCard(String title, double val, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(sub, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedRollingCurrency(
            value: val,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
