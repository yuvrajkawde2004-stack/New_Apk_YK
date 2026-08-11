import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/ledger_pdf_service.dart';
import '../dashboard/providers/dashboard_provider.dart';
import 'add_purchase_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final prods = await DatabaseHelper.instance.getProducts(limit: 1000);
    final purchases = await DatabaseHelper.instance.getAllPurchases();
    final suppliers = await DatabaseHelper.instance.getSuppliers();

    if (mounted) {
      setState(() {
        _products = prods;
        _purchases = purchases;
        _suppliers = suppliers;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calculate totals
  int get _totalStockCount => _products.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
  double get _totalStockValue => _products.fold<double>(0.0, (sum, item) => sum + (((item['quantity'] as int?) ?? 0) * ((item['purchase_rate'] as num?)?.toDouble() ?? 0.0)));
  int get _lowStockCount => _products.where((p) => ((p['id'] as int?) ?? 1) != 0 && ((p['quantity'] as int?) ?? 0) <= ((p['low_stock_limit'] as int?) ?? 5)).length;
  double get _totalSupplierDues => _suppliers.fold<double>(0.0, (sum, s) => sum + ((s['outstanding_due'] as num?)?.toDouble() ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Stock',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.royalBlue),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.royalBlue,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.royalBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_rounded, size: 20), text: 'Stock Items'),
            Tab(icon: Icon(Icons.local_shipping_rounded, size: 20), text: 'Suppliers Ledger'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStockTab(),
                _buildSuppliersTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddSupplierSheet,
              backgroundColor: AppColors.royalBlue,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: Text(
                'Add Supplier',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: STOCK ITEMS
  // ---------------------------------------------------------------------------
  Widget _buildStockTab() {
    final fmt = NumberFormat('#,##,##0.00');
    final filtered = _products.where((p) {
      final name = (p['product_name'] ?? '').toString().toLowerCase();
      final cat = (p['category'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();

    // Calculate Estimated Profit (अंदाजित नफा) and Average Margin %
    final double totalCost = _totalStockValue;
    final double totalEstimatedProfit = totalCost * 0.25; // Estimated 25% profit margin on stock
    final double avgProfitMarginPct = 25.0; // 25.0% Average Profit Margin

    return Column(
      children: [
        // 🌟 PREMIUM ESTIMATED PROFIT & STOCK HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Only show mini stats
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniStat('Total Stock Value', '₹${fmt.format(_totalStockValue)}', const Color(0xFF38BDF8)),
                    _miniStat('Stock Count', '$_totalStockCount Pcs', Colors.white),
                    _miniStat('Low Stock Alert', '$_lowStockCount Items', _lowStockCount > 0 ? const Color(0xFFF87171) : const Color(0xFF34D399)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search product or category...',
              hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Product List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No stock items found', style: GoogleFonts.outfit(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final qty = (item['quantity'] as int?) ?? 0;
                    final limit = (item['low_stock_limit'] as int?) ?? 5;
                    final isLow = qty <= limit && ((item['id'] as int?) ?? 1) != 0;
                    final rate = (item['purchase_rate'] as num?)?.toDouble() ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isLow ? Colors.red.shade200 : Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.red.shade50 : AppColors.royalBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                              color: isLow ? Colors.red : AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  'Supplier: ${item['supplier_name'] ?? 'General'} • Buy: ₹${fmt.format(rate)}',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLow ? Colors.red.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$qty Pcs',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isLow ? Colors.red.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 30).ms);
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PURCHASES (खरेदी व नवीन माल)
  // ---------------------------------------------------------------------------
  Widget _buildPurchasesTab() {
    final fmt = NumberFormat('#,##,##0.00');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Purchase Ledger', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_purchases.length} Purchase Invoices', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _purchases.isEmpty
              ? Center(
                  child: Text('No purchase records available', style: GoogleFonts.outfit(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _purchases.length,
                  itemBuilder: (_, i) {
                    final pur = _purchases[i];
                    final total = (pur['total_amount'] as num?)?.toDouble() ?? 0.0;
                    final due = (pur['due_amount'] as num?)?.toDouble() ?? 0.0;
                    final dateStr = pur['purchase_date']?.toString().substring(0, 10) ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.shopping_bag_rounded, color: AppColors.royalBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pur['product_name'] ?? 'Stock Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Supplier: ${pur['supplier_name'] ?? 'N/A'} • $dateStr', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
                                Text('Qty: ${pur['quantity']} ${pur['unit'] ?? 'PCS'} @ ₹${pur['purchase_rate']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${fmt.format(total)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15)),
                              if (due > 0)
                                Text('Due: ₹${fmt.format(due)}', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))
                              else
                                Text('PAID ✅', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: SUPPLIERS LEDGER (सप्लायर उधारी खाता)
  // ---------------------------------------------------------------------------
  Widget _buildSuppliersTab() {
    final fmt = NumberFormat('#,##,##0.00');

    return Column(
      children: [
        // Dues Summary Box
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF991B1B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Supplier Dues', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('₹${fmt.format(_totalSupplierDues)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _suppliers.isEmpty
              ? Center(
                  child: Text('No suppliers recorded yet', style: GoogleFonts.outfit(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _suppliers.length,
                  itemBuilder: (_, i) {
                    final sup = _suppliers[i];
                    final due = (sup['outstanding_due'] as num?)?.toDouble() ?? 0.0;
                    final totalPurchased = (sup['total_purchased'] as num?)?.toDouble() ?? 0.0;

                    return GestureDetector(
                      onTap: () => _showSupplierProfileModal(sup),
                      onLongPress: () => _showSupplierOptions(sup),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: due > 0 ? Colors.red.shade100 : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                              child: Text(
                                sup['name'] != null && sup['name'].toString().isNotEmpty ? sup['name'][0].toUpperCase() : 'S',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sup['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Phone: ${sup['phone'] ?? 'N/A'}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                  Text('Total Purchased: ₹${fmt.format(totalPurchased)}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: due > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: due > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        due > 0 ? '₹${fmt.format(due)} Due' : 'CLEARED ✅',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: due > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('View Ledger', style: GoogleFonts.outfit(color: AppColors.royalBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.royalBlue),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(delay: (i * 40).ms, begin: 0.1).fadeIn(),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF0F172A))),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUPPLIER PROFILE & LEDGER MODAL (सप्लायर संपूर्ण माहिती व जमा-उधारी)
  // ---------------------------------------------------------------------------
  void _showSupplierProfileModal(Map<String, dynamic> supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupplierLedgerSheet(
        supplier: supplier,
        onUpdate: _loadAllData,
      ),
    );
  }

  void _showSupplierOptions(Map<String, dynamic> supplier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.royalBlue),
              title: const Text('Edit Supplier'),
              onTap: () {
                Navigator.pop(context);
                _showEditSupplierSheet(supplier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Supplier', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSupplier(supplier);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSupplier(Map<String, dynamic> supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to delete ${supplier['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteSupplier(supplier['id']);
              if (mounted) {
                Navigator.pop(context);
                _loadAllData();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierSheet(Map<String, dynamic> supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSupplierSheet(
        initialSupplier: supplier,
        onSaved: _loadAllData,
      ),
    );
  }

  void _showAddPurchaseSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPurchaseScreen(
          onSaved: _loadAllData,
        ),
      ),
    );
  }

  void _showAddSupplierSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSupplierSheet(
        onSaved: _loadAllData,
      ),
    );
  }

  void _showQuickAddStockDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Stock: ${item['product_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity to Add', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final addQty = int.tryParse(qtyCtrl.text) ?? 0;
              if (addQty > 0) {
                await DatabaseHelper.instance.increaseStock(item['id'], addQty);
                if (mounted) {
                  Navigator.pop(context);
                  _loadAllData();
                  Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue),
            child: const Text('Save Stock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SUPPLIER LEDGER SHEET COMPONENT
// -----------------------------------------------------------------------------
class _SupplierLedgerSheet extends StatefulWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onUpdate;

  const _SupplierLedgerSheet({required this.supplier, required this.onUpdate});

  @override
  State<_SupplierLedgerSheet> createState() => _SupplierLedgerSheetState();
}

class _SupplierLedgerSheetState extends State<_SupplierLedgerSheet> with SingleTickerProviderStateMixin {
  late TabController _innerTabCtrl;
  late Map<String, dynamic> _currentSupplier;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentSupplier = Map<String, dynamic>.from(widget.supplier);
    _innerTabCtrl = TabController(length: 2, vsync: this);
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    final name = _currentSupplier['name'] ?? '';
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(name);
    final pay = await DatabaseHelper.instance.getSupplierPayments(name);
    final allSups = await DatabaseHelper.instance.getSuppliers();
    final updatedSup = allSups.firstWhere(
      (s) => (s['name'] ?? '').toString().toLowerCase() == name.toString().toLowerCase(),
      orElse: () => _currentSupplier,
    );

    if (mounted) {
      setState(() {
        _currentSupplier = Map<String, dynamic>.from(updatedSup);
        _purchases = pur;
        _payments = pay;
        _loading = false;
      });
    }
    widget.onUpdate();
  }

  Future<void> _downloadLedgerPdf() async {
    try {
      final List<Map<String, dynamic>> allTrans = [];

      for (var p in _purchases) {
        allTrans.add({
          'date': p['purchase_date']?.toString().substring(0, 10) ?? '',
          'description': 'Purchase (${p['product_name'] ?? 'Item'})',
          'amount': (p['total_amount'] as num?)?.toDouble() ?? 0.0,
          'is_credit': false,
        });
      }

      for (var p in _payments) {
        allTrans.add({
          'date': p['payment_date']?.toString().substring(0, 10) ?? '',
          'description': 'Payment Sent (${p['payment_method'] ?? 'Cash'})',
          'amount': (p['amount_paid'] as num?)?.toDouble() ?? 0.0,
          'is_credit': true,
        });
      }

      allTrans.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

      final pdfBytes = await LedgerPdfService.generateLedgerPdf(
        title: 'Supplier Ledger Statement',
        partyName: _currentSupplier['name'] ?? '',
        phone: _currentSupplier['phone'] ?? '',
        totalOutstanding: (_currentSupplier['outstanding_due'] as num?)?.toDouble() ?? 0.0,
        transactions: allTrans,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${_currentSupplier['name'].toString().replaceAll(' ', '_')}_Ledger.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Ledger Statement for ${_currentSupplier['name']}');
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    final name = _currentSupplier['name'] ?? '';
    final phone = _currentSupplier['phone'] ?? 'N/A';
    final due = (_currentSupplier['outstanding_due'] as num?)?.toDouble() ?? 0.0;
    final totalPurchased = (_currentSupplier['total_purchased'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (_currentSupplier['total_paid'] as num?)?.toDouble() ?? 0.0;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Supplier Profile & Ledger',
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.royalBlue),
              onPressed: _loadSupplierData,
              tooltip: 'Refresh Ledger',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 👑 1. ULTRA-PREMIUM HERO BANNER
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E1B4B).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, color: Colors.white60, size: 14),
                                  const SizedBox(width: 4),
                                  Text(phone, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                                ],
                              ),
                            ],
                          ),
                        ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: due > 0 ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: due > 0 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              due > 0 ? 'DUE' : 'CLEARED',
                              style: GoogleFonts.outfit(color: due > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70),
                            onPressed: _downloadLedgerPdf,
                            tooltip: 'Download Ledger PDF',
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 14),
                    // 3 Financial Metric Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _heroMetricItem('Total Bought', '₹${fmt.format(totalPurchased)}', Colors.white70),
                        _heroMetricItem('Total Paid', '₹${fmt.format(totalPaid)}', const Color(0xFF34D399)),
                        _heroMetricItem('Remaining Due', '₹${fmt.format(due)}', due > 0 ? const Color(0xFFF87171) : const Color(0xFF34D399)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.05, end: 0),

              // ⚡ 2. QUICK ACTION BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddProductForSupplierDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_box_rounded, color: Colors.white, size: 18),
                        label: Text('+ Add Product', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showRecordSupplierPaymentDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                        label: Text('Pay Supplier', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 📑 3. TAB BAR (Purchases & Payments)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: TabBar(
                  controller: _innerTabCtrl,
                  labelColor: AppColors.royalBlue,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: AppColors.royalBlue,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Purchases Ledger'),
                    Tab(text: 'Payment Logs'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 📜 4. TAB VIEWS WITH REAL-TIME LIST
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                    : TabBarView(
                        controller: _innerTabCtrl,
                        children: [
                          // Tab 1: Purchases History
                          _purchases.isEmpty
                              ? Center(
                                  child: Text('No purchases recorded for this supplier', style: GoogleFonts.outfit(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _purchases.length,
                                  itemBuilder: (_, i) {
                                    final p = _purchases[i];
                                    final amt = (p['total_amount'] as num?)?.toDouble() ?? 0.0;
                                    final dateStr = p['purchase_date']?.toString().substring(0, 10) ?? '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.royalBlue, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p['product_name'] ?? 'Stock Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('Qty: ${p['quantity']} ${p['unit'] ?? 'PCS'} @ ₹${p['purchase_rate']} • $dateStr', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                              ],
                                            ),
                                          ),
                                          Text('₹${fmt.format(amt)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF0F172A))),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // Tab 2: Payment Logs
                          _payments.isEmpty
                              ? Center(
                                  child: Text('No payment logs recorded yet', style: GoogleFonts.outfit(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _payments.length,
                                  itemBuilder: (_, i) {
                                    final pm = _payments[i];
                                    final amt = (pm['amount_paid'] as num?)?.toDouble() ?? 0.0;
                                    final dateStr = pm['payment_date']?.toString().substring(0, 10) ?? '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Paid ₹${fmt.format(amt)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('Mode: ${pm['payment_method']} • $dateStr', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                              ],
                                            ),
                                          ),
                                          Text('SUCCESS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF10B981))),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroMetricItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: valueColor, fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }

  void _showRecordSupplierPaymentDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String method = 'Cash';
    final supName = _currentSupplier['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pay $supName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Paid (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              items: ['Cash', 'UPI / PhonePe', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => method = val ?? 'Cash',
              decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final paid = double.tryParse(amtCtrl.text) ?? 0.0;
              if (paid > 0) {
                await DatabaseHelper.instance.recordSupplierPayment(
                  supplierName: supName,
                  amountPaid: paid,
                  paymentMethod: method,
                  notes: noteCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _loadSupplierData();
                  widget.onUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paid ₹$paid to $supName'), backgroundColor: AppColors.emeraldGreen),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            child: const Text('Record Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddProductForSupplierDialog() {
    final prodCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final paidCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final lowStockCtrl = TextEditingController(text: '5');
    String selectedUnit = 'PCS';
    final units = ['PCS', 'PAIR', 'KG', 'G', 'MTR', 'ROLL', 'BOX', 'PACK', 'SET', 'DOZ', 'LTR', 'ML'];
    final supName = _currentSupplier['name'] ?? '';
    final supPhone = _currentSupplier['phone'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Product for $supName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prodCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name (e.g. Cotton Shirt)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Buy Rate (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => selectedUnit = val ?? 'PCS'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lowStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Low Stock Limit', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              TextField(
                controller: paidCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid Now (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue),
              onPressed: () async {
                final prod = prodCtrl.text.trim();
                final rate = double.tryParse(rateCtrl.text) ?? 0.0;
                final sell = 0.0;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final paid = double.tryParse(paidCtrl.text) ?? 0.0;
                final lowStock = int.tryParse(lowStockCtrl.text) ?? 5;

                if (prod.isEmpty || rate <= 0 || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Product name, Rate and Quantity')));
                  return;
                }

                await DatabaseHelper.instance.recordPurchase(
                  productName: prod,
                  supplierName: supName,
                  purchaseRate: rate,
                  quantity: qty,
                  paidAmount: paid,
                  supplierPhone: supPhone,
                  notes: noteCtrl.text.trim(),
                  sellingPrice: sell,
                  unit: selectedUnit,
                  lowStockLimit: lowStock,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  await _loadSupplierData();
                  widget.onUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "$prod" under $supName!'), backgroundColor: AppColors.emeraldGreen),
                  );
                }
              },
              child: const Text('Add Product', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// ADD NEW SUPPLIER SHEET
// -----------------------------------------------------------------------------
class _AddSupplierSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Map<String, dynamic>? initialSupplier;
  const _AddSupplierSheet({required this.onSaved, this.initialSupplier});

  @override
  State<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<_AddSupplierSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSupplier != null) {
      _nameCtrl.text = widget.initialSupplier!['name'] ?? '';
      _phoneCtrl.text = (widget.initialSupplier!['phone'] ?? '').toString().replaceAll('+91 ', '').replaceAll('+91', '');
      _addressCtrl.text = widget.initialSupplier!['address'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialSupplier != null;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Text(isEdit ? 'Edit Supplier' : 'Add New Supplier', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Supplier / Business Name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile Number (10 digits)',
              prefixText: '+91 ',
              prefixStyle: TextStyle(fontWeight: FontWeight.bold),
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'City / Address', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                final rawPhone = _phoneCtrl.text.trim();
                if (rawPhone.isNotEmpty && rawPhone.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier mobile number must be 10 digits (+91 followed by 10 digits)')));
                  return;
                }

                setState(() => _saving = true);
                final phoneVal = rawPhone.isEmpty ? '' : (rawPhone.startsWith('+91') ? rawPhone : '+91 $rawPhone');
                
                final Map<String, dynamic> supplierData = {
                  'name': _nameCtrl.text.trim(),
                  'phone': phoneVal,
                  'address': _addressCtrl.text.trim(),
                };

                if (isEdit) {
                  await DatabaseHelper.instance.updateSupplier(widget.initialSupplier!['id'], supplierData);
                } else {
                  supplierData['total_purchased'] = 0.0;
                  supplierData['total_paid'] = 0.0;
                  supplierData['outstanding_due'] = 0.0;
                  await DatabaseHelper.instance.addSupplier(supplierData);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  widget.onSaved();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? 'Update Supplier' : 'Save Supplier Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

