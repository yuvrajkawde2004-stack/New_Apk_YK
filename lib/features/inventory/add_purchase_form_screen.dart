import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';

class AddPurchaseFormScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? initialSupplierName;
  const AddPurchaseFormScreen({super.key, this.onSaved, this.initialSupplierName});

  @override
  State<AddPurchaseFormScreen> createState() => _AddPurchaseFormScreenState();
}

class _AddPurchaseFormScreenState extends State<AddPurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSupplierName;
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  String _category = 'Electronics'; // Default category
  final _brandCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _gst = '5';
  String _unit = 'PCS';
  final _qtyCtrl = TextEditingController();
  bool _lowStockAlert = true;
  final _alertQtyCtrl = TextEditingController(text: '5');
  final _notesCtrl = TextEditingController();

  final List<String> _categories = ['Electronics', 'Clothing', 'Grocery', 'Hardware', 'Other'];
  final List<String> _gstRates = ['0', '5', '12', '18', '28'];
  final List<String> _units = ['PCS', 'PAIR', 'KG', 'G', 'MTR', 'ROLL', 'BOX', 'PACK', 'SET', 'DOZ', 'LTR', 'ML'];

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color buttonGreen = Color(0xFF10B981);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1F2937);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color iconBg = Color(0xFFEAF9F1);

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
      }
      _loading = false;
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final brand = _brandCtrl.text.trim();
      final rate = double.parse(_rateCtrl.text);
      final qty = int.parse(_qtyCtrl.text);
      final alertQty = int.parse(_alertQtyCtrl.text);
      final notes = _notesCtrl.text.trim();
      final date = DateTime.now().toIso8601String();
      final totalAmount = rate * qty;

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // 1. Check if product exists
        int productId = 0;
        final existingProduct = await txn.query('products', where: 'product_name = ?', whereArgs: [name], limit: 1);
        if (existingProduct.isEmpty) {
          productId = await txn.insert('products', {
            'product_name': name,
            'category': _category,
            'purchase_rate': rate,
            'quantity': qty,
            'supplier_name': _selectedSupplierName,
            'purchase_date': date,
            'low_stock_limit': alertQty,
            'unit': _unit,
            'notes': brand.isNotEmpty ? 'Brand: $brand\n$notes' : notes,
            'created_at': date,
          });
        } else {
          productId = existingProduct.first['id'] as int;
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ?, purchase_rate = ? WHERE id = ?',
            [qty, rate, productId],
          );
        }

        // 2. Insert into purchases
        await txn.insert('purchases', {
          'product_id': productId,
          'product_name': name,
          'supplier_name': _selectedSupplierName,
          'purchase_rate': rate,
          'quantity': qty,
          'total_amount': totalAmount,
          'paid_amount': 0.0,
          'due_amount': totalAmount,
          'purchase_date': date,
          'notes': notes,
          'created_at': date,
        });

        // 3. Update supplier dues
        await txn.rawUpdate(
          'UPDATE suppliers SET total_purchased = total_purchased + ?, outstanding_due = outstanding_due + ? WHERE name = ?',
          [totalAmount, totalAmount, _selectedSupplierName],
        );
      });

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType, IconData? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(color: labelGrey, fontSize: 13, fontWeight: FontWeight.w600),
            children: [
              if (required) TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red)),
              if (!required && !label.contains('(Optional)')) TextSpan(text: ' (Optional)', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: textDark, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryGreen, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, {IconData? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(color: labelGrey, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryGreen, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: backgroundLight, appBar: AppBar(backgroundColor: primaryGreen, elevation: 0), body: const Center(child: CircularProgressIndicator(color: primaryGreen)));
    }

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Purchase', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            Text('Add a new purchase to your inventory', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image placeholder
                        Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: primaryGreen, size: 32),
                              const SizedBox(height: 8),
                              Text('Add Product Image\n(Optional)', textAlign: TextAlign.center, style: GoogleFonts.inter(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildTextField('Product Name', _nameCtrl, required: true, prefixIcon: Icons.inventory_2_outlined),
                              const SizedBox(height: 12),
                              _buildDropdown('Category *', _category, _categories, (v) => setState(() => _category = v!), prefixIcon: Icons.category_outlined),
                              const SizedBox(height: 12),
                              _buildTextField('Brand', _brandCtrl, prefixIcon: Icons.local_offer_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Stock Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.currency_rupee, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text('Pricing & Stock Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Purchase Rate (₹)', _rateCtrl, required: true, keyboardType: TextInputType.number, prefixIcon: Icons.currency_rupee)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdown('GST (%)', _gst, _gstRates, (v) => setState(() => _gst = v!), prefixIcon: Icons.percent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('Unit', _unit, _units, (v) => setState(() => _unit = v!), prefixIcon: Icons.layers_outlined)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Quantity (Stock)', _qtyCtrl, required: true, keyboardType: TextInputType.number, prefixIcon: Icons.widgets_outlined)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Low Stock Alert
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_none, color: primaryGreen),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Low Stock Alert', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryGreen, fontSize: 14)),
                                    Text('Notify when stock is below limit', style: GoogleFonts.inter(color: primaryGreen.withOpacity(0.8), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _lowStockAlert,
                                activeColor: primaryGreen,
                                onChanged: (v) => setState(() => _lowStockAlert = v),
                              ),
                              if (_lowStockAlert) ...[
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _alertQtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Qty',
                                      labelStyle: GoogleFonts.inter(fontSize: 12, color: primaryGreen),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryGreen)),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Additional Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.note_alt_outlined, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text('Additional Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: 'Notes (optional)',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
              elevation: 0,
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text('Save Purchase', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
            onPressed: _saving ? null : _savePurchase,
          ),
        ),
      ),
    );
  }
}
