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
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/sync_service.dart';
import '../dashboard/providers/dashboard_provider.dart';
import '../customers/customer_list_screen.dart';
import 'templates/invoice_template_classic_white.dart';
import 'templates/invoice_template_minimal_corporate.dart';
import 'templates/invoice_template_modern_indigo.dart';
import 'templates/invoice_template_elegant_emerald.dart';
import 'templates/invoice_template_premium_white.dart';
import '../inventory/add_purchase_screen.dart';

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
  double qty;
  double price;
  final TextEditingController priceCtrl;
  final FocusNode priceFocusNode;

  _BillItem({
    this.product,
    required this.name,
    this.qty = 1.0,
    this.price = 0,
  })  : priceCtrl = TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : ''),
        priceFocusNode = FocusNode();

  double get total => price * qty;
  
  void dispose() {
    priceCtrl.dispose();
    priceFocusNode.dispose();
  }
}

class _BillingScreenState extends State<BillingScreen> {
  final List<_BillItem> _items = [];
  final ScrollController _itemsScrollController = ScrollController();
  late Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';
  bool _isProcessing = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _paidAmountCtrl = TextEditingController();
  bool _isManualPaidAmount = false;

  final List<String> _paymentMethods = ['Cash', 'UPI'];
  final List<double> _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  double _globalGstPercent = 0.0;

  List<Product> _dbProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.billToEdit != null) {
      _loadBillToEdit();
    } else {
      _selectedCustomer = widget.customer;
    }
    _loadProducts();
  }

  Future<void> _loadBillToEdit() async {
    final bill = widget.billToEdit!;
    _selectedCustomer = Customer(
      id: bill['customer_id'] ?? 1,
      name: bill['customer_name'] ?? 'Walk-in Customer',
      phone: bill['customer_mobile'] ?? 'N/A',
      outstandingBalance: 0,
    );
    _paymentMethod = bill['payment_method'] ?? 'Cash';
    
    final paidAmt = (bill['paid_amount'] as num?)?.toDouble() ?? 0.0;
    _paidAmountCtrl.text = paidAmt > 0 ? paidAmt.toStringAsFixed(0) : '';
    if (paidAmt > 0) _isManualPaidAmount = true;

    // Load items
    final billId = bill['id'] is int ? bill['id'] as int : int.tryParse(bill['id'].toString()) ?? 0;
    final itemsData = await DatabaseHelper.instance.getBillItems(billId);
    
    setState(() {
      _items.clear();
      for (final item in itemsData) {
        final itemPrice = (item['selling_price'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0;
        final newItem = _BillItem(
          product: null,
          name: item['product_name'] ?? '',
          qty: item['quantity'] ?? 1,
          price: itemPrice,
        );
        newItem.priceFocusNode.addListener(() {
          if (newItem.priceFocusNode.hasFocus) {
            _scrollToItem(newItem);
          }
        });
        _items.add(newItem);
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
        unit: json['unit'] ?? 'PCS',
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
  double get _gstAmount => _subtotal * (_globalGstPercent / 100);
  double get _grandTotal => (_subtotal + _gstAmount).clamp(0.0, double.infinity);

  double get _paidAmount {
    if (!_isManualPaidAmount || _paidAmountCtrl.text.trim().isEmpty) {
      return _grandTotal;
    }
    return double.tryParse(_paidAmountCtrl.text.trim()) ?? _grandTotal;
  }

  double get _dueAmount => (_grandTotal - _paidAmount).clamp(0.0, double.infinity);

  void _scrollToItem(_BillItem item) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final idx = _items.indexOf(item);
      if (idx != -1 && _itemsScrollController.hasClients) {
        final maxScroll = _itemsScrollController.position.maxScrollExtent;
        // Adjusted offset for top widgets (Customer Card, Search, etc.) which take approx 250px
        final targetOffset = (250.0 + idx * 130.0).clamp(0.0, maxScroll);
        _itemsScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _addItem(Product? p, {String? customName}) {
    _BillItem? addedItem;
    setState(() {
      if (p != null) {
        final existing = _items.where((i) => i.product?.id == p.id).toList();
        if (existing.isNotEmpty) {
          existing.first.qty++;
          addedItem = existing.first;
        } else {
          addedItem = _BillItem(product: p, name: p.name, price: p.sellingPrice);
          _items.insert(0, addedItem!);
        }
      } else if (customName != null && customName.trim().isNotEmpty) {
        final cleanName = customName.trim();
        addedItem = _BillItem(product: null, name: cleanName, price: 0);
        _items.insert(0, addedItem!);
      }
    });

    if (addedItem != null) {
      final item = addedItem!;
      item.priceFocusNode.addListener(() {
        if (item.priceFocusNode.hasFocus) {
          _scrollToItem(item);
        }
      });
    }

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
                Text('Select Customer', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.backgroundLight,
              leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person_off_rounded, color: Colors.grey)),
              title: Text('Walk-in Customer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                    Text('Select Product', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showTopError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: (MediaQuery.of(context).size.height - 160).clamp(0.0, 9999.0),
          left: 20,
          right: 20,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

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

    if (_selectedCustomer == null) {
      _showTopError('Please select a customer first.');
      return;
    }

    if (_items.isEmpty) {
      _showTopError('Please select or type a product for the bill.');
      return;
    }
    
    // Validate if any item has 0 price
    if (_items.any((i) => i.price <= 0)) {
       _showTopError('Please enter item price.');
      return;
    }

    // Validate paid amount
    if (_isManualPaidAmount) {
      double enteredAmount = double.tryParse(_paidAmountCtrl.text.trim()) ?? 0.0;
      if (enteredAmount > _grandTotal) {
        _showTopError('Paid amount cannot exceed the bill amount (₹${_grandTotal.toStringAsFixed(0)}).');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final upiId = prefs.getString('upi_id') ?? '';
      final upiName = prefs.getString('upi_name') ?? '';

      if (_paymentMethod == 'UPI' && upiId.isEmpty) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please set up your UPI ID in Settings first.', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }
      final isEdit = widget.billToEdit != null;
      final billNo = isEdit ? widget.billToEdit!['bill_number'] : await DatabaseHelper.instance.generateBillNumber();
      final nowStr = DateTime.now().toIso8601String();
      final prevPaid = isEdit ? ((widget.billToEdit!['paid_amount'] as num?)?.toDouble() ?? 0.0) : 0.0;
      final isPaymentSettled = isEdit && (_paidAmount > prevPaid || _dueAmount <= 0);

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
        'bill_date': (isEdit && !isPaymentSettled) ? (widget.billToEdit!['bill_date'] ?? nowStr) : nowStr,
        'created_at': isEdit ? (widget.billToEdit!['created_at'] ?? nowStr) : nowStr,
      };

      final itemsData = _items.map((i) => {
        'product_id': i.product?.id ?? 0, // 0 for custom items so stock isn't affected
        'product_name': i.name,
        'quantity': i.qty,
        'selling_price': i.price,
        'total': i.total,
      }).toList();

      Future<void> saveBillData() async {
        if (isEdit) {
          final billId = widget.billToEdit!['id'] is int ? widget.billToEdit!['id'] as int : int.tryParse(widget.billToEdit!['id'].toString()) ?? 0;
          await DatabaseHelper.instance.updateCompleteBill(billId, billData, itemsData);
        } else {
          await DatabaseHelper.instance.createCompleteBill(billData, itemsData);
        }

        if (mounted) {
          Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
        }
        
        // Trigger immediate cloud sync
        SyncService().forceSync();
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      
      if (_paymentMethod == 'UPI') {
        setState(() => _isProcessing = false);
        _showUpiDialog(billData, upiId, upiName, () async {
          if (_isProcessing) return;
          setState(() => _isProcessing = true);
          try {
            await saveBillData();
            
            final billIdResult = await DatabaseHelper.instance.database.then((db) => db.query('bills', where: 'bill_number = ?', whereArgs: [billNo]));
            if (billIdResult.isNotEmpty) {
              final billId = billIdResult.first['id'] as int;
              await DatabaseHelper.instance.updateBill(billId, {
                'payment_status': 'Paid',
                'paid_at': DateTime.now().toIso8601String(),
              });
            }
            if (mounted) {
              setState(() => _isProcessing = false);
            }
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
        });
      } else {
        await saveBillData();
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        _showBillSuccessfulAnimationAndNavigate(billData);
      }
      
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
                widget.billToEdit != null ? 'Bill Updated Successfully!' : 'Bill Successful!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                widget.billToEdit != null
                    ? 'Invoice #${billData['bill_number']} updated successfully.'
                    : 'Invoice #${billData['bill_number']} saved successfully.\nRedirection to Customer Screen...',
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
                    if (widget.billToEdit != null) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerListScreen(isEmbedded: false)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.billToEdit != null ? 'OK' : 'Go to Customer Screen',
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
        if (widget.billToEdit != null) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerListScreen(isEmbedded: false)),
          );
        }
      }
    });
  }

  void _showUpiDialog(Map<String, dynamic> billData, String upiId, String upiName, VoidCallback onPaymentDone) {
    final amount = billData['paid_amount'];
    final billNo = billData['bill_number'];
    final qrData = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(upiName)}&am=$amount&cu=INR&tn=$billNo';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.royalBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Scan to Pay', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 16),
              
              // Amount with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.royalBlue, Color(0xFF6366F1)], // royalBlue to indigo
                ).createShader(bounds),
                child: Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              
              const SizedBox(height: 24),
              
              // QR Code Container with Scanner Animation
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow / Border
                  RepaintBoundary(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: AppColors.royalBlue.withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                          BoxShadow(color: AppColors.emeraldGreen.withOpacity(0.1), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10)),
                        ],
                        border: Border.all(color: AppColors.royalBlue.withOpacity(0.1), width: 2),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ),
                  // Scanner Laser Animation
                  Positioned(
                    top: 20,
                    child: RepaintBoundary(
                      child: Container(
                        width: 200, height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.transparent, AppColors.emeraldGreen, Colors.transparent]),
                          boxShadow: [BoxShadow(color: AppColors.emeraldGreen.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).slideY(begin: 0, end: 66, duration: 2.seconds, curve: Curves.easeInOut),
                    ),
                  ),
                ],
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24),
              
              // Paying To text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Paying to ', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
                    Flexible(
                      child: Text(upiName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Waiting badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldGreen),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WAITING FOR PAYMENT...',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF166534),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .fadeIn(duration: 800.ms).fadeOut(delay: 800.ms, duration: 800.ms),
              
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Skip', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.emeraldGreen.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onPaymentDone();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Payment Done', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
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
            
            final p = snapshot.data!;
            final tmpl = p.getString('invoice_template') ?? 'Classic White';
            
            final updatedBillData = Map<String, dynamic>.from(billData);
            if (p.getString('shop_name') != null) updatedBillData['shop_name'] = p.getString('shop_name');
            if (p.getString('shop_address') != null) updatedBillData['shop_address'] = p.getString('shop_address');
            if (p.getString('shop_phone') != null) updatedBillData['shop_phone'] = p.getString('shop_phone');
            if (p.getString('shop_gstin') != null) updatedBillData['shop_gstin'] = p.getString('shop_gstin');

            Widget invoiceWidget;
            if (tmpl == 'Minimal Corporate') {
              invoiceWidget = InvoiceTemplateMinimalCorporate(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Modern Indigo') {
              invoiceWidget = InvoiceTemplateModernIndigo(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Elegant Emerald') {
              invoiceWidget = InvoiceTemplateElegantEmerald(billData: updatedBillData, itemsData: itemsData);
            } else if (tmpl == 'Premium White') {
              invoiceWidget = InvoiceTemplatePremiumWhite(billData: updatedBillData, itemsData: itemsData);
            } else {
              invoiceWidget = InvoiceTemplateClassicWhite(billData: updatedBillData, itemsData: itemsData);
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
                              final image = await screenshotController.capture(pixelRatio: 4.0);
                              if (image == null) return;
                              
                              final directory = await getTemporaryDirectory();
                              final custName = (billData['customer_name'] ?? 'Customer').toString().replaceAll(' ', '_');
                              final imagePath = await File('${directory.path}/${custName}_Bill.png').create();
                              await imagePath.writeAsBytes(image);
                              
                              await Share.shareXFiles([XFile(imagePath.path)]);
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
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.billToEdit != null ? 'Edit Bill' : 'Create Bill',
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Add items and generate invoice',
                    style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                Text(
                  todayStr,
                  style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF0F172A)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _itemsScrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                    // 👤 Premium Customer Card
                    GestureDetector(
              onTap: _showCustomerSelectionSheet,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF818CF8)]),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1E293B),
                        child: Text(
                          (_selectedCustomer?.name.isNotEmpty == true) ? _selectedCustomer!.name[0].toUpperCase() : 'C',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCustomer?.name ?? 'Select Customer First',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCustomer?.phone ?? 'Tap here to pick customer from list ▾',
                            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Change', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔍 Search Bar & Dropdown
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textCapitalization: TextCapitalization.sentences,
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
                              tooltip: 'Add New Product to Inventory',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                                );
                                if (context.mounted) {
                                  _loadProducts();
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dbProducts.take(15).map((p) {
                      final colors = [
                        const Color(0xFF3B82F6), const Color(0xFF10B981),
                        const Color(0xFF8B5CF6), const Color(0xFFF43F5E),
                      ];
                      final color = colors[p.id % colors.length];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _addItem(p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: color),
                                const SizedBox(width: 4),
                                Text('${p.name} (₹${p.sellingPrice.toStringAsFixed(0)})',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.shopping_basket_rounded, size: 12, color: color),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // 🛒 Premium Items List
            _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40.0, bottom: 20.0, left: 16, right: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Custom Illustration
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120, height: 120,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFF3B82F6)),
                              const Positioned(top: 10, left: 10, child: Icon(Icons.star, size: 16, color: Color(0xFF93C5FD))),
                              const Positioned(bottom: 20, right: 10, child: Icon(Icons.circle, size: 10, color: Color(0xFFBFDBFE))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Cart is empty', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('Add items from stock or enter product name', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 32),
                          // Quick Add Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                                  child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Quick Add', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15)),
                                      Text('Tap on product shortcuts above to add items fast', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).scale(curve: Curves.easeOutBack),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                        final item = _items[i];
                        return Dismissible(
                          key: ObjectKey(item),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF87171), Color(0xFFEF4444)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                          ),
                          onDismissed: (_) => _removeItem(i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6))],
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: item.product != null ? AppColors.royalBlue : const Color(0xFFF59E0B), width: 4)),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: item.product != null ? AppColors.royalBlue.withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(item.product != null ? Icons.inventory_2_rounded : Icons.label_important_rounded, 
                                            color: item.product != null ? AppColors.royalBlue : const Color(0xFFF59E0B), size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(item.name, 
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('₹${fmt.format(item.total)}', 
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A))),
                                        ),
                                      ],
                                    ),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: Row(
                                              children: [
                                                Text('₹ ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                                                Expanded(
                                                  child: TextField(
                                                    controller: item.priceCtrl,
                                                    focusNode: item.priceFocusNode,
                                                    keyboardType: TextInputType.number,
                                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Enter Price',
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                    ),
                                                    onTap: () => _scrollToItem(item),
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
                                        const SizedBox(width: 12),
                                        Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              _qtyBtn(Icons.remove_rounded, () {
                                                setState(() { if (item.qty > 1) item.qty--; else _items.removeAt(i); });
                                              }),
                                              GestureDetector(
                                                onTap: () => _showQuantityDialog(item),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  alignment: Alignment.center,
                                                  child: Text('${item.qty % 1 == 0 ? item.qty.toInt() : item.qty} ${item.product?.unit ?? 'PCS'}', 
                                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                                                ),
                                              ),
                                              _qtyBtn(Icons.add_rounded, () => setState(() => item.qty++)),
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
                        ).animate().slideX(delay: (i * 40).ms, begin: 0.1).fadeIn();
                      },
                    ),
                  ],
                ),

            // 🧾 Premium Footer (Restructured to match image)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Text('Subtotal', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          Text('₹${fmt.format(_subtotal)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Apply GST
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.percent_rounded, color: Color(0xFFA855F7), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Text('Apply GST (%)', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: _globalGstPercent,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 15),
                                items: _gstOptions.map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('${v.toInt()}%'),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _globalGstPercent = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                      // Received Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Received Amount', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15)),
                                  Text('Enter paid amount', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: TextField(
                              controller: _paidAmountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), fontSize: 16),
                              onChanged: (v) {
                                setState(() {
                                  _isManualPaidAmount = true;
                                });
                              },
                              decoration: InputDecoration(
                                suffixText: '₹',
                                suffixStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                                hintText: '0',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Grand Total', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                                  Text('Amount to be paid', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text('₹${fmt.format(_grandTotal)}', 
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _dueAmount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _dueAmount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _dueAmount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                      color: _dueAmount > 0 ? Colors.redAccent : const Color(0xFF10B981),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _dueAmount > 0 ? 'DUE' : 'PAID',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: _dueAmount > 0 ? Colors.red.shade700 : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Payment Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _paymentMethods.map((m) {
                  final sel = _paymentMethod == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(m == 'Cash' ? Icons.money_rounded : Icons.qr_code_rounded, 
                              color: sel ? Colors.white : const Color(0xFF64748B), size: 18),
                            const SizedBox(width: 8),
                            Text(m, style: GoogleFonts.outfit(
                              color: sel ? Colors.white : const Color(0xFF64748B), 
                              fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Generate Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _processPayment,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(widget.billToEdit != null ? 'UPDATE INVOICE' : 'GENERATE INVOICE', 
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Text('Simple  •  Fast  •  Smart', 
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
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
  Future<void> _showQuantityDialog(_BillItem item) async {
    final TextEditingController qtyCtrl = TextEditingController(
      text: item.qty % 1 == 0 ? item.qty.toInt().toString() : item.qty.toString()
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Enter Quantity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. 1.5',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: item.product?.unit ?? 'PCS',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed = double.tryParse(qtyCtrl.text);
                if (parsed != null && parsed > 0) {
                  setState(() {
                    item.qty = parsed;
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

