import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'Monthly';
  final _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.primaryGradient : null,
                            color: sel ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: AppColors.royalBlue.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  color: sel ? Colors.white : AppColors.textSecondaryLight,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // Sales Cards
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Sales',
                      value: '₹12,50,000',
                      sub: '+18.5%',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.royalBlue,
                      delay: 100,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      title: 'Net Profit',
                      value: '₹3,25,000',
                      sub: '+22.1%',
                      icon: Icons.account_balance_rounded,
                      color: AppColors.emeraldGreen,
                      delay: 200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Bills',
                      value: '284',
                      sub: 'This Month',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.purpleAccent,
                      delay: 300,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      title: 'GST Collected',
                      value: '₹47,500',
                      sub: 'GSTR Ready',
                      icon: Icons.percent_rounded,
                      color: AppColors.softOrange,
                      delay: 400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text('Top Categories', style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 14),
              _buildCategoryBars(),

              const SizedBox(height: 28),

              Text('Top Products', style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 400.ms),
              const SizedBox(height: 14),
              _buildTopProducts(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBars() {
    final data = [
      ('Saree', 0.75, AppColors.royalBlue),
      ('Kurti', 0.55, AppColors.emeraldGreen),
      ('Lehenga', 0.85, AppColors.purpleAccent),
      ('Suit', 0.40, AppColors.softOrange),
      ('Dupatta', 0.30, const Color(0xFFEC4899)),
    ];

    return Column(
      children: data.asMap().entries.map((e) {
        final i = e.key;
        final (name, pct, color) = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                  width: 72,
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${(pct * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ).animate().slideX(delay: (300 + i * 80).ms, begin: 0.2, end: 0).fadeIn(),
        );
      }).toList(),
    );
  }

  Widget _buildTopProducts() {
    final products = [
      ('Bridal Lehenga Set', '₹76,000', 2),
      ('Kanjivaram Silk Saree', '₹52,500', 5),
      ('Cotton Kurti', '₹18,050', 19),
      ('Salwar Suit Set', '₹14,000', 5),
    ];

    return Column(
      children: products.asMap().entries.map((e) {
        final i = e.key;
        final (name, revenue, qty) = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalBlue,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(revenue,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldGreen,
                          fontSize: 14)),
                  Text('$qty units',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondaryLight.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
        ).animate().slideY(delay: (400 + i * 80).ms, begin: 0.15, end: 0).fadeIn();
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  final int delay;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        ],
      ),
    ).animate().scale(delay: delay.ms, duration: 350.ms, curve: Curves.easeOutBack);
  }
}
