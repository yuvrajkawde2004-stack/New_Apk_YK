import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import 'providers/dashboard_provider.dart';
import '../billing/billing_screen.dart';
import '../customers/customer_list_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/database/database_helper.dart';
import '../billing/templates/invoice_template_classic_gst.dart';
import '../billing/templates/invoice_template_premium_gold.dart';
import '../billing/templates/invoice_template_modern_emerald.dart';
import '../billing/templates/invoice_template_royal_violet.dart';
import '../billing/templates/invoice_template_minimal_slate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _HomeTab(
        onAddCustomer: () => _showAddCustomerSheet(context),
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

// ─────────────────────────── HOME TAB ───────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onAddCustomer;

  const _HomeTab({
    required this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 1. TOP HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondaryLight,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.royalBlue,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    provider.shopName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryLight, size: 20),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                      const SizedBox(height: 20),

                      // 👑 2. ULTRA-PREMIUM HERO REVENUE BANNER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E1B4B).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.auto_graph_rounded, color: Color(0xFFF59E0B), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Today\'s Sales',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, color: Color(0xFF10B981), size: 8)
                                          .animate().shimmer(duration: 1000.ms, color: Colors.white24)
                                          .scaleXY(end: 1.0, duration: 300.ms)
                                          .fade(begin: 0.4, end: 1.0),
                                      const SizedBox(width: 5),
                                      Text(
                                        'LIVE',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF10B981),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AnimatedRollingCurrency(
                              value: provider.todaySales,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 16),
                            // Quick Stats Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _heroStatItem(
                                  icon: Icons.receipt_long_rounded,
                                  label: 'Total Bills',
                                  valueWidget: AnimatedRollingNumber(
                                    value: provider.totalBills,
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _heroStatItem(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: 'Pending Dues',
                                  valueWidget: AnimatedRollingCurrency(
                                    value: (provider.pendingPayments as num).toDouble(),
                                    style: GoogleFonts.outfit(color: const Color(0xFFF87171), fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _heroStatItem(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'Low Stock',
                                  valueWidget: AnimatedRollingNumber(
                                    value: provider.lowStockItems,
                                    style: GoogleFonts.outfit(color: const Color(0xFFFBBF24), fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 26),

                      // 🚀 3. QUICK ACTIONS GRID TITLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '1-Click',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalBlue,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 14),

                      // ⚡ HERO ACTION CARDS (2x3 Grid - All App Controllers)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: [
                          _buildActionCard(
                            context: context,
                            title: 'New Bill',
                            subtitle: 'Instant Billing',
                            icon: Icons.flash_on_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            badge: 'FAST',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BillingScreen()),
                              );
                            },
                          ),
                          _buildActionCard(
                            context: context,
                            title: 'Stock',
                            subtitle: '${provider.totalProducts} Items Available',
                            icon: Icons.inventory_2_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const InventoryScreen()),
                              );
                            },
                          ),
                          _buildActionCard(
                            context: context,
                            title: 'Customer',
                            subtitle: '${provider.totalCustomers} Customer List',
                            icon: Icons.people_alt_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerListScreen(isEmbedded: false)),
                              );
                            },
                          ),
                          _buildActionCard(
                            context: context,
                            title: 'Sales Reports',
                            subtitle: 'Revenue & Analytics',
                            icon: Icons.bar_chart_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReportsScreen()),
                              );
                            },
                          ),
                          _buildActionCard(
                            context: context,
                            title: 'App Settings',
                            subtitle: 'Shop & Preferences',
                            icon: Icons.settings_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF475569), Color(0xFF334155)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                          _buildActionCard(
                            context: context,
                            title: 'Add Customer',
                            subtitle: 'Create Profile',
                            icon: Icons.person_add_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: onAddCustomer,
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),

                      const SizedBox(height: 28),

                      // 🧾 RECENT BILLS SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Sales',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReportsScreen()),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'View All',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.royalBlue),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 14),
                      _buildRecentBills(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  Widget _heroStatItem({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scaleXY(begin: 1.0, end: 1.15, duration: 500.ms, curve: Curves.easeInOut)
                     .shimmer(duration: 1000.ms, color: Colors.white, blendMode: BlendMode.srcOver),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBills(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final bills = provider.recentBills;

    if (bills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textSecondaryLight),
            const SizedBox(height: 8),
            Text(
              'No sales recorded yet',
              style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: bills.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        final name = d['customer_name']?.toString() ?? 'Walk-in Customer';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
        final billNumber = d['bill_number']?.toString() ?? '';
        final amount = d['grand_total']?.toString() ?? '0';
        final date = d['bill_date']?.toString() ?? '';
        String formattedDate = date;
        try {
          final dt = DateTime.parse(date);
          formattedDate = DateFormat('d MMM, hh:mm a').format(dt);
        } catch (_) {}

        final dueAmount = (d['due_amount'] as num?)?.toDouble() ?? 0.0;
        final isPending = dueAmount > 0;
        final statusColor = isPending ? const Color(0xFFEF4444) : const Color(0xFF10B981);

        return GestureDetector(
          onTap: () => _showBillDetailsModal(context, d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$billNumber • $formattedDate',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹ $amount',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().slideY(delay: (200 + i * 70).ms, begin: 0.2, end: 0).fadeIn();
      }).toList(),
    );
  }

  void _confirmDeleteBill(BuildContext context, Map<String, dynamic> billData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Invoice #${billData['bill_number']}?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this invoice? Deleting will deduct the amount from Today\'s Sales and restore stock items.',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final bId = billData['id'] as int?;
              if (bId != null) {
                await DatabaseHelper.instance.deleteBill(bId);
                Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close bill details sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice #${billData['bill_number']} deleted. Today\'s Sales & Stock updated!'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBillDetailsModal(BuildContext context, Map<String, dynamic> billData) {
    final screenshotController = ScreenshotController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getBillItems(billData['id']),
          builder: (context, itemsSnapshot) {
            if (!itemsSnapshot.hasData) {
              return Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
              );
            }
            final itemsData = itemsSnapshot.data!;

            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, prefSnapshot) {
                if (!prefSnapshot.hasData) {
                  return Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
                  );
                }

                final tmpl = prefSnapshot.data!.getString('invoice_template') ?? 'Premium Gold';
                Widget invoiceWidget;
                if (tmpl == 'Classic GST') {
                  invoiceWidget = InvoiceTemplateClassicGst(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Modern Emerald') {
                  invoiceWidget = InvoiceTemplateModernEmerald(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Royal Violet') {
                  invoiceWidget = InvoiceTemplateRoyalViolet(billData: billData, itemsData: itemsData);
                } else if (tmpl == 'Minimal Slate') {
                  invoiceWidget = InvoiceTemplateMinimalSlate(billData: billData, itemsData: itemsData);
                } else {
                  invoiceWidget = InvoiceTemplatePremiumGold(billData: billData, itemsData: itemsData);
                }

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice #${billData['bill_number']}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Screenshot(
                          controller: screenshotController,
                          child: invoiceWidget,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BillingScreen(billToEdit: billData)),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  side: const BorderSide(color: AppColors.royalBlue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.edit_rounded, color: AppColors.royalBlue, size: 20),
                                label: Text('Edit Bill', style: GoogleFonts.outfit(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _confirmDeleteBill(context, billData);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  side: BorderSide(color: Colors.red.shade400),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                label: Text('Delete Bill', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final image = await screenshotController.capture(pixelRatio: 2.0);
                                if (image == null) return;

                                final directory = await getTemporaryDirectory();
                                final imagePath = await File('${directory.path}/invoice_${billData['bill_number']}.png').create();
                                await imagePath.writeAsBytes(image);

                                await Share.shareXFiles(
                                  [XFile(imagePath.path)],
                                  text: 'Hello ${billData['customer_name']},\n\nHere is your invoice for ₹${billData['grand_total']}.\nThank you for your business!',
                                );
                              } catch (e) {
                                debugPrint('Error sharing bill: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                            label: Text(
                              'Share WhatsApp',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add New Customer',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _inputField(_nameController, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _inputField(_phoneController, 'Phone Number', Icons.phone_outlined, TextInputType.phone),
          const SizedBox(height: 14),
          _inputField(_notesController, 'Notes (optional)', Icons.note_outlined),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : () async {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter customer name')),
                );
                return;
              }
              setState(() => _isSaving = true);
              try {
                final phoneVal = _phoneController.text.trim();
                await DatabaseHelper.instance.addCustomer({
                  'name': _nameController.text.trim(),
                  'phone': phoneVal.isEmpty ? 'N/A_${DateTime.now().millisecondsSinceEpoch}' : phoneVal,
                  'address': _notesController.text.trim(), 
                  'outstanding_balance': 0.0,
                  'total_spent': 0.0,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Customer "${_nameController.text}" added successfully!'),
                      backgroundColor: AppColors.emeraldGreen,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding customer: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Customer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, [TextInputType? type]) {
    final isPhone = type == TextInputType.phone;
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ] : null,
      decoration: InputDecoration(
        counterText: '',
        prefixText: isPhone ? '+91 ' : null,
        prefixStyle: isPhone ? const TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue) : null,
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.royalBlue),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
      ),
    );
  }
}

class AnimatedRollingCurrency extends StatelessWidget {
  final double value;
  final TextStyle style;
  final Duration duration;

  const AnimatedRollingCurrency({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.fastOutSlowIn,
      builder: (context, animatedVal, child) {
        return Text(
          fmt.format(animatedVal),
          style: style,
        );
      },
    );
  }
}

class AnimatedRollingNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;

  const AnimatedRollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.fastOutSlowIn,
      builder: (context, animatedVal, child) {
        return Text(
          '${animatedVal.round()}',
          style: style,
        );
      },
    );
  }
}

