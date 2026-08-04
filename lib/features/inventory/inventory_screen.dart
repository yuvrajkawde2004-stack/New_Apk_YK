import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../dashboard/providers/dashboard_provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
  int get _lowStockCount => _products.where((p) => ((p['quantity'] as int?) ?? 0) <= ((p['low_stock_limit'] as int?) ?? 5)).length;
  double get _totalSupplierDues => _suppliers.fold<double>(0.0, (sum, s) => sum + ((s['outstanding_due'] as num?)?.toDouble() ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Inventory & Purchase Studio',
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
            Tab(icon: Icon(Icons.shopping_bag_rounded, size: 20), text: 'Purchases'),
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
                _buildPurchasesTab(),
                _buildSuppliersTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddPurchaseSheet,
              backgroundColor: AppColors.royalBlue,
              icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
              label: Text(
                'New Purchase (खरेदी नोंद)',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
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

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _summaryCard('Total Stock', '$_totalStockCount Pcs', Icons.inventory_2_outlined, const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard('Stock Value', '₹${fmt.format(_totalStockValue)}', Icons.account_balance_wallet_outlined, const Color(0xFF059669)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard('Low Stock', '$_lowStockCount Items', Icons.warning_amber_rounded, const Color(0xFFDC2626)),
              ),
            ],
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
                    final isLow = qty <= limit;
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
                                Text('Qty: ${pur['quantity']} @ ₹${pur['purchase_rate']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade800)),
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
                    Text('Total Supplier Dues (उधारी)', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPurchaseSheet(
        suppliers: _suppliers,
        onSaved: _loadAllData,
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
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _innerTabCtrl = TabController(length: 2, vsync: this);
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    final name = widget.supplier['name'] ?? '';
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(name);
    final pay = await DatabaseHelper.instance.getSupplierPayments(name);
    if (mounted) {
      setState(() {
        _purchases = pur;
        _payments = pay;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    final due = (widget.supplier['outstanding_due'] as num?)?.toDouble() ?? 0.0;
    final totalPurchased = (widget.supplier['total_purchased'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (widget.supplier['total_paid'] as num?)?.toDouble() ?? 0.0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),

          // Supplier Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.15),
                child: Text(
                  widget.supplier['name'] != null && widget.supplier['name'].toString().isNotEmpty ? widget.supplier['name'][0].toUpperCase() : 'S',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.royalBlue),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.supplier['name'] ?? '', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Ph: ${widget.supplier['phone'] ?? 'N/A'}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),

          const SizedBox(height: 16),

          // Due Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: due > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: due > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Balance (उधारी)', style: GoogleFonts.outfit(fontSize: 11, color: due > 0 ? Colors.red.shade800 : Colors.green.shade800)),
                    Text('₹${fmt.format(due)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: due > 0 ? Colors.red.shade900 : Colors.green.shade900)),
                    Text('Total Bought: ₹${fmt.format(totalPurchased)} • Total Paid: ₹${fmt.format(totalPaid)}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade700)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRecordSupplierPaymentDialog(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 16),
                  label: Text('Pay Supplier', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          TabBar(
            controller: _innerTabCtrl,
            labelColor: AppColors.royalBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.royalBlue,
            tabs: const [
              Tab(text: 'Purchases History'),
              Tab(text: 'Payment Logs'),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                : TabBarView(
                    controller: _innerTabCtrl,
                    children: [
                      // Tab 1: Purchases History
                      _purchases.isEmpty
                          ? Center(child: Text('No purchases recorded for this supplier', style: GoogleFonts.outfit(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _purchases.length,
                              itemBuilder: (_, i) {
                                final p = _purchases[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(p['product_name'] ?? 'Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Qty: ${p['quantity']} @ ₹${p['purchase_rate']} • ${p['purchase_date']?.toString().substring(0, 10)}'),
                                  trailing: Text('₹${fmt.format((p['total_amount'] as num?)?.toDouble() ?? 0.0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                                );
                              },
                            ),

                      // Tab 2: Payment Logs
                      _payments.isEmpty
                          ? Center(child: Text('No payments recorded yet', style: GoogleFonts.outfit(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _payments.length,
                              itemBuilder: (_, i) {
                                final pm = _payments[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                  title: Text('Paid ₹${fmt.format((pm['amount_paid'] as num?)?.toDouble() ?? 0.0)} via ${pm['payment_method']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Date: ${pm['payment_date']?.toString().substring(0, 10)} ${pm['notes'] != null && pm['notes'].toString().isNotEmpty ? "• " + pm['notes'] : ""}'),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showRecordSupplierPaymentDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pay ${widget.supplier['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  supplierName: widget.supplier['name'],
                  amountPaid: paid,
                  paymentMethod: method,
                  notes: noteCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadSupplierData();
                  widget.onUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paid ₹$paid to ${widget.supplier['name']}'), backgroundColor: AppColors.emeraldGreen),
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
}

// -----------------------------------------------------------------------------
// ADD NEW PURCHASE SHEET
// -----------------------------------------------------------------------------
class _AddPurchaseSheet extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers;
  final VoidCallback onSaved;

  const _AddPurchaseSheet({required this.suppliers, required this.onSaved});

  @override
  State<_AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<_AddPurchaseSheet> {
  final _prodCtrl = TextEditingController();
  final _supCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _paidCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedSupplierName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.suppliers.isNotEmpty) {
      _selectedSupplierName = widget.suppliers.first['name'];
      _supCtrl.text = _selectedSupplierName!;
      _phoneCtrl.text = widget.suppliers.first['phone'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text('Record New Stock Purchase', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Step 1: Select or Add Supplier FIRST
            if (widget.suppliers.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedSupplierName,
                decoration: const InputDecoration(labelText: '1. Select Supplier (सप्लायर निवडा)', border: OutlineInputBorder()),
                items: widget.suppliers.map((s) {
                  final name = s['name'].toString();
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSupplierName = val;
                      _supCtrl.text = val;
                      final match = widget.suppliers.firstWhere((s) => s['name'] == val, orElse: () => {});
                      _phoneCtrl.text = (match['phone'] ?? '').toString().replaceAll('+91 ', '').replaceAll('+91', '');
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ] else ...[
              TextField(
                controller: _supCtrl,
                decoration: const InputDecoration(labelText: '1. Supplier Name (e.g. Surat Textiles)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
            ],

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Supplier Mobile (+91)',
                prefixText: '+91 ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Step 2: Product & Rate
            TextField(controller: _prodCtrl, decoration: const InputDecoration(labelText: '2. Product Name (e.g. Cotton Shirt)', border: OutlineInputBorder())),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: TextField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Price (₹)', prefixText: '₹ ', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (Pcs)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 10),

            TextField(controller: _paidCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount Paid Now (₹)', prefixText: '₹ ', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder())),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePurchase,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text('Save Purchase Record', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase() async {
    final prod = _prodCtrl.text.trim();
    final sup = _supCtrl.text.trim();
    final rate = double.tryParse(_rateCtrl.text) ?? 0.0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final paid = double.tryParse(_paidCtrl.text) ?? 0.0;
    final rawPhone = _phoneCtrl.text.trim();

    if (prod.isEmpty || sup.isEmpty || rate <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Supplier Name, Product Name, Price and Quantity.')));
      return;
    }

    if (rawPhone.isNotEmpty && rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('सप्लायर मोबाईल नंबर १० अंकांचा असावा (+91 नंतर १० अंक)')));
      return;
    }

    final phoneVal = rawPhone.isEmpty ? '' : (rawPhone.startsWith('+91') ? rawPhone : '+91 $rawPhone');

    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.recordPurchase(
        productName: prod,
        supplierName: sup,
        purchaseRate: rate,
        quantity: qty,
        paidAmount: paid,
        supplierPhone: phoneVal,
        notes: _noteCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase recorded! Stock updated for "$prod"'), backgroundColor: AppColors.emeraldGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving purchase: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('सप्लायर मोबाईल नंबर १० अंकांचा असावा (+91 नंतर १० अंक)')));
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

