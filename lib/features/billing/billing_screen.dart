import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/database/database_helper.dart';
import '../dashboard/providers/dashboard_provider.dart';

class BillingScreen extends StatefulWidget {
  final Customer? customer;

  const BillingScreen({super.key, this.customer});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillItem {
  final Product product;
  int qty;
  _BillItem({required this.product, required this.qty});
  double get total => product.sellingPrice * qty;
}

class _BillingScreenState extends State<BillingScreen> {
  final List<_BillItem> _items = [];
  late Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';
  double _discount = 0;
  bool _isProcessing = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');

  final List<String> _paymentMethods = ['Cash', 'UPI', 'Card', 'Credit'];

  final List<Product> _allProducts = [
    Product(id: 1, name: 'Kanjivaram Silk Saree', category: 'Saree', mrp: 12000,
        sellingPrice: 10500, purchasePrice: 8000, stock: 15, gst: 5),
    Product(id: 2, name: 'Cotton Kurti - Block Print', category: 'Kurti', mrp: 1200,
        sellingPrice: 950, purchasePrice: 600, stock: 3, gst: 5),
    Product(id: 3, name: 'Bridal Lehenga Set', category: 'Lehenga', mrp: 45000,
        sellingPrice: 38000, purchasePrice: 28000, stock: 2, gst: 12),
    Product(id: 4, name: 'Georgette Dupatta', category: 'Dupatta', mrp: 800,
        sellingPrice: 650, purchasePrice: 350, stock: 25, gst: 5),
    Product(id: 5, name: 'Salwar Suit Set', category: 'Suit', mrp: 3500,
        sellingPrice: 2800, purchasePrice: 1800, stock: 8, gst: 5),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer ?? Customer(id: 1, name: 'Walk-in Customer', phone: 'N/A', outstandingBalance: 0);
  }

  List<Product> get _searchResults {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      final nameMatch = p.name.toLowerCase().contains(q);
      final catMatch = (p.category ?? '').toLowerCase().contains(q);
      return nameMatch || catMatch;
    }).toList();
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _gstAmount => _items.fold(0, (s, i) => s + (i.total * i.product.gst / 100));
  double get _grandTotal => (_subtotal + _gstAmount - _discount).clamp(0.0, double.infinity);

  void _addItem(Product p) {
    setState(() {
      final existing = _items.where((i) => i.product.id == p.id).toList();
      if (existing.isNotEmpty) {
        existing.first.qty++;
      } else {
        _items.add(_BillItem(product: p, qty: 1));
      }
    });
    _searchCtrl.clear();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _processPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one product for billing', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Save to DatabaseHelper
    try {
      final billNo = await DatabaseHelper.instance.generateBillNumber();
      final billData = {
        'bill_number': billNo,
        'customer_name': _selectedCustomer?.name ?? 'Walk-in Customer',
        'customer_mobile': _selectedCustomer?.phone ?? '',
        'subtotal': _subtotal,
        'discount': _discount,
        'gst': _gstAmount,
        'grand_total': _grandTotal,
        'payment_method': _paymentMethod,
        'bill_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final itemsData = _items.map((i) => {
        'product_id': i.product.id,
        'product_name': i.product.name,
        'quantity': i.qty,
        'selling_price': i.product.sellingPrice,
        'total': i.total,
      }).toList();

      await DatabaseHelper.instance.createCompleteBill(billData, itemsData);

      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
      }
    } catch (e) {
      debugPrint('Bill save error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 46),
              ).animate().scale(curve: Curves.easeOutBack),
              const SizedBox(height: 18),
              Text('Bill Generated Successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##,##0.00').format(_grandTotal)} collected via $_paymentMethod for ${_selectedCustomer?.name}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: Text('Print Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _items.clear();
                          _discount = 0;
                          _discountCtrl.text = '0';
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                      ),
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Create Premium Bill', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Customer Header Badge Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.royalBlue, Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (_selectedCustomer?.name.isNotEmpty == true) ? _selectedCustomer!.name[0].toUpperCase() : 'C',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer?.name ?? 'Walk-in Customer',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _selectedCustomer?.phone ?? 'Mobile Billing',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'INV-2025',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.15, end: 0).fadeIn(),

          // Product Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products by name or category...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                suffixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.royalBlue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Product Search Dropdown Overlay if typing
          if (_searchCtrl.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                children: _searchResults.map((p) {
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.checkroom_rounded, color: AppColors.royalBlue, size: 18),
                    ),
                    title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('₹${p.sellingPrice.toStringAsFixed(0)} • Stock: ${p.stock}',
                        style: GoogleFonts.outfit(fontSize: 11)),
                    trailing: const Icon(Icons.add_circle_rounded, color: AppColors.emeraldGreen, size: 24),
                    onTap: () => _addItem(p),
                  );
                }).toList(),
              ),
            ),

          // Bill Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 64, color: AppColors.royalBlue.withValues(alpha: 0.25)),
                        const SizedBox(height: 12),
                        Text(
                          'Search and add items to generate bill',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondaryLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ).animate().scale().fadeIn(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.red),
                        ),
                        onDismissed: (_) => _removeItem(i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.checkroom_rounded, color: AppColors.royalBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('₹${item.product.sellingPrice.toStringAsFixed(0)} each',
                                      style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _qtyBtn(Icons.remove, () {
                                  setState(() {
                                    if (item.qty > 1) {
                                      item.qty--;
                                    } else {
                                      _items.removeAt(i);
                                    }
                                  });
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('${item.qty}',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                                _qtyBtn(Icons.add, () => setState(() => item.qty++)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text('₹${item.total.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.royalBlue)),
                          ],
                        ),
                      ),
                    ).animate().slideX(delay: (i * 40).ms, begin: 0.1, end: 0).fadeIn();
                    },
                  ),
          ),

          // Summary & Payment Action Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                    Text('₹${fmt.format(_subtotal)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GST Tax', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                    Text('+₹${fmt.format(_gstAmount)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount (₹)', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                    SizedBox(
                      width: 84,
                      height: 32,
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                        onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                        decoration: InputDecoration(
                          prefixText: '-₹',
                          prefixStyle: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.red.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GRAND TOTAL', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('₹${fmt.format(_grandTotal)}',
                        style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.royalBlue)),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Method Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _paymentMethods.map((m) {
                      final sel = _paymentMethod == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.royalBlue : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppColors.royalBlue : AppColors.textSecondaryLight.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(m,
                                style: GoogleFonts.outfit(
                                    color: sel ? Colors.white : AppColors.textSecondaryLight,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Process Payment Button
                _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: _processPayment,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.royalBlue, Color(0xFF2563EB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.royalBlue.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('GENERATE & SAVE BILL',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.royalBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.royalBlue),
      ),
    );
  }
}
