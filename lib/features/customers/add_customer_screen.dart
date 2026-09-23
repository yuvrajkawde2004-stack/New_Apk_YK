import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import 'contact_selection_sheet.dart';

class AddCustomerScreen extends StatefulWidget {
  final VoidCallback? onCustomerAdded;

  const AddCustomerScreen({super.key, this.onCustomerAdded});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  String _selectedCategory = 'Regular';
  bool _saving = false;

  static const Color primaryGreen = Color(0xFF064E3B);
  static const Color textDark = Color(0xFF1F2937);

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);

    try {
      await DatabaseHelper.instance.addCustomer({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'category': _selectedCategory,
        'outstanding_balance': 0.0,
      });

      if (mounted) {
        widget.onCustomerAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Mobile number might already exist.'), backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildTopTabs() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_add_alt_1_outlined, color: primaryGreen, size: 28),
                const SizedBox(height: 8),
                Text('Add Manually', style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold)),
                Text('Enter details yourself', style: GoogleFonts.inter(color: primaryGreen, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              ContactSelectionSheet.show(context, onAdded: widget.onCustomerAdded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.contact_phone_outlined, color: Colors.grey.shade600, size: 28),
                  const SizedBox(height: 8),
                  Text('Import from Contacts', style: GoogleFonts.inter(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                  Text('Select from phone contacts', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType, IconData? prefixIcon, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
            children: [
              if (required) TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Add Customer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _saving 
        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopTabs(),
                  const SizedBox(height: 24),
                  _buildTextField('Customer Name', _nameCtrl, required: true, prefixIcon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField('Mobile Number', _phoneCtrl, required: true, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                  const SizedBox(height: 16),
                  _buildTextField('Email (Optional)', _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField('Address (Optional)', _addressCtrl, prefixIcon: Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  Text('Category', style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Regular', 'Credit', 'VIP'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(cat, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade700)),
                          selected: isSelected,
                          selectedColor: primaryGreen,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveCustomer,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text('Save Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }
}
