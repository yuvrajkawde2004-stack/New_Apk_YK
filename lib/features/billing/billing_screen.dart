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
import 'templates/invoice_template_classic_gst.dart';
import 'templates/invoice_template_premium_gold.dart';
import 'templates/invoice_template_modern_emerald.dart';
import 'templates/invoice_template_royal_violet.dart';
import 'templates/invoice_template_minimal_slate.dart';

class BillingScreen extends StatefulWidget {
  final Customer? customer;
  final Map<String, dynamic>? billToEdit;

  const BillingScreen({super.key, this.customer, this.billToEdit});

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
  bool _isProcessing = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _paidAmountCtrl = TextEditingController();
  bool _isManualPaidAmount = false;

  final List<String> _paymentMethods = ['Cash', 'UPI', 'Card', 'Credit'];

  List<Product> _dbProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.billToEdit != null) {
      _loadBillToEdit();
    } else {
      _selectedCustomer = widget.customer ?? Customer(id: 1, name: 'Walk-in Customer', phone: 'N/A', outstandingBalance: 0);
    }
    _loadProducts();
  }

  Future<void> _loadBillToEdit() async {
    final bill = widget.billToEdit!;
    _selectedCustomer = Customer(
      id: bill['customer_id'] ?? 1,
      name: bill['customer_name'] ?? 'Walk-in Customer',
      phone: bill['customer_mobile'] ?? 'N/A',
      outstandingBalance: 0, // Not perfectly accurate but we mostly need ID and Name here
    );
    _paymentMethod = bill['payment_method'] ?? 'Cash';
    
    final paidAmt = (bill['paid_amount'] as num?)?.toDouble() ?? 0.0;
    _paidAmountCtrl.text = paidAmt > 0 ? paidAmt.toStringAsFixed(0) : '';
    if (paidAmt > 0) _isManualPaidAmount = true;

    // Load items
    final billId = bill['id'] is int ? bill['id'] as int : int.tryParse(bill['id'].toString()) ?? 0;
    final itemsData = await DatabaseHelper.instance.getBillItems(billId);
    
    setState(() {
      for (final item in itemsData) {
        _items.add(_BillItem(
          product: null, // We don't link full Product objects back unless we search for it, but for editing existing items we just need name and price
          name: item['product_name'] ?? '',
          qty: item['quantity'] ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
        ));
      }
    });
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
  double get _grandTotal => (_subtotal + _gstAmount).clamp(0.0, double.infinity);

  double get _paidAmount {
    if (!_isManualPaidAmount || _paidAmountCtrl.text.trim().isEmpty) {
      return _grandTotal;
    }
    return double.tryParse(_paidAmountCtrl.text.trim()) ?? _grandTotal;
  }

  double get _dueAmount => (_grandTotal - _paidAmount).clamp(0.0, double.infinity);

  void _addItem(Product? p, {String? customName}) {
    setState(() {
      if (p != null) {
        final existing = _items.where((i) => i.product?.id == p.id).toList();
        if (existing.isNotEmpty) {
          existing.first.qty++;
        } else {
          _items.insert(0, _BillItem(product: p, name: p.name, price: p.sellingPrice));
        }
      } else if (customName != null && customName.trim().isNotEmpty) {
        final cleanName = customName.trim();
        _items.insert(0, _BillItem(product: null, name: cleanName, price: 0));
      }
    });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _showCustomerSelectionSheet() async {
    final rawData = await DatabaseHelper.instance.getCustomers();
    final customers = rawData.map<Customer>((json) {
      return Customer(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        notes: json['address'],
        outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Customer / ग्राहक निवडा', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.backgroundLight,
              leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person_off_rounded, color: Colors.grey)),
              title: Text('Walk-in Customer (साधा ग्राहक)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() => _selectedCustomer = null);
                Navigator.pop(ctx);
              },
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            Expanded(
              child: customers.isEmpty
                  ? Center(child: Text('No customers found.', style: GoogleFonts.outfit(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = customers[i];
                        final isSel = _selectedCustomer?.id == c.id;
                        return ListTile(
                          selected: isSel,
                          selectedTileColor: AppColors.royalBlue.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                            child: Text(c.name[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
                          ),
                          title: Text(c.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone ?? '', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 12)),
                          trailing: c.outstandingBalance > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text('Due: ₹${c.outstandingBalance.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () {
                            setState(() => _selectedCustomer = c);
                            Navigator.pop(ctx);
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

  Future<void> _showProductSelectionSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: AppColors.royalBlue),
                    const SizedBox(width: 10),
                    Text('Select Product / प्रॉडक्ट निवडा', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _dbProducts.isEmpty
                  ? Center(child: Text('No stock items in inventory.', style: GoogleFonts.outfit(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _dbProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final p = _dbProducts[i];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.royalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.royalBlue),
                          ),
                          title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stock: ${p.stock} Pcs • Selling Rate: ₹${p.sellingPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: const Icon(Icons.add_circle_rounded, color: AppColors.emeraldGreen, size: 24),
                          onTap: () {
                            _addItem(p);
                            Navigator.pop(ctx);
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

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _processPayment() async {
    // If cart is empty but user typed a product in search bar, auto add it!
    if (_items.isEmpty && _searchCtrl.text.trim().isNotEmpty) {
      final text = _searchCtrl.text.trim();
      final matches = _searchResults;
      if (matches.isNotEmpty) {
        _addItem(matches.first);
      } else {
        _addItem(null, customName: text);
      }
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('कृपया बिलात प्रॉडक्ट सेलेक्ट करा किंवा टाईप करा (Select or Type Product)', style: GoogleFonts.outfit()),
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
          content: Text('कृपया प्रॉडक्टची किंमत (Price) टाका.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isEdit = widget.billToEdit != null;
      final billNo = isEdit ? widget.billToEdit!['bill_number'] : await DatabaseHelper.instance.generateBillNumber();
      
      final billData = {
        'bill_number': billNo,
        'customer_id': _selectedCustomer?.id,
        'customer_name': _selectedCustomer?.name ?? 'Walk-in Customer',
        'customer_mobile': _selectedCustomer?.phone ?? '',
        'shop_name': prefs.getString('shop_name') ?? 'RetailFlow Cloth Shop',
        'shop_gstin': prefs.getString('shop_gstin') ?? '27AADCB2230M1Z2',
        'shop_address': prefs.getString('shop_address') ?? '123 Main Street, Market Area',
        'shop_phone': prefs.getString('shop_phone') ?? '+91 99422 20307',
        'subtotal': _subtotal,
        'discount': 0.0,
        'gst': _gstAmount,
        'grand_total': _grandTotal,
        'paid_amount': _paidAmount,
        'due_amount': _dueAmount,
        'payment_method': _paymentMethod,
        'bill_date': isEdit ? widget.billToEdit!['bill_date'] : DateTime.now().toIso8601String(),
        'created_at': isEdit ? widget.billToEdit!['created_at'] : DateTime.now().toIso8601String(),
      };

      final itemsData = _items.map((i) => {
        'product_id': i.product?.id ?? 0, // 0 for custom items so stock isn't affected
        'product_name': i.name,
        'quantity': i.qty,
        'selling_price': i.price,
        'total': i.total,
      }).toList();

      if (isEdit) {
        final billId = widget.billToEdit!['id'] is int ? widget.billToEdit!['id'] as int : int.tryParse(widget.billToEdit!['id'].toString()) ?? 0;
        await DatabaseHelper.instance.updateCompleteBill(billId, billData, itemsData);
      } else {
        await DatabaseHelper.instance.createCompleteBill(billData, itemsData);
      }

      // Update customer dues if balance remains and we just created a NEW customer bill 
      // (For edits, updateCompleteBill handles it perfectly!)
      if (!isEdit && _dueAmount > 0 && _selectedCustomer != null && _selectedCustomer!.id != null) {
        // We only do this for new bills because createCompleteBill doesn't actually do this if the customer already exists! 
        // Wait, createCompleteBill DOES update outstanding_balance. We don't need this extra call.
        // Let's remove the redundant updateCustomerDues call to prevent double addition.
      }

      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showBillSuccessfulAnimationAndNavigate(billData);
      
    } catch (e) {
      debugPrint('Bill save error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill save error: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showBillSuccessfulAnimationAndNavigate(Map<String, dynamic> billData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                'Bill Successful!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'Invoice #${billData['bill_number']} saved successfully.\nRedirection to Customer Screen...',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerListScreen(isEmbedded: false)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Go to Customer Screen',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerListScreen(isEmbedded: false)),
        );
      }
    });
  }

=======
>>>>>>> f9f7ac957573f0687f6e1d8855c034856ebba6c0
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _items.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Done & Close', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
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
                            minimumSize: const Size(0, 52),
                            backgroundColor: const Color(0xFF25D366),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          label: Text('Share WhatsApp', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ).animate().scale(begin: const Offset(0.98, 0.98), end: const Offset(1.0, 1.0), duration: 300.ms),
                      ),
                    ],
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
    _paidAmountCtrl.dispose();
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
            // 🌟 Premium White Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
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
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('Premium Invoice', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: Text('PRO', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _showCustomerSelectionSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.15),
                                child: Text((_selectedCustomer?.name.isNotEmpty == true) ? _selectedCustomer!.name[0].toUpperCase() : 'C',
                                    style: GoogleFonts.outfit(color: AppColors.royalBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedCustomer?.name ?? 'Select Customer (Walk-in)',
                                        style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(_selectedCustomer?.phone ?? 'Tap here to pick customer from list ▾',
                                        style: GoogleFonts.outfit(color: AppColors.royalBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_circle_rounded, color: AppColors.royalBlue, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          final matches = _searchResults;
                          if (matches.isNotEmpty) {
                            _addItem(matches.first);
                          } else {
                            _addItem(null, customName: text.trim());
                          }
                        }
                      },
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Type product name or select from list...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list_alt_rounded, color: AppColors.royalBlue),
                              tooltip: 'Browse All Stock',
                              onPressed: () => _showProductSelectionSheet(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_rounded, color: AppColors.emeraldGreen),
                              tooltip: 'Add Item',
                              onPressed: () {
                                if (_searchCtrl.text.trim().isNotEmpty) {
                                  final matches = _searchResults;
                                  if (matches.isNotEmpty) {
                                    _addItem(matches.first);
                                  } else {
                                    _addItem(null, customName: _searchCtrl.text.trim());
                                  }
                                }
                              },
                            ),
                          ],
                        ),
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

            // ⚡ Quick Inventory Product Chips
            if (_dbProducts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dbProducts.take(15).map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.royalBlue),
                          label: Text('${p.name} (₹${p.sellingPrice.toStringAsFixed(0)})',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                          side: BorderSide(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                          onPressed: () => _addItem(p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                          key: ObjectKey(item),
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
                      const SizedBox(height: 10),
                      
                      // 💵 Amount Received Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Received Amount', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('Amount Paid (₹)', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                          SizedBox(
                            width: 120,
                            height: 38,
                            child: TextField(
                              controller: _paidAmountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.emeraldGreen, fontSize: 15),
                              onChanged: (v) {
                                setState(() {
                                  _isManualPaidAmount = true;
                                });
                              },
                              decoration: InputDecoration(
                                prefixText: '₹',
                                prefixStyle: GoogleFonts.outfit(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold),
                                hintText: _grandTotal.toStringAsFixed(0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                filled: true,
                                fillColor: AppColors.emeraldGreen.withValues(alpha: 0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                          Text('₹${fmt.format(_grandTotal)}', 
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.royalBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 📌 Remaining Balance / Status Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _dueAmount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _dueAmount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _dueAmount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                              color: _dueAmount > 0 ? Colors.redAccent : AppColors.emeraldGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dueAmount > 0 ? 'Your remaining balance is ₹${fmt.format(_dueAmount)}' : 'Payment Status: PAID ✅',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _dueAmount > 0 ? Colors.red.shade700 : AppColors.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
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
                                    const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text(widget.billToEdit != null ? 'UPDATE & SAVE' : 'SAVE INVOICE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
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

