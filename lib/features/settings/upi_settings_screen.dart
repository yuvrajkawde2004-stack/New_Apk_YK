import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';

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
  String _previewQrData = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getShopSettings();
    if (settings != null) {
      _upiIdController.text = settings['upi_id'] ?? '';
      _upiNameController.text = settings['upi_name'] ?? '';
      _updateQrPreview();
    }
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

    final settings = await DatabaseHelper.instance.getShopSettings() ?? {};
    
    settings['upi_id'] = _upiIdController.text.trim();
    settings['upi_name'] = _upiNameController.text.trim();
    
    await DatabaseHelper.instance.saveShopSettings(settings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI Settings Saved successfully!'), backgroundColor: AppColors.emeraldGreen),
      );
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
                onChanged: (_) => _updateQrPreview(),
                decoration: InputDecoration(
                  labelText: 'UPI ID / VPA',
                  hintText: 'e.g. 9876543210@ybl',
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryBlue),
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
                onChanged: (_) => _updateQrPreview(),
                decoration: InputDecoration(
                  labelText: 'Display Name (Payee Name)',
                  hintText: 'e.g. ABC Supermart',
                  prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Save UPI Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryBlue),
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
