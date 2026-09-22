import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_purchase_form_screen.dart';

class SupplierLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;
  const SupplierLedgerScreen({super.key, required this.supplier});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _currentSupplier = {};
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentSupplier = widget.supplier;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final String supName = _currentSupplier['name'];
    
    // Refresh supplier data for updated due
    final sups = await DatabaseHelper.instance.getSuppliers();
    final updatedSup = sups.firstWhere((s) => s['name'] == supName, orElse: () => _currentSupplier);
    
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(supName);
    final pay = await DatabaseHelper.instance.getSupplierPayments(supName);
    
    setState(() {
      _currentSupplier = updatedSup;
      _purchases = pur;
      _payments = pay;
      _loading = false;
    });
  }

  void _showAddPaymentDialog() {
    final amtCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amtCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount Paid (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await DatabaseHelper.instance.recordSupplierPayment(
                  supplierName: _currentSupplier['name'],
                  amountPaid: double.parse(amtCtrl.text),
                  paymentMethod: 'Cash',
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    if (_purchases.isEmpty) {
      return const Center(child: Text('No purchases yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final p = _purchases[index];
        final date = DateTime.tryParse(p['purchase_date'] ?? '') ?? DateTime.now();
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.blue),
            ),
            title: Text('Bill: ₹${p['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: Text(
              '${p['status'] ?? 'COMPLETED'}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No payments yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final date = DateTime.tryParse(p['payment_date'] ?? '') ?? DateTime.now();
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.currency_rupee_rounded, color: Colors.green),
            ),
            title: Text('Paid: ₹${p['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: Text(
              p['payment_method'] ?? 'CASH',
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double due = (_currentSupplier['outstanding_due'] as num?)?.toDouble() ?? 0.0;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_currentSupplier['name'] ?? 'Supplier', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.royalBlue, Color(0xFF1E293B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OUTSTANDING DUE',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${due.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: due > 0 ? const Color(0xFFFDA4AF) : Colors.greenAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Text(
                            (_currentSupplier['phone'] != null && _currentSupplier['phone'].toString().isNotEmpty) 
                                ? _currentSupplier['phone'] 
                                : 'No Phone',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.royalBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.royalBlue,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Purchases (Kharedi)'),
                    Tab(text: 'Payments (Dile)'),
                  ],
                ),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPurchasesTab(),
                      _buildPaymentsTab(),
                    ],
                  ),
                ),
              ],
            ),
            
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.currency_rupee_rounded),
                label: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _showAddPaymentDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Add Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPurchaseFormScreen(initialSupplierName: _currentSupplier['name']),
                    ),
                  );
                  _loadData(); // Refresh when back from purchase screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
