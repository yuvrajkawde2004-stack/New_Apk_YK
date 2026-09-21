import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

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

  List<Map<String, dynamic>> _selectedSupplierLedger = [];
  bool _loadingLedger = false;

  Future<void> _loadSupplierLedger(String supName) async {
    setState(() => _loadingLedger = true);
    final pur = await DatabaseHelper.instance.getPurchasesBySupplier(supName);
    final pay = await DatabaseHelper.instance.getSupplierPayments(supName);
    
    final List<Map<String, dynamic>> allTrans = [];
    for (var p in pur) {
      allTrans.add({
        'date': p['purchase_date']?.toString().substring(0, 10) ?? '',
        'desc': 'Purchase (${p['product_name']})',
        'type': 'Purchase',
        'amt': (p['total_amount'] as num?)?.toDouble() ?? 0.0,
      });
    }
    for (var p in pay) {
      allTrans.add({
        'date': p['payment_date']?.toString().substring(0, 10) ?? '',
        'desc': 'Payment',
        'type': 'Payment',
        'amt': (p['amount_paid'] as num?)?.toDouble() ?? 0.0,
      });
    }
    
    allTrans.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    
    if (mounted) {
      setState(() {
        _selectedSupplierLedger = allTrans.take(5).toList();
        _loadingLedger = false;
      });
    }
  }

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
        _loadSupplierLedger(_selectedSupplierName!);
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
                  _loadSupplierLedger(val);
                }
              },
            ),
          
          if (_selectedSupplierName != null && _suppliers.any((s) => s['name'] == _selectedSupplierName))
            Builder(builder: (ctx) {
              final sup = _suppliers.firstWhere((s) => s['name'] == _selectedSupplierName);
              final fmt = NumberFormat('#,##,##0.00');
              final due = (sup['outstanding_due'] as num?)?.toDouble() ?? 0.0;
              final paid = (sup['total_paid'] as num?)?.toDouble() ?? 0.0;
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid (Jama): ₹${fmt.format(paid)}', style: GoogleFonts.outfit(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Due (Baki): ₹${fmt.format(due)}', style: GoogleFonts.outfit(color: due > 0 ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    if (_loadingLedger)
                       const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator())
                    else if (_selectedSupplierLedger.isNotEmpty) ...[
                      const Divider(height: 12),
                      Text('Recent Transactions:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      ..._selectedSupplierLedger.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${t['date']} - ${t['desc']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade800))),
                            Text(
                              t['type'] == 'Payment' ? 'Jama: ₹${fmt.format(t['amt'])}' : 'Bill: ₹${fmt.format(t['amt'])}',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: t['type'] == 'Payment' ? Colors.green.shade700 : Colors.red.shade700),
                            ),
                          ],
                        ),
                      )),
                    ]
                  ],
                ),
              );
            }),
            
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
                  onChanged: (v) {
                    setState(() {
                      item.quantity = int.tryParse(v) ?? 1;
                    });
                  },
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
                  onChanged: (v) {
                    setState(() {
                      item.purchaseRate = double.tryParse(v) ?? 0.0;
                    });
                  },
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 300.ms);
  }

  Widget _buildPaymentStatusBadge() {
    final double total = _totalPurchaseAmount;
    final double paid = double.tryParse(_paidCtrl.text) ?? 0.0;
    final double due = (total - paid) > 0 ? (total - paid) : 0.0;
    
    if (total == 0) return const SizedBox.shrink();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (paid == 0) {
      statusText = 'UNPAID (Due: ₹${due.toStringAsFixed(2)})';
      statusColor = Colors.red.shade700;
      statusIcon = Icons.error_outline;
    } else if (paid < total) {
      statusText = 'PARTIAL (Due: ₹${due.toStringAsFixed(2)})';
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = 'FULLY PAID';
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(statusText, style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
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
            onChanged: (val) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Amount Paid Now (₹)', prefixText: '₹ ', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _buildPaymentStatusBadge(),
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
            'total_purchased': 0.0,
            'total_paid': 0.0,
            'outstanding_due': 0.0,
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          supId = existingSup.first['id'] as int;
        }

        // 2. Insert Purchases and Products
        double totalPurchaseValue = 0.0;
        final nowStr = DateTime.now().toIso8601String();
        for (var item in _items) {
          final pName = item.name.trim();
          final qty = item.quantity;
          final rate = item.purchaseRate;
          totalPurchaseValue += (rate * qty);
          
          await txn.insert('purchases', {
            'product_id': 0,
            'product_name': pName,
            'supplier_name': sup,
            'purchase_rate': rate,
            'quantity': qty,
            'total_amount': rate * qty,
            'paid_amount': 0.0,
            'due_amount': 0.0,
            'purchase_date': nowStr,
            'notes': _noteCtrl.text.trim(),
            'created_at': nowStr,
          });

          // Update Stock
          final existingProd = await txn.query('products', where: 'product_name = ?', whereArgs: [pName]);
          if (existingProd.isNotEmpty) {
            final currentQty = (existingProd.first['quantity'] as num?)?.toInt() ?? 0;
            await txn.update(
              'products',
              {
                'quantity': currentQty + qty,
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
              'quantity': qty,
              'purchase_rate': rate,
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
        final supData = await txn.query('suppliers', where: 'id = ?', whereArgs: [supId]);
        if (supData.isNotEmpty) {
          double curPurchased = (supData.first['total_purchased'] as num?)?.toDouble() ?? 0.0;
          double curPaid = (supData.first['total_paid'] as num?)?.toDouble() ?? 0.0;
          
          final newPurchased = curPurchased + totalPurchaseValue;
          final newPaid = curPaid + paid;
          final newDue = (newPurchased - newPaid) > 0 ? (newPurchased - newPaid) : 0.0;

          await txn.update(
            'suppliers',
            {
              'total_purchased': newPurchased,
              'total_paid': newPaid,
              'outstanding_due': newDue
            },
            where: 'id = ?',
            whereArgs: [supId],
          );
        }
        
        // 4. Add SINGLE Payment Log
        if (paid > 0) {
          final pDate = DateTime.now().toIso8601String();
          await txn.insert('supplier_payments', {
            'supplier_name': sup,
            'amount_paid': paid,
            'payment_method': 'Cash',
            'payment_date': pDate,
            'created_at': pDate,
          });
          
          await txn.insert('purchase_bill_payments', {
            'bill_key': nowStr,
            'amount_paid': paid,
            'payment_date': pDate,
            'created_at': pDate,
          });
        }
      });
      
      if (widget.onSaved != null) widget.onSaved!();
      
      if (mounted) {
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text('${_items.length} Product(s) added successfully!'),
        //   backgroundColor: Colors.green,
        // ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
