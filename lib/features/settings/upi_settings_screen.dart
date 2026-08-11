import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_helper.dart';

class UPISettingsScreen extends StatefulWidget {
  const UPISettingsScreen({super.key});

  @override
  State<UPISettingsScreen> createState() => _UPISettingsScreenState();
}

class _UPISettingsScreenState extends State<UPISettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _upiNameController = TextEditingController();
  
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String _previewQrData = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _upiIdController.text = prefs.getString('upi_id') ?? '';
    _upiNameController.text = prefs.getString('upi_name') ?? '';
    _updateQrPreview();
    setState(() => _isLoading = false);
  }

  void _updateQrPreview() {
    final upiId = _upiIdController.text.trim();
    final name = _upiNameController.text.trim();
    if (upiId.isNotEmpty) {
      setState(() {
        _previewQrData = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(name)}&cu=INR';
      });
    } else {
      setState(() => _previewQrData = '');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('upi_id', _upiIdController.text.trim());
    await prefs.setString('upi_name', _upiNameController.text.trim());
    
    // Save to DB for Cloud Sync
    await DatabaseHelper.instance.saveShopSettings({
      'upi_id': _upiIdController.text.trim(),
      'upi_name': _upiNameController.text.trim(),
    });
    
    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('UPI Settings Saved successfully!'), backgroundColor: AppColors.emeraldGreen),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('UPI & Payment Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accept Payments via UPI', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter your UPI ID to generate dynamic QR codes during billing. Zero transaction fees.', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
              
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _upiIdController,
                onChanged: (_) {
                  setState(() => _hasUnsavedChanges = true);
                  _updateQrPreview();
                },
                decoration: InputDecoration(
                  labelText: 'UPI ID / VPA',
                  hintText: 'e.g. 9876543210@ybl',
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.royalBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && !val.contains('@')) {
                    return 'Please enter a valid UPI ID (must contain @)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _upiNameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  setState(() => _hasUnsavedChanges = true);
                  _updateQrPreview();
                },
                decoration: InputDecoration(
                  labelText: 'Display Name (Payee Name)',
                  hintText: 'e.g. ABC Supermart',
                  prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.royalBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (_hasUnsavedChanges)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Save UPI Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen),
                        const SizedBox(width: 8),
                        Text('Settings Saved', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.emeraldGreen, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 48),
              
              if (_previewQrData.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      Text('QR Code Preview', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: QrImageView(
                          data: _previewQrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.royalBlue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Scan with any UPI App to test', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
