import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import '../customers/contact_selection_sheet.dart';

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
  static const Color backgroundLight = Color(0xFFE8F0EA);
  static const Color textDark = Color(0xFF1F2937);

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

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, IconData? prefixIcon, String? hintText, Widget? labelSuffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: GoogleFonts.inter(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                children: [
                  if (required) TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red)),
                  if (!required && !label.contains('(Optional)')) TextSpan(text: ' (Optional)', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            if (labelSuffix != null) labelSuffix,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(color: textDark, fontSize: 15),
          maxLines: label.contains('Address') ? 3 : 1,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF4B5563), size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'This field is required' : null : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopTabs() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_add_alt_1_outlined, color: primaryGreen, size: 24),
                const SizedBox(height: 4),
                Text('Add Manually', style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              ContactSelectionSheet.show(
                context, 
                isSupplier: true, 
                onAdded: () => Navigator.pop(context, true),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.contact_phone_outlined, color: Colors.grey.shade600, size: 24),
                  const SizedBox(height: 4),
                  Text('Import Contacts', style: GoogleFonts.inter(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
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
        centerTitle: true,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTopTabs(),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.handshake_outlined, color: primaryGreen, size: 28),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.grey.shade500, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Profile Photo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.security_outlined, color: primaryGreen, size: 28),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Provide detailed info to securely register your supplier',
                                style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Form Fields
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField('Supplier Name', _nameCtrl, required: true, prefixIcon: Icons.domain_rounded),
                                _buildTextField('Mobile Number', _mobileCtrl, required: true, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, hintText: 'ex. 9876543210', inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                                _buildTextField('Email', _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined, hintText: 'ex. contact@company.com'),
                                _buildTextField('Address', _addressCtrl, required: true, prefixIcon: Icons.location_on_outlined),
                                
                                _buildTextField(
                                  'GST Number (Optional)', 
                                  _gstCtrl, 
                                  prefixIcon: Icons.receipt_long_outlined, 
                                  hintText: 'ex. 27AAAC1234A1Z5',
                                  labelSuffix: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('GST is for invoice accuracy', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF064E3B)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _saveSupplier,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                    ),
                                    child: Text('Save Supplier', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
