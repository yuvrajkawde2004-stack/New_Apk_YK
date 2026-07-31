import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/database/database_helper.dart';
import '../dashboard/providers/dashboard_provider.dart';
import 'templates/invoice_template_premium_gold.dart';
import 'templates/invoice_template_minimal_light.dart';
import 'templates/invoice_template_royal_blue.dart';

class BillingScreen extends StatefulWidget {
  final Customer? customer;

  const BillingScreen({super.key, this.customer});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillItem {
  final Product? product;
  String name;
  int qty;
  double price;
  final TextEditingController priceCtrl;

  _BillItem({
    this.product,
    required this.name,
    this.qty = 1,
    this.price = 0,
  }) : priceCtrl = TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : '');

  double get total => price * qty;
  
  void dispose() {
    priceCtrl.dispose();
  }
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

  List<Product> _dbProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer ?? Customer(id: 1, name: 'Walk-in Customer', phone: 'N/A', outstandingBalance: 0);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getProducts(limit: 500); // Load enough products for billing search
    final products = data.map((json) {
      return Product(
        id: json['id'],
        name: json['product_name'] ?? '',
        category: json['category'] ?? '',
        mrp: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        purchasePrice: (json['purchase_rate'] as num?)?.toDouble() ?? 0.0,
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        stock: json['quantity'] ?? 0,
        lowStockThreshold: json['low_stock_limit'] ?? 5,
        brand: json['supplier_name'] ?? '',
        gst: 0, // Default to 0 unless added to DB later
      );
    }).toList();
    if (mounted) {
      setState(() {
        _dbProducts = products;
      });
    }
  }

  List<Product> get _searchResults {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _dbProducts;
    return _dbProducts.where((p) {
      final nameMatch = p.name.toLowerCase().contains(q);
      final catMatch = (p.category ?? '').toLowerCase().contains(q);
      return nameMatch || catMatch;
    }).toList();
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _gstAmount => _items.fold(0, (s, i) => s + (i.total * (i.product?.gst ?? 0) / 100)); // GST 0 if custom
  double get _grandTotal => (_subtotal + _gstAmount - _discount).clamp(0.0, double.infinity);

  void _addItem(Product? p, {String? customName}) {
    setState(() {
      if (p != null) {
        final existing = _items.where((i) => i.product?.id == p.id).toList();
        if (existing.isNotEmpty) {
          existing.first.qty++;
        } else {
          _items.insert(0, _BillItem(product: p, name: p.name));
        }
      } else if (customName != null && customName.isNotEmpty) {
        _items.insert(0, _BillItem(product: null, name: customName));
      }
    });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _processPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one product for billing', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Validate if any item has 0 price
    if (_items.any((i) => i.price <= 0)) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price for all items.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

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
        'product_id': i.product?.id ?? 0, // 0 for custom items so stock isn't affected
        'product_name': i.name,
        'quantity': i.qty,
        'selling_price': i.price,
        'total': i.total,
      }).toList();

      await DatabaseHelper.instance.createCompleteBill(billData, itemsData);

      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showInvoicePreviewDialog(billData, itemsData);
      
    } catch (e) {
      debugPrint('Bill save error: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showInvoicePreviewDialog(Map<String, dynamic> billData, List<Map<String, dynamic>> itemsData) {
    final screenshotController = ScreenshotController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
            
            final tmpl = snapshot.data!.getString('invoice_template') ?? 'Premium Gold';
            
            Widget invoiceWidget;
            if (tmpl == 'Minimal Light') {
              invoiceWidget = InvoiceTemplateMinimalLight(billData: billData, itemsData: itemsData);
            } else if (tmpl == 'Royal Blue') {
              invoiceWidget = InvoiceTemplateRoyalBlue(billData: billData, itemsData: itemsData);
            } else {
              invoiceWidget = InvoiceTemplatePremiumGold(billData: billData, itemsData: itemsData);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invoice Generated!', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _items.clear();
                            _discount = 0;
                            _discountCtrl.text = '0';
                          });
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Screenshot(
                            controller: screenshotController,
                            child: invoiceWidget,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                            text: 'Hello ${billData['customer_name']},\n\nHere is your invoice for ₹${billData['grand_total']}.\nThank you for your business!'
                          );
                        } catch (e) {
                          debugPrint('Error sharing: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: Text('Share on WhatsApp', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    for (var i in _items) { i.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00');
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light gray background
      body: SafeArea(
        child: Column(
          children: [
            // 🌟 Premium Glassmorphism Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('Premium Invoice', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                              ),
                              child: Text('PRO', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: Text((_selectedCustomer?.name.isNotEmpty == true) ? _selectedCustomer!.name[0].toUpperCase() : 'C',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedCustomer?.name ?? 'Walk-in Customer',
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(_selectedCustomer?.phone ?? 'Standard Billing',
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().slideY(begin: -0.1).fadeIn(),

            // 🔍 Search Bar & Dropdown
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Type to search or add custom product...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  Positioned(
                    top: 65, left: 16, right: 16,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor: Colors.black26,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            if (_searchResults.isNotEmpty) ..._searchResults.map((p) {
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.royalBlue, size: 20),
                                ),
                                title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('In Stock: ${p.stock}', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
                                trailing: const Icon(Icons.add_circle_rounded, color: AppColors.emeraldGreen),
                                onTap: () => _addItem(p),
                              );
                            }),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.post_add_rounded, color: Color(0xFFF59E0B), size: 20),
                              ),
                              title: Text('Add "${_searchCtrl.text}" as Custom Item', 
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                              subtitle: Text('Enter manual price', style: GoogleFonts.outfit(fontSize: 12)),
                              onTap: () => _addItem(null, customName: _searchCtrl.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 🛒 Items List
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_basket_rounded, size: 80, color: AppColors.royalBlue.withValues(alpha: 0.15)),
                          const SizedBox(height: 16),
                          Text('Cart is empty', style: GoogleFonts.outfit(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Add items to create a premium invoice', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 14)),
                        ],
                      ).animate().fadeIn().scale(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                          ),
                          onDismissed: (_) => _removeItem(i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(item.product != null ? Icons.inventory_rounded : Icons.label_important_rounded, 
                                      color: item.product != null ? AppColors.royalBlue : const Color(0xFFF59E0B), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(item.name, 
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
                                    ),
                                    Text('₹${fmt.format(item.total)}', 
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.royalBlue)),
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                Row(
                                  children: [
                                    // Custom Price Input
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            Text('₹ ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                                            Expanded(
                                              child: TextField(
                                                controller: item.priceCtrl,
                                                keyboardType: TextInputType.number,
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                                decoration: const InputDecoration(
                                                  hintText: 'Enter Price',
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                ),
                                                onChanged: (val) {
                                                  setState(() {
                                                    item.price = double.tryParse(val) ?? 0;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Quantity Stepper
                                    Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          _qtyBtn(Icons.remove, () {
                                            setState(() { if (item.qty > 1) item.qty--; else _items.removeAt(i); });
                                          }),
                                          SizedBox(
                                            width: 32,
                                            child: Text('${item.qty}', textAlign: TextAlign.center, 
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                          ),
                                          _qtyBtn(Icons.add, () => setState(() => item.qty++)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().slideX(delay: (i * 50).ms, begin: 0.2).fadeIn();
                      },
                    ),
            ),

            // 🧾 Premium Footer
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                          Text('₹${fmt.format(_subtotal)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                          SizedBox(
                            width: 100,
                            height: 36,
                            child: TextField(
                              controller: _discountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                              onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                              decoration: InputDecoration(
                                prefixText: '-₹',
                                prefixStyle: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.redAccent.withValues(alpha: 0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                          Text('₹${fmt.format(_grandTotal)}', 
                            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.royalBlue)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Payment Methods
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _paymentMethods.map((m) {
                            final sel = _paymentMethod == m;
                            return GestureDetector(
                              onTap: () => setState(() => _paymentMethod = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? const Color(0xFF1E293B) : Colors.grey.shade300),
                                ),
                                child: Text(m, style: GoogleFonts.outfit(
                                  color: sel ? Colors.white : AppColors.textSecondaryLight, 
                                  fontWeight: sel ? FontWeight.bold : FontWeight.w500)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Generate Button
                      GestureDetector(
                        onTap: _processPayment,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.royalBlue, Color(0xFF2563EB)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.royalBlue.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: Center(
                            child: _isProcessing 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text('GENERATE INVOICE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        color: Colors.transparent,
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
    );
  }
}

