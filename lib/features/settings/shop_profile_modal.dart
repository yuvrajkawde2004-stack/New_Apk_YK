import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../dashboard/providers/dashboard_provider.dart';

class ShopProfileModal extends StatefulWidget {
  const ShopProfileModal({super.key});

  @override
  State<ShopProfileModal> createState() => _ShopProfileModalState();
}

class _ShopProfileModalState extends State<ShopProfileModal> {
  final _nameController = TextEditingController(text: 'RetailFlow');
  final _gstinController = TextEditingController(text: '27AADCB2230M1Z2');
  final _addressController = TextEditingController(text: '123 Main Street, Market Area, City');
  final _phoneController = TextEditingController(text: '+91 9876543210');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('shop_name') ?? 'RetailFlow';
      _gstinController.text = prefs.getString('shop_gstin') ?? '27AADCB2230M1Z2';
      _addressController.text = prefs.getString('shop_address') ?? '123 Main Street, Market Area, City';
      _phoneController.text = prefs.getString('shop_phone') ?? '+91 9876543210';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim();
    await prefs.setString('shop_name', name);
    await prefs.setString('shop_gstin', _gstinController.text.trim());
    await prefs.setString('shop_address', _addressController.text.trim());
    await prefs.setString('shop_phone', _phoneController.text.trim());

    // Save to DB for Cloud Sync
    await DatabaseHelper.instance.saveShopSettings({
      'shop_name': name,
      'gst_number': _gstinController.text.trim(),
      'address': _addressController.text.trim(),
      'mobile': _phoneController.text.trim(),
    });

    if (!mounted) return;
    Provider.of<DashboardProvider>(context, listen: false).updateShopName(name);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop Profile Updated Successfully'),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Shop Profile Settings',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                  child: const Icon(Icons.storefront_rounded, size: 48, color: AppColors.royalBlue),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTextField('Shop Name', Icons.store_rounded, _nameController),
            const SizedBox(height: 16),
            _buildTextField('GSTIN Number', Icons.receipt_rounded, _gstinController),
            const SizedBox(height: 16),
            _buildTextField('Business Address', Icons.location_on_rounded, _addressController),
            const SizedBox(height: 16),
            _buildTextField('Contact Number', Icons.phone_rounded, _phoneController),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.outfit(color: AppColors.textPrimaryLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
        prefixIcon: Icon(icon, color: AppColors.royalBlue),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
        ),
      ),
    );
  }
}
