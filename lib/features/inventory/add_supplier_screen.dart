import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  bool _saving = false;

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color buttonGreen = Color(0xFF10B981);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1F2937);
  static const Color labelGrey = Color(0xFF6B7280);

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);

    try {
      final db = await DatabaseHelper.instance.database;
      
      final existingSup = await db.query('suppliers', where: 'name = ?', whereArgs: [_nameCtrl.text.trim()]);
      if (existingSup.isNotEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier with this name already exists')));
        return;
      }

      await DatabaseHelper.instance.addSupplier({
        'name': _nameCtrl.text.trim(),
        'phone': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gst_number': _gstCtrl.text.trim(),
        'outstanding_due': 0.0,
        'total_purchased': 0.0,
        'total_paid': 0.0,
      });

      if (mounted) {
        Navigator.pop(context, true); // true indicates success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(color: labelGrey, fontSize: 13, fontWeight: FontWeight.w500),
            children: [
              if (required) TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red)),
              if (!required) TextSpan(text: ' (Optional)', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: textDark, fontSize: 15),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: buttonGreen, width: 1.5),
            ),
          ),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'This field is required' : null : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Add Supplier', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Supplier Name', _nameCtrl, required: true),
                      _buildTextField('Mobile Number', _mobileCtrl, required: true, keyboardType: TextInputType.phone),
                      _buildTextField('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
                      _buildTextField('Address', _addressCtrl, required: true),
                      _buildTextField('GST Number', _gstCtrl),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveSupplier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: Text('Save Supplier', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
