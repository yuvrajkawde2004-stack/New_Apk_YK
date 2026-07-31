import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'providers/dashboard_provider.dart';
import '../products/product_list_screen.dart';
import '../billing/billing_screen.dart';
import '../customers/customer_list_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/animated_charts_widget.dart';
import 'widgets/top_categories_list.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
        _HomeTab(
          onAddCustomer: () => _showAddCustomerSheet(context),
          onNavigateToCustomers: () => setState(() => _selectedIndex = 2),
        ),
        const InventoryScreen(),
        CustomerListScreen(
          isEmbedded: true,
          onAddCustomer: () => _showAddCustomerSheet(context),
        ),
        const ReportsScreen(),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.inventory_2_rounded, 'Inventory'),
              _premiumCustomerNavItem(2, 'Customers'),
              _navItem(3, Icons.analytics_rounded, 'Reports'),
              _navItem(4, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumCustomerNavItem(int index, String label) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.royalBlue, Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.12),
                          AppColors.softOrange.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: selected ? const Color(0xFFF59E0B) : AppColors.royalBlue.withValues(alpha: 0.25),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: selected ? Colors.white : AppColors.royalBlue,
                    size: 20,
                  ),
                  const Positioned(
                    top: -4,
                    right: -6,
                    child: Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.royalBlue : AppColors.textSecondaryLight,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    final color = selected ? AppColors.royalBlue : AppColors.textSecondaryLight.withValues(alpha: 0.5);
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: selected ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: selected ? AppColors.royalBlue.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── HOME TAB ───────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onAddCustomer;
  final VoidCallback onNavigateToCustomers;

  const _HomeTab({
    required this.onAddCustomer,
    required this.onNavigateToCustomers,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now).toUpperCase();

    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TOP HEADER (Date, Shop Title, Add Customer, Avatar, Bell)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondaryLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Manisha Collection',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onAddCustomer,
                                child: Tooltip(
                                  message: 'Add Customer',
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.royalBlue, Color(0xFF3B82F6)],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.royalBlue.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: AppColors.royalBlue, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryLight, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 22),

                      // 2. TOTAL BALANCE HEADER (Matching Screenshot)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Balance',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmt.format(provider.monthlySales),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimaryLight,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 22),

                      // 3. MY CARDS CAROUSEL (Matching Screenshot)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Cards (4)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: onNavigateToCustomers,
                            child: const Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.royalBlue),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 145,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildBankCard(
                              title: "Today's Sales",
                              amount: fmt.format(provider.todaySales),
                              subtitle: '+12.5% vs yesterday',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7A00), Color(0xFFFF5252)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: Icons.trending_up_rounded,
                              cardType: 'Paytrum',
                            ),
                            _buildBankCard(
                              title: 'Monthly Sales',
                              amount: fmt.format(provider.monthlySales),
                              subtitle: 'July 2025',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C853), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: Icons.account_balance_wallet_outlined,
                              cardType: 'gopay',
                            ),
                            _buildBankCard(
                              title: 'Pending Dues',
                              amount: '${provider.pendingPayments} Customers',
                              subtitle: 'Outstanding',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: Icons.pending_actions_rounded,
                              cardType: 'Dues',
                            ),
                            _buildBankCard(
                              title: 'Low Stock',
                              amount: '${provider.lowStockItems} Items',
                              subtitle: 'Restock Alert',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              icon: Icons.inventory_2_outlined,
                              cardType: 'Inventory',
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // 4. RECENT TRANSFER / QUICK CUSTOMERS (Matching Screenshot)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transfer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: onNavigateToCustomers,
                            child: const Row(
                              children: [
                                Text(
                                  'Money',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.royalBlue),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: onAddCustomer,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.add, color: AppColors.textPrimaryLight, size: 24),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'New Transfer',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _customerAvatar('Santi', 'S', AppColors.royalBlue),
                            _customerAvatar('Rizal', 'R', AppColors.emeraldGreen),
                            _customerAvatar('Asri', 'A', AppColors.softOrange),
                            _customerAvatar('Habib', 'H', AppColors.purpleAccent),
                            _customerAvatar('Priya', 'P', Colors.pinkAccent),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 24),

                      // 5. QUICK ACTIONS
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),

                      const SizedBox(height: 24),

                      // 6. LAST TRANSACTIONS (Matching Screenshot)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Last Transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.royalBlue),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildRecentBills(context),

                      const SizedBox(height: 24),
                      const AnimatedChartsWidget().animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 24),
                      const TopCategoriesList().animate().fadeIn(delay: 380.ms),

                      const SizedBox(height: 100),
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

  Widget _buildBankCard({
    required String title,
    required String amount,
    required String subtitle,
    required LinearGradient gradient,
    required IconData icon,
    required String cardType,
  }) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
              Text(
                cardType,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$title • $subtitle',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerAvatar(String name, String initial, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onNavigateToCustomers,
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem('Products', Icons.checkroom_rounded, AppColors.royalBlue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()))),
      _ActionItem('Customers', Icons.people_alt_rounded, AppColors.emeraldGreen,
          onNavigateToCustomers),
      _ActionItem('Billing', Icons.receipt_long_rounded, AppColors.softOrange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()))),
      _ActionItem('Reports', Icons.bar_chart_rounded, AppColors.purpleAccent, () {}),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: a.onTap,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [a.color.withValues(alpha: 0.15), a.color.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: a.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(a.icon, color: a.color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(a.label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight)),
                ],
              ).animate().slideX(delay: (100 * (i + 1)).ms, begin: 0.4, end: 0).fadeIn(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentBills(BuildContext context) {
    final demoData = [
      {
        'name': 'Valorant',
        'bill': '#1026',
        'category': 'Games',
        'amount': '- Rp 20.243',
        'date': 'Paytrum • 26-10',
        'color': const Color(0xFFEA4335),
      },
      {
        'name': 'Link Bola Gahacor',
        'bill': '#1025',
        'category': 'Flowers',
        'amount': '- Rp 1.786.243',
        'date': 'Paytrum • 25-10',
        'color': const Color(0xFFFBBC05),
      },
      {
        'name': 'Priya Sharma',
        'bill': '#1024',
        'category': 'Apparel',
        'amount': '+ ₹ 3,200',
        'date': 'Cash • Today',
        'color': AppColors.emeraldGreen,
      },
    ];

    return Column(
      children: demoData.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (d['color'] as Color).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    d['name'].toString()[0],
                    style: TextStyle(
                      color: d['color'] as Color,
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
                    Text(d['name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      '${d['category']} • ${d['date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                d['amount'].toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: d['amount'].toString().startsWith('+')
                      ? AppColors.emeraldGreen
                      : AppColors.textPrimaryLight,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ).animate().slideY(delay: (300 + i * 80).ms, begin: 0.2, end: 0).fadeIn();
      }).toList(),
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
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter customer name')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Customer "${_nameController.text}" added successfully!'),
                  backgroundColor: AppColors.emeraldGreen,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text('Save Customer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, [TextInputType? type]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
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

