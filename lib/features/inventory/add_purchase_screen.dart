import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';

class AddPurchaseScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? initialSupplierName;
  const AddPurchaseScreen({super.key, this.onSaved, this.initialSupplierName});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseItem {
  String name = '';
  String unit = 'PCS';
  double purchaseRate = 0.0;
  int quantity = 1;
  int lowStock = 5;
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedSupplierName;
  final _supCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  bool _saving = false;
  List<Map<String, dynamic>> _suppliers = [];
  final List<String> _units = ['PCS', 'PAIR', 'KG', 'G', 'MTR', 'ROLL', 'BOX', 'PACK', 'SET', 'DOZ', 'LTR', 'ML'];
  
  final List<_AddPurchaseItem> _items = [_AddPurchaseItem()];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final sups = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      _suppliers = sups;
      if (sups.isNotEmpty) {
        if (widget.initialSupplierName != null && sups.any((s) => s['name'] == widget.initialSupplierName)) {
          _selectedSupplierName = widget.initialSupplierName;
        } else {
          _selectedSupplierName = sups.first['name'];
        }
        _supCtrl.text = _selectedSupplierName!;
      }
    });
  }

  double get _totalPurchaseAmount {
    double total = 0.0;
    for (var item in _items) {
      total += (item.purchaseRate * item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Add Multiple Products (Purchase)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
      ),
      body: _saving 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSupplierSection(),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Products', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _items.add(_AddPurchaseItem());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Product'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.royalBlue),
                    )
                  ],
                ),
                
                ...List.generate(_items.length, (index) => _buildProductItem(index)),
                
                const SizedBox(height: 16),
                _buildPaymentSection(),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _savePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('SAVE PRODUCTS & PURCHASE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildSupplierSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supplier Details', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 16),
          if (_suppliers.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedSupplierName,
              decoration: const InputDecoration(labelText: 'Select Existing Supplier', border: OutlineInputBorder()),
              items: _suppliers.map((s) => DropdownMenuItem(value: s['name'] as String, child: Text(s['name']))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSupplierName = val;
                    _supCtrl.text = val;
                  });
                }
              },
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _supCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Or Type Supplier Name', border: OutlineInputBorder()),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Supplier Phone (Optional)', prefixText: '+91 ', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Product ${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _items.removeAt(index)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
            onChanged: (v) => item.name = v,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty *', border: OutlineInputBorder()),
                  onChanged: (v) => item.quantity = int.tryParse(v) ?? 1,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: item.unit,
                  decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setState(() => item.unit = val ?? 'PCS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.purchaseRate == 0 ? '' : item.purchaseRate.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Purchase Rate (₹) *', prefixText: '₹ ', border: OutlineInputBorder()),
                  onChanged: (v) => item.purchaseRate = double.tryParse(v) ?? 0.0,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 300.ms);
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bill Amount:', style: GoogleFonts.outfit(fontSize: 16)),
              Text('₹${_totalPurchaseAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
            ],
          ),
          const Divider(height: 24),
          TextFormField(
            controller: _paidCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount Paid Now (₹)', prefixText: '₹ ', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes (optional)', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields correctly.')));
      return;
    }
    
    final sup = _supCtrl.text.trim();
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isNotEmpty && rawPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier mobile must be 10 digits.')));
      return;
    }
    final phoneVal = rawPhone.isEmpty ? '' : (rawPhone.startsWith('+91') ? rawPhone : '+91 $rawPhone');
    final paid = double.tryParse(_paidCtrl.text) ?? 0.0;
    
    setState(() => _saving = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        
        // 1. Supplier Check
        int supId = 0;
        final existingSup = await txn.query('suppliers', where: 'name = ?', whereArgs: [sup]);
        if (existingSup.isEmpty) {
          supId = await txn.insert('suppliers', {
            'name': sup,
            'phone': phoneVal,
            'outstanding_balance': 0.0,
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          supId = existingSup.first['id'] as int;
        }

        // 2. Insert Purchases and Products
        double totalPurchaseValue = 0.0;
        for (var item in _items) {
          final pName = item.name.trim();
          final qty = item.quantity;
          final rate = item.purchaseRate;
          totalPurchaseValue += (rate * qty);
          
          final nowStr = DateTime.now().toIso8601String();
          
          await txn.insert('purchases', {
            'product_name': pName,
            'supplier_name': sup,
            'purchase_rate': rate,
            'selling_price': 0.0, // Selling price removed
            'quantity': qty,
            'paid_amount': 0.0, // We will handle total payment below
            'unit': item.unit,
            'purchase_date': nowStr,
            'notes': _noteCtrl.text.trim(),
            'created_at': nowStr,
          });

          // Update Stock
          final existingProd = await txn.query('products', where: 'product_name = ?', whereArgs: [pName]);
          if (existingProd.isNotEmpty) {
            final currentQty = (existingProd.first['stock_quantity'] as num?)?.toInt() ?? 0;
            await txn.update(
              'products',
              {
                'stock_quantity': currentQty + qty,
                'purchase_rate': rate,
                // Do not override selling price if they set it elsewhere
                'supplier_name': sup,
                'unit': item.unit,
              },
              where: 'product_name = ?',
              whereArgs: [pName],
            );
          } else {
            await txn.insert('products', {
              'product_name': pName,
              'category': 'General',
              'stock_quantity': qty,
              'purchase_rate': rate,
              'selling_price': 0.0,
              'supplier_name': sup,
              'unit': item.unit,
              'low_stock_limit': item.lowStock,
              'created_at': nowStr,
            });
          }
        }
        
        // 3. Handle Payment and Outstanding Balance
        final dueAmount = totalPurchaseValue - paid;
        
        // Update outstanding balance
        if (dueAmount != 0) {
          final supData = await txn.query('suppliers', where: 'id = ?', whereArgs: [supId]);
          if (supData.isNotEmpty) {
            double currentOutstanding = (supData.first['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
            currentOutstanding += dueAmount;
            await txn.update(
              'suppliers',
              {'outstanding_balance': currentOutstanding},
              where: 'id = ?',
              whereArgs: [supId],
            );
          }
        }
        
        // 4. Add SINGLE Payment Log
        if (paid > 0) {
          await txn.insert('supplier_payments', {
            'supplier_name': sup,
            'amount_paid': paid,
            'payment_method': 'Cash',
            'payment_date': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });
      
      if (widget.onSaved != null) widget.onSaved!();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_items.length} Product(s) added successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
